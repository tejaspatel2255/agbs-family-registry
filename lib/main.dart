import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/services/supabase_service.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch synchronous Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter framework error: ${details.exception}');
  };

  // Catch asynchronous errors in the platform dispatcher
  WidgetsBinding.instance.platformDispatcher.onError = (Object error, StackTrace stack) {
    debugPrint('Unhandled platform error: $error\n$stack');
    return true;
  };

  // Initialize Supabase backend
  try {
    await SupabaseService.initialize();
  } catch (e, stack) {
    debugPrint('Error during SupabaseService.initialize: $e\n$stack');
  }

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
