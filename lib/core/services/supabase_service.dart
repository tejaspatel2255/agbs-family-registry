import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';

class SupabaseService {
  SupabaseService._();

  static Future<void> initialize() async {
    if (SupabaseConstants.supabaseUrl == 'YOUR_SUPABASE_URL') {
      // Demo initialization or warning log when keys are placeholders
      return;
    }
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      anonKey: SupabaseConstants.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
