import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authRepositoryProvider).currentUser;
});

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? profile;

  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.profile,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? profile,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      profile: profile ?? this.profile,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState());

  Future<bool> loginMember(String mobile, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _repository.signIn(mobile: mobile, password: password);
      if (response.user != null) {
        final profile = await _repository.getUserProfile(response.user!.id);
        state = state.copyWith(isLoading: false, profile: profile);
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Login failed');
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> loginAdmin(String mobile, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _repository.signIn(mobile: mobile, password: password);
      if (response.user != null) {
        final profile = await _repository.getUserProfile(response.user!.id);
        final role = profile?['role'] ?? 'member';
        
        if (role != 'admin') {
          await _repository.signOut();
          state = state.copyWith(
            isLoading: false, 
            errorMessage: 'Access Denied: Admin privileges required.',
          );
          return false;
        }

        state = state.copyWith(isLoading: false, profile: profile);
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Admin login failed');
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> signUpMember({
    required String mobile,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _repository.signUpMember(
        mobile: mobile,
        password: password,
        fullName: fullName,
      );
      if (response.user != null) {
        final profile = await _repository.getUserProfile(response.user!.id);
        state = state.copyWith(isLoading: false, profile: profile);
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Sign up failed');
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.signOut();
    state = AuthState();
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
