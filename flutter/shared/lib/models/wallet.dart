import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet.freezed.dart';
part 'wallet.g.dart';

// ─────────────────────────────────────────────
// TRANSACTION (general)
// ─────────────────────────────────────────────

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String type,
    required double amount,
    required String user,
    required String date,
    required String status,
    required String ref,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}

// ─────────────────────────────────────────────
// WALLET TRANSACTION
// ─────────────────────────────────────────────

enum WalletTransactionType {
  @JsonValue('deposit')
  deposit,
  @JsonValue('withdrawal')
  withdrawal,
  @JsonValue('commission')
  commission,
  @JsonValue('refund')
  refund,
  @JsonValue('fee')
  fee,
}

enum TransactionStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
}

@freezed
class WalletTransaction with _$WalletTransaction {
  const factory WalletTransaction({
    required String id,
    required WalletTransactionType type,
    required double amount,
    required String description,
    required String date,
    required TransactionStatus status,
    required String ref,
  }) = _WalletTransaction;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionFromJson(json);
}

// ─────────────────────────────────────────────
// BOOKING
// ─────────────────────────────────────────────

enum BookingStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('completed')
  completed,
}

@freezed
class Booking with _$Booking {
  const factory Booking({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'listing_id') String? listingId,
    @JsonKey(name: 'listing_type') String? listingType,
    @JsonKey(name: 'provider_id') String? providerId,
    @Default(BookingStatus.pending) BookingStatus status,
    required double amount,
    @Default('LKR') String currency,
    @JsonKey(name: 'payment_method') String? paymentMethod,
    @JsonKey(name: 'payment_status') @Default('pending') String paymentStatus,
    @JsonKey(name: 'damage_deposit') double? damageDeposit,
    @JsonKey(name: 'check_in') String? checkIn,
    @JsonKey(name: 'check_out') String? checkOut,
    int? guests,
    String? notes,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _Booking;

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);
}

// ─────────────────────────────────────────────
// TRIP BUNDLE
// ─────────────────────────────────────────────

enum BundleItemType {
  @JsonValue('stay')
  stay,
  @JsonValue('vehicle')
  vehicle,
  @JsonValue('event')
  event,
}

@freezed
class BundleItem with _$BundleItem {
  const factory BundleItem({
    required String id,
    required BundleItemType type,
    required String title,
    required double price,
    @Default('LKR') String currency,
    String? image,
    String? dateFrom,
    String? dateTo,
    int? quantity,
    String? details,
  }) = _BundleItem;

  factory BundleItem.fromJson(Map<String, dynamic> json) =>
      _$BundleItemFromJson(json);
}

// ─────────────────────────────────────────────
// PEARL POINTS
// ─────────────────────────────────────────────

@freezed
class PearlPoints with _$PearlPoints {
  const factory PearlPoints({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required int points,
    required String source,
    String? description,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _PearlPoints;

  factory PearlPoints.fromJson(Map<String, dynamic> json) =>
      _$PearlPointsFromJson(json);
}

// ─────────────────────────────────────────────
// RECENTLY VIEWED
// ─────────────────────────────────────────────

@freezed
class RecentlyViewed with _$RecentlyViewed {
  const factory RecentlyViewed({
    required String id,
    required String title,
    required String type,
    double? price,
    required String image,
    required String location,
    required int viewedAt,
  }) = _RecentlyViewed;

  factory RecentlyViewed.fromJson(Map<String, dynamic> json) =>
      _$RecentlyViewedFromJson(json);
}
