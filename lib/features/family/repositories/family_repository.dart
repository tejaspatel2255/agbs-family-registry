import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../models/family_model.dart';
import '../../members/models/family_member_model.dart';

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
      final families = (data as List).map((e) => FamilyModel.fromJson(e)).toList();

      try {
        final profilesData = await _client.from('profiles').select('id, mobile_number');
        final mobileMap = <String, String>{};
        for (final p in profilesData as List) {
          if (p['id'] != null && p['mobile_number'] != null) {
            mobileMap[p['id'].toString()] = p['mobile_number'].toString();
          }
        }
        return families.map((f) {
          if (f.createdBy != null && mobileMap.containsKey(f.createdBy)) {
            return f.copyWith(mobileNumber: mobileMap[f.createdBy]);
          }
          return f;
        }).toList();
      } catch (_) {
        return families;
      }
    } catch (e) {
      return [];
    }
  }

  /// Fetch a single family record by ID with its members
  Future<Map<String, dynamic>?> fetchFamilyWithMembers(String familyId) async {
    try {
      final familyData = await _client.from('families').select().eq('id', familyId).single();
      final membersData = await _client.from('family_members').select().eq('family_id', familyId);

      final family = FamilyModel.fromJson(familyData);
      final members = (membersData as List).map((e) => FamilyMemberModel.fromJson(e)).toList();

      return {
        'family': family,
        'members': members,
      };
    } catch (e) {
      return null;
    }
  }

  /// Create a new family record and its associated members
  Future<bool> createFamily({
    required Map<String, dynamic> familyData,
    required List<FamilyMemberModel> members,
    required String? userId,
  }) async {
    try {
      final payload = Map<String, dynamic>.from(familyData);
      payload['created_by'] = userId;

      // Insert family row
      final insertedFamily = await _client.from('families').insert(payload).select().single();
      final familyId = insertedFamily['id'] as String;

      // Insert family members if any
      if (members.isNotEmpty) {
        final membersPayload = members.map((m) => m.toJson(assignedFamilyId: familyId)).toList();
        await _client.from('family_members').insert(membersPayload);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update an existing family record and sync its members
  Future<bool> updateFamily({
    required String familyId,
    required Map<String, dynamic> familyData,
    required List<FamilyMemberModel> members,
  }) async {
    try {
      // Update families table
      await _client.from('families').update(familyData).eq('id', familyId);

      // Delete old family members for this family
      await _client.from('family_members').delete().eq('family_id', familyId);

      // Insert new/updated family members
      if (members.isNotEmpty) {
        final membersPayload = members.map((m) => m.toJson(assignedFamilyId: familyId)).toList();
        await _client.from('family_members').insert(membersPayload);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a family record by ID and all associated family members
  Future<bool> deleteFamily(String familyId) async {
    try {
      // 1. Delete associated family members first to avoid FK constraint errors
      await _client.from('family_members').delete().eq('family_id', familyId);

      // 2. Delete the family record
      await _client.from('families').delete().eq('id', familyId);
      return true;
    } catch (e) {
      print('Family delete error: $e');
      return false;
    }
  }
}
