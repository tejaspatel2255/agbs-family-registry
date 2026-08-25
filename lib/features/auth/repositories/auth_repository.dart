import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

class AuthRepository {
  SupabaseClient get _client => SupabaseService.client;

  String _mobileToEmail(String mobile) => '${mobile.trim()}@agbs.app';

  /// Sign up a new community member (role = 'member')
  Future<AuthResponse> signUpMember({
    required String mobile,
    required String password,
    required String fullName,
  }) async {
    final email = _mobileToEmail(mobile);
    
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'mobile_number': mobile,
      },
    );

    if (response.user != null) {
      // Upsert into profiles table
      await _client.from('profiles').upsert({
        'id': response.user!.id,
        'mobile_number': mobile,
        'role': 'member',
        'full_name': fullName,
      });
    }

    return response;
  }

  /// Sign in using 10-digit mobile number & password
  Future<AuthResponse> signIn({
    required String mobile,
    required String password,
  }) async {
    final email = _mobileToEmail(mobile);
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  /// Fetch user profile role from Supabase
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

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
}
