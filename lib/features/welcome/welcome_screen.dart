import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Logo Container
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.diversity_3_rounded,
                    size: 56,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Welcome to AGBS',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Audichya Gadhiya Brahm Samaj, Junagadh\nFamily Registry Portal',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),

              const Spacer(),

              // Actions
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/login');
                },
                icon: const Icon(Icons.login_rounded),
                label: const Text('Login / Sign In'),
              ),

              const SizedBox(height: 14),

              OutlinedButton.icon(
                onPressed: () {
                  context.push('/register-family');
                },
                icon: const Icon(Icons.group_add_rounded),
                label: const Text('Register New Family'),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
