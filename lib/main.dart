import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/services/supabase_service.dart';

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
    return MaterialApp(
      title: 'AGBS Family Registry',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audichya Gadhiya Brahm Samaj'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo / Banner Header
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  size: 54,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Family Registry System',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 26,
                      color: AppColors.primaryDark,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Audichya Gadhiya Brahm Samaj (AGBS)\nJunagadh',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigation will be added in Phase 2
                },
                icon: const Icon(Icons.login_rounded),
                label: const Text('Login / Sign In'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  // Registration will be added in Phase 2
                },
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Register New Family'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
