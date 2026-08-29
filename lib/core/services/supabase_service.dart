import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';

class SupabaseService {
  SupabaseService._();

  static Future<void> initialize() async {
    if (SupabaseConstants.supabaseUrl == 'YOUR_SUPABASE_URL') {
      // Demo initialization or warning log when keys are placeholders
      return;
    }
    try {
      await Supabase.initialize(
        url: SupabaseConstants.supabaseUrl,
        anonKey: SupabaseConstants.supabaseAnonKey,
      );
    } catch (e, stack) {
      debugPrint('Supabase initialization failed: $e\n$stack');
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
