import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../auth/providers/auth_provider.dart';
import '../family/providers/family_provider.dart';

class MemberDashboardScreen extends ConsumerStatefulWidget {
  const MemberDashboardScreen({super.key});

  @override
  ConsumerState<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends ConsumerState<MemberDashboardScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(familyStateProvider.notifier).loadFamilies();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDeleteFamily(String familyId, String fullName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Confirm Delete'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the family record for "$fullName"?\n\nThis action will also delete all associated family members and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref
                  .read(familyStateProvider.notifier)
                  .deleteFamily(familyId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Family record deleted successfully'
                          : 'Failed to delete family record',
                    ),
                    backgroundColor:
                        success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyStateProvider);
    final displayedFamilies = familyState.filteredFamilies;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Member Dashboard'),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 1. Search Bar with Search Icon, Clear (X) button, and Submit button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref
                            .read(familyStateProvider.notifier)
                            .setSearchQuery(val);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by Name...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(familyStateProvider.notifier)
                                      .setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      onPressed: () {
                        ref
                            .read(familyStateProvider.notifier)
                            .setSearchQuery(_searchController.text);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Full Width "New Family Entry" Button
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/family-form');
                },
                icon: const Icon(Icons.add_rounded, size: 24),
                label: const Text('New Family Entry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  elevation: 2,
                ),
              ),

              const SizedBox(height: 16),

              // 3. Scrollable List of Family Cards
              Expanded(
                child: familyState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    : displayedFamilies.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.family_restroom_rounded,
                                  size: 64,
                                  color: AppColors.textMuted.withOpacity(0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  familyState.searchQuery.isNotEmpty
                                      ? 'No family records match your search'
                                      : 'No family records found',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(familyStateProvider.notifier)
                                .loadFamilies(),
                            color: AppColors.primary,
                            child: ListView.builder(
                              itemCount: displayedFamilies.length,
                              itemBuilder: (context, index) {
                                final family = displayedFamilies[index];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        // Circular Photo or Fallback Avatar
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: AppColors.primaryContainer,
                                          backgroundImage: family.photoUrl != null && family.photoUrl!.isNotEmpty
                                              ? CachedNetworkImageProvider(family.photoUrl!)
                                              : null,
                                          child: family.photoUrl == null || family.photoUrl!.isEmpty
                                              ? Text(
                                                  family.fullName.isNotEmpty
                                                      ? family.fullName[0].toUpperCase()
                                                      : 'F',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                )
                                              : null,
                                        ),

                                        const SizedBox(width: 14),

                                        // Family Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                family.fullName,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'ID: ${family.familyCode}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Members: ${family.memberCount}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Action Icons: Edit & Delete
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: AppColors.primary,
                                          ),
                                          tooltip: 'Edit Family Record',
                                          onPressed: () {
                                            context.push('/family-form?id=${family.id}');
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: AppColors.error,
                                          ),
                                          tooltip: 'Delete Family Record',
                                          onPressed: () {
                                            _confirmDeleteFamily(
                                              family.id,
                                              family.fullName,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
