import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/taxi.dart';
import 'supabase_client.dart';

// ─────────────────────────────────────────────
// TAXI CATEGORIES PROVIDER
// Mirrors useTaxiCategories() — active categories sorted by base_fare.
// ─────────────────────────────────────────────

final taxiCategoriesProvider =
    FutureProvider<List<TaxiVehicleCategory>>((ref) async {
  final data = await PearlHubSupabase.client
      .from('taxi_vehicle_categories')
      .select()
      .eq('is_active', true)
      .order('base_fare', ascending: true);

  return (data as List).map((e) => TaxiVehicleCategory.fromJson(e)).toList();
});

// ─────────────────────────────────────────────
// CUSTOMER RIDES PROVIDER
// Mirrors useTaxiRides().
// ─────────────────────────────────────────────

final taxiRidesProvider =
    FutureProvider.family<List<TaxiRide>, String>((ref, userId) async {
  final data = await PearlHubSupabase.client
      .from('taxi_rides')
      .select()
      .eq('customer_id', userId)
      .order('created_at', ascending: false);

  return (data as List).map((e) => TaxiRide.fromJson(e)).toList();
});

// ─────────────────────────────────────────────
// PROVIDER RIDES
// Mirrors useTaxiProviderRides().
// ─────────────────────────────────────────────

final taxiProviderRidesProvider =
    FutureProvider.family<List<TaxiRide>, String>((ref, providerId) async {
  final data = await PearlHubSupabase.client
      .from('taxi_rides')
      .select()
      .eq('provider_id', providerId)
      .order('created_at', ascending: false)
      .limit(20);

  return (data as List).map((e) => TaxiRide.fromJson(e)).toList();
});

// ─────────────────────────────────────────────
// PROMO VALIDATION
// Mirrors validateTaxiPromo().
// ─────────────────────────────────────────────

class PromoValidationResult {
  final bool valid;
  final String? error;
  final String? discountType;
  final double? discountAmount;
  final String? id;

  const PromoValidationResult({
    required this.valid,
    this.error,
    this.discountType,
    this.discountAmount,
    this.id,
  });
}

Future<PromoValidationResult> validateTaxiPromo(String code) async {
  final data = await PearlHubSupabase.client
      .from('taxi_promo_codes')
      .select()
      .eq('code', code.trim().toUpperCase())
      .eq('is_active', true)
      .maybeSingle();

  if (data == null) {
    return const PromoValidationResult(valid: false, error: 'Invalid promo code');
  }

  final promo = TaxiPromo.fromJson(data);

  if (promo.usesCount >= promo.maxUses) {
    return const PromoValidationResult(valid: false, error: 'Promo exhausted');
  }
  if (promo.validUntil != null &&
      DateTime.parse(promo.validUntil!).isBefore(DateTime.now())) {
    return const PromoValidationResult(valid: false, error: 'Promo expired');
  }

  return PromoValidationResult(
    valid: true,
    discountType: promo.discountType,
    discountAmount: promo.discountAmount,
    id: promo.id,
  );
}

// ─────────────────────────────────────────────
// ADMIN STATS
// Mirrors useTaxiAdminStats().
// ─────────────────────────────────────────────

class TaxiAdminStats {
  final double revenue;
  final int rides;
  final int driversOnline;
  final int pendingKyc;
  final int totalRides;

  const TaxiAdminStats({
    required this.revenue,
    required this.rides,
    required this.driversOnline,
    required this.pendingKyc,
    required this.totalRides,
  });
}

final taxiAdminStatsProvider = FutureProvider<TaxiAdminStats>((ref) async {
  final results = await Future.wait([
    PearlHubSupabase.client.from('taxi_rides').select('fare, status'),
    PearlHubSupabase.client
        .from('taxi_provider_locations')
        .select()
        .eq('is_online', true),
    PearlHubSupabase.client
        .from('taxi_kyc_documents')
        .select()
        .eq('verification_status', 'pending'),
  ]);

  final rides = results[0] as List;
  final driversOnline = results[1] as List;
  final pendingKyc = results[2] as List;

  final completed = rides.where((r) => r['status'] == 'completed').toList();
  final revenue =
      completed.fold<double>(0, (sum, r) => sum + (r['fare'] as num? ?? 0));

  return TaxiAdminStats(
    revenue: revenue,
    rides: completed.length,
    driversOnline: driversOnline.length,
    pendingKyc: pendingKyc.length,
    totalRides: rides.length,
  );
});

