import 'package:freezed_annotation/freezed_annotation.dart';

part 'taxi.freezed.dart';
part 'taxi.g.dart';

// ─────────────────────────────────────────────
// TAXI RIDE STATUS
// ─────────────────────────────────────────────

enum TaxiRideStatus {
  @JsonValue('searching')
  searching,
  @JsonValue('accepted')
  accepted,
  @JsonValue('arrived')
  arrived,
  @JsonValue('in_transit')
  inTransit,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

// ─────────────────────────────────────────────
// VEHICLE CATEGORY
// ─────────────────────────────────────────────

@freezed
class TaxiVehicleCategory with _$TaxiVehicleCategory {
  const factory TaxiVehicleCategory({
    required String id,
    required String name,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'default_seats') required int defaultSeats,
    @JsonKey(name: 'base_fare') required double baseFare,
    @JsonKey(name: 'per_km_rate') required double perKmRate,
    @Default('🚗') String icon,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _TaxiVehicleCategory;

  factory TaxiVehicleCategory.fromJson(Map<String, dynamic> json) =>
      _$TaxiVehicleCategoryFromJson(json);
}

// ─────────────────────────────────────────────
// TAXI RIDE
// ─────────────────────────────────────────────

@freezed
class TaxiRide with _$TaxiRide {
  const factory TaxiRide({
    required String id,
    @JsonKey(name: 'customer_id') required String customerId,
    @JsonKey(name: 'provider_id') String? providerId,
    @JsonKey(name: 'vehicle_category_id') String? vehicleCategoryId,
    @JsonKey(name: 'pickup_lat') required double pickupLat,
    @JsonKey(name: 'pickup_lng') required double pickupLng,
    @JsonKey(name: 'pickup_address') String? pickupAddress,
    @JsonKey(name: 'dropoff_lat') required double dropoffLat,
    @JsonKey(name: 'dropoff_lng') required double dropoffLng,
    @JsonKey(name: 'dropoff_address') String? dropoffAddress,
    @Default(TaxiRideStatus.searching) TaxiRideStatus status,
    double? fare,
    @JsonKey(name: 'distance_km') double? distanceKm,
    @JsonKey(name: 'ride_module') @Default('ride') String rideModule,
    @JsonKey(name: 'parcel_details') Map<String, dynamic>? parcelDetails,
    List<Map<String, dynamic>>? stops,
    @JsonKey(name: 'payment_method') @Default('cash') String paymentMethod,
    @JsonKey(name: 'payment_status') @Default('pending') String paymentStatus,
    @JsonKey(name: 'surge_multiplier') @Default(1.0) double surgeMultiplier,
    @JsonKey(name: 'scheduled_for') String? scheduledFor,
    @JsonKey(name: 'is_emergency_sos') @Default(false) bool isEmergencySos,
    @JsonKey(name: 'promo_id') String? promoId,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _TaxiRide;

  factory TaxiRide.fromJson(Map<String, dynamic> json) =>
      _$TaxiRideFromJson(json);
}

// ─────────────────────────────────────────────
// TAXI PROMO CODE
// ─────────────────────────────────────────────

@freezed
class TaxiPromo with _$TaxiPromo {
  const factory TaxiPromo({
    required String id,
    required String code,
    @JsonKey(name: 'discount_type') required String discountType,
    @JsonKey(name: 'discount_amount') required double discountAmount,
    @JsonKey(name: 'max_uses') required int maxUses,
    @JsonKey(name: 'uses_count') @Default(0) int usesCount,
    @JsonKey(name: 'valid_until') String? validUntil,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _TaxiPromo;

  factory TaxiPromo.fromJson(Map<String, dynamic> json) =>
      _$TaxiPromoFromJson(json);
}

// ─────────────────────────────────────────────
// TAXI CHAT MESSAGE
// ─────────────────────────────────────────────

@freezed
class TaxiChatMessage with _$TaxiChatMessage {
  const factory TaxiChatMessage({
    required String id,
    @JsonKey(name: 'ride_id') required String rideId,
    @JsonKey(name: 'sender_id') required String senderId,
    required String content,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _TaxiChatMessage;

  factory TaxiChatMessage.fromJson(Map<String, dynamic> json) =>
      _$TaxiChatMessageFromJson(json);
}

// ─────────────────────────────────────────────
// TAXI KYC
// ─────────────────────────────────────────────

enum KycVerificationStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
}

@freezed
class TaxiKYC with _$TaxiKYC {
  const factory TaxiKYC({
    required String id,
    @JsonKey(name: 'provider_id') required String providerId,
    @JsonKey(name: 'nic_number') String? nicNumber,
    @JsonKey(name: 'license_number') String? licenseNumber,
    @JsonKey(name: 'verification_status')
    @Default(KycVerificationStatus.pending)
    KycVerificationStatus verificationStatus,
    @JsonKey(name: 'submitted_at') String? submittedAt,
  }) = _TaxiKYC;

  factory TaxiKYC.fromJson(Map<String, dynamic> json) =>
      _$TaxiKYCFromJson(json);
}

// ─────────────────────────────────────────────
// TAXI RATING
// ─────────────────────────────────────────────

@freezed
class TaxiRating with _$TaxiRating {
  const factory TaxiRating({
    required String id,
    @JsonKey(name: 'ride_id') required String rideId,
    @JsonKey(name: 'reviewer_id') required String reviewerId,
    @JsonKey(name: 'target_id') required String targetId,
    required double rating,
    @Default('') String feedback,
    @JsonKey(name: 'tip_amount') @Default(0.0) double tipAmount,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _TaxiRating;

  factory TaxiRating.fromJson(Map<String, dynamic> json) =>
      _$TaxiRatingFromJson(json);
}

// ─────────────────────────────────────────────
// TAXI PROVIDER LOCATION (Realtime tracking)
// ─────────────────────────────────────────────

@freezed
class TaxiProviderLocation with _$TaxiProviderLocation {
  const factory TaxiProviderLocation({
    required String id,
    @JsonKey(name: 'provider_id') required String providerId,
    required double lat,
    required double lng,
    @JsonKey(name: 'is_online') @Default(false) bool isOnline,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _TaxiProviderLocation;

  factory TaxiProviderLocation.fromJson(Map<String, dynamic> json) =>
      _$TaxiProviderLocationFromJson(json);
}
