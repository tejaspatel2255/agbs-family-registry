class FamilyModel {
  final String id;
  final String familyCode;
  final String fullName;
  final String fatherHusbandName;
  final String motherName;
  final DateTime dateOfBirth;
  final String gender;
  final String bloodGroup;
  final String maritalStatus;
  final String address;
  final String? photoUrl;
  final int memberCount;
  final String? createdBy;
  final String? mobileNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  FamilyModel({
    required this.id,
    required this.familyCode,
    required this.fullName,
    required this.fatherHusbandName,
    required this.motherName,
    required this.dateOfBirth,
    required this.gender,
    required this.bloodGroup,
    required this.maritalStatus,
    required this.address,
    this.photoUrl,
    required this.memberCount,
    this.createdBy,
    this.mobileNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    String? mobile;
    if (json['profiles'] != null && json['profiles'] is Map) {
      mobile = json['profiles']['mobile_number']?.toString();
    } else if (json['mobile_number'] != null) {
      mobile = json['mobile_number']?.toString();
    }

    return FamilyModel(
      id: json['id'] as String,
      familyCode: json['family_code'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      fatherHusbandName: json['father_husband_name'] as String? ?? '',
      motherName: json['mother_name'] as String? ?? '',
      dateOfBirth: DateTime.tryParse(json['date_of_birth']?.toString() ?? '') ?? DateTime.now(),
      gender: json['gender'] as String? ?? '',
      bloodGroup: json['blood_group'] as String? ?? '',
      maritalStatus: json['marital_status'] as String? ?? '',
      address: json['address'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      memberCount: json['member_count'] as int? ?? 1,
      createdBy: json['created_by'] as String?,
      mobileNumber: mobile,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_code': familyCode,
      'full_name': fullName,
      'father_husband_name': fatherHusbandName,
      'mother_name': motherName,
      'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
      'gender': gender,
      'blood_group': bloodGroup,
      'marital_status': maritalStatus,
      'address': address,
      'photo_url': photoUrl,
      'member_count': memberCount,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FamilyModel copyWith({
    String? id,
    String? familyCode,
    String? fullName,
    String? fatherHusbandName,
    String? motherName,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? maritalStatus,
    String? address,
    String? photoUrl,
    int? memberCount,
    String? createdBy,
    String? mobileNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyModel(
      id: id ?? this.id,
      familyCode: familyCode ?? this.familyCode,
      fullName: fullName ?? this.fullName,
      fatherHusbandName: fatherHusbandName ?? this.fatherHusbandName,
      motherName: motherName ?? this.motherName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      memberCount: memberCount ?? this.memberCount,
      createdBy: createdBy ?? this.createdBy,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
