import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_profile.dart';

part 'listings.freezed.dart';
part 'listings.g.dart';

// ─────────────────────────────────────────────
// PROPERTIES
// ─────────────────────────────────────────────

enum PropertyType {
  @JsonValue('house')
  house,
  @JsonValue('apartment')
  apartment,
  @JsonValue('land')
  land,
  @JsonValue('commercial')
  commercial,
  @JsonValue('villa')
  villa,
  @JsonValue('office')
  office,
}

enum PropertyListingType {
  @JsonValue('sale')
  sale,
  @JsonValue('rent')
  rent,
  @JsonValue('lease')
  lease,
  @JsonValue('wanted')
  wanted,
}

@freezed
class Property with _$Property {
  const factory Property({
    required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    required String title,
    required String description,
    @JsonKey(name: 'property_type') required PropertyType propertyType,
    @JsonKey(name: 'listing_type') required PropertyListingType listingType,
    required String location,
    required String address,
    required double lat,
    required double lng,
    required double price,
    @Default('LKR') String currency,
    @JsonKey(name: 'area_sqft') required double areaSqft,
    required int bedrooms,
    required int bathrooms,
    @Default([]) List<String> images,
    @Default([]) List<String> features,
    @Default(ListingStatus.pending) ListingStatus status,
    @Default(0) int views,
    String? listed,
    @JsonKey(name: 'admin_note') String? adminNote,
  }) = _Property;

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);
}

// ─────────────────────────────────────────────
// STAYS
// ─────────────────────────────────────────────

