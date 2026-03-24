import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/listings.dart';
import '../models/wallet.dart';
import 'supabase_client.dart';

// ─────────────────────────────────────────────
// FILTER TYPES
// Mirrors useListings.ts filter interfaces.
// ─────────────────────────────────────────────

class StayFilters {
  final String? location;
  final String? stayType;
  final double? maxPrice;
  final double? minRating;
  final String? amenity;

  const StayFilters({
    this.location,
    this.stayType,
    this.maxPrice,
    this.minRating,
    this.amenity,
  });
}

class VehicleFilters {
  final String? location;
  final String? vehicleType;
  final double? maxPrice;
  final bool? withDriver;

  const VehicleFilters({
    this.location,
    this.vehicleType,
    this.maxPrice,
    this.withDriver,
  });
}

class EventFilters {
  final String? location;
  final String? category;

  const EventFilters({this.location, this.category});
}

class PropertyFilters {
  final String? location;
  final String? type;
  final String? subtype;
  final double? maxPrice;

  const PropertyFilters({
    this.location,
    this.type,
    this.subtype,
    this.maxPrice,
  });
}

// ─────────────────────────────────────────────
// STAYS PROVIDER
// Mirrors useStays() — queries stays_listings with moderation_status='approved'.
// ─────────────────────────────────────────────

final staysProvider =
    FutureProvider.family<List<Stay>, StayFilters?>((ref, filters) async {
  var query = PearlHubSupabase.client
      .from('stays_listings')
      .select()
      .eq('moderation_status', 'approved')
      .eq('active', true)
      .order('created_at', ascending: false);

  if (filters?.location != null && filters!.location!.isNotEmpty) {
    query = query.ilike('location', '%${filters.location}%');
  }
  if (filters?.stayType != null && filters!.stayType != 'all') {
    query = query.eq('stay_type', filters.stayType!);
  }
  if (filters?.maxPrice != null) {
    query = query.lte('price_per_night', filters!.maxPrice!);
  }

  final data = await query;
  return (data as List).map((e) => Stay.fromJson(e)).toList();
});

// ─────────────────────────────────────────────
// VEHICLES PROVIDER
// Mirrors useVehicles().
// ─────────────────────────────────────────────

final vehiclesProvider =
    FutureProvider.family<List<Vehicle>, VehicleFilters?>((ref, filters) async {
  var query = PearlHubSupabase.client
      .from('vehicles_listings')
      .select()
      .eq('moderation_status', 'approved')
      .eq('active', true)
      .order('created_at', ascending: false);

  if (filters?.location != null && filters!.location!.isNotEmpty) {
    query = query.ilike('location', '%${filters.location}%');
  }
  if (filters?.vehicleType != null && filters!.vehicleType != 'all') {
    query = query.eq('vehicle_type', filters.vehicleType!);
  }
  if (filters?.maxPrice != null) {
    query = query.lte('price_per_day', filters!.maxPrice!);
  }
  if (filters?.withDriver != null) {
    query = query.eq('with_driver', filters!.withDriver!);
  }

  final data = await query;
  return (data as List).map((e) => Vehicle.fromJson(e)).toList();
});

// ─────────────────────────────────────────────
// EVENTS PROVIDER
// Mirrors useEvents() — future events only.
// ─────────────────────────────────────────────

final eventsProvider =
    FutureProvider.family<List<PearlEvent>, EventFilters?>((ref, filters) async {
  final today = DateTime.now().toIso8601String().split('T')[0];

  var query = PearlHubSupabase.client
      .from('events_listings')
      .select()
      .eq('moderation_status', 'approved')
      .eq('active', true)
      .gte('event_date', today)
      .order('event_date', ascending: true);

  if (filters?.location != null && filters!.location!.isNotEmpty) {
    query = query.ilike('location', '%${filters.location}%');
  }
  if (filters?.category != null && filters!.category != 'all') {
    query = query.eq('category', filters.category!);
  }

  final data = await query;
  return (data as List).map((e) => PearlEvent.fromJson(e)).toList();
});

// ─────────────────────────────────────────────
// PROPERTIES PROVIDER
// Mirrors useProperties().
// ─────────────────────────────────────────────

final propertiesProvider = FutureProvider.family<List<Property>, PropertyFilters?>(
    (ref, filters) async {
  var query = PearlHubSupabase.client
      .from('properties_listings')
      .select()
      .eq('moderation_status', 'approved')
      .eq('active', true)
      .order('created_at', ascending: false);

  if (filters?.location != null && filters!.location!.isNotEmpty) {
    query = query.ilike('location', '%${filters.location}%');
  }
  if (filters?.type != null && filters!.type != 'all') {
    query = query.eq('type', filters.type!);
  }
  if (filters?.subtype != null) {
    query = query.eq('subtype', filters.subtype!);
  }
  if (filters?.maxPrice != null) {
    query = query.lte('price', filters!.maxPrice!);
  }

  final data = await query;
  return (data as List).map((e) => Property.fromJson(e)).toList();
});

// ─────────────────────────────────────────────
// PROVIDER-SPECIFIC LISTINGS
// Mirrors useProviderStays(), useProviderVehicles(), etc.
// ─────────────────────────────────────────────

final providerStaysProvider =
    FutureProvider.family<List<Stay>, String>((ref, userId) async {
  final data = await PearlHubSupabase.client
      .from('stays_listings')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);
  return (data as List).map((e) => Stay.fromJson(e)).toList();
});

final providerVehiclesProvider =
    FutureProvider.family<List<Vehicle>, String>((ref, userId) async {
  final data = await PearlHubSupabase.client
      .from('vehicles_listings')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);
  return (data as List).map((e) => Vehicle.fromJson(e)).toList();
});

final providerEventsProvider =
    FutureProvider.family<List<PearlEvent>, String>((ref, userId) async {
  final data = await PearlHubSupabase.client
      .from('events_listings')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);
  return (data as List).map((e) => PearlEvent.fromJson(e)).toList();
});

final providerPropertiesProvider =
    FutureProvider.family<List<Property>, String>((ref, userId) async {
  final data = await PearlHubSupabase.client
      .from('properties_listings')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);
  return (data as List).map((e) => Property.fromJson(e)).toList();
});

// ─────────────────────────────────────────────
// USER BOOKINGS PROVIDER
// Mirrors useUserBookings().
// ─────────────────────────────────────────────

final userBookingsProvider =
    FutureProvider.family<List<Booking>, String>((ref, userId) async {
  final data = await PearlHubSupabase.client
      .from('bookings')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);
  return (data as List).map((e) => Booking.fromJson(e)).toList();
});

// ─────────────────────────────────────────────
// PROVIDER EARNINGS
// Real earnings data — fixes the hardcoded chart in web app.
// ─────────────────────────────────────────────

final providerEarningsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, providerId) async {
  final thirtyDaysAgo =
      DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

  final data = await PearlHubSupabase.client
      .from('earnings')
      .select('amount, created_at')
      .eq('provider_id', providerId)
      .gte('created_at', thirtyDaysAgo)
      .order('created_at', ascending: true);

  return List<Map<String, dynamic>>.from(data);
});
