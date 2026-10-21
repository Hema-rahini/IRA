import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ira/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../urls.dart';
import '../utilsn.dart';
import 'DoctorConsultationPage.dart';
import 'InsightsPage.dart';
import 'PatientNotificationsPage.dart';
import 'TodayActivity.dart';
import 'TrackActivity.dart';
import 'games/gamescreen.dart';
import 'settings.dart';

class PHomePage extends StatefulWidget {
  final String email;
  const PHomePage({Key? key, required this.email}) : super(key: key);

  @override
  State<PHomePage> createState() => _PHomePageState();
}

class _PHomePageState extends State<PHomePage> {
  String? base64Image;
  String userName = '';
  int _selectedMoodIndex = -1;
  String doctorStatus = 'Active';
  String doctorName = 'Dr. Dinesh';

  final List<Map<String, dynamic>> _quickMoods = [
    {'label': 'Calm', 'emoji': '🌿', 'color': Color(0xFF14B8A6)},
    {'label': 'Happy', 'emoji': '✨', 'color': Color(0xFF10B981)},
    {'label': 'Reflective', 'emoji': '🌊', 'color': Color(0xFF3B82F6)},
    {'label': 'Tense', 'emoji': '⚡', 'color': Color(0xFFF59E0B)},
    {'label': 'Overwhelmed', 'emoji': '🌧️', 'color': Color(0xFF8B5CF6)},
  ];

  @override
  void initState() {
    super.initState();
    _deriveUserName();
    fetchProfileImageWithRetry();
    fetchUserData();
    fetchDoctorStatus();
  }

