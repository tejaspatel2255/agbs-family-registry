import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class MemberForgotPasswordScreen extends ConsumerStatefulWidget {
  final String returnRoute;
  const MemberForgotPasswordScreen({super.key, this.returnRoute = '/member-login'});

  @override
  ConsumerState<MemberForgotPasswordScreen> createState() => _MemberForgotPasswordScreenState();
}

class _MemberForgotPasswordScreenState extends ConsumerState<MemberForgotPasswordScreen> {
  final _mobileFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 1; // 1: Mobile, 2: OTP, 3: New Password
  String? _resetToken;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _handleSendOtp() async {
    if (!_mobileFormKey.currentState!.validate()) return;

    final mobile = _mobileController.text.trim();
    final res = await ref.read(authStateProvider.notifier).sendOtp(
          mobile,
          purpose: 'reset_password',
        );

    if (res['success'] == true && mounted) {
      setState(() => _currentStep = 2);
      _startCooldownTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Password reset OTP sent to $mobile'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;

    final mobile = _mobileController.text.trim();
    final otp = _otpController.text.trim();

    final token = await ref.read(authStateProvider.notifier).verifyPasswordResetOtp(
          mobile: mobile,
          otp: otp,
        );

    if (token != null && mounted) {
      setState(() {
        _resetToken = token;
        _currentStep = 3;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP Verified! Please enter your new password.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final mobile = _mobileController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    final success = await ref.read(authStateProvider.notifier).resetAdminPassword(
          mobile: mobile,
          resetToken: _resetToken!,
          newPassword: newPassword,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 4),
        ),
      );
      context.go(widget.returnRoute);
    }
  }

  void _restartFlow() {
    setState(() {
      _currentStep = 1;
      _resetToken = null;
      _otpController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
  }

  bool _hasMinLength(String p) => p.length >= 8;
  bool _hasLetter(String p) => RegExp(r'[a-zA-Z]').hasMatch(p);
  bool _hasDigit(String p) => RegExp(r'[0-9]').hasMatch(p);

  bool get _isPasswordValid {
    final p = _newPasswordController.text.trim();
    final c = _confirmPasswordController.text.trim();
    return _hasMinLength(p) && _hasLetter(p) && _hasDigit(p) && p == c && c.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentStep == 1
              ? 'Forgot Password'
              : _currentStep == 2
                  ? 'Verify Reset OTP'
                  : 'Set New Password',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() => _currentStep--);
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go(widget.returnRoute);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _currentStep == 1
                          ? Icons.lock_reset_rounded
                          : _currentStep == 2
                              ? Icons.mark_email_read_rounded
                              : Icons.key_rounded,
                      size: 42,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  _currentStep == 1
                      ? 'Forgot Password'
                      : _currentStep == 2
                          ? 'Enter 6-Digit OTP'
                          : 'Create New Password',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  _currentStep == 1
                      ? 'Enter your registered mobile number to receive an OTP.'
                      : _currentStep == 2
                          ? 'Enter the verification code sent to +91 ${_mobileController.text}'
                          : 'Your new password must be at least 8 characters with a letter and a number.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 28),

                if (authState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          authState.errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        if (_currentStep == 3) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _restartFlow,
                            icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.error),
                            label: const Text(
                              'Restart Reset Request',
                              style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // STEP 1: Enter Mobile Number
                if (_currentStep == 1) ...[
                  Form(
                    key: _mobileFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: const InputDecoration(
                            labelText: 'Registered Mobile Number',
                            hintText: 'Enter 10-digit mobile number',
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
                        const SizedBox(height: 28),
                        ElevatedButton(
                          onPressed: authState.isLoading ? null : _handleSendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('Send OTP'),
                        ),
                      ],
                    ),
                  ),
                ],

                // STEP 2: Enter 6-Digit OTP
                if (_currentStep == 2) ...[
                  Form(
                    key: _otpFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                          validator: (val) {
                            if (val == null || val.trim().length != 6) {
                              return 'Please enter the 6-digit OTP code';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: authState.isLoading ? null : _handleVerifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('Verify OTP'),
                        ),
                        const SizedBox(height: 20),
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
                    ),
                  ),
                ],

                // STEP 3: Enter New Password & Retype Password
                if (_currentStep == 3) ...[
                  Form(
                    key: _passwordFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // New Password
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNewPassword,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            hintText: 'Minimum 8 characters',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() => _obscureNewPassword = !_obscureNewPassword);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Retype New Password
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Retype Password',
                            hintText: 'Retype your new password',
                            prefixIcon: const Icon(Icons.lock_reset_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password rules indicator
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
                                _hasMinLength(_newPasswordController.text),
                              ),
                              _buildRuleItem(
                                'Contains at least one letter (A-Z, a-z)',
                                _hasLetter(_newPasswordController.text),
                              ),
                              _buildRuleItem(
                                'Contains at least one number (0-9)',
                                _hasDigit(_newPasswordController.text),
                              ),
                              _buildRuleItem(
                                'Both fields must match',
                                _newPasswordController.text.isNotEmpty &&
                                    _newPasswordController.text == _confirmPasswordController.text,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        ElevatedButton(
                          onPressed: (_isPasswordValid && !authState.isLoading)
                              ? _handleResetPassword
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('Save'),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Center(
                  child: TextButton.icon(
                    onPressed: () => context.go('/member-login'),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Return to Member Login'),
                  ),
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
