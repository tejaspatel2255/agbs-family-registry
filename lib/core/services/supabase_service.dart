import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';

class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (SupabaseConstants.supabaseUrl.isEmpty ||
        SupabaseConstants.supabaseUrl == 'YOUR_SUPABASE_URL' ||
        SupabaseConstants.supabaseUrl.startsWith('YOUR_')) {
      debugPrint('Supabase initialization skipped: placeholder or empty keys.');
      return;
    }
    try {
      await Supabase.initialize(
        url: SupabaseConstants.supabaseUrl,
        anonKey: SupabaseConstants.supabaseAnonKey,
      );
      _initialized = true;
    } catch (e, stack) {
      debugPrint('Supabase initialization warning: $e\n$stack');
    }
  }

  static bool get isInitialized => _initialized;

  static SupabaseClient? get clientOrNull {
    if (!_initialized) return null;
    try {
      return Supabase.instance.client;
    } catch (e) {
      debugPrint('SupabaseService.client accessed before initialization: $e');
      return null;
    }
  }

  // Keep backwards-compatible getter — but now safe (won't throw)
  static SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      debugPrint('SupabaseService.client error: $e');
      rethrow;
    }
  }
}

