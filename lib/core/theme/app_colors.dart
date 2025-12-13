import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color accent = Color(0xFFFF6584);
  
  // Background colors
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);
  
  // Surface colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  // Text colors
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);
  
  // Shadow
  static const Color shadow = Color(0xFF000000);
  
  // Game-specific colors
  static const Color gameRed = Color(0xFFEF5350);
  static const Color gameBlue = Color(0xFF42A5F5);
  static const Color gameGreen = Color(0xFF66BB6A);
  static const Color gameYellow = Color(0xFFFFCA28);
  static const Color gameOrange = Color(0xFFFFA726);
  static const Color gamePurple = Color(0xFFAB47BC);
  static const Color gamePink = Color(0xFFEC407A);
  static const Color gameTeal = Color(0xFF26A69A);
  
  // 2048 game colors
  static const Map<int, Color> tile2048Colors = {
    0: Color(0xFFCDC1B4),
    2: Color(0xFFEEE4DA),
    4: Color(0xFFEDE0C8),
    8: Color(0xFFF2B179),
    16: Color(0xFFF59563),
    32: Color(0xFFF67C5F),
    64: Color(0xFFF65E3B),
    128: Color(0xFFEDCF72),
    256: Color(0xFFEDCC61),
    512: Color(0xFFEDC850),
    1024: Color(0xFFEDC53F),
    2048: Color(0xFFEDC22E),
  };
  
  // Gradient presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8B83FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFF4DE8D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
