import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final profile = authState.profile;
    final fullName = profile?['full_name'] ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go('/welcome');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      size: 42,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Welcome, $fullName',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Your account has both Admin & Member privileges.\nPlease select which portal you want to access:',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 32),

                // Card 1: Admin Portal
                _buildRoleCard(
                  context: context,
                  title: 'Administrator Portal',
                  subtitle: 'Manage community families, approvals, directory records, and systemic controls.',
                  icon: Icons.shield_outlined,
                  color: AppColors.primaryDark,
                  buttonText: 'Continue as Admin',
                  onTap: () => context.go('/admin-dashboard'),
                ),

                const SizedBox(height: 20),

                // Card 2: Member Portal
                _buildRoleCard(
                  context: context,
                  title: 'Member Portal',
                  subtitle: 'View family details, directory listings, and manage your family member profiles.',
                  icon: Icons.person_outline_rounded,
                  color: AppColors.primary,
                  buttonText: 'Continue as Member',
                  onTap: () => context.go('/member-dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  buttonText,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
