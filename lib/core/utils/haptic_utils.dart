import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../providers/settings_provider.dart';

class HapticUtils {
  static Future<void> lightImpact(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    if (settings.isVibrationEnabled) {
      HapticFeedback.lightImpact();
      // Also use the vibration package for better feedback
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 50);
      }
    }
  }
  
  static Future<void> mediumImpact(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    if (settings.isVibrationEnabled) {
      HapticFeedback.mediumImpact();
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 100);
      }
    }
  }
  
  static Future<void> heavyImpact(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    if (settings.isVibrationEnabled) {
      HapticFeedback.heavyImpact();
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 150);
      }
    }
  }
  
  static Future<void> selectionClick(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    if (settings.isVibrationEnabled) {
      HapticFeedback.selectionClick();
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 30);
      }
    }
  }
  
  static Future<void> vibrate(BuildContext context, {int duration = 100}) async {
    final settings = context.read<SettingsProvider>();
    if (settings.isVibrationEnabled) {
      HapticFeedback.vibrate();
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: duration);
      }
    }
  }
  
  static Future<void> vibratePattern(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    if (settings.isVibrationEnabled) {
      if (await Vibration.hasVibrator()) {
        // Pattern: vibrate for 100ms, pause for 50ms, vibrate for 100ms
        Vibration.vibrate(pattern: [0, 100, 50, 100]);
      }
    }
  }
}
