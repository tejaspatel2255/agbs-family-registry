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

  /// Standard Member Login
  Future<bool> loginMember(String mobile, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _repository.signInMember(mobile: mobile, password: password);
      if (response.user != null) {
        final profile = await _repository.getUserProfile(response.user!.id);
        state = state.copyWith(isLoading: false, profile: profile);
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Member login failed.');
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', ''),
      );
      return false;
    }
  }

  /// Send OTP
  Future<Map<String, dynamic>> sendOtp(String mobile, {String purpose = 'signup'}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repository.sendOtp(mobile, purpose: purpose);
      state = state.copyWith(isLoading: false);
      if (res['success'] != true && res['message'] != null) {
        state = state.copyWith(errorMessage: res['message'].toString());
      }
      return res;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return {'success': false, 'message': msg};
    }
  }

  /// Verify OTP & Register
  Future<bool> verifyOtpAndLogin({
    required String mobile,
    required String otp,
    String purpose = 'signup',
    String? fullName,
    String role = 'member',
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _repository.verifyOtpAndLogin(
        mobile: mobile,
        otp: otp,
        purpose: purpose,
        fullName: fullName,
        role: role,
      );
      if (response.user != null) {
        final profile = await _repository.getUserProfile(response.user!.id);
        state = state.copyWith(isLoading: false, profile: profile);
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'OTP verification failed');
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', ''),
      );
      return false;
    }
  }

  /// Verify Password Reset OTP to get reset token
  Future<String?> verifyPasswordResetOtp({
    required String mobile,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final resetToken = await _repository.verifyPasswordResetOtp(
        mobile: mobile,
        otp: otp,
      );
      state = state.copyWith(isLoading: false);
      return resetToken;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', ''),
      );
      return null;
    }
  }

  /// Reset Admin Password
  Future<bool> resetAdminPassword({
    required String mobile,
    required String resetToken,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final success = await _repository.resetAdminPassword(
        mobile: mobile,
        resetToken: resetToken,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', ''),
      );
      return false;
    }
  }

  /// Admin Login
  Future<bool> loginAdmin(String emailOrMobile, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _repository.signInAdmin(emailOrMobile: emailOrMobile, password: password);
      if (response.user != null) {
        final profile = await _repository.getUserProfile(response.user!.id);
        
        List<String> roles = [];
        if (profile != null) {
          if (profile['roles'] != null && profile['roles'] is List) {
            roles = List<String>.from(profile['roles']);
          } else if (profile['role'] != null) {
            roles = [profile['role'].toString()];
          }
        }

        if (!roles.contains('admin')) {
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
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', ''),
      );
      return false;
    }
  }

  /// Check profile by mobile number
  Future<Map<String, dynamic>?> getProfileByMobile(String mobile) async {
    return await _repository.getProfileByMobile(mobile);
  }

  /// Add a new role to an existing account
  Future<bool> addRoleToExistingAccount({
    required String mobile,
    required String password,
    required String otp,
    required String newRole,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final success = await _repository.addRoleToExistingAccount(
        mobile: mobile,
        password: password,
        otp: otp,
        newRole: newRole,
      );
      if (success) {
        final user = _repository.currentUser;
        if (user != null) {
          final profile = await _repository.getUserProfile(user.id);
          state = state.copyWith(isLoading: false, profile: profile);
        } else {
          state = state.copyWith(isLoading: false);
        }
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to add role');
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', ''),
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
