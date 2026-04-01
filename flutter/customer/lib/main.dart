import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/services/supabase_client.dart';

import 'app/router.dart';
import 'app/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PearlHubSupabase.initialize();

  runApp(
    const ProviderScope(
      child: PearlHubCustomerApp(),
    ),
  );
}

class PearlHubCustomerApp extends ConsumerWidget {
  const PearlHubCustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'PearlHub',
      theme: pearlHubTheme(),
      darkTheme: pearlHubDarkTheme(),
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
