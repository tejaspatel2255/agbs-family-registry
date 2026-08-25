import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

class AuthRepository {
  SupabaseClient get _client => SupabaseService.client;

  String _mobileToEmail(String mobile) => '${mobile.trim()}@gmail.com';

  /// Standard Member Login using Mobile Number (as email) & Password
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

      if (response.status == 200 && response.data?['success'] == true) {
        return {'success': true, 'message': 'OTP sent successfully to $mobile'};
      } else {
        final error = response.data?['error'] ?? 'Failed to send OTP';
        return {'success': false, 'message': error.toString()};
      }
    } catch (e) {
      // Fallback local RPC if Edge Function fails
      try {
        final res = await _client.rpc('send_otp_rpc', params: {'p_mobile': mobile.trim()});
        return {'success': true, 'message': 'OTP sent to $mobile', 'otp_preview': res};
      } catch (err) {
        return {'success': false, 'message': 'Could not send OTP: ${e.toString()}'};
      }
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

    // Verify OTP via Edge Function or RPC
    bool isOtpValid = false;
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
      if (response.status == 200 && (response.data?['success'] == true || response.data?['valid'] == true)) {
        isOtpValid = true;
      } else if (response.data?['error'] != null) {
        throw AuthException(response.data!['error'].toString());
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      // Fallback RPC check
      final rpcRes = await _client.rpc('verify_otp_rpc', params: {
        'p_mobile': mobile.trim(),
        'p_otp': otp.trim(),
      });
      if (rpcRes == true) {
        isOtpValid = true;
      }
    }

    if (!isOtpValid) {
      throw const AuthException('Invalid or expired OTP. Please try again.');
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