// ─────────────────────────────────────────────
// REALTIME RIDE TRACKING
// The core fix: replaces web app's hardcoded mock coordinates
// with actual Supabase Realtime channel subscriptions.
//
// Flow:
//   Customer books ride → INSERT into taxi_rides
//   Flutter subscribes: supabase.channel('taxi-ride-{id}').onPostgresChanges(UPDATE)
//   Any status change → Flutter UI updates in real time — no polling
// ─────────────────────────────────────────────

class TaxiRealtimeService {
  RealtimeChannel? _rideChannel;
  RealtimeChannel? _locationChannel;

  /// Subscribe to ride status changes for a specific ride.
  /// Returns a stream of TaxiRide updates.
  Stream<TaxiRide> subscribeToRide(String rideId) {
    final controller = StreamController<TaxiRide>.broadcast();

    _rideChannel = PearlHubSupabase.client.channel('taxi-ride-$rideId');

    _rideChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'taxi_rides',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: rideId,
          ),
          callback: (payload) {
            final newData = payload.newRecord;
            if (newData.isNotEmpty) {
              controller.add(TaxiRide.fromJson(newData));
            }
          },
        )
        .subscribe();

    controller.onCancel = () => unsubscribeFromRide();

    return controller.stream;
  }

  /// Subscribe to driver location updates for a specific provider.
  Stream<TaxiProviderLocation> subscribeToDriverLocation(String providerId) {
    final controller = StreamController<TaxiProviderLocation>.broadcast();

    _locationChannel =
        PearlHubSupabase.client.channel('driver-location-$providerId');

    _locationChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'taxi_provider_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'provider_id',
            value: providerId,
          ),
          callback: (payload) {
            final newData = payload.newRecord;
            if (newData.isNotEmpty) {
              controller.add(TaxiProviderLocation.fromJson(newData));
            }
          },
        )
        .subscribe();

    controller.onCancel = () => unsubscribeFromDriverLocation();

    return controller.stream;
  }

  /// Unsubscribe from ride updates.
  void unsubscribeFromRide() {
    _rideChannel?.unsubscribe();
    _rideChannel = null;
  }

  /// Unsubscribe from driver location updates.
  void unsubscribeFromDriverLocation() {
    _locationChannel?.unsubscribe();
    _locationChannel = null;
  }

  /// Clean up all subscriptions.
  void dispose() {
    unsubscribeFromRide();
    unsubscribeFromDriverLocation();
  }
}

/// Singleton provider for the taxi realtime service.
final taxiRealtimeServiceProvider = Provider<TaxiRealtimeService>((ref) {
  final service = TaxiRealtimeService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ─────────────────────────────────────────────
// RIDE BOOKING
// Creates a new taxi ride in the database.
// ─────────────────────────────────────────────

Future<TaxiRide> bookTaxiRide({
  required String customerId,
  required double pickupLat,
  required double pickupLng,
  String? pickupAddress,
  required double dropoffLat,
  required double dropoffLng,
  String? dropoffAddress,
  required String vehicleCategoryId,
  String rideModule = 'ride',
  Map<String, dynamic>? parcelDetails,
  List<Map<String, dynamic>>? stops,
  String paymentMethod = 'cash',
  double surgeMultiplier = 1.0,
  String? scheduledFor,
  String? promoId,
}) async {
  final data = await PearlHubSupabase.client
      .from('taxi_rides')
      .insert({
        'customer_id': customerId,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'pickup_address': pickupAddress,
        'dropoff_lat': dropoffLat,
        'dropoff_lng': dropoffLng,
        'dropoff_address': dropoffAddress,
        'vehicle_category_id': vehicleCategoryId,
        'status': 'searching',
        'ride_module': rideModule,
        'parcel_details': parcelDetails,
        'stops': stops,
        'payment_method': paymentMethod,
        'surge_multiplier': surgeMultiplier,
        'scheduled_for': scheduledFor,
        'promo_id': promoId,
      })
      .select()
      .single();

  return TaxiRide.fromJson(data);
}

// ─────────────────────────────────────────────
// FARE CALCULATOR
// ─────────────────────────────────────────────

double calculateFare({
  required double baseFare,
  required double perKmRate,
  required double distanceKm,
  double surgeMultiplier = 1.0,
  String? discountType,
  double? discountAmount,
}) {
  double fare = (baseFare + (perKmRate * distanceKm)) * surgeMultiplier;

  if (discountType != null && discountAmount != null) {
    if (discountType == 'percentage') {
      fare -= fare * (discountAmount / 100);
    } else if (discountType == 'flat') {
      fare -= discountAmount;
    }
  }

  return fare < 0 ? 0 : fare;
}