  Future<void> fetchDoctorStatus() async {
    try {
      final response = await http.post(
        Uri.parse(api.get_doctor_details),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            if (data['status'] != null && data['status'].toString().trim().isNotEmpty) {
              doctorStatus = data['status'].toString().trim();
            }
            if (data['name'] != null && data['name'].toString().trim().isNotEmpty) {
              doctorName = data['name'].toString().trim();
            }
          });
        }
      }
    } catch (_) {}
  }

  void _deriveUserName() {
    if (widget.email.isNotEmpty) {
      final prefix = widget.email.split('@')[0];
      // Capitalize first letter
      userName = prefix.isNotEmpty
          ? prefix[0].toUpperCase() + prefix.substring(1)
          : 'Friend';
    } else {
      userName = 'Friend';
    }
  }

  Future<void> fetchUserData() async {
    try {
      final response = await http.post(
        Uri.parse(api.ip + '/get_user_details'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"Email_ID": widget.email}),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Name'] != null && data['Name'].toString().trim().isNotEmpty) {
          if (mounted) {
            setState(() {
              userName = data['Name'].toString().trim();
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> fetchProfileImageWithRetry() async {
    int maxRetries = 3;

    while (maxRetries > 0) {
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
          break;
        } else if (response.statusCode == 404) {
          break;
        }
      } catch (e) {
        maxRetries--;
        if (maxRetries > 0) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await fetchProfileImageWithRetry();
            await fetchUserData();
          },
          color: AppColors.patientPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Custom Header
                _buildModernHeader(),

                const SizedBox(height: 20.0),

                // Hero Mindfulness Welcome Banner
                _buildHeroBanner(),

                const SizedBox(height: 24.0),

                // Quick Emotional Pulse Check-in
                _buildMoodPulseSection(),

                const SizedBox(height: 28.0),

                // Core Therapy Modules Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Therapy & Care Modules',
                          style: TextStyle(
                            fontSize: 19.0,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Evidence-based cognitive healing roadmap',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.patientPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 13, color: AppColors.patientPrimary),
                          SizedBox(width: 4),
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.patientPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16.0),

                // Bento Grid Cards
                _buildTherapyBentoGrid(),

                const SizedBox(height: 24.0),

                // Practice Affiliation Card (IRA Behavioral & Mind Wellness Clinic)
                _buildPracticeAffiliationCard(),

                const SizedBox(height: 20.0),

                // Daily Mindfulness Affirmation Card
                _buildAffirmationCard(),

                const SizedBox(height: 20.0),

                // Clinical Consult Referral Banner
                _buildClinicalSupportBanner(),

                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Top App Header ---
  Widget _buildModernHeader() {
    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E525B), Color(0xFF2A7B88)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.patientPrimary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getTimeGreeting()}, $userName',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'IRA Wellness',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // Notification Bell with unread dot
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 21),
                      padding: EdgeInsets.zero,
                      tooltip: 'Notifications & Alerts',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientNotificationsPage(email: widget.email),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      top: 10,
                      right: 11,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.patientWarmAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Profile Avatar
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileSettingsPage(
                        email: widget.email,
                        img: base64Image ?? '',
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.patientPrimary, AppColors.patientSecondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.patientPrimary.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: getSafeImageProvider(base64Image),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Hero Banner with Organic Gradient & Glassmorphism ---
  Widget _buildHeroBanner() {
    return FadeInUp(
      duration: const Duration(milliseconds: 550),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF163E45),
              Color(0xFF1E525B),
              Color(0xFF286A77),
              Color(0xFF3B8A7A),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF163E45).withValues(alpha: 0.32),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              // Ambient Decorative Rings in background
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),

              // Banner Content
              Padding(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                              Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                              SizedBox(width: 5),
                              Text(
                                'DAILY CALM & HEALING',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Day 1 / 13',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Welcome to your Safe Space',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Breathe deeply. Complete today’s mindful video session to reduce tension and recalibrate your thoughts.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Call to Action Pill Button
                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrackActivity(email: widget.email),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.play_circle_fill_rounded,
                          size: 20,
                          color: Color(0xFF163E45),
                        ),
                        label: const Text(
                          'Resume Daily Therapy',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF163E45),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Quick Mood Check-In Row ---
  Widget _buildMoodPulseSection() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'How are you feeling right now?',
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Tap to log',
                style: TextStyle(
                  fontSize: 12.0,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickMoods.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final mood = _quickMoods[index];
                final isSelected = _selectedMoodIndex == index;
                final Color moodColor = mood['color'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMoodIndex = index;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Text(mood['emoji'], style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Mood logged: ${mood['label']}. Take a moment to reflect.',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.patientPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? moodColor.withValues(alpha: 0.15) : Colors.white,
                      borderRadius: BorderRadius.circular(23),
                      border: Border.all(
                        color: isSelected ? moodColor : AppColors.borderSubtle,
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(mood['emoji'], style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 6),
                        Text(
                          mood['label'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? moodColor : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Bento Grid Therapy Modules ---
  Widget _buildTherapyBentoGrid() {
    return Column(
      children: [
        // 1. Featured Big Bento Card: 13-Day Cognitive Therapy Program
        FadeInUp(
          duration: const Duration(milliseconds: 500),
          delay: const Duration(milliseconds: 200),
          child: _buildBentoCard(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrackActivity(email: widget.email),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2A7B88), Color(0xFF1E525B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.patientPrimary.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.self_improvement_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '13-Day Therapy Program',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppColors.patientPrimary.withValues(alpha: 0.8),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Structured daily video modules & therapist-led mindful anger reduction exercises.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress Bar Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'Current Milestone: Day 1',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.patientPrimary,
                                  ),
                                ),
                                Text(
                                  '26 Total Sessions',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: 0.15,
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.patientPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 2. Split 2-Column Bento Row: Checklist + Relaxation Games
        Row(
          children: [
            // Left: Progress Checklist
            Expanded(
              child: FadeInUp(
                duration: const Duration(milliseconds: 500),
                delay: const Duration(milliseconds: 250),
                child: _buildBentoCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TodaysActivity(email: widget.email),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.patientSecondary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.checklist_rtl_rounded,
                          color: AppColors.patientSecondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Progress Checklist',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Track all 26 completed daily steps.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          Text(
                            'Review',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.patientSecondary,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.patientSecondary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Right: Relaxation & Games
            Expanded(
              child: FadeInUp(
                duration: const Duration(milliseconds: 500),
                delay: const Duration(milliseconds: 300),
                child: _buildBentoCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameScreenHome(email: widget.email),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.patientWarmAccent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.palette_outlined,
                          color: AppColors.patientWarmAccent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Art & Games',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Zen art canvas & touch de-escalation.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          Text(
                            'De-stress',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.patientWarmAccent,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.patientWarmAccent),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // 3. Wide Bento Card: Emotional Insights
        FadeInUp(
          duration: const Duration(milliseconds: 500),
          delay: const Duration(milliseconds: 350),
          child: _buildBentoCard(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Insights(email: widget.email),
                ),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.patientAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_graph_rounded,
                    color: AppColors.patientAccent,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Emotional Insights & Trends',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Mood history, sentiment curves & anger scale score comparisons.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.patientAccent.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Base Bento Card wrapper
  Widget _buildBentoCard({required Widget child, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EEF0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163E45).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: child,
          ),
        ),
      ),
    );
  }

  // --- Daily Mindfulness Affirmation Card ---
  Widget _buildAffirmationCard() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: const Duration(milliseconds: 400),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7EE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEFE8D6)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFFD97706),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Daily Reflection',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB45309),
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '“You cannot stop the waves, but you can learn to surf. Take three deep breaths whenever tension arises.”',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF78350F),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Clinician Support / Helpline Card ---
  Widget _buildClinicalSupportBanner() {
    final bool isDocActive = doctorStatus.toLowerCase() == 'active';

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: const Duration(milliseconds: 450),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isDocActive ? AppColors.positiveGreen : const Color(0xFFF59E0B)).withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: (isDocActive ? AppColors.positiveGreen : const Color(0xFFF59E0B)).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDocActive ? AppColors.positiveGreen : const Color(0xFFF59E0B)).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.support_agent_rounded,
                color: isDocActive ? AppColors.positiveGreen : const Color(0xFFD97706),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'Need Clinical Guidance?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isDocActive ? AppColors.positiveGreen : const Color(0xFFEF4444)).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isDocActive ? AppColors.positiveGreen : const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isDocActive ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isDocActive ? AppColors.positiveGreen : const Color(0xFFDC2626),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDocActive
                        ? '$doctorName is online & accepting calls.'
                        : '$doctorName is off-duty. Crisis support available.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorConsultationPage(),
                  ),
                ).then((_) => fetchDoctorStatus());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDocActive ? AppColors.patientPrimary : const Color(0xFFD97706),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(isDocActive ? 'Consult' : 'Contact', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Practice Affiliation Card (IRA Behavioral & Mind Wellness Clinic) ---
  Widget _buildPracticeAffiliationCard() {
    final bool isDocActive = doctorStatus.toLowerCase() == 'active';

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.local_hospital_rounded, size: 18, color: AppColors.textPrimary),
                  SizedBox(width: 8),
                  Text(
                    'Practice Affiliation',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DoctorConsultationPage(),
                    ),
                  ).then((_) => fetchDoctorStatus());
                },
                child: const Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.patientPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DoctorConsultationPage(),
                ),
              ).then((_) => fetchDoctorStatus());
            },
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
                          color: AppColors.patientPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.domain_rounded,
                          color: AppColors.patientPrimary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'IRA Behavioral & Mind Wellness Clinic',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isDocActive ? AppColors.positiveGreen : const Color(0xFFEF4444)).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isDocActive ? '● Active' : '● Inactive',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDocActive ? AppColors.positiveGreen : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$doctorName • Consultant Clinical Psychiatrist',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
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
                      Text(
                        'Clinical Hours:',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Flexible(
                        child: Text(
                          'Mon - Fri, 09:00 AM - 05:00 PM',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

