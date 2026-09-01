import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/family_provider.dart';
import '../../members/models/family_member_model.dart';

class FamilyFormScreen extends ConsumerStatefulWidget {
  final String? familyId; // Null for Add, non-null for Edit

  const FamilyFormScreen({super.key, this.familyId});

  @override
  ConsumerState<FamilyFormScreen> createState() => _FamilyFormScreenState();
}

class _FamilyFormScreenState extends ConsumerState<FamilyFormScreen> {
  int _currentStep = 1; // 1 = Basic, 2 = Family Members
  bool _isLoadingInitial = false;
  bool _isSaving = false;

  // Step 1 Controllers & State
  final _step1FormKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _fatherHusbandController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _selectedDOB;
  int _calculatedAge = 0;
  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _selectedMaritalStatus;
  String? _photoUrl;
  File? _selectedPhotoFile;

  // Step 2 State: Family Members
  final List<FamilyMemberModel> _members = [];

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _maritalStatuses = ['Single', 'Married', 'Widowed', 'Divorced'];
  final List<String> _relations = [
    'Wife',
    'Husband',
    'Son',
    'Daughter',
    'Father',
    'Mother',
    'Brother',
    'Sister',
    'Daughter-in-Law (Bahu)',
    'Son-in-Law (Jamai)',
    'Father-in-Law (Sasra)',
    'Mother-in-Law (Sasu)',
    'Brother-in-Law (Bhai/Saala/Devar)',
    'Sister-in-Law (Bhabhi/Saali/Nanand)',
    'Grandfather (Dada/Nana)',
    'Grandmother (Dadi/Nani)',
    'Grandson (Pautra/Dautra)',
    'Granddaughter (Pautri/Dautri)',
    'Uncle (Kaka/Mama/Fuwa/Masa)',
    'Aunt (Kaki/Mami/Foi/Masi)',
    'Nephew (Bhatijo/Bhanjo)',
    'Niece (Bhatiji/Bhanji)',
    'Cousin'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.familyId != null) {
      _loadExistingFamily();
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _fatherHusbandController.dispose();
    _motherNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingFamily() async {
    setState(() => _isLoadingInitial = true);
    final repo = ref.read(familyRepositoryProvider);
    final data = await repo.fetchFamilyWithMembers(widget.familyId!);

    if (data != null && mounted) {
      final family = data['family'];
      final membersList = data['members'] as List<FamilyMemberModel>;

      setState(() {
        _fullNameController.text = family.fullName;
        _fatherHusbandController.text = family.fatherHusbandName;
        _motherNameController.text = family.motherName;
        _addressController.text = family.address;
        _selectedDOB = family.dateOfBirth;
        _calculatedAge = _calculateAgeFromDOB(family.dateOfBirth);
        _selectedGender = family.gender;
        _selectedBloodGroup = family.bloodGroup;
        _selectedMaritalStatus = family.maritalStatus;
        _photoUrl = family.photoUrl;

        _members.clear();
        _members.addAll(membersList);
        _isLoadingInitial = false;
      });
    } else {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  int _calculateAgeFromDOB(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  bool get _isUnderMarriageAge {
    if (_selectedDOB == null) return false;
    final minAge = (_selectedGender == 'Female') ? 18 : 21;
    return _calculatedAge < minAge;
  }

  void _checkAndEnforceMarriageAgeConstraint() {
    if (_isUnderMarriageAge) {
      _selectedMaritalStatus = 'Single';
    }
  }

  Future<void> _selectDOB(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDOB ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDOB = picked;
        _calculatedAge = _calculateAgeFromDOB(picked);
        _checkAndEnforceMarriageAgeConstraint();
      });
    }
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discard Changes?'),
        content: const Text('Are you sure you want to discard your changes and leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No, Stay'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Yes, Discard'),
          ),
        ],
      ),
    );
  }

  void _showAddEditMemberBottomSheet({FamilyMemberModel? memberToEdit, int? editIndex}) {
    final nameCtrl = TextEditingController(text: memberToEdit?.fullName ?? '');
    DateTime? memberDOB = memberToEdit?.dateOfBirth;
    int calculatedMemberAge = memberToEdit?.age ?? 0;
    final ageCtrl = TextEditingController(text: memberToEdit != null ? memberToEdit.age.toString() : '');
    String? rel = memberToEdit?.relation ?? _relations.first;
    String? blood = memberToEdit?.bloodGroup;
    File? memberPhotoFile;
    String? memberPhotoUrl = memberToEdit?.photoUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctxState, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        memberToEdit != null ? 'Edit Family Member' : 'Add Family Member',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Member Photo Picker
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final file = await StorageService.pickImage(ImageSource.gallery);
                        if (file != null) {
                          setModalState(() {
                            memberPhotoFile = file;
                          });
                        }
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.primaryContainer,
                            backgroundImage: memberPhotoFile != null
                                ? FileImage(memberPhotoFile!)
                                : (memberPhotoUrl != null && memberPhotoUrl.isNotEmpty
                                    ? CachedNetworkImageProvider(memberPhotoUrl)
                                    : null) as ImageProvider?,
                            child: memberPhotoFile == null && (memberPhotoUrl == null || memberPhotoUrl.isEmpty)
                                ? const Icon(Icons.person_add_alt_1_rounded, size: 36, color: AppColors.primary)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Member Full Name
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Relation Dropdown
                  DropdownButtonFormField<String>(
                    value: rel,
                    decoration: const InputDecoration(
                      labelText: 'Relation *',
                      prefixIcon: Icon(Icons.people_outline_rounded),
                    ),
                    items: _relations
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setModalState(() => rel = v),
                  ),

                  const SizedBox(height: 12),

                  // Date of Birth & Auto-Calculated Age
                  Row(
                    children: [
                      // Date of Birth Picker
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: memberDOB ?? DateTime(2000, 1, 1),
                              firstDate: DateTime(1900),
                              lastDate: now,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppColors.primary,
                                      onPrimary: Colors.white,
                                      onSurface: AppColors.textPrimary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (picked != null) {
                              setModalState(() {
                                memberDOB = picked;
                                int a = now.year - picked.year;
                                if (now.month < picked.month ||
                                    (now.month == picked.month && now.day < picked.day)) {
                                  a--;
                                }
                                calculatedMemberAge = a < 0 ? 0 : a;
                                ageCtrl.text = calculatedMemberAge.toString();
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth *',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(
                              memberDOB != null
                                  ? DateFormat('dd MMM yyyy').format(memberDOB!)
                                  : 'Select DOB',
                              style: TextStyle(
                                fontSize: 13,
                                color: memberDOB != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Read-only Auto-calculated Age
                      Expanded(
                        flex: 2,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Age',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                          child: Text(
                            '$calculatedMemberAge yrs',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Blood Group Dropdown
                  DropdownButtonFormField<String>(
                    value: blood,
                    decoration: const InputDecoration(
                      labelText: 'Blood Group',
                      prefixIcon: Icon(Icons.water_drop_outlined),
                    ),
                    items: _bloodGroups
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) => setModalState(() => blood = v),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter member name'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      if (memberDOB == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select Date of Birth'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      String? uploadedUrl = memberPhotoUrl;
                      if (memberPhotoFile != null) {
                        uploadedUrl = await StorageService.uploadPhoto(
                          memberPhotoFile!,
                          'members',
                        );
                      }

                      final newMember = FamilyMemberModel(
                        id: memberToEdit?.id,
                        familyId: memberToEdit?.familyId,
                        fullName: nameCtrl.text.trim(),
                        relation: rel ?? _relations.first,
                        dateOfBirth: memberDOB,
                        age: calculatedMemberAge,
                        bloodGroup: blood,
                        photoUrl: uploadedUrl,
                      );

                      setState(() {
                        if (editIndex != null) {
                          _members[editIndex] = newMember;
                        } else {
                          _members.add(newMember);
                        }
                      });

                      Navigator.pop(ctx);
                    },
                    child: Text(memberToEdit != null ? 'Update Member' : 'Save Member'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleSaveFamily() async {
    setState(() => _isSaving = true);
    final repo = ref.read(familyRepositoryProvider);
    final currentUser = ref.read(currentUserProvider);

    try {
      String? finalPhotoUrl = _photoUrl;

      // Upload head photo if newly selected
      if (_selectedPhotoFile != null) {
        final uploaded = await StorageService.uploadPhoto(
          _selectedPhotoFile!,
          'heads',
        );
        if (uploaded != null) finalPhotoUrl = uploaded;
      }

      final familyPayload = {
        'full_name': _fullNameController.text.trim(),
        'father_husband_name': _fatherHusbandController.text.trim(),
        'mother_name': _motherNameController.text.trim(),
        'date_of_birth': _selectedDOB!.toIso8601String().split('T').first,
        'gender': _selectedGender,
        'blood_group': _selectedBloodGroup,
        'marital_status': _selectedMaritalStatus,
        'address': _addressController.text.trim(),
        'photo_url': finalPhotoUrl,
      };

      bool success = false;
      if (widget.familyId != null) {
        success = await repo.updateFamily(
          familyId: widget.familyId!,
          familyData: familyPayload,
          members: _members,
        );
      } else {
        success = await repo.createFamily(
          familyData: familyPayload,
          members: _members,
          userId: currentUser?.id,
        );
      }

      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          ref.read(familyStateProvider.notifier).loadFamilies();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.familyId != null
                    ? 'Family record updated successfully!'
                    : 'Family record created successfully!',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save family record. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.familyId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Family Record' : 'New Family Record'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _confirmCancel,
        ),
      ),
      body: _isLoadingInitial
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: Column(
                children: [
                  // Step Indicator (Only 2 Steps: Step 1 - Basic, Step 2 - Family Members)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStepTab(
                            stepNumber: 1,
                            title: 'Basic',
                            isActive: _currentStep == 1,
                            isCompleted: _currentStep > 1,
                          ),
                        ),
                        Container(
                          width: 30,
                          height: 2,
                          color: _currentStep > 1 ? AppColors.primary : AppColors.border,
                        ),
                        Expanded(
                          child: _buildStepTab(
                            stepNumber: 2,
                            title: 'Family Members',
                            isActive: _currentStep == 2,
                            isCompleted: false,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Step Content Pages
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: _currentStep == 1 ? _buildStep1Basic() : _buildStep2Members(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStepTab({
    required int stepNumber,
    required String title,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isActive || isCompleted
              ? AppColors.primary
              : AppColors.surfaceVariant,
          child: isCompleted
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : Text(
                  '$stepNumber',
                  style: TextStyle(
                    color: isActive ? Colors.white : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // STEP 1 — Basic Details Form
  Widget _buildStep1Basic() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // 1. Full Name (Head of Family)
          TextFormField(
            controller: _fullNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full Name (Head of Family) *',
              prefixIcon: Icon(Icons.person_rounded),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Full name is required';
              return null;
            },
          ),

          const SizedBox(height: 16),

          // 2. Father's / Husband's Name
          TextFormField(
            controller: _fatherHusbandController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: "Father's / Husband's Name *",
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return "Father/Husband name is required";
              return null;
            },
          ),

          const SizedBox(height: 16),

          // 3. Mother's Name
          TextFormField(
            controller: _motherNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: "Mother's Name *",
              prefixIcon: Icon(Icons.female_rounded),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return "Mother's name is required";
              return null;
            },
          ),

          const SizedBox(height: 16),

          // 4. Date of Birth & 5. Age Display Field
          Row(
            children: [
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: () => _selectDOB(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth *',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                    child: Text(
                      _selectedDOB != null
                          ? DateFormat('dd MMM yyyy').format(_selectedDOB!)
                          : 'Select DOB',
                      style: TextStyle(
                        color: _selectedDOB != null
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake_rounded),
                  ),
                  child: Text(
                    '$_calculatedAge yrs',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 6. Gender & 7. Blood Group
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender *',
                    prefixIcon: Icon(Icons.people_alt_rounded),
                  ),
                  items: _genders
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedGender = v;
                    _checkAndEnforceMarriageAgeConstraint();
                  }),
                  validator: (v) => v == null ? 'Select gender' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedBloodGroup,
                  decoration: const InputDecoration(
                    labelText: 'Blood Group *',
                    prefixIcon: Icon(Icons.water_drop_rounded),
                  ),
                  items: _bloodGroups
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedBloodGroup = v),
                  validator: (v) => v == null ? 'Select blood group' : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 8. Marital Status (Locked to Single if under legal marriage age)
          _isUnderMarriageAge
              ? InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Marital Status *',
                    prefixIcon: Icon(Icons.favorite_outline_rounded),
                    helperText: 'Locked to Single (Under legal marriage age)',
                  ),
                  child: Text(
                    'Single',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedMaritalStatus,
                  decoration: const InputDecoration(
                    labelText: 'Marital Status *',
                    prefixIcon: Icon(Icons.favorite_outline_rounded),
                  ),
                  items: _maritalStatuses
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedMaritalStatus = v),
                  validator: (v) => v == null ? 'Select marital status' : null,
                ),

          const SizedBox(height: 16),

          // 9. Address (Multi-line text field)
          TextFormField(
            controller: _addressController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Full Address *',
              hintText: 'Enter complete residential address in Junagadh/other location',
              prefixIcon: Icon(Icons.location_on_rounded),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Address is required';
              return null;
            },
          ),

          const SizedBox(height: 32),

          // Navigation Action Buttons
          ElevatedButton(
            onPressed: () {
              if (_selectedDOB == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select Date of Birth'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              if (_step1FormKey.currentState!.validate()) {
                setState(() => _currentStep = 2);
              }
            },
            child: const Text('Continue to Family Members'),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: _confirmCancel,
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  // STEP 2 — Family Members List & Add Button
  Widget _buildStep2Members() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Family Members (${_members.length})',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showAddEditMemberBottomSheet(),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Member'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (_members.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.group_add_rounded,
                  size: 48,
                  color: AppColors.textMuted.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'No family members added yet.',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Click "Add Member" above to add children, spouse, parents, etc.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _members.length,
            itemBuilder: (context, index) {
              final m = _members[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryContainer,
                    backgroundImage: m.photoUrl != null && m.photoUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(m.photoUrl!)
                        : null,
                    child: m.photoUrl == null || m.photoUrl!.isEmpty
                        ? Text(
                            m.fullName.isNotEmpty ? m.fullName[0].toUpperCase() : 'M',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    m.fullName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    '${m.relation} • ${m.age} yrs${m.bloodGroup != null ? ' • ${m.bloodGroup}' : ''}',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                        onPressed: () => _showAddEditMemberBottomSheet(
                          memberToEdit: m,
                          editIndex: index,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                        onPressed: () {
                          setState(() {
                            _members.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: 32),

        // Action Buttons: Save Family Record & Back/Cancel
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSaveFamily,
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Text(widget.familyId != null ? 'Update Family Record' : 'Save Family Record'),
        ),

        const SizedBox(height: 12),

        OutlinedButton(
          onPressed: () {
            setState(() => _currentStep = 1);
          },
          child: const Text('Back to Basic Details'),
        ),

        const SizedBox(height: 8),

        TextButton(
          onPressed: _confirmCancel,
          child: const Text('Cancel & Discard', style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}
