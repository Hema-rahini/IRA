import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ira/theme/app_theme.dart';
import '../urls.dart';

class DataItem {
  int x;
  double y1;
  double y2;
  double y3;

  DataItem({required this.x, required this.y1, required this.y2, required this.y3});
}

class Insights extends StatefulWidget {
  final String email;
  const Insights({Key? key, required this.email}) : super(key: key);

  @override
  State<Insights> createState() => _InsightsState();
}

class _InsightsState extends State<Insights> {
  late List<DataItem> _chartData;
  late List<DataItem> _horizontalChartData;

  double score1 = 0.0, score2 = 0.0;
  int negativeCount = 0, positiveCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chartData = [
      DataItem(x: 0, y1: 0.0, y2: 0.0, y3: 0.0),
      DataItem(x: 1, y1: 0.0, y2: 0.0, y3: 0.0),
    ];
    _horizontalChartData = List.generate(
      10,
      (index) => DataItem(x: index, y1: 0.0, y2: 0.0, y3: 0.0),
    );
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchMoodCount();
    await _checkScore1();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMoodCount() async {
    try {
      final response = await http.post(
        Uri.parse(api.ip + '/mood_count'),
        headers: {'Content-Type': 'application/json'},
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      final response2 = await http.post(
        Uri.parse(api.ip + '/thoughts_count'),
        headers: {'Content-Type': 'application/json'},
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
        setState(() {
          _chartData = [
            DataItem(x: 0, y1: score1, y2: 0.0, y3: 0.0),
            DataItem(x: 1, y1: score2, y2: 0.0, y3: 0.0),
          ];
        });
      }
    } catch (e) {
      print('Error checking thoughts count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double maxSentiment = (score1 > score2 ? score1 : score2);
    final double sentimentMaxY = maxSentiment > 0 ? (maxSentiment + 2) : 5.0;

    final double maxMood = _horizontalChartData.fold(0.0, (prev, elem) => elem.y1 > prev ? elem.y1 : prev);
    final double moodMaxY = maxMood > 0 ? (maxMood + 2) : 5.0;

    return Scaffold(
      backgroundColor: AppColors.patientBackground,
      appBar: AppBar(
        title: const Text('Emotional Insights'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.patientPrimary))
          : RefreshIndicator(
              onRefresh: _initializeData,
              color: AppColors.patientPrimary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sentiment Overview Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: AppStyles.cardDecoration(
                        backgroundColor: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Thought Sentiment Ratio',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Icon(Icons.psychology_outlined, color: AppColors.patientPrimary, size: 22),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Comparison of negative vs positive journal reflections',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 180,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                borderData: FlBorderData(show: false),
                                maxY: sentimentMaxY,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: (sentimentMaxY <= 5 ? 1 : (sentimentMaxY / 5).ceilToDouble()),
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: AppColors.borderSubtle,
                                    strokeWidth: 1,
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 28,
                                      interval: (sentimentMaxY <= 5 ? 1 : (sentimentMaxY / 5).ceilToDouble()),
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (double value, TitleMeta meta) {
                                        if (value == 0) {
                                          return const Padding(
                                            padding: EdgeInsets.only(top: 8.0),
                                            child: Text('Negative', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.negativeRed)),
                                          );
                                        } else if (value == 1) {
                                          return const Padding(
                                            padding: EdgeInsets.only(top: 8.0),
                                            child: Text('Positive', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.positiveGreen)),
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
                                        width: 32,
                                        color: AppColors.negativeRed,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 1,
                                    barRods: [
                                      BarChartRodData(
                                        toY: score2,
                                        width: 32,
                                        color: AppColors.positiveGreen,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 24,
                            runSpacing: 8,
                            children: [
                              _buildLegendItem('Negative (${negativeCount})', AppColors.negativeRed),
                              _buildLegendItem('Positive (${positiveCount})', AppColors.positiveGreen),
                            ],
                          ),
                          if (score1 == 0 && score2 == 0) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.patientPrimary.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.patientPrimary.withValues(alpha: 0.18)),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.tips_and_updates_outlined, size: 18, color: AppColors.patientPrimary),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'No journal reflections yet. Share your thoughts in the Daily Journal to see your AI sentiment ratio!',
                                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Mood Distribution Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: AppStyles.cardDecoration(
                        backgroundColor: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Most Logged Emotions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Icon(Icons.emoji_emotions_outlined, color: AppColors.patientWarmAccent, size: 22),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Frequencies of post-activity feelings you reported',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                borderData: FlBorderData(show: false),
                                maxY: moodMaxY,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: (moodMaxY <= 5 ? 1 : (moodMaxY / 5).ceilToDouble()),
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: AppColors.borderSubtle,
                                    strokeWidth: 1,
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 26,
                                      interval: (moodMaxY <= 5 ? 1 : (moodMaxY / 5).ceilToDouble()),
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (double value, TitleMeta meta) {
                                        const labels = ['Joy', 'Hap', 'Amz', 'Dep', 'Chil', 'Mis', 'Fur', 'Irr', 'Man', 'Calm'];
                                        int idx = value.toInt();
                                        if (idx >= 0 && idx < labels.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
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
                                              color: AppColors.patientSecondary,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ],
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                          if (maxMood == 0) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.patientWarmAccent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.patientWarmAccent.withValues(alpha: 0.20)),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.sentiment_satisfied_alt_rounded, size: 18, color: AppColors.patientWarmAccent),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'No emotion logs recorded yet. Complete today\'s therapy activities to track your feelings here!',
                                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
