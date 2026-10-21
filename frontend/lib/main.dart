import 'dart:io';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:ira/theme/app_theme.dart';
import 'package:ira/OnboardingScreens/splashscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = MyHttpOverrides();

  Flame.device.fullScreen();
  runApp(const MyApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IRA - Emotional Health',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.patientBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.patientPrimary,
          primary: AppColors.patientPrimary,
          secondary: AppColors.patientSecondary,
          surface: AppColors.patientSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}
