import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Hero text (screen centerpiece)
  static TextStyle hero({Color color = AppColors.textPrimary}) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
        height: 1.15,
      );

  // Screen title
  static TextStyle screenTitle({Color color = AppColors.textPrimary}) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
        height: 1.2,
      );

  // Section title
  static TextStyle sectionTitle({Color color = AppColors.textPrimary}) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.2,
      );

  // Card title
  static TextStyle cardTitle({Color color = AppColors.textPrimary}) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.1,
      );

  // Body text
  static TextStyle body({Color color = AppColors.textSecondary}) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.6,
      );

  // Body medium
  static TextStyle bodyMedium({Color color = AppColors.textPrimary}) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.5,
      );

  // Label
  static TextStyle label({Color color = AppColors.textSecondary}) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.8,
      );

  // Metadata/caption
  static TextStyle metadata({Color color = AppColors.textMuted}) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: color,
        letterSpacing: 0.3,
      );

  // Overline (ALL CAPS small label)
  static TextStyle overline({Color color = AppColors.accent}) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 2.0,
      );

  // Score / number display
  static TextStyle score({Color color = AppColors.textPrimary}) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -1.0,
      );

  // Button text
  static TextStyle button({Color color = AppColors.textPrimary}) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.5,
      );
}

class AppConstants {
  // API
  static const String apiBaseUrl = 'http://10.0.2.2:8000'; // Android emulator
  // For iOS simulator use: http://localhost:8000
  // For physical device use your machine's local IP: http://192.168.x.x:8000

  // Timing
  static const Duration rouletteAnimDuration = Duration(milliseconds: 2200);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);

  // Quiz
  static const int quizTimerSeconds = 10;

  // Cache
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String usernameKey = 'username';
}
