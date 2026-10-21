import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ira/theme/app_theme.dart';
import '../OnboardingScreens/authoptions.dart';
import '../urls.dart';
import '../utilsn.dart';

class ThirdTab extends StatefulWidget {
  final String email;
  const ThirdTab({Key? key, required this.email}) : super(key: key);

  @override
  State<ThirdTab> createState() => _ThirdTabState();
}

class _ThirdTabState extends State<ThirdTab> {
  String? base64Image;
  String count = "0";
  int mild = 0;
  String sMild = "0";
  String severe = "0", critical = "0";
  String name = "Dr. Dinesh";
  String age = "38";
  String gender = "Male";
  String experience = "10 Years";
  String contact = "+91 98765 43210";
  String status = "Active";
  String clinicName = "IRA Behavioral & Mind Wellness Clinic";
  String specialty = "Consultant Clinical Psychiatrist";

  // Notification & Workstation Preferences (Persistent state without annoying popup snackbars)
  bool _triageAlerts = true;
  bool _dailyDigest = true;
  String _digestTime = "08:00 PM";

  // Active Clinical Alerts Feed
  List<Map<String, dynamic>> _clinicalAlerts = [
    {
      'id': '1',
      'title': 'High Anger Triage Alert',
      'patient': 'Critical Score (46/50)',
      'desc': 'Patient recorded severe escalation during Day 4 session.',
      'time': '10 mins ago',
      'priority': 'critical',
      'isRead': false,
    },
    {
      'id': '2',
      'title': 'Follow-Up Assessment Due',
      'patient': 'Cohort Milestone',
      'desc': 'Day 13 therapy sessions completed. Score 2 ready for review.',
      'time': '1 hour ago',
      'priority': 'medium',
      'isRead': false,
    },
    {
      'id': '3',
      'title': 'Negative Sentiment Diary',
      'patient': 'Diary Entry Alert',
      'desc': 'HuggingFace AI classified entry with high negative sentiment.',
      'time': '3 hours ago',
      'priority': 'moderate',
      'isRead': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    await fetchImageWithRetry();
    await getAngerScaleCount();
    await getscores();
  }

  Future<void> getAngerScaleCount() async {
    try {
      final response = await http.get(
        Uri.parse(api.ip + '/anger_scale_counts'),
        headers: {
          'content-type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        Map<String, dynamic> detailsData = json.decode(response.body);
        if (mounted) {
          setState(() {
            mild = (detailsData['Minimal Anger'] ?? 0) + (detailsData['Moderate Anger'] ?? 0);
            sMild = mild.toString();
            severe = (detailsData['Severe Anger'] ?? 0).toString();
            critical = (detailsData['Critical Anger'] ?? 0).toString();
          });
        }
      }
    } catch (e) {
      print('Error getting anger scale counts: $e');
    }
  }

  Future<void> getscores() async {
    try {
      final response = await http.get(
        Uri.parse(api.ip + '/total_users'),
        headers: {
          'content-type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        Map<String, dynamic> detailsData = json.decode(response.body);
        if (mounted) {
          setState(() {
            count = detailsData['total_users_count']?.toString() ?? "0";
          });
        }
      }

      // Fetch Doctor details directly
      if (widget.email.isNotEmpty) {
        final response2 = await http.post(
          Uri.parse(api.get_doctor_details),
          headers: {
            'content-type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({"Email_ID": widget.email}),
        ).timeout(const Duration(seconds: 4));

        if (response2.statusCode == 200) {
          Map<String, dynamic> docData = json.decode(response2.body);
          if (mounted) {
            setState(() {
              if (docData['name'] != null && docData['name'].toString().trim().isNotEmpty) {
                name = docData['name'].toString().trim();
              }
              if (docData['age'] != null) {
                age = docData['age'].toString().trim();
              }
              if (docData['gender'] != null && docData['gender'].toString().trim().isNotEmpty) {
                gender = docData['gender'].toString().trim();
              }
              if (docData['experience'] != null && docData['experience'].toString().trim().isNotEmpty) {
                experience = docData['experience'].toString().trim();
              }
              if (docData['contact'] != null && docData['contact'].toString().trim().isNotEmpty) {
                contact = docData['contact'].toString().trim();
              }
              if (docData['status'] != null && docData['status'].toString().trim().isNotEmpty) {
                status = docData['status'].toString().trim();
              }
            });
            return;
          }
        }

        // Fallback
        final response3 = await http.post(
          Uri.parse(api.ip + '/get_user_details'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({"Email_ID": widget.email}),
        ).timeout(const Duration(seconds: 4));

        if (response3.statusCode == 200) {
          Map<String, dynamic> detailsData = json.decode(response3.body);
          if (mounted && detailsData['Name'] != null && detailsData['Name'].toString().isNotEmpty) {
            setState(() {
              name = detailsData['Name'].toString().trim();
            });
          }
        }
      }
    } catch (e) {
      // Graceful fallback
    }
  }

  Future<void> fetchImageWithRetry() async {
    if (widget.email.isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse(api.ip + '/fetch_image'),
        headers: {
          'content-type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({"Email_ID": widget.email}),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        Map<String, dynamic> imageData = json.decode(response.body);
        if (mounted) {
          setState(() {
            base64Image = imageData["base64_image"]?.toString();
          });
        }
      }
    } catch (_) {
      // Fallback
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: AppColors.negativeRed, size: 24),
              SizedBox(width: 10),
              Text('Doctor Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: const Text(
            'Are you sure you want to end your active clinician session? You will be returned to the sign in portal.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.negativeRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await http.post(
                    Uri.parse(api.ip + '/log_activity'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'email': widget.email, "type": "s"}),
                  ).timeout(const Duration(seconds: 2));
                } catch (_) {}

                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthPage()),
                  (route) => false,
                );
              },
              child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _editPracticeDetails() {
    final clinicController = TextEditingController(text: clinicName);
    final specialtyController = TextEditingController(text: specialty);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Practice Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Clinic / Hospital Affiliation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: clinicController,
                decoration: AppStyles.inputDecoration(hintText: 'Enter clinic name'),
              ),
              const SizedBox(height: 14),
              const Text('Clinical Specialization', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: specialtyController,
                decoration: AppStyles.inputDecoration(hintText: 'Enter specialization'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.doctorPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() {
                clinicName = clinicController.text.trim();
                specialty = specialtyController.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDoctorStatus() async {
    final nextStatus = status.toLowerCase() == 'active' ? 'Inactive' : 'Active';
    setState(() {
      status = nextStatus;
    });

    try {
      await http.post(
        Uri.parse(api.update_doctor_profile),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Email_ID': widget.email,
          'status': nextStatus,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Doctor status updated to: $nextStatus'),
          backgroundColor: nextStatus == 'Active' ? AppColors.positiveGreen : const Color(0xFFE11D48),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _editDoctorProfile() {
    final nameCtrl = TextEditingController(text: name);
    final ageCtrl = TextEditingController(text: age);
    final expCtrl = TextEditingController(text: experience);
    final contactCtrl = TextEditingController(text: contact);
    String selectedGender = ['Male', 'Female', 'Other'].contains(gender) ? gender : 'Male';
    String selectedStatus = status.toLowerCase() == 'inactive' ? 'Inactive' : 'Active';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.doctorPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.manage_accounts_rounded, color: AppColors.doctorPrimary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Doctor Profile',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text(
                                'Update clinical credentials & active status',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Doctor Name
                    const Text('Doctor Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: AppStyles.inputDecoration(
                        hintText: 'e.g. Dr. Dinesh',
                        prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.doctorPrimary, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Age & Gender in side-by-side balanced columns
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Age', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: ageCtrl,
                                keyboardType: TextInputType.number,
                                decoration: AppStyles.inputDecoration(
                                  hintText: 'e.g. 38',
                                  prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.doctorPrimary, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Gender', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: selectedGender,
                                decoration: AppStyles.inputDecoration(
                                  prefixIcon: const Icon(Icons.wc_rounded, color: AppColors.doctorPrimary, size: 20),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Male', child: Text('Male', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'Female', child: Text('Female', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'Other', child: Text('Other', overflow: TextOverflow.ellipsis)),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() => selectedGender = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Clinical Experience
                    const Text('Clinical Experience', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: expCtrl,
                      decoration: AppStyles.inputDecoration(
                        hintText: 'e.g. 10 Years',
                        prefixIcon: const Icon(Icons.workspace_premium_outlined, color: AppColors.doctorPrimary, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Contact Number
                    const Text('Contact Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: contactCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: AppStyles.inputDecoration(
                        hintText: 'e.g. +91 98765 43210',
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.doctorPrimary, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Current Status Selector
                    const Text('Current Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => selectedStatus = 'Active'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedStatus == 'Active' ? AppColors.positiveGreen : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: selectedStatus == 'Active'
                                      ? [
                                          BoxShadow(
                                            color: AppColors.positiveGreen.withValues(alpha: 0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: selectedStatus == 'Active' ? Colors.white : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Active',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: selectedStatus == 'Active' ? Colors.white : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => selectedStatus = 'Inactive'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedStatus == 'Inactive' ? const Color(0xFFE11D48) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: selectedStatus == 'Inactive'
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFE11D48).withValues(alpha: 0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.pause_circle_filled_rounded,
                                      size: 16,
                                      color: selectedStatus == 'Inactive' ? Colors.white : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Inactive',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: selectedStatus == 'Inactive' ? Colors.white : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.doctorPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final updatedName = nameCtrl.text.trim();
                                final updatedAge = ageCtrl.text.trim();
                                final updatedExp = expCtrl.text.trim();
                                final updatedContact = contactCtrl.text.trim();

                                if (updatedName.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Doctor name cannot be empty'),
                                      backgroundColor: AppColors.negativeRed,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isSaving = true);

                                try {
                                  await http.post(
                                    Uri.parse(api.update_doctor_profile),
                                    headers: {'Content-Type': 'application/json'},
                                    body: jsonEncode({
                                      'Email_ID': widget.email,
                                      'name': updatedName,
                                      'age': updatedAge,
                                      'gender': selectedGender,
                                      'experience': updatedExp,
                                      'contact': updatedContact,
                                      'status': selectedStatus,
                                    }),
                                  ).timeout(const Duration(seconds: 5));
                                } catch (_) {}

                                if (mounted) {
                                  setState(() {
                                    name = updatedName;
                                    if (updatedAge.isNotEmpty) age = updatedAge;
                                    gender = selectedGender;
                                    if (updatedExp.isNotEmpty) experience = updatedExp;
                                    if (updatedContact.isNotEmpty) contact = updatedContact;
                                    status = selectedStatus;
                                  });
                                }

                                if (modalContext.mounted) {
                                  Navigator.pop(modalContext);
                                }

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text('Doctor profile updated successfully'),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: AppColors.positiveGreen,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                              )
                            : const Text('Save Profile Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _markAllAlertsAsRead() {
    setState(() {
      for (var alert in _clinicalAlerts) {
        alert['isRead'] = true;
      }
    });
  }

  void _dismissAlert(int index) {
    setState(() {
      _clinicalAlerts.removeAt(index);
    });
  }

  int get _unreadCount => _clinicalAlerts.where((a) => a['isRead'] == false).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.doctorBackground,
      body: RefreshIndicator(
        onRefresh: initializeData,
        color: AppColors.doctorPrimary,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // Doctor Header with Wave Clipper
            ClipPath(
              clipper: WaveClipperOne(),
              child: Container(
                padding: const EdgeInsets.only(top: 52, bottom: 42),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.doctorPrimary,
                      Color(0xFF2B5383),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          backgroundImage: getSafeImageProvider(base64Image),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name.isNotEmpty ? (name.startsWith('Dr.') ? name : 'Dr. $name') : 'Clinical Administrator',
                        style: const TextStyle(
                          fontSize: 21,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              specialty.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Live Status badge (tap to toggle)
                          GestureDetector(
                            onTap: _toggleDoctorStatus,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (status.toLowerCase() == 'active' ? AppColors.positiveGreen : const Color(0xFFF59E0B)).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: status.toLowerCase() == 'active' ? AppColors.positiveGreen : const Color(0xFFF59E0B),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: status.toLowerCase() == 'active' ? AppColors.positiveGreen : const Color(0xFFF59E0B),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    status.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _editDoctorProfile,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_note_rounded, size: 15, color: Colors.white),
                              SizedBox(width: 5),
                              Text(
                                'Edit Profile',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Analytics Section Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Cohort Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded, size: 14, color: AppColors.doctorSecondary),
                      SizedBox(width: 4),
                      Text(
                        'Live Statistics',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.doctorSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2x2 Analytics Grid with Modern Aspect Ratio
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12.0,
                crossAxisSpacing: 12.0,
                childAspectRatio: 1.10,
                children: [
                  _buildStatCard(
                    title: count,
                    icon: Icons.people_outline_rounded,
                    heading: 'Total Patients',
                    subtitle: 'Active cohort',
                    color: AppColors.doctorPrimary,
                  ),
                  _buildStatCard(
                    title: sMild,
                    icon: Icons.sentiment_satisfied_alt_rounded,
                    heading: 'Mild & Moderate',
                    subtitle: 'Standard CBT',
                    color: AppColors.mildAnger,
                  ),
                  _buildStatCard(
                    title: severe,
                    icon: Icons.warning_amber_rounded,
                    heading: 'Severe Tier',
                    subtitle: 'Attention required',
                    color: AppColors.severeAnger,
                  ),
                  _buildStatCard(
                    title: critical,
                    icon: Icons.local_hospital_outlined,
                    heading: 'Critical Triage',
                    subtitle: 'Immediate review',
                    color: AppColors.criticalAnger,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // -------------------------------------------------------------
            // SECTION 1: CLINICAL NOTIFICATIONS & TRIAGE FEED (FUNCTIONAL)
            // -------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, size: 19, color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      const Text(
                        'Live Clinical Alerts',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_unreadCount > 0 && _triageAlerts) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.negativeRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_unreadCount new',
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_unreadCount > 0 && _triageAlerts)
                    GestureDetector(
                      onTap: _markAllAlertsAsRead,
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.doctorPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Live Alert Cards Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Container(
                decoration: AppStyles.cardDecoration(
                  backgroundColor: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _triageAlerts
                    ? (_clinicalAlerts.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, size: 36, color: AppColors.positiveGreen),
                                  SizedBox(height: 8),
                                  Text(
                                    'All clinical triage alerts resolved',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: List.generate(_clinicalAlerts.length, (index) {
                              final alert = _clinicalAlerts[index];
                              final isCritical = alert['priority'] == 'critical';
                              final isUnread = alert['isRead'] == false;

                              return Column(
                                children: [
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: (isCritical ? AppColors.negativeRed : AppColors.doctorPrimary).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isCritical ? Icons.emergency_rounded : Icons.notification_important_rounded,
                                        size: 20,
                                        color: isCritical ? AppColors.negativeRed : AppColors.doctorPrimary,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            alert['title']!,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          alert['time']!,
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        alert['desc']!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                                      tooltip: 'Dismiss',
                                      onPressed: () => _dismissAlert(index),
                                    ),
                                  ),
                                  if (index < _clinicalAlerts.length - 1)
                                    const Divider(height: 1, indent: 64),
                                ],
                              );
                            }),
                          ))
                    : Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF94A3B8).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_off_outlined, size: 20, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                'Triage alerts are currently muted. Turn on the switch below to resume real-time patient notifications.',
                                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 14),

            // -------------------------------------------------------------
            // SECTION 2: NOTIFICATION PREFERENCES (NO SNACKBAR POPUPS)
            // -------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: Row(
                children: const [
                  Icon(Icons.tune_rounded, size: 18, color: AppColors.textPrimary),
                  SizedBox(width: 8),
                  Text(
                    'Workstation Alert Preferences',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Container(
                decoration: AppStyles.cardDecoration(
                  backgroundColor: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // High Anger Triage Switch
                    SwitchListTile(
                      value: _triageAlerts,
                      onChanged: (val) {
                        setState(() {
                          _triageAlerts = val;
                        });
                      },
                      activeTrackColor: AppColors.doctorPrimary,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.doctorPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.emergency_outlined, size: 20, color: AppColors.doctorPrimary),
                      ),
                      title: Row(
                        children: [
                          const Flexible(
                            child: Text('Real-Time Triage Alerts', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _triageAlerts
                                  ? AppColors.positiveGreen.withValues(alpha: 0.12)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _triageAlerts ? 'Active' : 'Muted',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _triageAlerts ? AppColors.positiveGreen : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: const Text('Audible push flags for critical score entries', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ),
                    const Divider(height: 1, indent: 60),

                    // Daily Cohort Summary Digest
                    SwitchListTile(
                      value: _dailyDigest,
                      onChanged: (val) {
                        setState(() {
                          _dailyDigest = val;
                        });
                      },
                      activeTrackColor: AppColors.doctorPrimary,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.doctorSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.mark_email_read_outlined, size: 20, color: AppColors.doctorSecondary),
                      ),
                      title: Row(
                        children: [
                          const Flexible(
                            child: Text('Daily Cohort Digest', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _dailyDigest
                                  ? AppColors.doctorSecondary.withValues(alpha: 0.12)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _dailyDigest ? _digestTime : 'Off',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _dailyDigest ? AppColors.doctorSecondary : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: const Text('Automated end-of-day patient therapy summary', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // -------------------------------------------------------------
            // SECTION 3: DOCTOR CLINICAL PROFILE & STATUS
            // -------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.badge_rounded, size: 19, color: AppColors.textPrimary),
                      SizedBox(width: 8),
                      Text(
                        'Doctor Profile',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _editDoctorProfile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.doctorPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 13, color: AppColors.doctorPrimary),
                          SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.doctorPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: AppStyles.cardDecoration(
                  backgroundColor: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Doctor name + Status switch / badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.startsWith('Dr.') ? name : 'Dr. $name',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.email,
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Status badge (clickable to toggle)
                        InkWell(
                          onTap: _toggleDoctorStatus,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: status.toLowerCase() == 'active'
                                  ? AppColors.positiveGreen.withValues(alpha: 0.12)
                                  : const Color(0xFFE11D48).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: status.toLowerCase() == 'active'
                                    ? AppColors.positiveGreen.withValues(alpha: 0.5)
                                    : const Color(0xFFE11D48).withValues(alpha: 0.5),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: status.toLowerCase() == 'active'
                                        ? AppColors.positiveGreen
                                        : const Color(0xFFE11D48),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: status.toLowerCase() == 'active'
                                        ? AppColors.positiveGreen
                                        : const Color(0xFFE11D48),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // Grid of Age, Gender, Experience, Contact
                    Row(
                      children: [
                        Expanded(
                          child: _buildProfileInfoTile(
                            icon: Icons.calendar_today_rounded,
                            label: 'Age',
                            value: '$age Years',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildProfileInfoTile(
                            icon: Icons.wc_rounded,
                            label: 'Gender',
                            value: gender,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildProfileInfoTile(
                            icon: Icons.workspace_premium_rounded,
                            label: 'Experience',
                            value: experience,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildProfileInfoTile(
                            icon: Icons.phone_rounded,
                            label: 'Contact',
                            value: contact,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // Quick Action Edit button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.doctorPrimary, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: _editDoctorProfile,
                        icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.doctorPrimary),
                        label: const Text(
                          'Edit Profile Details',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.doctorPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // -------------------------------------------------------------
            // SECTION 4: PRACTICE PROFILE & WORKSTATION INFO
            // -------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.local_hospital_rounded, size: 18, color: AppColors.textPrimary),
                      SizedBox(width: 8),
                      Text(
                        'Practice Affiliation',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _editPracticeDetails,
                    child: const Text(
                      'Edit',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.doctorPrimary),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: AppStyles.cardDecoration(
                  backgroundColor: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.doctorPrimary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.domain_rounded, color: AppColors.doctorPrimary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(clinicName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text(specialty, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Clinical Hours:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Flexible(
                          child: Text(
                            'Mon - Fri, 09:00 AM - 05:00 PM',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // -------------------------------------------------------------
            // SECTION 4: RED LOGOUT WORKSTATION BUTTON
            // -------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Container(
                decoration: AppStyles.cardDecoration(
                  backgroundColor: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.negativeRed.withValues(alpha: 0.25)),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.negativeRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.logout_rounded, size: 20, color: AppColors.negativeRed),
                  ),
                  title: const Text(
                    'Sign Out Workstation',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.negativeRed,
                    ),
                  ),
                  subtitle: const Text(
                    'Safely end current doctor session',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.exit_to_app_rounded, color: AppColors.negativeRed, size: 20),
                  onTap: _handleLogout,
                ),
              ),
            ),

            const SizedBox(height: 34),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required String heading,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 9.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20.0, color: color),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 26.0,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                heading,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 1.0),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.doctorPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.doctorPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