@freezed
class Stay with _$Stay {
  const factory Stay({
    required String id,
    @JsonKey(name: 'provider_id') required String providerId,
    required String name,
    required String description,
    required String location,
    required double lat,
    required double lng,
    @JsonKey(name: 'price_per_night') required double pricePerNight,
    @Default('LKR') String currency,
    @Default([]) List<String> images,
    @Default([]) List<String> amenities,
    @Default(1) int bedrooms,
    @Default(1) int bathrooms,
    @JsonKey(name: 'max_guests') @Default(2) int maxGuests,
    @Default(0) int stars,
    @Default(0.0) double rating,
    @JsonKey(name: 'review_count') @Default(0) int reviewCount,
    @Default(ListingStatus.pending) ListingStatus status,
    @JsonKey(name: 'stay_type') @Default('hotel') String stayType,
    @Default(1) int rooms,
    @Default(false) bool approved,
    @JsonKey(name: 'admin_note') String? adminNote,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _Stay;

  factory Stay.fromJson(Map<String, dynamic> json) => _$StayFromJson(json);
}

// ─────────────────────────────────────────────
// VEHICLES
// ─────────────────────────────────────────────

enum VehicleType {
  @JsonValue('car')
  car,
  @JsonValue('van')
  van,
  @JsonValue('bus')
  bus,
  @JsonValue('tuk_tuk')
  tukTuk,
  @JsonValue('motorcycle')
  motorcycle,
  @JsonValue('scooter')
  scooter,
  @JsonValue('suv')
  suv,
  @JsonValue('minibus')
  minibus,
  @JsonValue('luxury_coach')
  luxuryCoach,
  @JsonValue('jeep')
  jeep,
}

@freezed
class Vehicle with _$Vehicle {
  const factory Vehicle({
    required String id,
    @JsonKey(name: 'provider_id') required String providerId,
    required String title,
    required String description,
    @JsonKey(name: 'vehicle_type') required VehicleType vehicleType,
    required String make,
    required String model,
    required int year,
    required int seats,
    @JsonKey(name: 'price_per_day') required double pricePerDay,
    @Default('LKR') String currency,
    @Default([]) List<String> images,
    @Default([]) List<String> features,
    @JsonKey(name: 'with_driver') @Default(false) bool withDriver,
    @JsonKey(name: 'insurance_included') @Default(false) bool insuranceIncluded,
    required String location,
    @Default(0.0) double lat,
    @Default(0.0) double lng,
    @Default('petrol') String fuel,
    @Default(0.0) double rating,
    @Default(0) int trips,
    @JsonKey(name: 'is_fleet') @Default(false) bool isFleet,
    @JsonKey(name: 'fleet_size') int? fleetSize,
    @Default(ListingStatus.pending) ListingStatus status,
    @JsonKey(name: 'admin_note') String? adminNote,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _Vehicle;

  factory Vehicle.fromJson(Map<String, dynamic> json) =>
      _$VehicleFromJson(json);
}

// ─────────────────────────────────────────────
// EVENTS
// ─────────────────────────────────────────────

enum EventCategory {
  @JsonValue('cultural')
  cultural,
  @JsonValue('music')
  music,
  @JsonValue('food')
  food,
  @JsonValue('sports')
  sports,
  @JsonValue('business')
  business,
  @JsonValue('adventure')
  adventure,
  @JsonValue('religious')
  religious,
  @JsonValue('art')
  art,
  @JsonValue('educational')
  educational,
  @JsonValue('cinema')
  cinema,
  @JsonValue('concert')
  concert,
}

@freezed
class SeatMap with _$SeatMap {
  const factory SeatMap({
    required int rows,
    required int cols,
    @Default([]) List<int> booked,
  }) = _SeatMap;

  factory SeatMap.fromJson(Map<String, dynamic> json) =>
      _$SeatMapFromJson(json);
}

@freezed
class PearlEvent with _$PearlEvent {
  const factory PearlEvent({
    required String id,
    @JsonKey(name: 'provider_id') required String providerId,
    required String title,
    required String description,
    required EventCategory category,
    required String location,
    required String venue,
    @Default(0.0) double lat,
    @Default(0.0) double lng,
    required String date,
    required String time,
    @Default('') String image,
    @Default([]) List<String> images,
    @Default({}) Map<String, double> prices,
    SeatMap? seats,
    @JsonKey(name: 'total_seats') @Default(0) int totalSeats,
    @JsonKey(name: 'available_seats') @Default(0) int availableSeats,
    @JsonKey(name: 'tickets_sold') @Default(0) int ticketsSold,
    @JsonKey(name: 'has_seat_map') @Default(false) bool hasSeatMap,
    @JsonKey(name: 'qr_enabled') @Default(false) bool qrEnabled,
    @Default([]) List<String> tags,
    @Default(ListingStatus.pending) ListingStatus status,
    @JsonKey(name: 'admin_note') String? adminNote,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _PearlEvent;

  factory PearlEvent.fromJson(Map<String, dynamic> json) =>
      _$PearlEventFromJson(json);
}

// ─────────────────────────────────────────────
// SOCIAL / COMMUNITY
// ─────────────────────────────────────────────

@freezed
class SocialPost with _$SocialPost {
  const factory SocialPost({
    required String id,
    @JsonKey(name: 'author_id') required String authorId,
    required String content,
    @Default([]) List<String> images,
    String? location,
    double? lat,
    double? lng,
    @Default([]) List<String> tags,
    @Default(0) int likes,
    @JsonKey(name: 'comments_count') @Default(0) int commentsCount,
    @Default(ListingStatus.active) ListingStatus status,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _SocialPost;

  factory SocialPost.fromJson(Map<String, dynamic> json) =>
      _$SocialPostFromJson(json);
}

// ─────────────────────────────────────────────
// SME BUSINESS
// ─────────────────────────────────────────────

@freezed
class SMEBusiness with _$SMEBusiness {
  const factory SMEBusiness({
    required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'business_name') required String businessName,
    required String description,
    required String category,
    required String location,
    double? lat,
    double? lng,
    required String phone,
    required String email,
    String? website,
    @Default([]) List<String> images,
    @Default(false) bool verified,
    @Default(ListingStatus.pending) ListingStatus status,
    @JsonKey(name: 'admin_note') String? adminNote,
    @JsonKey(name: 'created_at') String? createdAt,
    List<SMEProduct>? products,
  }) = _SMEBusiness;

  factory SMEBusiness.fromJson(Map<String, dynamic> json) =>
      _$SMEBusinessFromJson(json);
}

@freezed
class SMEProduct with _$SMEProduct {
  const factory SMEProduct({
    required String id,
    @JsonKey(name: 'business_id') required String businessId,
    required String name,
    required String description,
    required double price,
    @Default('LKR') String currency,
    @JsonKey(name: 'quantity_available') @Default(0) int quantityAvailable,
    @Default([]) List<String> images,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _SMEProduct;

  factory SMEProduct.fromJson(Map<String, dynamic> json) =>
      _$SMEProductFromJson(json);
}

// ─────────────────────────────────────────────
// MAP MARKER (shared across verticals)
// ─────────────────────────────────────────────

@freezed
class MapMarker with _$MapMarker {
  const factory MapMarker({
    required double lat,
    required double lng,
    required String title,
    required String location,
    double? price,
    String? emoji,
    required String type,
    double? rating,
  }) = _MapMarker;

  factory MapMarker.fromJson(Map<String, dynamic> json) =>
      _$MapMarkerFromJson(json);
}
