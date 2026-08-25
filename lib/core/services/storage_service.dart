import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import 'supabase_service.dart';

class StorageService {
  StorageService._();

  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery or camera
  static Future<File?> pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Upload an image to Supabase Storage "family-photos" bucket and return the public URL
  static Future<String?> uploadPhoto(File imageFile, String folderPath) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final fullPath = '$folderPath/$fileName';

      await SupabaseService.client.storage
          .from(SupabaseConstants.familyPhotosBucket)
          .upload(fullPath, imageFile, fileOptions: const FileOptions(upsert: true));

      final publicUrl = SupabaseService.client.storage
          .from(SupabaseConstants.familyPhotosBucket)
          .getPublicUrl(fullPath);

      return publicUrl;
    } catch (e) {
      return null;
    }
  }
}
