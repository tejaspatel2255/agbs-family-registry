import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/family_model.dart';
import '../repositories/family_repository.dart';
import '../../auth/providers/auth_provider.dart';

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository();
});

class FamilyState {
  final bool isLoading;
  final String? errorMessage;
  final List<FamilyModel> families;
  final String searchQuery;

  FamilyState({
    this.isLoading = false,
    this.errorMessage,
    this.families = const [],
    this.searchQuery = '',
  });

  List<FamilyModel> get filteredFamilies {
    if (searchQuery.trim().isEmpty) {
      return families;
    }
    final q = searchQuery.toLowerCase().trim();
    return families.where((f) {
      return f.fullName.toLowerCase().contains(q) ||
             f.familyCode.toLowerCase().contains(q) ||
             f.address.toLowerCase().contains(q);
    }).toList();
  }

  FamilyState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<FamilyModel>? families,
    String? searchQuery,
  }) {
    return FamilyState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      families: families ?? this.families,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class FamilyNotifier extends StateNotifier<FamilyState> {
  final FamilyRepository _repository;
  final Ref _ref;

  FamilyNotifier(this._repository, this._ref) : super(FamilyState());

  Future<void> loadFamilies() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      bool isAdmin = false;
      final profile = authState.profile;
      if (profile != null) {
        final role = profile['role']?.toString();
        final rolesList = profile['roles'] is List ? List<String>.from(profile['roles']) : [];
        if (role == 'admin' || rolesList.contains('admin')) {
          isAdmin = true;
        }
      }

      final list = await _repository.fetchFamilies(
        isAdmin: isAdmin,
        userId: currentUser?.id,
      );

      state = state.copyWith(isLoading: false, families: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> deleteFamily(String familyId) async {
    final success = await _repository.deleteFamily(familyId);
    if (success) {
      await loadFamilies();
    }
    return success;
  }
}

final familyStateProvider = StateNotifierProvider<FamilyNotifier, FamilyState>((ref) {
  final repo = ref.watch(familyRepositoryProvider);
  return FamilyNotifier(repo, ref);
});
