## Flutter & R8 ProGuard keep rules for Release APK builds

# Keep Supabase Flutter & Realtime / WebSockets
-keep class com.supabase.** { *; }
-keep class io.supabase.** { *; }
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep Image Picker & Media handling
-keep class io.flutter.plugins.imagepicker.** { *; }

# Keep PDF & Printing native interfaces
-keep class net.nfet.flutter.printing.** { *; }

# Keep Sqflite & SQLite database engine
-keep class com.tekartik.sqflite.** { *; }

# Keep Riverpod & GSON / JSON serializations
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Ignore warnings for third-party libraries
-dontwarn io.flutter.embedding.engine.**
-dontwarn io.flutter.plugin.**
