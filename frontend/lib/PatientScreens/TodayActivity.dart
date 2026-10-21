import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ira/theme/app_theme.dart';
import '../urls.dart';

class TodaysActivity extends StatefulWidget {
  final String email;

  const TodaysActivity({Key? key, required this.email}) : super(key: key);

  @override
  State<TodaysActivity> createState() => _TodaysActivityState();
}

class _TodaysActivityState extends State<TodaysActivity> {
  late List<int> updateList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    updateList = List<int>.filled(26, 0);
    CheckActivitycall();
  }

  void CheckActivitycall() async {
    try {
      final response = await http.post(
        Uri.parse(api.ip + '/get_activity_update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<int> fetchedList = [];
        if (decoded is Map && decoded['update_list'] != null) {
          fetchedList = List<int>.from(decoded['update_list']);
        } else if (decoded is List) {
          fetchedList = List<int>.from(decoded);
        }
        if (mounted) {
          setState(() {
            updateList = fetchedList;
            _isLoading = false;
          });
        }
      } else {
        print('Failed to refresh data: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching activity update: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int completedCount = updateList.where((item) => item == 1).length;
    double progress = completedCount / 26.0;

    return Scaffold(
      backgroundColor: AppColors.patientBackground,
      appBar: AppBar(
        title: const Text('Activity Tracker'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.patientPrimary))
          : RefreshIndicator(
              onRefresh: () async => CheckActivitycall(),
              color: AppColors.patientPrimary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  children: [
                    // Summary Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: AppStyles.cardDecoration(
                        backgroundColor: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '13-Day Progress',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$completedCount of 26 sessions completed',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.patientPrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${(progress * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.patientPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: AppColors.borderSubtle,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.patientPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 26 Steps List
                    _buildActivityList(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActivityList() {
    List<String> activityItems = [];
    for (int day = 1; day <= 13; day++) {
      for (int activity = 1; activity <= 2; activity++) {
        activityItems.add('Day $day - Activity $activity');
      }
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activityItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final bool isDone = index < updateList.length && updateList[index] == 1;

        return FadeInUp(
          duration: const Duration(milliseconds: 250),
          delay: Duration(milliseconds: (index % 10) * 30),
          child: Container(
            decoration: AppStyles.cardDecoration(
              backgroundColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (isDone ? AppColors.positiveGreen : AppColors.borderSubtle).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isDone ? AppColors.positiveGreen : AppColors.textMuted,
                  size: 22.0,
                ),
              ),
              title: Text(
                activityItems[index],
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                  color: isDone ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDone ? AppColors.positiveGreen : AppColors.textMuted).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isDone ? 'Completed' : 'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDone ? AppColors.positiveGreen : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
