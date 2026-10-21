import 'package:flutter/material.dart';
import 'package:ira/theme/app_theme.dart';
import '../Authpage/DoctorLogin.dart';
import '../Authpage/PatientLoginpage.dart';
import '../Authpage/PatientSignUp.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _selectedRole = 0; // 0 = Patient, 1 = Doctor

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onRoleChanged(int index) {
    if (_selectedRole == index) return;
    setState(() {
      _selectedRole = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDoctor = _selectedRole == 1;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDoctor
                ? const [
                    Color(0xFF0F2038),
                    Color(0xFF1E3A5F),
                    Color(0xFF174266),
                  ]
                : const [
                    Color(0xFF1E525B),
                    Color(0xFF2A7B88),
                    Color(0xFF458575),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Header Brand Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.spa_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'IRA HEALTH',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Segmented Role Switcher Pill Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(27),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Animated Sliding Pill
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        alignment: isDoctor
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: 0.5,
                          child: Container(
                            height: 44,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Clickable Tab Buttons
                      Row(
                        children: [
                          // Patient Tab
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(27),
                                onTap: () => _onRoleChanged(0),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_rounded,
                                        size: 19,
                                        color: !isDoctor
                                            ? AppColors.patientPrimary
                                            : Colors.white.withValues(alpha: 0.75),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Patient',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: !isDoctor
                                              ? AppColors.patientPrimary
                                              : Colors.white.withValues(alpha: 0.75),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Doctor Tab
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(27),
                                onTap: () => _onRoleChanged(1),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.medical_services_rounded,
                                        size: 18,
                                        color: isDoctor
                                            ? AppColors.doctorPrimary
                                            : Colors.white.withValues(alpha: 0.75),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Doctor',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isDoctor
                                              ? AppColors.doctorPrimary
                                              : Colors.white.withValues(alpha: 0.75),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Animated Hero Avatar / Illustration
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ambient Glow
                    Container(
                      width: 106,
                      height: 106,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isDoctor
                                    ? AppColors.doctorSecondary
                                    : AppColors.patientWarmAccent)
                                .withValues(alpha: 0.35),
                            blurRadius: 28,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    // White circular frame
                    Container(
                      width: 96,
                      height: 96,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          "assets/drpat.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Role Badge Chip
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDoctor ? AppColors.doctorPrimary : AppColors.patientPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          isDoctor ? Icons.medical_services_rounded : Icons.favorite_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // PageView Content Area (Full screen swipeable cards)
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedRole = index;
                    });
                  },
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Page 0: Patient View
                    _buildPatientView(context, size),

                    // Page 1: Doctor View
                    _buildDoctorView(context, size),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Patient View Builder ---
  Widget _buildPatientView(BuildContext context, Size size) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Category Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.patientPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.spa_rounded, size: 14, color: AppColors.patientPrimary),
                  SizedBox(width: 6),
                  Text(
                    'EMOTIONAL SUPPORT & CARE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.patientPrimary,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'Patient Portal',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Take clinical anger assessments, track your daily moods & complete guided therapy exercises.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            // Feature Highlights
            _buildFeatureTile(
              icon: Icons.assignment_turned_in_rounded,
              color: AppColors.patientPrimary,
              title: 'Clinical Anger Scale Test',
              subtitle: 'Baseline & follow-up severity assessments',
            ),
            const SizedBox(height: 10),
            _buildFeatureTile(
              icon: Icons.calendar_month_rounded,
              color: AppColors.patientSecondary,
              title: '13-Day Therapy Roadmap',
              subtitle: '26 structured therapeutic video sessions',
            ),
            const SizedBox(height: 10),
            _buildFeatureTile(
              icon: Icons.auto_awesome_rounded,
              color: AppColors.patientAccent,
              title: 'Journal & Stress Relief',
              subtitle: 'Daily thought diary and relaxation games',
            ),

            const SizedBox(height: 24),

            // Primary Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PatientLoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.patientPrimary,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shadowColor: AppColors.patientPrimary.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Patient Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Register Secondary Link
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PatientSingPage()),
                );
              },
              child: RichText(
                text: const TextSpan(
                  text: "New patient? ",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  children: [
                    TextSpan(
                      text: "Create an Account",
                      style: TextStyle(
                        color: AppColors.patientPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Doctor View Builder ---
  Widget _buildDoctorView(BuildContext context, Size size) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Category Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.doctorPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_rounded,
                      size: 14, color: AppColors.doctorPrimary),
                  SizedBox(width: 6),
                  Text(
                    'HEALTHCARE PROFESSIONAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.doctorPrimary,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'Doctor Portal',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Monitor patient progress, review clinical thought analytics & prescribe targeted therapy modules.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            // Feature Highlights
            _buildFeatureTile(
              icon: Icons.people_alt_rounded,
              color: AppColors.doctorPrimary,
              title: 'Patient Directory & Demographics',
              subtitle: 'Filter cohorts by Teen, Women, and Men',
            ),
            const SizedBox(height: 10),
            _buildFeatureTile(
              icon: Icons.analytics_rounded,
              color: AppColors.doctorSecondary,
              title: 'Clinical Score Analytics',
              subtitle: 'Pre & post therapy Anger Scale metrics',
            ),
            const SizedBox(height: 10),
            _buildFeatureTile(
              icon: Icons.psychology_rounded,
              color: AppColors.doctorAccent,
              title: 'Thought Sentiment Review',
              subtitle: '10-Emotion distribution and thought streams',
            ),

            const SizedBox(height: 24),

            // Primary Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DoctorLogin()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.doctorPrimary,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shadowColor: AppColors.doctorPrimary.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Doctor Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Security Note
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Authorized Clinical Staff Only',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Feature Highlights Tile ---
  Widget _buildFeatureTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}