import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

// ─────────────────────────────────────────────
// USER ROLES
// ─────────────────────────────────────────────

enum UserRole {
  @JsonValue('admin')
  admin,
  @JsonValue('stay_provider')
  stayProvider,
  @JsonValue('vehicle_provider')
  vehicleProvider,
  @JsonValue('event_provider')
  eventProvider,
  @JsonValue('owner')
  owner,
  @JsonValue('broker')
  broker,
  @JsonValue('sme')
  sme,
  @JsonValue('customer')
  customer;

  bool get isProvider => [
        stayProvider,
        vehicleProvider,
        eventProvider,
        owner,
        broker,
        sme,
      ].contains(this);

  bool get isAdmin => this == admin;
}

// ─────────────────────────────────────────────
// LISTING STATUS
// ─────────────────────────────────────────────

enum ListingStatus {
  @JsonValue('active')
  active,
  @JsonValue('paused')
  paused,
  @JsonValue('off')
  off,
  @JsonValue('pending')
  pending,
  @JsonValue('rejected')
  rejected,
}

// ─────────────────────────────────────────────
// PROVIDER TIERS
// ─────────────────────────────────────────────

enum ProviderTier {
  @JsonValue('standard')
  standard,
  @JsonValue('verified')
  verified,
  @JsonValue('pro')
  pro,
  @JsonValue('elite')
  elite,
}

class TierConfig {
  final String label;
  final String icon;
  final int minBookings;
  final double minRating;

  const TierConfig({
    required this.label,
    required this.icon,
    required this.minBookings,
    required this.minRating,
  });
}

const Map<ProviderTier, TierConfig> tierConfigs = {
  ProviderTier.standard: TierConfig(
    label: 'Standard',
    icon: '●',
    minBookings: 0,
    minRating: 0,
  ),
  ProviderTier.verified: TierConfig(
    label: 'Verified',
    icon: '✓',
    minBookings: 5,
    minRating: 0,
  ),
  ProviderTier.pro: TierConfig(
    label: 'Pro',
    icon: '★',
    minBookings: 50,
    minRating: 4.5,
  ),
  ProviderTier.elite: TierConfig(
    label: 'Elite',
    icon: '♛',
    minBookings: 100,
    minRating: 4.8,
  ),
};

// ─────────────────────────────────────────────
// USER PROFILE
// ─────────────────────────────────────────────

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String email,
    required String name,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    String? phone,
    required UserRole role,
    String? joined,
    @Default(false) bool verified,
    @Default(0) double balance,
    String? nic,
    String? membership,
    @JsonKey(name: 'memberships_remaining') int? membershipsRemaining,
    double? revenue,
    int? listings,
    double? spent,
    int? bookings,
    @JsonKey(name: 'verification_badges') List<String>? verificationBadges,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

// ─────────────────────────────────────────────
// PROFILE DATA (from Supabase profiles table)
// ─────────────────────────────────────────────

@freezed
class ProfileData with _$ProfileData {
  const factory ProfileData({
    required String id,
    @JsonKey(name: 'full_name') required String fullName,
    required String email,
    @Default('') String phone,
    @Default('customer') String role,
    @JsonKey(name: 'avatar_url') @Default('') String avatarUrl,
    @Default('') String nic,
    @Default(false) bool verified,
    @JsonKey(name: 'verification_badges') List<String>? verificationBadges,
  }) = _ProfileData;

  factory ProfileData.fromJson(Map<String, dynamic> json) =>
      _$ProfileDataFromJson(json);
}
