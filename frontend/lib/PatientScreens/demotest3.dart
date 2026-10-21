import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:ira/theme/app_theme.dart';
import '../urls.dart';
import 'DetailsFillingPage.dart';
import 'DoctorConsultationPage.dart';
import 'InsightsPage.dart';
import 'DairyPage.dart';
import 'TodayActivity.dart';
import 'AngerScaleQuestions.dart';

class CheckGivenImage extends StatefulWidget {
  final String email;

  const CheckGivenImage({Key? key, required this.email}) : super(key: key);

  @override
  State<CheckGivenImage> createState() => _CheckGivenImageState();
}

class _CheckGivenImageState extends State<CheckGivenImage> {
  String? base64Image;
  String accountantName = "";
  double height = 0.0;
  double weight = 0.0;
  double bmi = 0.0;
  String commonMood = "--";
  String score1 = "--", score2 = "--";

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    await fetchAllDetailsWithRetry();
    await fetchImageWithRetry();
    await getmaxmood();
    await getscores();
  }

  Future<void> getmaxmood() async {
    try {
      final response = await http.post(
        Uri.parse(api.ip + '/most_mood'),
        headers: {
          'content-type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({"email": widget.email}),
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> detailsData = json.decode(response.body);
        if (mounted) {
          setState(() {
            commonMood = detailsData['most_mood']?.toString() ?? "--";
          });
        }
      }
    } catch (e) {
      print('Error getting max mood: $e');
    }
  }

  Future<void> getscores() async {
    try {
      final response = await http.post(
        Uri.parse(api.ip + '/get_score_1'),
        headers: {
          'content-type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({"email": widget.email}),
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> detailsData = json.decode(response.body);
        if (mounted) {
          setState(() {
            score1 = detailsData['score_1'] != null ? detailsData['score_1'].toString() : "--";
            score2 = detailsData['score_2'] != null ? detailsData['score_2'].toString() : "--";
          });
        }
      }
    } catch (e) {
      print("Error getting scores: $e");
    }
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
              accountantName = detailsData["Name"]?.toString() ?? "";
              weight = (detailsData["Weight"] is num) ? (detailsData["Weight"] as num).toDouble() : 0.0;
              height = (detailsData["Height"] is num) ? (detailsData["Height"] as num).toDouble() : 0.0;

              if (height > 0) {
                double heightInMeters = height / 100.0;
                bmi = weight / (heightInMeters * heightInMeters);
              }
            });
          }
          break;
        }
      } catch (e) {
        print('Error fetching user details: $e');
        maxRetries--;
        if (maxRetries > 0) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
  }

  Future<void> fetchImageWithRetry() async {
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
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          Map<String, dynamic> imageData = json.decode(response.body);
          if (mounted) {
            setState(() {
              base64Image = imageData["base64_image"]?.toString();
            });
          }
          break;
        }
      } catch (e) {
        print('Error fetching image: $e');
        maxRetries--;
        if (maxRetries > 0) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
  }

  // Adaptive configuration for Dominant Mood
  _AdaptiveConfig _getMoodConfig(String moodRaw) {
    final mood = moodRaw.toLowerCase().trim();
    if (mood.contains('joy') || mood.contains('happy') || mood.contains('excite')) {
      return _AdaptiveConfig(
        icon: Icons.wb_sunny_rounded,
        color: const Color(0xFFE58E26),
        badgeText: 'Joyful State',
        interpretation: 'Your dominant state reflects optimism and positive emotional resilience.',
      );
    } else if (mood.contains('calm') || mood.contains('peace') || mood.contains('relax')) {
      return _AdaptiveConfig(
        icon: Icons.spa_rounded,
        color: const Color(0xFF10B981),
        badgeText: 'Calm & Grounded',
        interpretation: 'Your mind is centered and emotionally stable with low cognitive reactivity.',
      );
    } else if (mood.contains('ang') || mood.contains('irrit') || mood.contains('frust')) {
      return _AdaptiveConfig(
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFE53935),
        badgeText: 'High Reactivity',
        interpretation: 'Anger impulses detected. Recommended to engage in relaxation games or journaling.',
      );
    } else if (mood.contains('sad') || mood.contains('depress') || mood.contains('down')) {
      return _AdaptiveConfig(
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF3B82F6),
        badgeText: 'Subdued State',
        interpretation: 'Feelings of low energy or emotional fatigue logged. Express thoughts freely in your journal.',
      );
    } else if (mood.contains('anx') || mood.contains('fear') || mood.contains('worr') || mood.contains('stress')) {
      return _AdaptiveConfig(
        icon: Icons.bolt_rounded,
        color: const Color(0xFF8B5CF6),
        badgeText: 'Elevated Tension',
        interpretation: 'Heightened mental stimulation. Mindful breathing activities are strongly advised.',
      );
    }
    return _AdaptiveConfig(
      icon: Icons.psychology_rounded,
      color: AppColors.patientPrimary,
      badgeText: moodRaw == "--" ? 'Observing' : 'Balanced',
      interpretation: 'Keep recording your daily thoughts to generate precise emotional patterns.',
    );
  }

  // Adaptive configuration for Initial Anger (Score 1)
  _AdaptiveConfig _getScore1Config(String scoreStr) {
    final score = int.tryParse(scoreStr);
    if (score == null || scoreStr == "--" || scoreStr == "null") {
      return _AdaptiveConfig(
        icon: Icons.pending_actions_rounded,
        color: AppColors.textSecondary,
        badgeText: 'Pending Check',
        interpretation: 'Complete your 21-question clinical assessment to establish baseline calibration.',
      );
    }
    if (score >= 0 && score <= 13) {
      return _AdaptiveConfig(
        icon: Icons.verified_user_rounded,
        color: const Color(0xFF2E7D32),
        badgeText: 'Minimal Tier',
        interpretation: 'Score $score/63 indicates healthy emotional regulation. Occasional frustration is managed well.',
      );
    } else if (score >= 14 && score <= 19) {
      return _AdaptiveConfig(
        icon: Icons.speed_rounded,
        color: const Color(0xFFF59E0B),
        badgeText: 'Mild Tier',
        interpretation: 'Score $score/63 indicates situational anger spikes. Mindful exercises help prevent escalation.',
      );
    } else if (score >= 20 && score <= 28) {
      return _AdaptiveConfig(
        icon: Icons.whatshot_rounded,
        color: const Color(0xFFE65100),
        badgeText: 'Moderate Tier',
        interpretation: 'Score $score/63 reflects recurring anger impacting focus. Daily therapeutic tasks are vital.',
      );
    } else {
      return _AdaptiveConfig(
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFC62828),
        badgeText: 'Severe Tier',
        interpretation: 'Score $score/63 signals intense emotional distress. Follow your guided program closely.',
      );
    }
  }

  // Adaptive configuration for Post-Therapy (Score 2)
  _AdaptiveConfig _getScore2Config(String scoreStr) {
    final score = int.tryParse(scoreStr);
    if (score == null || scoreStr == "--" || scoreStr == "null" || scoreStr == "Yet to give") {
      return _AdaptiveConfig(
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFF6366F1),
        badgeText: 'In Progress',
        interpretation: 'Post-intervention assessment unlocks after completing the 13-day cognitive therapy journey.',
      );
    }
    return _AdaptiveConfig(
      icon: Icons.task_alt_rounded,
      color: AppColors.positiveGreen,
      badgeText: 'Therapy Evaluated',
      interpretation: 'Follow-up score recorded ($score). Comparison with baseline reflects clinical progress.',
    );
  }

  // Adaptive configuration for BMI
  _AdaptiveConfig _getBmiConfig(double val) {
    if (val <= 0) {
      return _AdaptiveConfig(
        icon: Icons.straighten_rounded,
        color: AppColors.patientPrimary,
        badgeText: 'Biometrics Needed',
        interpretation: 'Update your height and weight in profile settings to compute clinical BMI.',
      );
    }
    if (val < 18.5) {
      return _AdaptiveConfig(
        icon: Icons.monitor_weight_outlined,
        color: const Color(0xFFF59E0B),
        badgeText: 'Underweight',
        interpretation: 'BMI is below standard clinical range. Balanced nutrition supports nervous stability.',
      );
    } else if (val <= 24.9) {
      return _AdaptiveConfig(
        icon: Icons.health_and_safety_rounded,
        color: const Color(0xFF2E7D32),
        badgeText: 'Optimal Health',
        interpretation: 'BMI is within the ideal clinical range, supporting balanced physiological health.',
      );
    } else if (val <= 29.9) {
      return _AdaptiveConfig(
        icon: Icons.fitness_center_rounded,
        color: const Color(0xFFE65100),
        badgeText: 'Overweight',
        interpretation: 'BMI slightly elevated. Light physical activity pairs effectively with emotional regulation.',
      );
    } else {
      return _AdaptiveConfig(
        icon: Icons.healing_rounded,
        color: const Color(0xFFC62828),
        badgeText: 'Health Alert',
        interpretation: 'Elevated biometric profile. Consult a health coach alongside emotional therapy.',
      );
    }
  }

  // Modal Detail Dialogs & Redirections
  void _showBmiDetailsDialog(_AdaptiveConfig config) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(config.icon, color: config.color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Body Mass Index (BMI)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: config.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          config.badgeText,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: config.color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.patientBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSubStat('Current BMI', bmi > 0 ? bmi.toStringAsFixed(1) : '--', config.color),
                  Container(height: 30, width: 1, color: AppColors.divider),
                  _buildSubStat('Height', height > 0 ? '${height.toStringAsFixed(0)} cm' : '--', AppColors.textPrimary),
                  Container(height: 30, width: 1, color: AppColors.divider),
                  _buildSubStat('Weight', weight > 0 ? '${weight.toStringAsFixed(1)} kg' : '--', AppColors.textPrimary),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              config.interpretation,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.patientPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 22),
                label: const Text('Update Height & Weight', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DetailsUpdatePage(email: widget.email)),
                  );
                  initializeData(); // Refresh biometrics
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
  }

  void _showMoodDetailsDialog(_AdaptiveConfig config) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(config.icon, color: config.color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dominant Mood Status',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: config.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          commonMood.isNotEmpty && commonMood != "null" ? commonMood.toUpperCase() : 'NO LOGS YET',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: config.color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.patientBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                config.interpretation,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.45),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.divider, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.patientPrimary),
                    label: const Text('Add Journal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DairyPage(email: widget.email)),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.patientPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.insights_rounded, size: 18),
                    label: const Text('View Insights', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Insights(email: widget.email)),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
  }

  void _showScore1DetailsDialog(_AdaptiveConfig config) {
    final score = int.tryParse(score1);
    final isSevere = score != null && score >= 29;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(config.icon, color: config.color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Initial Anger (Score 1)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: config.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          config.badgeText,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: config.color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.patientBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Clinical Severity Index',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      Text(
                        score != null ? '$score / 63' : '--',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: config.color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: score != null ? (score / 63.0).clamp(0.0, 1.0) : 0.0,
                      minHeight: 8,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(config.color),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    config.interpretation,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            if (isSevere) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'High Distress Detected',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Clinical consultation is strongly advised. Connect with clinic assist or visit in person.',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF7F1D1D)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                  ),
                  icon: const Icon(Icons.medical_services_rounded, size: 19),
                  label: const Text(
                    'Contact Clinic Assist',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DoctorConsultationPage()),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.patientPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                icon: Icon(score == null ? Icons.quiz_rounded : Icons.insights_rounded, size: 20),
                label: Text(
                  score == null ? 'Take Baseline Assessment' : 'View Emotional Insights',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (score == null) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AngerQuestions(email: widget.email)),
                    );
                    initializeData();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Insights(email: widget.email)),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
  }

  void _showScore2DetailsDialog(_AdaptiveConfig config) {
    final hasScore2 = score2.isNotEmpty && score2 != "null" && score2 != "Yet to give" && score2 != "--";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(config.icon, color: config.color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Post Therapy (Score 2)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: config.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          config.badgeText,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: config.color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.patientBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Therapeutic Calibration',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      Text(
                        hasScore2 ? '$score2 / 63' : 'In Progress',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: config.color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    config.interpretation,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.patientPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                icon: Icon(hasScore2 ? Icons.insights_rounded : Icons.self_improvement_rounded, size: 20),
                label: Text(
                  hasScore2 ? 'View Progress Comparison' : "Go to Today's Therapy Session",
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  if (hasScore2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Insights(email: widget.email)),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TodaysActivity(email: widget.email)),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildSubStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bmiConfig = _getBmiConfig(bmi);
    final moodConfig = _getMoodConfig(commonMood);
    final score1Config = _getScore1Config(score1);
    final score2Config = _getScore2Config(score2);

    final hasScore2 = score2.isNotEmpty && score2 != "null" && score2 != "Yet to give" && score2 != "--";

    return Scaffold(
      backgroundColor: AppColors.patientBackground,
      body: RefreshIndicator(
        onRefresh: initializeData,
        color: AppColors.patientPrimary,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // Header with Wave Clipper
            ClipPath(
              clipper: WaveClipperOne(),
              child: Container(
                padding: const EdgeInsets.only(top: 55, bottom: 45),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.patientPrimary,
                      AppColors.patientSecondary,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          backgroundImage: base64Image != null && base64Image!.isNotEmpty
                              ? MemoryImage(base64Decode(base64Image!)) as ImageProvider<Object>
                              : const AssetImage('assets/drpat.png') as ImageProvider<Object>,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        accountantName.isNotEmpty ? accountantName : 'Patient Profile',
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Profile Metrics Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Wellness Metrics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Pre & Post Clinical Data',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.patientPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // 2x2 Interactive Metrics Grid with Adaptive Icons & Click-Through
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12.0,
                crossAxisSpacing: 12.0,
                childAspectRatio: 0.88,
                children: [
                  // Card 1: BMI
                  _buildMetricCard(
                    title: bmi > 0 ? (bmi.toStringAsFixed(1)) : '--',
                    icon: bmiConfig.icon,
                    heading: 'Body Mass Index (BMI)',
                    color: bmiConfig.color,
                    badgeText: bmiConfig.badgeText,
                    onTap: () => _showBmiDetailsDialog(bmiConfig),
                  ),

                  // Card 2: Dominant Mood
                  _buildMetricCard(
                    title: commonMood.isNotEmpty && commonMood != "null" ? commonMood : '--',
                    icon: moodConfig.icon,
                    heading: 'Dominant Mood',
                    color: moodConfig.color,
                    badgeText: moodConfig.badgeText,
                    onTap: () => _showMoodDetailsDialog(moodConfig),
                  ),

                  // Card 3: Initial Anger
                  _buildMetricCard(
                    title: score1 != "null" ? score1 : '--',
                    icon: score1Config.icon,
                    heading: 'Initial Anger (Score 1)',
                    color: score1Config.color,
                    badgeText: score1Config.badgeText,
                    onTap: () => _showScore1DetailsDialog(score1Config),
                  ),

                  // Card 4: Post Therapy
                  _buildMetricCard(
                    title: hasScore2 ? score2 : "Yet to give",
                    icon: score2Config.icon,
                    heading: 'Post Therapy (Score 2)',
                    color: score2Config.color,
                    badgeText: score2Config.badgeText,
                    onTap: () => _showScore2DetailsDialog(score2Config),
                  ),
                ],
              ),
            ),

            // Generous clearance padding so bottom floating dock never cuts off cards
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required IconData icon,
    required String heading,
    required Color color,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          decoration: AppStyles.cardDecoration(
            backgroundColor: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top icon & adaptive status badge row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20.0, color: color),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Value & Heading
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                          color: color,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      heading,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom tap prompt
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 14, color: color.withValues(alpha: 0.8)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdaptiveConfig {
  final IconData icon;
  final Color color;
  final String badgeText;
  final String interpretation;

  _AdaptiveConfig({
    required this.icon,
    required this.color,
    required this.badgeText,
    required this.interpretation,
  });
}
