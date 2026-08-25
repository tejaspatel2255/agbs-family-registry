import 'package:flutter/material.dart';

/// App color palette for Family Registry System (AGBS Junagadh).
/// Primary color is dark green (~#0F6E51) as per design specification.
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF0F6E51); // Dark Green
  static const Color primaryDark = Color(0xFF0A4D38);
  static const Color primaryLight = Color(0xFF16936D);
  static const Color primaryContainer = Color(0xFFE0F2EC);

  // Accent / Secondary Colors (Golden Warm Accent for AGBS Gujarati heritage)
  static const Color secondary = Color(0xFFD4AF37); // Warm Gold accent
  static const Color secondaryContainer = Color(0xFFFFF8E7);

  // Background & Surface
  static const Color background = Color(0xFFF8FAF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEDF2F0);

  // Text & Neutral Colors
  static const Color textPrimary = Color(0xFF1E2923);
  static const Color textSecondary = Color(0xFF5A6B63);
  static const Color textMuted = Color(0xFF8E9E96);
  static const Color border = Color(0xFFD5DFDA);

  // Feedback Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFED6C02);
  static const Color info = Color(0xFF0288D1);
}
