import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ira/theme/app_theme.dart';
import '../urls.dart';
import 'AngerScaleQuestions.dart';
import 'AngerScaleQuestions2.dart';
import 'DairyPage.dart';
import 'HomePage.dart';
import 'demotest3.dart';

class PhomePage extends StatefulWidget {
  final String email;

  const PhomePage({Key? key, required this.email}) : super(key: key);

  @override
  State<PhomePage> createState() => _PhomePageState();
}

class _PhomePageState extends State<PhomePage> {
  int _selectedIndex = 0;
  String status = "";
  String score2 = "";

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    await _checkScore1();
    await checktodayisscore2();
  }

  Future<void> checktodayisscore2() async {
    try {
      final response = await http.post(
        Uri.parse(api.ip + '/check_score_2_date'),
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
            status = detailsData['is_score_2_date_today'].toString();
            score2 = detailsData['is_score_2_null'].toString();
          });
          if (status == "true" && score2 == "true") {
            _showCustomPopup2();
          }
        }
      }
    } catch (e) {
      print('Error checking score 2 date: $e');
    }
  }

  Future<void> _checkScore1() async {
    final url = api.ip + '/get_score_1';
    final loginact = api.ip + '/log_activity';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData.containsKey('error')) {
          if (responseData['error'] == 'No entry found for the email' ||
              responseData['error'] == 'Score_1 column is None') {
            _showCustomPopup();
          }
        } else if (responseData.containsKey('score_1')) {
          final dynamic rawScore = responseData['score_1'];
          if (rawScore == null) {
            _showCustomPopup();
          }
          // Note: score == 0 is valid 'Minimal Anger' clinical baseline; do not re-prompt!
        }
      }
    } catch (e) {
      print('Error in HTTP POST request: $e');
    }

    try {
      await http.post(
        Uri.parse(loginact),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, "type": "l"}),
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  void _onTabChange(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showCustomPopup2() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.positiveGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 42,
                    color: AppColors.positiveGreen,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Follow-up Assessment Due',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'It is time to take your second Anger Scale questionnaire to evaluate your progress after completing your therapy sessions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.patientPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AngerQuestions2(email: widget.email),
                        ),
                      );
                    },
                    child: const Text('Start Assessment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  }

  void _showCustomPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.patientPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.quiz_outlined,
                    size: 42,
                    color: AppColors.patientPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Initial Anger Assessment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please complete the 21 clinical questions to establish your baseline anger score and calibrate your 13-day therapy plan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.patientPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AngerQuestions(email: widget.email),
                        ),
                      );
                    },
                    child: const Text('Begin Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      PHomePage(email: widget.email),
      DairyPage(email: widget.email),
      CheckGivenImage(email: widget.email),
    ];

    return Scaffold(
      backgroundColor: AppColors.patientBackground,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: SafeArea(
          top: false,
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(33),
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.patientPrimary.withValues(alpha: 0.14),
                  blurRadius: 26,
                  offset: const Offset(0, 8),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.auto_stories_rounded,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.person_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
  }) {
    final isSelected = _selectedIndex == index;
    const double iconSize = 26.0; // All 3 icons are strictly the same size

    return GestureDetector(
      onTap: () => _onTabChange(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 52,
        height: 50,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    AppColors.patientPrimary,
                    Color(0xFF3B8E7D),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.patientPrimary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            icon,
            size: iconSize,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
