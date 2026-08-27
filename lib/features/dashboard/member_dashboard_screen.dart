import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../auth/providers/auth_provider.dart';
import '../family/providers/family_provider.dart';
import '../family/models/family_model.dart';
import '../members/models/family_member_model.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authStateProvider.notifier).loadUserProfile();
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

  void _showFamilyDetailsModal(BuildContext context, FamilyModel family) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          family.fullName,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          'Family Code: ${family.familyCode}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              Expanded(
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: ref.read(familyRepositoryProvider).fetchFamilyWithMembers(family.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }

                    final data = snapshot.data;
                    final members = (data?['members'] as List<FamilyMemberModel>?) ?? [];

                    return ListView(
                      children: [
                        // HOF Details Section
                        Text(
                          'Head of Family Details',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (family.mobileNumber != null && family.mobileNumber!.isNotEmpty)
                                _buildDetailRow('Registered Mobile:', family.mobileNumber!),
                              _buildDetailRow('Father / Husband:', family.fatherHusbandName),
                              _buildDetailRow('Mother Name:', family.motherName),
                              _buildDetailRow('Gender:', family.gender),
                              _buildDetailRow('Blood Group:', family.bloodGroup),
                              _buildDetailRow('Marital Status:', family.maritalStatus),
                              _buildDetailRow('Address:', family.address),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Family Members Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Family Members (${members.length})',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (members.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'No additional family members registered.',
                              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          )
                        else
                          ...members.map((m) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryContainer,
                                  child: Icon(
                                    m.relation.toLowerCase().contains('wife') || m.relation.toLowerCase().contains('daughter') || m.relation.toLowerCase().contains('mother')
                                        ? Icons.woman_rounded
                                        : Icons.man_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                                title: Text(
                                  m.fullName,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                subtitle: Text(
                                  'Relation: ${m.relation}  •  Age: ${m.age} yrs${m.bloodGroup != null && m.bloodGroup!.isNotEmpty ? "  •  BG: ${m.bloodGroup}" : ""}',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ),
                            );
                          }),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly = GoRouterState.of(context).uri.queryParameters['readOnly'] == 'true';
    final familyState = ref.watch(familyStateProvider);
    final authState = ref.watch(authStateProvider);
    final profile = authState.profile;
    final displayedFamilies = familyState.filteredFamilies;

    List<String> roles = [];
    if (profile != null) {
      if (profile['roles'] != null && profile['roles'] is List) {
        roles = List<String>.from(profile['roles']);
      } else if (profile['role'] != null) {
        roles = [profile['role'].toString()];
      }
    }
    final hasDualRoles = roles.contains('member') && roles.contains('admin');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isReadOnly ? 'All Family Registrations' : 'Member Dashboard'),
        leading: isReadOnly
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/admin-dashboard');
                  }
                },
              )
            : null,
        actions: [
          if (hasDualRoles)
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'Switch Role',
              onPressed: () => context.go('/select-role'),
            ),
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

              // 2. Full Width "New Family Entry" Button (Hidden in Read-Only Mode)
              if (!isReadOnly) ...[
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
              ],

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
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      _showFamilyDetailsModal(context, family);
                                    },
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

                                          // Action Icons
                                          if (!isReadOnly) ...[
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
                                          ] else ...[
                                            const Icon(
                                              Icons.chevron_right_rounded,
                                              color: AppColors.textSecondary,
                                            ),
                                          ],
                                        ],
                                      ),
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
