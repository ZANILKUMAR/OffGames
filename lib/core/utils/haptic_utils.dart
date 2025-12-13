import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class HapticUtils {
  static void lightImpact(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    if (settings.isVibrationEnabled) {
      HapticFeedback.lightImpact();
    }
  }
  
  static void mediumImpact(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    if (settings.isVibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
  }
  
  static void heavyImpact(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    if (settings.isVibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
  }
  
  static void selectionClick(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    if (settings.isVibrationEnabled) {
      HapticFeedback.selectionClick();
    }
  }
  
  static void vibrate(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    if (settings.isVibrationEnabled) {
      HapticFeedback.vibrate();
    }
  }
}
