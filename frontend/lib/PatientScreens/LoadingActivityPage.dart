import 'package:flutter/material.dart';
import 'package:ira/theme/app_theme.dart';
import 'HomePageNav.dart';

class LoadingActivityPage extends StatefulWidget {
  final String email;
  const LoadingActivityPage({Key? key, required this.email}) : super(key: key);

  @override
  State<LoadingActivityPage> createState() => _LoadingActivityPageState();
}

class _LoadingActivityPageState extends State<LoadingActivityPage> {
  @override
  void initState() {
    super.initState();
    _startLoadingLoop();
  }

  void _startLoadingLoop() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _showSnackBar();
      _navigateToHomePage();
    });
  }

  void _showSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Therapy curriculum loaded successfully'),
        backgroundColor: AppColors.positiveGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToHomePage() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PhomePage(email: widget.email)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.patientBackground,
      body: Center(
        child: Padding(
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
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    color: AppColors.patientPrimary,
                    strokeWidth: 3.5,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Personalizing Your Activities',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Calibrating your 13-day cognitive therapy exercises according to your assessment score...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}