/// Template Supabase configuration file.
/// Copy this file to `lib/core/constants/supabase_constants.dart` and insert your credentials.
class SupabaseConstants {
  SupabaseConstants._();

  static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';

  // Storage Buckets
  static const String profilePhotosBucket = 'family-photos';
  static const String familyPhotosBucket = 'family-photos';
}
