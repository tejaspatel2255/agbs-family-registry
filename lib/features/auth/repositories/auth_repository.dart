import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

class AuthRepository {
  SupabaseClient get _client => SupabaseService.client;

  String _mobileToEmail(String mobile) => '${mobile.trim()}@gmail.com';

  /// Standard Member Login using Mobile Number & Password
  Future<AuthResponse> signInMember({
    required String mobile,
    required String password,
  }) async {
    final email = _mobileToEmail(mobile);
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// 1. Send OTP via Supabase Edge Function (Brevo SMS API)
  Future<Map<String, dynamic>> sendOtp(String mobile, {String purpose = 'signup'}) async {
    try {
      final response = await _client.functions.invoke(
        'send-otp',
        body: {
          'mobile_number': mobile.trim(),
          'purpose': purpose,
        },
      );

      if (response.status == 200 && response.data != null) {
        final msg = response.data['message'] ?? 'OTP generated successfully';
        final devOtp = response.data['dev_otp'];
        return {
          'success': true,
          'message': devOtp != null ? '$msg (Code: $devOtp)' : msg,
          'dev_otp': devOtp,
        };
      } else {
        final error = response.data?['error'] ?? 'Failed to send OTP';
        return {'success': false, 'message': error.toString()};
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to send OTP: ${e.toString()}'};
    }
  }

  /// 2. Verify OTP & Register User
  Future<AuthResponse> verifyOtpAndLogin({
    required String mobile,
    required String otp,
    String purpose = 'signup',
    String? fullName,
    String? password,
    String role = 'member',
  }) async {
    final email = _mobileToEmail(mobile);
    final userPassword = password ?? 'BrevoOTP#${mobile.trim()}#SecretKey2026';

    try {
      final response = await _client.functions.invoke(
        'verify-otp',
        body: {
          'mobile_number': mobile.trim(),
          'otp': otp.trim(),
          'purpose': purpose,
          'full_name': fullName,
          'role': role,
        },
      );

      if (response.status == 200 && response.data != null && response.data['success'] == true) {
        // OTP Verified successfully!
      } else {
        final errMsg = response.data?['error'] ?? 'Incorrect or expired OTP. Please try again.';
        throw AuthException(errMsg.toString());
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(e.toString().replaceAll('FunctionException: ', ''));
    }

    // After OTP verification, register user with email & password
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: userPassword,
      );

      if (response.user != null && fullName != null && fullName.isNotEmpty) {
        await _client.from('profiles').upsert({
          'id': response.user!.id,
          'mobile_number': mobile.trim(),
          'role': role,
          'full_name': fullName.trim(),
        });
      }

      return response;
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials') || e.statusCode == '400') {
        final signUpRes = await _client.auth.signUp(
          email: email,
          password: userPassword,
          data: {
            'full_name': fullName ?? (role == 'admin' ? 'Admin' : 'Member'),
            'mobile_number': mobile.trim(),
          },
        );

        if (signUpRes.user != null) {
          await _client.from('profiles').upsert({
            'id': signUpRes.user!.id,
            'mobile_number': mobile.trim(),
            'role': role,
            'full_name': fullName ?? (role == 'admin' ? 'Admin' : 'Member'),
          });
        }
        return signUpRes;
      }
      rethrow;
    }
  }

  /// 3. Verify Password Reset OTP and get reset_token
  Future<String> verifyPasswordResetOtp({
    required String mobile,
    required String otp,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'verify-otp',
        body: {
          'mobile_number': mobile.trim(),
          'otp': otp.trim(),
          'purpose': 'reset_password',
        },
      );

      if (response.status == 200 && response.data != null && response.data['success'] == true) {
        final resetToken = response.data['reset_token'];
        if (resetToken != null && resetToken.toString().isNotEmpty) {
          return resetToken.toString();
        }
        throw const AuthException('Reset token was not returned.');
      } else {
        final errMsg = response.data?['error'] ?? 'Invalid or expired OTP.';
        throw AuthException(errMsg.toString());
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(e.toString().replaceAll('FunctionException: ', ''));
    }
  }

  /// 4. Execute Password Reset with token and new password
  Future<bool> resetAdminPassword({
    required String mobile,
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'reset-password',
        body: {
          'reset_token': resetToken.trim(),
          'new_password': newPassword.trim(),
        },
      );

      if (response.status == 200 && response.data != null && response.data['success'] == true) {
        return true;
      } else {
        final errMsg = response.data?['error'] ?? 'Failed to reset password.';
        throw AuthException(errMsg.toString());
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(e.toString().replaceAll('FunctionException: ', ''));
    }
  }

  /// Sign in admin using Email or Mobile Number & Password
  Future<AuthResponse> signInAdmin({
    required String emailOrMobile,
    required String password,
  }) async {
    final input = emailOrMobile.trim();
    String email = input;

    // If input is 10-digit mobile number, check profiles for corresponding email/user
    if (RegExp(r'^[6-9]\d{9}$').hasMatch(input)) {
      final profile = await _client
          .from('profiles')
          .select('id')
          .eq('mobile_number', input)
          .maybeSingle();

      if (profile != null) {
        final userRes = await _client.auth.admin.getUserById(profile['id']);
        if (userRes.user?.email != null) {
          email = userRes.user!.email!;
        }
      }
    }

    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Fetch user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return res;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
}
