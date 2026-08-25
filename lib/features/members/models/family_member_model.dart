class FamilyMemberModel {
  final String? id;
  final String? familyId;
  final String fullName;
  final String relation;
  final DateTime? dateOfBirth;
  final int age;
  final String? bloodGroup;
  final String? photoUrl;
  final DateTime? createdAt;

  FamilyMemberModel({
    this.id,
    this.familyId,
    required this.fullName,
    required this.relation,
    this.dateOfBirth,
    required this.age,
    this.bloodGroup,
    this.photoUrl,
    this.createdAt,
  });

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    final dob = json['date_of_birth'] != null
        ? DateTime.tryParse(json['date_of_birth'].toString())
        : null;
    
    // Auto-calculate age from DOB if DOB exists, otherwise use age column
    int calculatedAge = json['age'] as int? ?? 0;
    if (dob != null) {
      final today = DateTime.now();
      int a = today.year - dob.year;
      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
        a--;
      }
      calculatedAge = a < 0 ? 0 : a;
    }

    return FamilyMemberModel(
      id: json['id'] as String?,
      familyId: json['family_id'] as String?,
      fullName: json['full_name'] as String? ?? '',
      relation: json['relation'] as String? ?? '',
      dateOfBirth: dob,
      age: calculatedAge,
      bloodGroup: json['blood_group'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson({String? assignedFamilyId}) {
    final data = <String, dynamic>{
      'full_name': fullName,
      'relation': relation,
      'age': age,
      'blood_group': bloodGroup,
      'photo_url': photoUrl,
    };
    if (dateOfBirth != null) {
      data['date_of_birth'] = dateOfBirth!.toIso8601String().split('T').first;
    }
    if (id != null) data['id'] = id;
    if (assignedFamilyId != null) {
      data['family_id'] = assignedFamilyId;
    } else if (familyId != null) {
      data['family_id'] = familyId;
    }
    return data;
  }

  FamilyMemberModel copyWith({
    String? id,
    String? familyId,
    String? fullName,
    String? relation,
    DateTime? dateOfBirth,
    int? age,
    String? bloodGroup,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return FamilyMemberModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      fullName: fullName ?? this.fullName,
      relation: relation ?? this.relation,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
