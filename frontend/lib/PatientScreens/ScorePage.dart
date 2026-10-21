import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:http/http.dart' as http;
import 'package:ira/theme/app_theme.dart';
import '../urls.dart';
import 'LoadingActivityPage.dart';
import 'DoctorConsultationPage.dart';

class ScorePage extends StatefulWidget {
  final int Score;
  final String email;

  const ScorePage({Key? key, required this.Score, required this.email}) : super(key: key);

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  @override
  void initState() {
    super.initState();
    postScoreData();
  }

  Future<void> postScoreData() async {
    try {
      final response = await http.post(
        Uri.parse(api.ip + '/update_score'),
        headers: {'Content-Type': 'application/json'},
        body: '{"email": "${widget.email}", "score_1": ${widget.Score}, "anger_scale_1": "${getClinicalAngerLevel(widget.Score)}"}',
      );

      if (response.statusCode == 200) {
        print('Score data posted successfully');
      } else {
        print('Failed to post score data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error posting score data: $e');
    }
  }

  String getClinicalAngerLevel(int score) {
    if (score >= 0 && score <= 13) {
      return 'Minimal Anger';
    } else if (score >= 14 && score <= 19) {
      return 'Mild Anger';
    } else if (score >= 20 && score <= 28) {
      return 'Moderate Anger';
    } else if (score >= 29 && score <= 63) {
      return 'Sever Anger';
    } else {
      return 'Contact Doctor';
    }
  }

  String _getInterpretation(String level) {
    switch (level) {
      case 'Minimal Anger':
        return 'Your responses indicate low levels of anger. Daily mindfulness and light exercises will help you maintain balance.';
      case 'Mild Anger':
        return 'You experience occasional situational anger. Our guided exercises will equip you with quick calming techniques.';
      case 'Moderate Anger':
        return 'Anger is beginning to noticeably impact your daily routine. Our 13-day cognitive therapy program is customized to help.';
      case 'Sever Anger':
        return 'You are experiencing persistent intense anger. Structured daily practices and emotional tracking will assist your recovery.';
      default:
        return 'Your score suggests high distress. We recommend consulting a healthcare professional alongside using the app.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String clinicalLevel = getClinicalAngerLevel(widget.Score);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.patientPrimary,
              AppColors.patientSecondary,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Badge
                        FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'ASSESSMENT COMPLETE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                // Center Score Ring & Card
                Column(
                  children: [
                    ElasticIn(
                      duration: const Duration(milliseconds: 800),
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.Score.toString(),
                              style: const TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: AppColors.patientPrimary,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'TOTAL SCORE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          clinicalLevel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.patientPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _getInterpretation(clinicalLevel),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.95),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Slide to continue action
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 200),
                  child: SlideAction(
                    innerColor: AppColors.patientPrimary,
                    outerColor: Colors.white,
                    sliderButtonIcon: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onSubmit: () {
                      if (widget.Score > 63) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const DoctorConsultationPage()),
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoadingActivityPage(email: widget.email)),
                        );
                      }
                      return null;
                    },
                    child: const Text(
                      'Slide to Continue',
                      style: TextStyle(
                        color: AppColors.patientPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
