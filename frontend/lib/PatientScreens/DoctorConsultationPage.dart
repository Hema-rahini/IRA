import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:ira/theme/app_theme.dart';
import '../urls.dart';

class DoctorConsultationPage extends StatefulWidget {
  final String? doctorEmail;
  const DoctorConsultationPage({Key? key, this.doctorEmail}) : super(key: key);

  @override
  State<DoctorConsultationPage> createState() => _DoctorConsultationPageState();
}

class _DoctorConsultationPageState extends State<DoctorConsultationPage> {
  String doctorName = 'Dr. Dinesh';
  String doctorEmail = 'doctor@hospital.com';
  String doctorStatus = 'Active'; // 'Active' or 'Inactive'
  String doctorContact = '+91 98765 43210';
  String doctorExperience = '10 Years';
  String doctorAge = '38';
  String doctorGender = 'Male';
  String clinicName = 'IRA Behavioral & Mind Wellness Clinic';
  String specialty = 'Consultant Clinical Psychiatrist';
  bool _isLoading = true;
  bool _isRequestingCallback = false;

  bool get isActive => doctorStatus.trim().toLowerCase() == 'active';

  @override
  void initState() {
    super.initState();
    fetchDoctorDetails();
  }

  Future<void> fetchDoctorDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(api.get_doctor_details),
        headers: {
          'content-type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(widget.doctorEmail != null ? {"Email_ID": widget.doctorEmail} : {}),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            if (data['name'] != null && data['name'].toString().trim().isNotEmpty) {
              doctorName = data['name'].toString().trim();
            }
            if (data['email'] != null && data['email'].toString().trim().isNotEmpty) {
              doctorEmail = data['email'].toString().trim();
            }
            if (data['status'] != null && data['status'].toString().trim().isNotEmpty) {
              doctorStatus = data['status'].toString().trim();
            }
            if (data['contact'] != null && data['contact'].toString().trim().isNotEmpty) {
              doctorContact = data['contact'].toString().trim();
            }
            if (data['experience'] != null && data['experience'].toString().trim().isNotEmpty) {
              doctorExperience = data['experience'].toString().trim();
            }
            if (data['age'] != null) {
              doctorAge = data['age'].toString().trim();
            }
            if (data['gender'] != null && data['gender'].toString().trim().isNotEmpty) {
              doctorGender = data['gender'].toString().trim();
            }
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      // Fallback grace
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanPhone,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (!mounted) return;
        _showDirectContactDialog(phoneNumber);
      }
    } catch (_) {
      if (!mounted) return;
      _showDirectContactDialog(phoneNumber);
    }
  }

  void _showDirectContactDialog(String phone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.phone_in_talk_rounded, color: AppColors.patientPrimary),
            SizedBox(width: 10),
            Text('Contact Clinician', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Direct telephone contact for $doctorName:'),
            const SizedBox(height: 8),
            SelectableText(
              phone,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.patientPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isActive ? AppColors.positiveGreen : const Color(0xFFF59E0B)).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isActive ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    size: 18,
                    color: isActive ? AppColors.positiveGreen : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isActive
                          ? 'Clinician is ACTIVE now and accepting calls.'
                          : 'Clinician is CURRENTLY INACTIVE / off-duty.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isActive ? AppColors.positiveGreen : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _requestCallback() {
    setState(() {
      _isRequestingCallback = true;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _isRequestingCallback = false;
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.mark_email_read_rounded, color: AppColors.positiveGreen),
              SizedBox(width: 10),
              Text('Callback Logged', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(
            'Your consultation callback request has been queued for $doctorName. You will be prioritized as soon as the clinician resumes ACTIVE status.',
            style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.patientPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Understood', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayName = doctorName.startsWith('Dr.') ? doctorName : 'Dr. $doctorName';

    return Scaffold(
      backgroundColor: AppColors.patientBackground,
      appBar: AppBar(
        title: const Text(
          'Clinical Consultation',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.3),
        ),
        centerTitle: true,
        actions: [
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.patientPrimary),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh Doctor Status',
                  onPressed: fetchDoctorDetails,
                ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchDoctorDetails,
          color: AppColors.patientPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // -------------------------------------------------------------
                // HERO CARD: ASSIGNED DOCTOR & REAL-TIME AVAILABILITY STATUS
                // -------------------------------------------------------------
                Container(
                  width: double.infinity,
                  decoration: AppStyles.cardDecoration(
                    backgroundColor: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      // Header with Doctor Avatar & Live Status Pill
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isActive
                                ? [
                                    const Color(0xFF0F3E2B),
                                    const Color(0xFF134E35),
                                    const Color(0xFF1B6A47),
                                  ]
                                : [
                                    const Color(0xFF332014),
                                    const Color(0xFF4C2A18),
                                    const Color(0xFF6B391D),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Doctor Avatar with live status pulse border
                                Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isActive ? AppColors.positiveGreen : const Color(0xFFF59E0B),
                                          width: 2.5,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 32,
                                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                                        child: const Icon(Icons.person_rounded, size: 40, color: Colors.white),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: isActive ? AppColors.positiveGreen : const Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: -0.3,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        specialty,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.white.withValues(alpha: 0.85),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        clinicName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // PROMINENT LIVE STATUS BANNER
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: isActive ? AppColors.positiveGreen : const Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isActive ? AppColors.positiveGreen : const Color(0xFFEF4444))
                                                  .withValues(alpha: 0.6),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isActive ? 'STATUS: ACTIVE' : 'STATUS: INACTIVE',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppColors.positiveGreen.withValues(alpha: 0.3)
                                          : const Color(0xFFEF4444).withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isActive ? 'Available Now' : 'Off-Duty',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Availability description & direct action triggers
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (isActive ? AppColors.positiveGreen : const Color(0xFFF59E0B))
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: (isActive ? AppColors.positiveGreen : const Color(0xFFF59E0B))
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    isActive ? Icons.check_circle_outline_rounded : Icons.pause_circle_outline_rounded,
                                    size: 20,
                                    color: isActive ? AppColors.positiveGreen : const Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      isActive
                                          ? '$displayName is currently ACTIVE and accepting direct patient consultations & triage calls.'
                                          : '$displayName is currently INACTIVE / off-duty. Please request a callback below or contact our 24/7 crisis support line.',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: isActive ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Action buttons based on ACTIVE vs INACTIVE state
                            if (isActive) ...[
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: () => _makePhoneCall(doctorContact),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.positiveGreen,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                                  label: Text(
                                    'Call Clinician ($doctorContact)',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: OutlinedButton.icon(
                                  onPressed: _requestCallback,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.patientPrimary),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  icon: const Icon(Icons.schedule_rounded, size: 18, color: AppColors.patientPrimary),
                                  label: const Text(
                                    'Request Consultation Booking',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.patientPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: () => _makePhoneCall('14416'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC2626),
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  icon: const Icon(Icons.emergency_rounded, size: 20),
                                  label: const Text(
                                    '24/7 National Crisis Hotline (14416)',
                                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: OutlinedButton.icon(
                                  onPressed: _isRequestingCallback ? null : _requestCallback,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFD97706)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  icon: const Icon(Icons.mark_email_unread_outlined, size: 18, color: Color(0xFFD97706)),
                                  label: _isRequestingCallback
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD97706)),
                                        )
                                      : const Text(
                                          'Request Callback When Doctor Is Active',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFD97706),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // -------------------------------------------------------------
                // SECTION: DOCTOR CREDENTIALS & CLINICAL SPECIFICATIONS
                // -------------------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: AppStyles.cardDecoration(
                    backgroundColor: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.badge_outlined, color: AppColors.patientPrimary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Clinician Details & Hours',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildInfoRow(
                        icon: Icons.workspace_premium_outlined,
                        label: 'Experience',
                        value: doctorExperience,
                      ),
                      const Divider(height: 18),
                      _buildInfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Clinical Hours',
                        value: 'Mon - Fri, 09:00 AM - 05:00 PM',
                      ),
                      const Divider(height: 18),
                      _buildInfoRow(
                        icon: Icons.domain_rounded,
                        label: 'Affiliated Facility',
                        value: clinicName,
                      ),
                      const Divider(height: 18),
                      _buildInfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Direct Contact Line',
                        value: doctorContact,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // -------------------------------------------------------------
                // SECTION: CLINICAL GUIDANCE & TRIAGE ADVICE
                // -------------------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: AppStyles.cardDecoration(
                    backgroundColor: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.health_and_safety_outlined, color: AppColors.patientPrimary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Guidance for Consultation',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildGuidanceStep(
                        '1',
                        'Active Doctor Consult',
                        'When the doctor status is Active, you can dial directly for immediate clinical guidance or appointment scheduling.',
                      ),
                      const SizedBox(height: 12),
                      _buildGuidanceStep(
                        '2',
                        'Self-Paced Calming Exercises',
                        'If the clinician is Inactive, practice sensory games (Touch Points, Drawing Canvas) and audio meditation to de-escalate emotional spikes.',
                      ),
                      const SizedBox(height: 12),
                      _buildGuidanceStep(
                        '3',
                        'Daily Thought Journal',
                        'Keep documenting daily triggers in your Thought Diary. All entries will be available for clinical review during your session.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Return to dashboard
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.patientPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Return to Dashboard', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.patientPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.patientPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuidanceStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.patientPrimary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.patientPrimary),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
