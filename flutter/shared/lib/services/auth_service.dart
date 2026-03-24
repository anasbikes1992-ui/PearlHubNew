import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import 'supabase_client.dart';

// ─────────────────────────────────────────────
// AUTH STATE PROVIDER
// Mirrors AuthContext.tsx — listens to Supabase auth state changes.
// ─────────────────────────────────────────────

final authStateProvider = StreamProvider<AuthState>((ref) {
  return PearlHubSupabase.auth.onAuthStateChange;
});

// ─────────────────────────────────────────────
// CURRENT USER PROVIDER
// ─────────────────────────────────────────────

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (state) => state.session?.user);
});

// ─────────────────────────────────────────────
// CURRENT SESSION PROVIDER
// ─────────────────────────────────────────────

final currentSessionProvider = Provider<Session?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (state) => state.session);
});

// ─────────────────────────────────────────────
// PROFILE PROVIDER
// Fetches from profiles table, mirrors AuthContext fetchProfile().
// ─────────────────────────────────────────────

final profileProvider = FutureProvider<ProfileData?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final response = await PearlHubSupabase.client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();

  if (response == null) return null;
  return ProfileData.fromJson(response);
});

// ─────────────────────────────────────────────
// USER ROLE PROVIDER
// ─────────────────────────────────────────────

final userRoleProvider = Provider<UserRole?>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  if (profile == null) return null;

  try {
    return UserRole.values.firstWhere(
      (r) => r.name == profile.role || _roleJsonValue(r) == profile.role,
    );
  } catch (_) {
    return UserRole.customer;
  }
});

String _roleJsonValue(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'admin';
    case UserRole.stayProvider:
      return 'stay_provider';
    case UserRole.vehicleProvider:
      return 'vehicle_provider';
    case UserRole.eventProvider:
      return 'event_provider';
    case UserRole.owner:
      return 'owner';
    case UserRole.broker:
      return 'broker';
    case UserRole.sme:
      return 'sme';
    case UserRole.customer:
      return 'customer';
  }
}

// ─────────────────────────────────────────────
// AUTH SERVICE
// Methods mirror AuthContext.tsx: signUp, signIn, signOut, resetPassword.
// ─────────────────────────────────────────────

class AuthService {
  AuthService._();

  /// Sign up with email/password. Optional metadata (full_name, role, phone).
  static Future<({AuthException? error})> signUp({
    required String email,
    required String password,
    Map<String, String>? metadata,
  }) async {
    try {
      await PearlHubSupabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );
      return (error: null);
    } on AuthException catch (e) {
      return (error: e);
    }
  }

  /// Sign in with email/password.
  static Future<({AuthException? error})> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await PearlHubSupabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return (error: null);
    } on AuthException catch (e) {
      return (error: e);
    }
  }

  /// Sign out.
  static Future<void> signOut() async {
    await PearlHubSupabase.auth.signOut();
  }

  /// Send password reset email.
  static Future<({AuthException? error})> resetPassword({
    required String email,
  }) async {
    try {
      await PearlHubSupabase.auth.resetPasswordForEmail(email);
      return (error: null);
    } on AuthException catch (e) {
      return (error: e);
    }
  }

  /// Refresh the current session.
  static Future<void> refreshSession() async {
    await PearlHubSupabase.auth.refreshSession();
  }
}

// ─────────────────────────────────────────────
// AUTH SERVICE PROVIDER (for convenience)
// ─────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((_) => AuthService._());
