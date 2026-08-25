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
          'role': 'member',
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
            'full_name': fullName ?? 'Member',
            'mobile_number': mobile.trim(),
          },
        );

        if (signUpRes.user != null) {
          await _client.from('profiles').upsert({
            'id': signUpRes.user!.id,
            'mobile_number': mobile.trim(),
            'role': 'member',
            'full_name': fullName ?? 'Member',
          });
        }
        return signUpRes;
      }
      rethrow;
    }
  }

  /// Sign in admin using Email & Password
  Future<AuthResponse> signInAdmin({
    required String email,
    required String password,
  }) async {
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
