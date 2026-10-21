import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ira/theme/app_theme.dart';
import '../PatientScreens/TodayActivity.dart';
import '../urls.dart';
import '../utilsn.dart';

class DataItem {
  int x;
  double y1;
  double y2;
  double y3;

  DataItem({required this.x, required this.y1, required this.y2, required this.y3});
}

class PatientDetails extends StatefulWidget {
  final String email;

  const PatientDetails({Key? key, required this.email}) : super(key: key);

  @override
  State<PatientDetails> createState() => _PatientDetailsState();
}

class _PatientDetailsState extends State<PatientDetails> {
  Map<String, dynamic> userDetail = {};
  late List<DataItem> _horizontalChartData = [];

  double score1 = 0.0, score2 = 0.0;
  int negativeCount = 0, positiveCount = 0;
  String angerscale = "";
  int scoree1 = 0, scoree2 = 0;
  bool _isLoading = true;

  List<Map<String, dynamic>> _patientNotifications = [];

  @override
  void initState() {
    super.initState();
    _initializeAllData();
  }

  Future<void> _initializeAllData() async {
    await fetchUserDetails();
    await gettheangerscaleandscore();
    await _fetchMoodCount();
    await _checkScore1();
    await _fetchPatientNotifications();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPatientNotifications() async {
    try {
      final response = await http.post(
        Uri.parse(api.ip + '/get_patient_notifications'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": widget.email}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted && data['notifications'] != null) {
          setState(() {
            _patientNotifications = List<Map<String, dynamic>>.from(data['notifications']);
          });
        }
      }
    } catch (_) {}
  }

  void _showSendNotificationDialog() {
    final titleCtrl = TextEditingController(text: 'Clinical Notice from Dr. Dinesh');
    final messageCtrl = TextEditingController();
    String selectedPriority = 'normal';
    String selectedCategory = 'Clinician';
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.doctorPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.add_alert_rounded, color: AppColors.doctorPrimary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Send Clinical Alert / Notice',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              'Push targeted alert to ${widget.email}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedCategory,
                    decoration: AppStyles.inputDecoration(
                      labelText: 'Alert Category',
                      prefixIcon: const Icon(Icons.category_outlined, color: AppColors.doctorPrimary, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Clinician', child: Text('Clinician Notice', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Therapy', child: Text('Therapy Reminder', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Mindfulness', child: Text('Mindfulness', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Milestones', child: Text('Milestone Alert', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) => setModalState(() => selectedCategory = val ?? 'Clinician'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedPriority,
                    decoration: AppStyles.inputDecoration(
                      labelText: 'Alert Priority',
                      prefixIcon: const Icon(Icons.flag_outlined, color: AppColors.doctorPrimary, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'normal', child: Text('Standard Priority', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'critical', child: Text('Critical / Urgent', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) => setModalState(() => selectedPriority = val ?? 'normal'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleCtrl,
                    decoration: AppStyles.inputDecoration(
                      hintText: 'Notice Title',
                      prefixIcon: const Icon(Icons.title_rounded, color: AppColors.doctorPrimary, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageCtrl,
                    maxLines: 3,
                    decoration: AppStyles.inputDecoration(
                      hintText: 'Type clinical guidance or instructions for the patient...',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedPriority == 'critical' ? AppColors.negativeRed : AppColors.doctorPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: isSending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              selectedPriority == 'critical' ? 'Send Urgent Clinical Alert' : 'Send Notification',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                      onPressed: isSending
                          ? null
                          : () async {
                              final title = titleCtrl.text.trim();
                              final message = messageCtrl.text.trim();
                              if (title.isEmpty || message.isEmpty) {
                                ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                                  const SnackBar(content: Text('Please enter both title and message')),
                                );
                                return;
                              }

                              setModalState(() => isSending = true);
                              try {
                                final res = await http.post(
                                  Uri.parse(api.ip + '/send_patient_notification'),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode({
                                    'email': widget.email,
                                    'title': title,
                                    'message': message,
                                    'category': selectedCategory,
                                    'priority': selectedPriority,
                                    'action_type': selectedCategory == 'Clinician' ? 'consult_clinic' : 'none',
                                  }),
                                );
                                if (res.statusCode == 200) {
                                  Navigator.pop(bottomSheetContext);
                                  await _fetchPatientNotifications();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Notification sent successfully to patient!'),
                                      backgroundColor: AppColors.positiveGreen,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              } finally {
                                setModalState(() => isSending = false);
                              }
                            },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
        },
      ),
    );
  }

  Future<void> gettheangerscaleandscore() async {
    try {
      final response = await http.post(
        Uri.parse(api.ip + '/get_angerscale'),
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
            angerscale = detailsData['angerscale']?.toString() ?? "";
          });
        }
      }
      final response2 = await http.post(
        Uri.parse(api.ip + '/get_score_1'),
        headers: {
          'content-type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({"email": widget.email}),
      );
      if (response2.statusCode == 200) {
        Map<String, dynamic> detailsData = json.decode(response2.body);
        if (mounted) {
          setState(() {
            scoree1 = detailsData['score_1'] ?? 0;
            scoree2 = detailsData['score_2'] ?? 0;
          });
        }
      }
    } catch (e) {
      print('Error getting scores: $e');
    }
  }

  Future<void> _fetchMoodCount() async {
    try {
      final response = await http.post(
        Uri.parse(api.ip + '/mood_count'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': widget.email}),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> moodCount = jsonDecode(response.body);

        List<String> moodListOrder = [
          "joyful",
          "happy",
          "amazed",
          "depression",
          "chill",
          "miserable",
          "furious",
          "irritated",
          "manic",
          "calm",
        ];

        if (mounted) {
          setState(() {
            _horizontalChartData = moodListOrder.map((mood) {
              final count = moodCount[mood] ?? 0;
              return DataItem(
                x: moodListOrder.indexOf(mood),
                y1: count.toDouble(),
                y2: 0.0,
                y3: 0.0,
              );
            }).toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching mood count: $e');
    }
  }

  Future<void> _checkScore1() async {
    final url = api.ip + '/check_thoughts_count';

    try {
      await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': widget.email}),
      );

      final response2 = await http.post(
        Uri.parse(api.ip + '/thoughts_count'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': widget.email}),
      );

      if (response2.statusCode == 200) {
        Map<String, dynamic> thoughtsCount = jsonDecode(response2.body);
        negativeCount = thoughtsCount['NEGATIVE'] ?? 0;
        positiveCount = thoughtsCount['POSITIVE'] ?? 0;
      }

      score1 = negativeCount.toDouble();
      score2 = positiveCount.toDouble();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error checking score: $e');
    }
  }

  Future<void> fetchUserDetails() async {
    try {
      var response = await http.post(
        Uri.parse(api.ip + '/get_details_with_image'),
        headers: {
          'content-type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({"email": widget.email}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['user_details'] != null) {
          Map<String, dynamic> data = Map<String, dynamic>.from(decoded['user_details']);
          if (mounted) {
            setState(() {
              userDetail = data;
            });
          }
        }
      }
    } catch (e) {
      // Graceful fallback
    }
  }

  Color _getAngerScaleColor(String scale) {
    final s = scale.toLowerCase();
    if (s.contains('minimal')) return AppColors.minimalAnger;
    if (s.contains('mild')) return AppColors.mildAnger;
    if (s.contains('moderate')) return AppColors.moderateAnger;
    if (s.contains('sever')) return AppColors.severeAnger;
    return AppColors.criticalAnger;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.doctorBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Clinical Profile',
          style: TextStyle(
            color: AppColors.doctorPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.doctorPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.doctorPrimary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Patient Hero Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22.0),
                    decoration: AppStyles.cardDecoration(
                      backgroundColor: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.doctorSecondary.withValues(alpha: 0.3), width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: AppColors.doctorBackground,
                            backgroundImage: getSafeImageProvider(userDetail['ProfileImage']),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          userDetail['Name'] ?? 'Patient Name',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userDetail['Occupation'] ?? 'Occupation unspecified',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.doctorSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (angerscale.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getAngerScaleColor(angerscale).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getAngerScaleColor(angerscale).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield_outlined, size: 16, color: _getAngerScaleColor(angerscale)),
                                const SizedBox(width: 6),
                                Text(
                                  angerscale,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _getAngerScaleColor(angerscale),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Biometrics / Vitals Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          'Age',
                          userDetail['Age']?.toString() ?? '--',
                          Icons.cake_outlined,
                          AppColors.doctorPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          'Weight',
                          userDetail['Weight'] != null ? '${userDetail['Weight']} kg' : '--',
                          Icons.monitor_weight_outlined,
                          AppColors.doctorSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          'Height',
                          userDetail['Height'] != null ? '${userDetail['Height']} cm' : '--',
                          Icons.height_rounded,
                          AppColors.patientAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Psychometric Scores Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildScoreTile(
                          'Score 1 (Baseline)',
                          scoree1.toString(),
                          'Initial Anger Test',
                          AppColors.doctorPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildScoreTile(
                          'Score 2 (Follow-up)',
                          scoree2 > 0 ? scoree2.toString() : 'Pending',
                          'Post-Therapy Test',
                          AppColors.positiveGreen,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Sentiment Chart Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18.0),
                    decoration: AppStyles.cardDecoration(
                      backgroundColor: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Thought Sentiment Analysis',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Icon(Icons.insights_rounded, color: AppColors.doctorSecondary, size: 20),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'AI-classified thoughts from patient diary entries',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              minY: 0,
                              maxY: ((score1 > score2 ? score1 : score2) > 0 ? (score1 > score2 ? score1 : score2) + 2 : 5.0),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  fitInsideHorizontally: true,
                                  fitInsideVertically: true,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 5,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: AppColors.borderSubtle,
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      if (value == 0) {
                                        return SideTitleWidget(
                                          meta: meta,
                                          space: 4,
                                          child: const Text('Negative', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.negativeRed)),
                                        );
                                      } else if (value == 1) {
                                        return SideTitleWidget(
                                          meta: meta,
                                          space: 4,
                                          child: const Text('Positive', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.positiveGreen)),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                              ),
                              barGroups: [
                                BarChartGroupData(
                                  x: 0,
                                  barRods: [
                                    BarChartRodData(
                                      toY: score1,
                                      width: 28,
                                      color: AppColors.negativeRed,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 1,
                                  barRods: [
                                    BarChartRodData(
                                      toY: score2,
                                      width: 28,
                                      color: AppColors.positiveGreen,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Mood Frequency Chart Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18.0),
                    decoration: AppStyles.cardDecoration(
                      backgroundColor: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Emotion Log Frequency',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Icon(Icons.emoji_emotions_outlined, color: AppColors.patientWarmAccent, size: 20),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Recorded post-activity feedback states',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              minY: 0,
                              maxY: (_horizontalChartData.isEmpty
                                  ? 5.0
                                  : (_horizontalChartData.map((e) => e.y1).reduce((a, b) => a > b ? a : b) > 0
                                      ? _horizontalChartData.map((e) => e.y1).reduce((a, b) => a > b ? a : b) + 2
                                      : 5.0)),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  fitInsideHorizontally: true,
                                  fitInsideVertically: true,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 2,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: AppColors.borderSubtle,
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 26)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      const labels = ['Joy', 'Hap', 'Amz', 'Dep', 'Chil', 'Mis', 'Fur', 'Irr', 'Man', 'Calm'];
                                      int idx = value.toInt();
                                      if (idx >= 0 && idx < labels.length) {
                                        return SideTitleWidget(
                                          meta: meta,
                                          space: 4,
                                          child: Text(
                                            labels[idx],
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                          ),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                              ),
                              barGroups: _horizontalChartData
                                  .map((item) => BarChartGroupData(
                                        x: item.x,
                                        barRods: [
                                          BarChartRodData(
                                            toY: item.y1,
                                            width: 14,
                                            color: AppColors.doctorSecondary,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ],
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Patient Notifications & Clinical Alerts History Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18.0),
                    decoration: AppStyles.cardDecoration(
                      backgroundColor: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Patient Clinical Alerts & History',
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_patientNotifications.length} notices recorded for this patient',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.doctorPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.send_rounded, size: 14),
                              label: const Text('Send Notice', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                              onPressed: _showSendNotificationDialog,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_patientNotifications.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            alignment: Alignment.center,
                            child: const Text(
                              'No notifications logged yet for this patient.',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _patientNotifications.length,
                            separatorBuilder: (context, index) => const Divider(height: 16, color: AppColors.borderSubtle),
                            itemBuilder: (context, index) {
                              final notif = _patientNotifications[index];
                              final isCritical = (notif['priority']?.toString().toLowerCase() == 'critical');
                              final isRead = notif['is_read'] == true;

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: (isCritical ? AppColors.negativeRed : AppColors.doctorPrimary).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isCritical ? Icons.warning_rounded : Icons.notifications_rounded,
                                      size: 18,
                                      color: isCritical ? AppColors.negativeRed : AppColors.doctorPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notif['title'] ?? 'Notice',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (isRead ? AppColors.positiveGreen : const Color(0xFFF59E0B)).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isRead ? 'Read' : 'Unread',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isRead ? AppColors.positiveGreen : const Color(0xFFF59E0B),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notif['message'] ?? '',
                                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.3),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notif['created_at'] ?? '',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Activity History Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.history_edu_rounded, size: 20),
                      label: const Text(
                        'View 13-Day Activity History',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TodaysActivity(email: widget.email),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.doctorPrimary,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: AppStyles.cardDecoration(
        backgroundColor: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: accentColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTile(String title, String score, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration(
        backgroundColor: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            score,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}