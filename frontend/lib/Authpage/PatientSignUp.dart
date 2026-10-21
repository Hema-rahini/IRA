import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ira/theme/app_theme.dart';
import '../urls.dart';
import 'PatientLoginpage.dart';

class PatientSingPage extends StatefulWidget {
  const PatientSingPage({Key? key}) : super(key: key);

  @override
  State<PatientSingPage> createState() => _PatientSingPageState();
}

class _PatientSingPageState extends State<PatientSingPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileNoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Real-time password criteria
  String _currentPassword = '';
  bool get _hasMinLength => _currentPassword.length >= 8;
  bool get _hasUpperLower => RegExp(r'(?=.*[a-z])(?=.*[A-Z])').hasMatch(_currentPassword);
  bool get _hasNumber => RegExp(r'\d').hasMatch(_currentPassword);
  bool get _hasSpecialChar => RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_currentPassword);

  int get _passwordScore {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUpperLower) score++;
    if (_hasNumber) score++;
    if (_hasSpecialChar) score++;
    return score;
  }

  Color get _strengthColor {
    switch (_passwordScore) {
      case 1:
        return const Color(0xFFEF4444); // Red
      case 2:
        return const Color(0xFFF97316); // Orange
      case 3:
        return const Color(0xFFEAB308); // Amber
      case 4:
        return const Color(0xFF10B981); // Emerald Green
      default:
        return const Color(0xFFE2E8F0);
    }
  }

  String get _strengthText {
    switch (_passwordScore) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong & Secure';
      default:
        return 'Too short';
    }
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      if (_currentPassword != _passwordController.text) {
        setState(() {
          _currentPassword = _passwordController.text;
        });
      }
    });
  }

  void _signup() async {
    // Enable auto-validation so errors show dynamically
    setState(() {
      _autoValidateMode = AutovalidateMode.onUserInteraction;
    });

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Please correct the highlighted form errors before proceeding.'),
              ),
            ],
          ),
          backgroundColor: AppColors.negativeRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final mobileno = _mobileNoController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(api.signup),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Email_ID": email,
          "Password": password,
          "Mobile_No": mobileno,
          "Confirm_Password": confirmPassword,
          "Name": name,
        }),
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Account created successfully! Please sign in.'),
                ),
              ],
            ),
            backgroundColor: AppColors.positiveGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PatientLoginPage()),
        );
      } else {
        String errMsg = 'Registration failed (${response.statusCode})';
        try {
          final resData = json.decode(response.body);
          if (resData['error'] != null) {
            errMsg = resData['error'].toString();
          } else if (resData['message'] != null) {
            errMsg = resData['message'].toString();
          }
        } catch (_) {}

        if (response.statusCode == 402) {
          errMsg = 'This email address is already registered.';
        } else if (response.statusCode == 409) {
          errMsg = 'This mobile number is already registered.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(errMsg)),
              ],
            ),
            backgroundColor: AppColors.negativeRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server connection failed. Ensure backend is running at ${api.ip}'),
          backgroundColor: AppColors.negativeRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileNoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.patientBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.patientPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'NEW PATIENT ACCOUNT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.patientPrimary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: const Text(
                  'Start Your Journey',
                  style: TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FadeInUp(
                duration: const Duration(milliseconds: 500),
                delay: const Duration(milliseconds: 100),
                child: const Text(
                  'Join IRA for personalized anger management, daily journaling, and therapy support.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24.0),

              // Form Container
              FadeInUp(
                duration: const Duration(milliseconds: 550),
                delay: const Duration(milliseconds: 150),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: AppStyles.cardDecoration(
                    backgroundColor: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autoValidateMode,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name
                        const Text(
                          'Full Name',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: AppStyles.inputDecoration(
                            hintText: 'Jane Doe',
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.patientPrimary, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your full name';
                            }
                            final trimmed = value.trim();
                            if (trimmed.length < 3) {
                              return 'Name must be at least 3 characters long';
                            }
                            if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(trimmed)) {
                              return 'Name can only contain alphabetic letters and spaces';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Mobile Number
                        const Text(
                          'Mobile Number',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _mobileNoController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: AppStyles.inputDecoration(
                            hintText: '10-digit mobile number',
                            prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.patientPrimary, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your mobile number';
                            }
                            final trimmed = value.trim();
                            if (trimmed.length != 10) {
                              return 'Mobile number must be exactly 10 digits';
                            }
                            if (!RegExp(r'^[6-9]\d{9}$').hasMatch(trimmed)) {
                              return 'Must be a valid 10-digit number starting with 6, 7, 8, or 9';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Email Address
                        const Text(
                          'Email Address',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: AppStyles.inputDecoration(
                            hintText: 'patient@email.com',
                            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.patientPrimary, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email address';
                            }
                            final trimmed = value.trim();
                            final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                            if (!emailRegExp.hasMatch(trimmed)) {
                              return 'Enter a valid email address (e.g. name@domain.com)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Create Password
                        const Text(
                          'Create Password',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: AppStyles.inputDecoration(
                            hintText: 'Minimum 8 characters with Aa, 12, #@',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.patientPrimary, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please create a secure password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters long';
                            }
                            if (!RegExp(r'(?=.*[a-z])(?=.*[A-Z])').hasMatch(value)) {
                              return 'Must contain both uppercase and lowercase letters';
                            }
                            if (!RegExp(r'\d').hasMatch(value)) {
                              return 'Must include at least one number (0-9)';
                            }
                            if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                              return 'Must include at least one special character (!@#\$%^&*...)';
                            }
                            return null;
                          },
                        ),

                        // Real-Time Password Strength Meter
                        if (_currentPassword.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _passwordScore / 4.0,
                                    minHeight: 5,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _strengthText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _strengthColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Criteria Checklist
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                _buildRequirementItem('At least 8 characters', _hasMinLength),
                                const SizedBox(height: 6),
                                _buildRequirementItem('Uppercase (A-Z) & Lowercase (a-z)', _hasUpperLower),
                                const SizedBox(height: 6),
                                _buildRequirementItem('At least one numeric digit (0-9)', _hasNumber),
                                const SizedBox(height: 6),
                                _buildRequirementItem('At least one special character (!@#\$...)', _hasSpecialChar),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),

                        // Confirm Password
                        const Text(
                          'Confirm Password',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: AppStyles.inputDecoration(
                            hintText: 'Re-enter your password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.patientPrimary, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please re-enter your password to confirm';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.patientPrimary,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                  )
                                : const Text(
                                    'Complete Registration',
                                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24.0),
              FadeInUp(
                duration: const Duration(milliseconds: 500),
                delay: const Duration(milliseconds: 250),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account? ",
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const PatientLoginPage()),
                          );
                        },
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.patientPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: isMet ? const Color(0xFF10B981) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isMet ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
          child: isMet
              ? const Icon(Icons.check, size: 11, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? const Color(0xFF0F172A) : AppColors.textMuted,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
