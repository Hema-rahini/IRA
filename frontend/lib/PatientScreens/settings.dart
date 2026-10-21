import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:ira/theme/app_theme.dart';
import '../OnboardingScreens/authoptions.dart';
import '../urls.dart';
import '../utilsn.dart';
import 'ChangeProfileDetails.dart';
import 'PatientNotificationsPage.dart';
import 'feedbackscreen.dart';

class ProfileSettingsPage extends StatefulWidget {
  final String email;
  final String img;
  const ProfileSettingsPage({Key? key, required this.email, required this.img}) : super(key: key);
  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  String accountantName = '';
  String occupation = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllDetailsWithRetry();
  }

  Future<void> fetchAllDetailsWithRetry() async {
    int maxRetries = 3;

    while (maxRetries > 0) {
      try {
        final response = await http.post(
          Uri.parse(api.ip + '/get_user_details'),
          headers: {
            'content-type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({"Email_ID": widget.email}),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          Map<String, dynamic> detailsData = json.decode(response.body);

          if (mounted) {
            setState(() {
              accountantName = detailsData["Name"]?.toString() ?? '';
              occupation = detailsData["Occupation"]?.toString() ?? '';
              _isLoading = false;
            });
          }
          break;
        }
      } catch (e) {
        print('Error fetching details: $e');
        maxRetries--;
        if (maxRetries > 0) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showChangePasswordModal() {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isUpdating = false;

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
                        child: const Icon(Icons.password_rounded, color: AppColors.patientPrimary, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Update Account Password',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Set a new secure password for this account',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text('New Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: obscureNew,
                    decoration: AppStyles.inputDecoration(
                      hintText: 'Minimum 6 characters',
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
                    controller: confirmPassCtrl,
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
                      onPressed: isUpdating
                          ? null
                          : () async {
                              final newPass = newPassCtrl.text.trim();
                              final confirmPass = confirmPassCtrl.text.trim();

                              if (newPass.isEmpty || confirmPass.isEmpty) {
                                ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                                  const SnackBar(content: Text('Please fill all fields'), backgroundColor: AppColors.negativeRed),
                                );
                                return;
                              }

                              if (newPass.length < 6) {
                                ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                                  const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: AppColors.negativeRed),
                                );
                                return;
                              }

                              if (newPass != confirmPass) {
                                ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                                  const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppColors.negativeRed),
                                );
                                return;
                              }

                              setModalState(() => isUpdating = true);

                              try {
                                final res = await http.post(
                                  Uri.parse(api.ip + '/patient_forgot_password'),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode({'Email_ID': widget.email, 'New_Password': newPass}),
                                );

                                if (res.statusCode == 200) {
                                  Navigator.pop(bottomSheetContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Account password updated successfully!'),
                                      backgroundColor: AppColors.positiveGreen,
                                    ),
                                  );
                                } else {
                                  final err = jsonDecode(res.body)['message'] ?? 'Password update failed';
                                  ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                                    SnackBar(content: Text(err), backgroundColor: AppColors.negativeRed),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.negativeRed),
                                );
                              } finally {
                                setModalState(() => isUpdating = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.patientPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isUpdating
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Update Password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to log out of your session?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.negativeRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await http.post(
                    Uri.parse(api.ip + '/log_activity'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'email': widget.email, "type": "s"}),
                  );
                } catch (e) {
                  print('Error logging out: $e');
                }
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthPage()),
                  (route) => false,
                );
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.patientBackground,
      appBar: AppBar(
        title: const Text('Settings & Account'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.patientPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Account & Security'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: AppStyles.cardDecoration(
                      backgroundColor: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildSettingItem(
                          title: 'Edit Profile Information',
                          subtitle: 'Update biometrics and profile photo',
                          icon: Icons.person_outline_rounded,
                          iconColor: AppColors.patientPrimary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChangeProfileData(email: widget.email),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 64, color: AppColors.borderSubtle),
                        _buildSettingItem(
                          title: 'Change Password',
                          subtitle: 'Update your account login security',
                          icon: Icons.lock_reset_rounded,
                          iconColor: AppColors.patientPrimary,
                          onTap: _showChangePasswordModal,
                        ),
                        const Divider(height: 1, indent: 64, color: AppColors.borderSubtle),
                        _buildSettingItem(
                          title: 'Notifications & Alerts',
                          subtitle: 'Therapy reminders, milestones and clinical updates',
                          icon: Icons.notifications_active_outlined,
                          iconColor: AppColors.patientPrimary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PatientNotificationsPage(email: widget.email),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 64, color: AppColors.borderSubtle),
                        _buildSettingItem(
                          title: 'Log Out',
                          subtitle: 'End current application session',
                          icon: Icons.logout_rounded,
                          iconColor: AppColors.negativeRed,
                          textColor: AppColors.negativeRed,
                          onTap: _handleLogout,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildSectionTitle('Support & Feedback'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: AppStyles.cardDecoration(
                      backgroundColor: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildSettingItem(
                          title: 'Send Application Feedback',
                          subtitle: 'Help us improve IRA therapy features',
                          icon: Icons.rate_review_outlined,
                          iconColor: AppColors.patientSecondary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => FeedbackScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 64, color: AppColors.borderSubtle),
                        _buildSettingItem(
                          title: 'Help & Emergency Support',
                          subtitle: 'Crisis contacts and platform guidelines',
                          icon: Icons.help_outline_rounded,
                          iconColor: AppColors.patientWarmAccent,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('If you are experiencing a mental health emergency, please call your local crisis line or 988.'),
                                duration: Duration(seconds: 4),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AppStyles.cardDecoration(
        backgroundColor: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.patientPrimary.withValues(alpha: 0.3), width: 2),
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.patientBackground,
              backgroundImage: getSafeImageProvider(widget.img),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accountantName.isNotEmpty ? accountantName : 'Patient',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  occupation.isNotEmpty ? occupation : 'Member',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.patientPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15.0,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    Color textColor = AppColors.textPrimary,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: AppColors.textMuted),
    );
  }
}
