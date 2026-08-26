import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class MemberSignUpScreen extends ConsumerStatefulWidget {
  const MemberSignUpScreen({super.key});

  @override
  ConsumerState<MemberSignUpScreen> createState() => _MemberSignUpScreenState();
}

class _MemberSignUpScreenState extends ConsumerState<MemberSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _otpSent = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldownTimer() {
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() => _cooldownSeconds--);
      } else {
        _cooldownTimer?.cancel();
      }
    });
  }

  bool _hasMinLength(String p) => p.length >= 8;
  bool _hasLetter(String p) => RegExp(r'[a-zA-Z]').hasMatch(p);
  bool _hasDigit(String p) => RegExp(r'[0-9]').hasMatch(p);

  bool get _isPasswordValid {
    final p = _passwordController.text.trim();
    final c = _confirmPasswordController.text.trim();
    return _hasMinLength(p) && _hasLetter(p) && _hasDigit(p) && p == c && c.isNotEmpty;
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isPasswordValid) return;

    final mobile = _mobileController.text.trim();
    final res = await ref.read(authStateProvider.notifier).sendOtp(mobile, purpose: 'signup');

    if (res['success'] == true && mounted) {
      setState(() => _otpSent = true);
      _startCooldownTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'OTP sent to $mobile'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  Future<void> _handleVerifyOtpAndSignUp() async {
    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit OTP received on your mobile'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref.read(authStateProvider.notifier).verifyOtpAndLogin(
          mobile: _mobileController.text.trim(),
          otp: _otpController.text.trim(),
          purpose: 'signup',
          fullName: _fullNameController.text.trim(),
        );

    if (success && mounted) {
      context.go('/member-dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_otpSent ? 'Verify OTP' : 'Member Registration (OTP)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_otpSent) {
              setState(() => _otpSent = false);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _otpSent ? Icons.mark_email_read_rounded : Icons.person_add_rounded,
                      size: 42,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  _otpSent ? 'Enter 6-Digit OTP' : 'Create AGBS Account',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _otpSent
                      ? 'OTP sent via Brevo SMS to +91 ${_mobileController.text}'
                      : 'Join the Audichya Gadhiya Brahm Samaj Registry',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 28),

                if (authState.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Text(
                      authState.errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                if (!_otpSent) ...[
                  // Step 1: Registration Form
                  TextFormField(
                    controller: _fullNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      hintText: 'Enter your full name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Full name is required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number *',
                      hintText: '10-digit mobile number',
                      prefixIcon: Icon(Icons.phone_android_rounded),
                      counterText: '',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length != 10) {
                        return 'Please enter a valid 10-digit mobile number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      hintText: 'Minimum 8 characters',
                      helperText: 'Your password must be at least 8 characters with a letter and a number.',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Password is required';
                      }
                      if (!_hasMinLength(val)) {
                        return 'Password must be at least 8 characters';
                      }
                      if (!_hasLetter(val)) {
                        return 'Password must contain at least one letter';
                      }
                      if (!_hasDigit(val)) {
                        return 'Password must contain at least one number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Retype Password *',
                      hintText: 'Retype your password',
                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please retype your password';
                      }
                      if (val != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password Requirements Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password Requirements:',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildRuleItem(
                          'At least 8 characters long',
                          _hasMinLength(_passwordController.text),
                        ),
                        _buildRuleItem(
                          'Contains at least one letter (A-Z, a-z)',
                          _hasLetter(_passwordController.text),
                        ),
                        _buildRuleItem(
                          'Contains at least one number (0-9)',
                          _hasDigit(_passwordController.text),
                        ),
                        _buildRuleItem(
                          'Both fields must match',
                          _passwordController.text.isNotEmpty &&
                              _passwordController.text == _confirmPasswordController.text,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: (_isPasswordValid && !authState.isLoading) ? _handleSendOtp : null,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Send SMS OTP for Registration'),
                  ),
                ] else ...[
                  // Step 2: OTP Verification Screen
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      labelText: '6-Digit Verification Code',
                      hintText: '______',
                      prefixIcon: Icon(Icons.security_rounded),
                      counterText: '',
                    ),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: authState.isLoading ? null : _handleVerifyOtpAndSignUp,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Verify OTP & Complete Registration'),
                  ),

                  const SizedBox(height: 20),

                  // Resend Timer
                  Center(
                    child: _cooldownSeconds > 0
                        ? Text(
                            'Resend OTP in ${_cooldownSeconds}s',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : TextButton.icon(
                            onPressed: authState.isLoading ? null : _handleSendOtp,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Resend OTP'),
                          ),
                  ),
                ],

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already registered? ',
                      style: GoogleFonts.inter(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.pushReplacement('/member-login');
                      },
                      child: Text(
                        'Member Login',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: isMet ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isMet ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
