import 'package:supabase_flutter/supabase_flutter.dart';

/// Compile-time env vars passed via --dart-define
const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: '',
);
const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: '',
);

/// Initialize Supabase — call once in main() before runApp().
///
/// Usage:
/// ```dart
/// await PearlHubSupabase.initialize();
/// ```
///
/// Build command:
/// ```bash
/// flutter run \
///   --dart-define=SUPABASE_URL=https://your-project.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=your-anon-key
/// ```
class PearlHubSupabase {
  PearlHubSupabase._();

  static bool _initialized = false;

  /// Initialize Supabase with compile-time credentials.
  /// Must be called before accessing [client].
  static Future<void> initialize() async {
    if (_initialized) return;

    assert(
      _supabaseUrl.isNotEmpty,
      'SUPABASE_URL not set. Use --dart-define=SUPABASE_URL=...',
    );
    assert(
      _supabaseAnonKey.isNotEmpty,
      'SUPABASE_ANON_KEY not set. Use --dart-define=SUPABASE_ANON_KEY=...',
    );

    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    _initialized = true;
  }

  /// The Supabase client singleton.
  static SupabaseClient get client => Supabase.instance.client;

  /// Shorthand for auth.
  static GoTrueClient get auth => client.auth;

  /// Shorthand for realtime.
  static RealtimeClient get realtime => client.realtime;
}
