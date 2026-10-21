import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:http/http.dart' as http;
import 'package:ira/theme/app_theme.dart';
import '../urls.dart';
import 'activitysession.dart';

class TrackActivity extends StatefulWidget {
  final String email;
  const TrackActivity({Key? key, required this.email}) : super(key: key);

  @override
  State<TrackActivity> createState() => _TrackActivityState();
}

class _TrackActivityState extends State<TrackActivity> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.patientBackground,
      appBar: AppBar(
        title: const Text('13-Day Therapy Plan'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        itemCount: 13,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final int day = index + 1;
          return FadeInUp(
            duration: const Duration(milliseconds: 300),
            delay: Duration(milliseconds: index * 30),
            child: _buildDayCard(day),
          );
        },
      ),
    );
  }

  Widget _buildDayCard(int day) {
    final List<Color> accentColors = [
      AppColors.patientPrimary,
      AppColors.patientSecondary,
      AppColors.patientAccent,
      AppColors.doctorSecondary,
      AppColors.patientWarmAccent,
      const Color(0xFF0F766E),
      const Color(0xFF4F46E5),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFF7C3AED),
      const Color(0xFF2563EB),
      const Color(0xFFDB2777),
      AppColors.patientPrimary,
    ];

    final Color dayColor = accentColors[(day - 1) % accentColors.length];

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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPage(
                  backgroundColor: dayColor,
                  day: day,
                  email: widget.email,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: dayColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'D$day',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: dayColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Day $day Therapy Program',
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3.0),
                      const Text(
                        '2 Video Sessions (Morning & Evening)',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: dayColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Start',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final Color backgroundColor;
  final int day;
  final String email;

  const DetailPage({
    Key? key,
    required this.backgroundColor,
    required this.day,
    required this.email,
  }) : super(key: key);

  Future<void> _handleActivityTap(BuildContext context, String activityName) async {
    // 1. Day 1 Activity 1 is the starting session of the 13-day curriculum - ALWAYS unlocked!
    if (day == 1 && activityName == 'Activity 1') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ActivitySessionPage(
            day: day,
            activity: activityName,
            email: email,
          ),
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(api.ip + '/check_activity'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'day_activity': 'Day-$day $activityName',
        }),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        if (data['result'] == 'yes') {
          if (!context.mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ActivitySessionPage(
                day: day,
                activity: activityName,
                email: email,
              ),
            ),
          );
        } else {
          if (!context.mounted) return;
          final msg = activityName == 'Activity 2'
              ? 'Please complete Day $day Activity 1 first.'
              : 'Please complete Day ${day - 1} activities before advancing to Day $day.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              duration: const Duration(seconds: 3),
              backgroundColor: AppColors.negativeRed,
            ),
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.negativeRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.patientBackground,
      appBar: AppBar(
        title: Text('Day $day Activities'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          children: [
            // Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: AppStyles.gradientHeaderDecoration(
                colors: [backgroundColor, backgroundColor.withValues(alpha: 0.85)],
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'DAY $day CURRICULUM',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Step-by-Step Guided Sessions',
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Complete both activities to advance your anger management journey.',
                    style: TextStyle(
                      fontSize: 13.0,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28.0),

            // Activity 1 Timeline Tile
            GestureDetector(
              onTap: () => _handleActivityTap(context, 'Activity 1'),
              child: TimelineTile(
                alignment: TimelineAlign.manual,
                lineXY: 0.1,
                isFirst: true,
                indicatorStyle: IndicatorStyle(
                  width: 38,
                  height: 38,
                  indicator: Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  ),
                ),
                beforeLineStyle: LineStyle(color: backgroundColor.withValues(alpha: 0.4)),
                afterLineStyle: LineStyle(color: backgroundColor.withValues(alpha: 0.4)),
                endChild: Container(
                  margin: const EdgeInsets.only(left: 16, bottom: 20),
                  padding: const EdgeInsets.all(18),
                  decoration: AppStyles.cardDecoration(
                    backgroundColor: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Activity 1: Cognitive Reflection',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Morning therapeutic video exercise',
                              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.patientPrimary),
                    ],
                  ),
                ),
              ),
            ),

            // Activity 2 Timeline Tile
            GestureDetector(
              onTap: () => _handleActivityTap(context, 'Activity 2'),
              child: TimelineTile(
                alignment: TimelineAlign.manual,
                lineXY: 0.1,
                isLast: true,
                indicatorStyle: IndicatorStyle(
                  width: 38,
                  height: 38,
                  indicator: Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  ),
                ),
                beforeLineStyle: LineStyle(color: backgroundColor.withValues(alpha: 0.4)),
                endChild: Container(
                  margin: const EdgeInsets.only(left: 16, bottom: 20),
                  padding: const EdgeInsets.all(18),
                  decoration: AppStyles.cardDecoration(
                    backgroundColor: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Activity 2: Mindful Calming',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Evening de-escalation practice',
                              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.patientPrimary),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}