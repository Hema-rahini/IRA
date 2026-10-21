import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ira/theme/app_theme.dart';
import '../urls.dart';

class ThoughtsList extends StatefulWidget {
  const ThoughtsList({Key? key}) : super(key: key);

  @override
  _ThoughtsListState createState() => _ThoughtsListState();
}

class _ThoughtsListState extends State<ThoughtsList> {
  List<Map<String, dynamic>>? thoughtsData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchThoughts();
  }

  Future<void> fetchThoughts() async {
    try {
      final response = await http.get(Uri.parse(api.ip + '/fetch_thoughts'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            thoughtsData = List<Map<String, dynamic>>.from(data);
            _isLoading = false;
          });
        }
      } else {
        print('Failed to fetch thoughts: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching thoughts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.doctorBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Thought Analytics Feed',
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: AppColors.doctorPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'AI Sentiment Triage & Journal Monitor',
              style: TextStyle(
                fontSize: 12.0,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.doctorPrimary),
            tooltip: 'Refresh Thoughts',
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              fetchThoughts();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.doctorPrimary))
          : thoughtsData == null || thoughtsData!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notes_rounded, size: 54, color: AppColors.textMuted.withValues(alpha: 0.6)),
                      const SizedBox(height: 12),
                      const Text(
                        'No thoughts shared yet.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Patient journal entries will appear here in real-time.',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchThoughts,
                  color: AppColors.doctorPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    itemCount: thoughtsData!.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      Map<String, dynamic> thought = thoughtsData![index];
                      final bool isNegative = thought['Output'] == 'NEGATIVE';
                      final Color sentimentColor = isNegative ? AppColors.negativeRed : AppColors.positiveGreen;
                      final String email = thought['Email_ID'] ?? 'Unknown Patient';
                      final String content = thought['thoughts'] ?? '';
                      String formattedDate = '';
                      String formattedTime = '';

                      try {
                        if (thought['received_time'] != null) {
                          final dt = DateTime.parse(thought['received_time']).toLocal();
                          formattedDate = dt.toString().split(" ")[0];
                          formattedTime = dt.toString().split(" ")[1].substring(0, 5);
                        }
                      } catch (_) {
                        formattedDate = thought['received_time']?.toString() ?? '';
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.borderSubtle),
                          boxShadow: AppStyles.cardShadow,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left Sentiment Accent Bar
                                Container(
                                  width: 6,
                                  color: sentimentColor,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      email,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: sentimentColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isNegative ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                                    size: 13,
                                                    color: sentimentColor,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isNegative ? 'NEGATIVE' : 'POSITIVE',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: sentimentColor,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.doctorBackground,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            content,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColors.textPrimary,
                                              height: 1.45,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textMuted),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$formattedDate at $formattedTime',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
