import 'package:flutter/material.dart';

/// Centralized Design System & Theme Tokens for IRA
/// Strictly UI-only styling definitions for Patient & Doctor experiences.
class AppColors {
  // --- Patient Theme (Calm, Supportive, Therapeutic) ---
  static const Color patientPrimary = Color(0xFF2A7B88); // Muted Teal
  static const Color patientSecondary = Color(0xFF5B8A72); // Sage Green
  static const Color patientAccent = Color(0xFF7E72A6); // Subtle Lavender
  static const Color patientWarmAccent = Color(0xFFE58F65); // Soft Terracotta
  static const Color patientBackground = Color(0xFFF7F9FA); // Warm Off-White
  static const Color patientSurface = Colors.white;
  static const Color patientCardBorder = Color(0xFFE5E9EB);

  // --- Doctor Theme (Clinical, Professional, Trustworthy) ---
  static const Color doctorPrimary = Color(0xFF1E3A5F); // Deep Navy
  static const Color doctorSecondary = Color(0xFF0D9488); // Clinical Teal
  static const Color doctorAccent = Color(0xFF2563EB); // Slate Blue
  static const Color doctorBackground = Color(0xFFF8FAFC); // Cool Neutral
  static const Color doctorSurface = Colors.white;
  static const Color doctorCardBorder = Color(0xFFE2E8F0);

  // --- Neutral Palette ---
  static const Color textPrimary = Color(0xFF1E293B); // Slate 800
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color dividerColor = Color(0xFFEEF2F6);

  // --- Status & Sentiment ---
  static const Color positiveGreen = Color(0xFF10B981);
  static const Color positiveGreenLight = Color(0xFFECFDF5);
  static const Color negativeRed = Color(0xFFEF4444);
  static const Color negativeRedLight = Color(0xFFFEF2F2);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color error = negativeRed;
  static const Color success = positiveGreen;
  static const Color divider = dividerColor;

  // --- Clinical Anger Tiers ---
  static const Color minimalAnger = Color(0xFF10B981); // Emerald
  static const Color mildAnger = Color(0xFF3B82F6); // Blue
  static const Color moderateAnger = Color(0xFFF59E0B); // Amber
  static const Color severeAnger = Color(0xFFEA580C); // Orange-Red
  static const Color criticalAnger = Color(0xFFDC2626); // Crimson

  // --- Emotion Spectrum Colors ---
  static const Map<String, Color> emotionColors = {
    'Joyful': Color(0xFFF59E0B),
    'Happy': Color(0xFF10B981),
    'Amazed': Color(0xFF6366F1),
    'Depression': Color(0xFF64748B),
    'Chill': Color(0xFF06B6D4),
    'Miserable': Color(0xFF8B5CF6),
    'Furious': Color(0xFFEF4444),
    'Irritated': Color(0xFFF97316),
    'Manic': Color(0xFFEC4899),
    'Calm': Color(0xFF14B8A6),
  };
}

class AppStyles {
  // Border Radii
  static final BorderRadius radiusSmall = BorderRadius.circular(8);
  static final BorderRadius radiusMedium = BorderRadius.circular(14);
  static final BorderRadius radiusLarge = BorderRadius.circular(20);
  static final BorderRadius radiusExtraLarge = BorderRadius.circular(28);

  // Shadows
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      offset: const Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  static final List<BoxShadow> hoverShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  // Elevated Card Decoration
  static BoxDecoration cardDecoration({
    Color backgroundColor = Colors.white,
    BorderRadius? borderRadius,
    Border? border,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: borderRadius ?? radiusLarge,
      border: border ?? Border.all(color: AppColors.borderSubtle, width: 1),
      boxShadow: cardShadow,
    );
  }

  // Gradient Header Card
  static BoxDecoration gradientHeaderDecoration({
    required List<Color> colors,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      borderRadius: borderRadius ?? radiusLarge,
      boxShadow: [
        BoxShadow(
          color: colors.first.withValues(alpha: 0.25),
          offset: const Offset(0, 8),
          blurRadius: 20,
        ),
      ],
    );
  }

  // Modern Input Decoration
  static InputDecoration inputDecoration({
    String hintText = '',
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color fillColor = Colors.white,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: AppColors.patientPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: AppColors.negativeRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(color: AppColors.negativeRed, width: 2),
      ),
    );
  }
}
