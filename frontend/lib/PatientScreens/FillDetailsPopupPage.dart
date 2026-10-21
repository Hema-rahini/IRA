import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ira/theme/app_theme.dart';
import '../urls.dart';
import 'DetailsFillingPage.dart';
import 'HomePageNav.dart';

class popupdetails extends StatefulWidget {
  const popupdetails({Key? key, required this.email}) : super(key: key);
  final String email;
  @override
  State<popupdetails> createState() => _popupdetailsState();
}

class _popupdetailsState extends State<popupdetails> {
  bool _isChecking = true;

  Future<void> onUploadImage() async {
    try {
      var response = await http.post(
        Uri.parse(api.ip + "/check_data_completion"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"Email_ID": widget.email}),
      ).timeout(const Duration(seconds: 4));

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PhomePage(email: widget.email)),
        );
      } else if (response.statusCode == 300) {
        setState(() {
          _isChecking = false;
        });
        _showCustomPopup();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PhomePage(email: widget.email)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PhomePage(email: widget.email)),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    onUploadImage();
  }

  void _showCustomPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
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
                    Icons.badge_outlined,
                    size: 42,
                    color: AppColors.patientPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Personalize Your Care',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please fill in your basic biometrics (age, height, weight) so we can calibrate your therapy exercises.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => PhomePage(email: widget.email)),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Skip for now', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.patientPrimary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToHomePage();
                        },
                        child: const Text(
                          'Fill Details',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  }

  void _navigateToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DetailsUpdatePage(email: widget.email)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.patientBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(
              color: AppColors.patientPrimary,
              strokeWidth: 3,
            ),
            SizedBox(height: 18),
            Text(
              'Preparing your wellness profile...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}