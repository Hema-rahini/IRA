import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:http/http.dart' as http;
import 'package:ira/theme/app_theme.dart';
import '../urls.dart';
import 'HomePageNav.dart';
import 'DoctorConsultationPage.dart';

class ScorePage2 extends StatefulWidget {
  final int Score;
  final String email;

  const ScorePage2({Key? key, required this.Score, required this.email}) : super(key: key);

  @override
  State<ScorePage2> createState() => _ScorePage2State();
}

class _ScorePage2State extends State<ScorePage2> {
  @override
  void initState() {
    super.initState();
    postScoreData();
  }

  Future<void> postScoreData() async {
    try {
      final response = await http.post(
        Uri.parse(api.ip + '/update_score2'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'score_2': widget.Score,
          'anger_scale_2': getClinicalAngerLevel(widget.Score),
        }),
      );

      if (response.statusCode == 200) {
        print('Score 2 posted successfully');
      } else {
        print('Failed to post score 2 data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error posting score 2 data: $e');
    }
  }

  String getClinicalAngerLevel(int score) {
    if (score >= 1 && score <= 13) {
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
        return 'Wonderful outcome! Your follow-up responses reflect significant progress and healthy emotional stabilization.';
      case 'Mild Anger':
        return 'Great progress! You are managing anger responses effectively. Continue using the journal and mindful activities.';
      case 'Moderate Anger':
        return 'Noticeable improvement achieved. We recommend revisiting challenging exercises and logging moods daily.';
      case 'Sever Anger':
        return 'Your score reflects ongoing emotional tension. We recommend repeating core therapy days and discussing with your doctor.';
      default:
        return 'Please consult your healthcare provider for clinical review alongside app therapy.';
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
              Color(0xFF0F766E), // Deep Teal
              AppColors.positiveGreen,
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
                      'POST-THERAPY OUTCOMES',
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
                                color: Color(0xFF0F766E),
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'FOLLOW-UP SCORE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.8,
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
                            color: Color(0xFF0F766E),
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

                // Slide to continue
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 200),
                  child: SlideAction(
                    innerColor: const Color(0xFF0F766E),
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
                          MaterialPageRoute(builder: (context) => PhomePage(email: widget.email)),
                        );
                      }
                      return null;
                    },
                    child: const Text(
                      'Slide to Finish',
                      style: TextStyle(
                        color: Color(0xFF0F766E),
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
