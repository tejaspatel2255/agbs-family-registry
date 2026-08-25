import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/services/supabase_service.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase backend
  await SupabaseService.initialize();

  runApp(
    const ProviderScope(
      child: FamilyRegistryApp(),
    ),
  );
}

class FamilyRegistryApp extends StatelessWidget {
  const FamilyRegistryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AGBS Family Registry',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
