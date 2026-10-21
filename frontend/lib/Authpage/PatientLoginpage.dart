import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:ira/theme/app_theme.dart';
import '../PatientScreens/FillDetailsPopupPage.dart';
import '../urls.dart';
import 'PatientSignUp.dart';

class PatientLoginPage extends StatefulWidget {
  const PatientLoginPage({Key? key}) : super(key: key);

  @override
  State<PatientLoginPage> createState() => _PatientLoginPageState();
}

class _PatientLoginPageState extends State<PatientLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
 
  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password'),
          backgroundColor: AppColors.negativeRed,
        ),
      );
      return;
    }

    // Client-side bypass for quick demo/testing (prevents browser CORS blocks on web)
    if ((email.toLowerCase() == 'arul072005@gmail.com' ||
            email.toLowerCase() == 'patient@email.com' ||
            email.toLowerCase() == 'patient@gmail.com') &&
        (password == 'Arul@123' ||
            password == '123456' ||
            password == 'password' ||
            password == 'patient123')) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => popupdetails(email: email)),
      );
      _emailController.clear();
      _passwordController.clear();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final normalizedEmail = email.toLowerCase().trim();
      final response = await http.post(
        Uri.parse(api.login),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"Email_ID": normalizedEmail, "Password": password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => popupdetails(email: normalizedEmail)),
        );
        _emailController.clear();
        _passwordController.clear();
      } else {
        if (!mounted) return;
        String errorMessage = 'Login failed: Invalid credentials (${response.statusCode})';
        try {
          final resData = json.decode(response.body);
          if (resData['message'] != null) {
            errorMessage = resData['message'].toString();
          } else if (resData['error'] != null) {
            errorMessage = resData['error'].toString();
          }
        } catch (_) {}

        if (response.statusCode == 404) {
          errorMessage = 'Account not found. Please tap "Sign Up" below to create an account.';
        } else if (response.statusCode == 401) {
          errorMessage = 'Incorrect password. Please try again or tap "Forgot Password?".';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.negativeRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to connect to server at ${api.ip}'),
          backgroundColor: AppColors.negativeRed,
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

  void _showForgotPasswordModal() {
    final resetEmailCtrl = TextEditingController(text: _emailController.text.trim());
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isResetting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              padding: const EdgeInsets.all(26),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.patientPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.lock_reset_rounded, color: AppColors.patientPrimary, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Reset Password',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Enter your email & choose a new password',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text('Registered Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: resetEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: AppStyles.inputDecoration(
                      hintText: 'patient@email.com',
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.patientPrimary, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('New Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: newPasswordCtrl,
                    obscureText: obscureNew,
                    decoration: AppStyles.inputDecoration(
                      hintText: 'At least 6 characters',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.patientPrimary, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                        onPressed: () => setModalState(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Confirm New Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: confirmPasswordCtrl,
                    obscureText: obscureConfirm,
                    decoration: AppStyles.inputDecoration(
                      hintText: 'Re-enter new password',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.patientPrimary, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                        onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isResetting
                          ? null
                          : () async {
                              final email = resetEmailCtrl.text.trim();
                              final newPass = newPasswordCtrl.text.trim();
                              final confirmPass = confirmPasswordCtrl.text.trim();

                              if (email.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                                ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill all fields'),
                                    backgroundColor: AppColors.negativeRed,
                                  ),
                                );
                                return;
                              }

                              if (newPass.length < 6) {
                                ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password must be at least 6 characters'),
                                    backgroundColor: AppColors.negativeRed,
                                  ),
                                );
                                return;
                              }

                              if (newPass != confirmPass) {
                                ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('Passwords do not match'),
                                    backgroundColor: AppColors.negativeRed,
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isResetting = true);

                              try {
                                final res = await http.post(
                                  Uri.parse(api.ip + '/patient_forgot_password'),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode({'Email_ID': email, 'New_Password': newPass}),
                                );

                                if (res.statusCode == 200) {
                                  Navigator.pop(bottomSheetContext);
                                  _emailController.text = email;
                                  _passwordController.text = newPass;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Password reset successfully! You can now sign in.'),
                                      backgroundColor: AppColors.positiveGreen,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                } else {
                                  final err = jsonDecode(res.body)['message'] ?? 'Password reset failed';
                                  ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                                    SnackBar(content: Text(err), backgroundColor: AppColors.negativeRed),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.negativeRed),
                                );
                              } finally {
                                setModalState(() => isResetting = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.patientPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isResetting
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Reset & Update Password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
        },
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF163E45), // Deep rich teal
              Color(0xFF1E525B), // Primary teal
              Color(0xFF2A7B88), // Lighter ambient teal
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar Navigation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.spa_rounded, size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'SAFE SPACE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        child: const Text(
                          'Welcome',
                          style: TextStyle(
                            fontSize: 32.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 100),
                        child: Text(
                          'Sign in to track your emotions, practice calming exercises, and review your personal progress.',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28.0),

                      // High-Contrast Solid White Card
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.all(26.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Email Address',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: AppStyles.inputDecoration(
                                  hintText: 'patient@email.com',
                                  fillColor: const Color(0xFFF7FAFB),
                                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.patientPrimary, size: 20),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Password',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: AppStyles.inputDecoration(
                                  hintText: 'Enter your password',
                                  fillColor: const Color(0xFFF7FAFB),
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
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _showForgotPasswordModal,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(50, 30),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: AppColors.patientPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.patientPrimary,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: AppColors.patientPrimary.withValues(alpha: 0.45),
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
                                          'Sign In',
                                          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28.0),
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 300),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.88)),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const PatientSingPage()),
                                  );
                                },
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white,
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
            ],
          ),
        ),
      ),
    );
  }
}
