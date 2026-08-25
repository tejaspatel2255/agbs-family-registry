class FamilyMemberModel {
  final String? id;
  final String? familyId;
  final String fullName;
  final String relation;
  final int age;
  final String? bloodGroup;
  final String? photoUrl;
  final DateTime? createdAt;

  FamilyMemberModel({
    this.id,
    this.familyId,
    required this.fullName,
    required this.relation,
    required this.age,
    this.bloodGroup,
    this.photoUrl,
    this.createdAt,
  });

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    return FamilyMemberModel(
      id: json['id'] as String?,
      familyId: json['family_id'] as String?,
      fullName: json['full_name'] as String? ?? '',
      relation: json['relation'] as String? ?? '',
      age: json['age'] as int? ?? 0,
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
      age: age ?? this.age,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
