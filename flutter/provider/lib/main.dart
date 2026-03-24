import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/services/supabase_client.dart';

import 'app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PearlHubSupabase.initialize();

  runApp(
    const ProviderScope(
      child: PearlHubProviderApp(),
    ),
  );
}

class PearlHubProviderApp extends ConsumerWidget {
  const PearlHubProviderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(providerRouterProvider);

    return MaterialApp.router(
      title: 'PearlHub Provider',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0EA5E9),
          primary: const Color(0xFF0EA5E9),
          secondary: const Color(0xFFF97316),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0EA5E9),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
