/// Supabase configuration constants for Audichya Gadhiya Brahm Samaj (AGBS) Family Registry System.
class SupabaseConstants {
  SupabaseConstants._();

  // Supabase Project URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hppmrifkxxlbytvkowdu.supabase.co',
  );

  // Supabase Anon / Public Key
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhwcG1yaWZreHhsYnl0dmtvd2R1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc2MzYyOTgsImV4cCI6MjEwMzIxMjI5OH0.-rE4MbOcRHfVeZAmz1zLMHwyRjXcoi7sQeZoc0ZkLIM',
  );

  // Storage Buckets
  static const String profilePhotosBucket = 'family-photos';
  static const String familyPhotosBucket = 'family-photos';
}
