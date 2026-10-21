import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ira/theme/app_theme.dart';
import 'playerpage.dart';
import '../urls.dart';

class ActivitySessionPage extends StatefulWidget {
  final int day;
  final String activity;
  final String email;

  const ActivitySessionPage({
    Key? key,
    required this.day,
    required this.activity,
    required this.email,
  }) : super(key: key);

  @override
  State<ActivitySessionPage> createState() => _ActivitySessionPageState();
}

class _ActivitySessionPageState extends State<ActivitySessionPage> {
  String folderName = '';

  @override
  void initState() {
    super.initState();
    sendEmailToServer();
  }

  void _navigateToPlayer(String folder) {
    if (!mounted) return;
    final resolvedFolder = folder.isNotEmpty ? folder : 'Minimal Anger';
    final rawUrl = '${api.ip}/video_send?foldername=$resolvedFolder&filename=Day-${widget.day} ${widget.activity}';
    final cleanUrl = Uri.encodeFull(rawUrl);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerPage(
          videoUrl: cleanUrl,
          email: widget.email,
          Foldername: resolvedFolder,
          day: '${widget.day}',
          activity: widget.activity,
        ),
      ),
    );
  }

  Future<void> sendEmailToServer() async {
    try {
      Map<String, String> payload = {'email': widget.email};
      String jsonPayload = jsonEncode(payload);
      String url = api.ip + '/get_anger_scale';

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonPayload,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final fetchedFolder = jsonResponse['anger_scale_1']?.toString() ?? 'Minimal Anger';
        _navigateToPlayer(fetchedFolder);
      } else {
        // Fallback to default tier if backend returns non-200
        _navigateToPlayer('Minimal Anger');
      }
    } catch (e) {
      print('Error getting anger scale: $e');
      // Fallback so patient is never stuck on loading screen
      _navigateToPlayer('Minimal Anger');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.patientBackground,
      appBar: AppBar(
        title: Text('Day ${widget.day} - ${widget.activity}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.patientPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    color: AppColors.patientPrimary,
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Loading Therapy Session',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connecting to Day ${widget.day} exercise tailored to your anger scale...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
