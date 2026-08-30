/// Supabase configuration constants for Audichya Gadhiya Brahm Samaj (AGBS) Family Registry System.
/// 
/// ⚠️ DO NOT hardcode real credentials here.
/// Values are injected at build time via --dart-define flags (see GitHub Actions workflow).
class SupabaseConstants {
  SupabaseConstants._();

  // Supabase Project URL — injected via: --dart-define=SUPABASE_URL=...
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  // Supabase Anon / Public Key — injected via: --dart-define=SUPABASE_ANON_KEY=...
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Storage Buckets
  static const String profilePhotosBucket = 'family-photos';
  static const String familyPhotosBucket = 'family-photos';
}
