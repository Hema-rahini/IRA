import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ira/theme/app_theme.dart';
import '../urls.dart';
import 'TrackActivity.dart';

class EmojiFeedback extends StatefulWidget {
  final String email;
  final String fn;
  final String day;
  final String activity;

  const EmojiFeedback({
    Key? key,
    required this.email,
    required this.fn,
    required this.day,
    required this.activity,
  }) : super(key: key);

  @override
  State<EmojiFeedback> createState() => _EmojiFeedbackState();
}

class _EmojiFeedbackState extends State<EmojiFeedback> {
  final List<Map<String, dynamic>> emotions = [
    {'name': 'Joyful', 'icon': Icons.sentiment_very_satisfied_rounded, 'color': Color(0xFFF59E0B)},
    {'name': 'Happy', 'icon': Icons.sentiment_satisfied_alt_rounded, 'color': Color(0xFF10B981)},
    {'name': 'Amazed', 'icon': Icons.auto_awesome_rounded, 'color': Color(0xFF6366F1)},
    {'name': 'Depression', 'icon': Icons.cloud_outlined, 'color': Color(0xFF64748B)},
    {'name': 'Chill', 'icon': Icons.nightlight_round, 'color': Color(0xFF06B6D4)},
    {'name': 'Miserable', 'icon': Icons.sentiment_very_dissatisfied_rounded, 'color': Color(0xFF8B5CF6)},
    {'name': 'Furious', 'icon': Icons.local_fire_department_rounded, 'color': Color(0xFFEF4444)},
    {'name': 'Irritated', 'icon': Icons.bolt_rounded, 'color': Color(0xFFF97316)},
    {'name': 'Manic', 'icon': Icons.electric_bolt_rounded, 'color': Color(0xFFEC4899)},
    {'name': 'Calm', 'icon': Icons.spa_rounded, 'color': Color(0xFF14B8A6)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.patientBackground,
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: const [
            Text(
              "How Do You Feel Now?",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              "Select your post-session emotional state",
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: 1.05,
          ),
          itemCount: emotions.length,
          itemBuilder: (context, index) {
            return _buildEmotionCard(index);
          },
        ),
      ),
    );
  }

  Widget _buildEmotionCard(int index) {
    final emotion = emotions[index];
    final String name = emotion['name'];
    final IconData icon = emotion['icon'];
    final Color color = emotion['color'];

    return Container(
      decoration: AppStyles.cardDecoration(
        backgroundColor: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            sendData(
              widget.email,
              '${widget.day} ${widget.activity}',
              index + 1,
              widget.fn,
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => TrackActivity(email: widget.email)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 32),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void sendData(String email, String dayActivity, int feedback, String fn) async {
  String datact = 'Day-' + dayActivity;
  try {
    final response = await http.post(
      Uri.parse(api.ip + '/update_activity'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'day_activity': datact,
        'feedbackscore': feedback,
        'scale': fn,
      }),
    );

    if (response.statusCode == 200) {
      print('Feedback data sent successfully');
    } else {
      print('Failed to send feedback: ${response.statusCode}');
    }
  } catch (e) {
    print('Error sending feedback: $e');
  }
}