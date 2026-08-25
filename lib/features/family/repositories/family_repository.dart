import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../models/family_model.dart';

class FamilyRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// Fetch families with role check (Admin gets all, Member gets own)
  Future<List<FamilyModel>> fetchFamilies({required bool isAdmin, required String? userId}) async {
    try {
      var query = _client.from('families').select('*');
      
      if (!isAdmin && userId != null) {
        query = query.eq('created_by', userId);
      }

      final data = await query.order('created_at', ascending: false);
      return (data as List).map((e) => FamilyModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete a family record by ID
  Future<bool> deleteFamily(String familyId) async {
    try {
      await _client.from('families').delete().eq('id', familyId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
