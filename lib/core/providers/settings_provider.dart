import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _darkModeKey = 'darkMode';
  static const String _soundKey = 'sound';
  static const String _vibrationKey = 'vibration';
  
  late SharedPreferences _prefs;
  
  bool _isDarkMode = false;
  bool _isSoundEnabled = true;
  bool _isVibrationEnabled = true;
  
  bool get isDarkMode => _isDarkMode;
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isVibrationEnabled => _isVibrationEnabled;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool(_darkModeKey) ?? false;
    _isSoundEnabled = _prefs.getBool(_soundKey) ?? true;
    _isVibrationEnabled = _prefs.getBool(_vibrationKey) ?? true;
    notifyListeners();
  }
  
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool(_darkModeKey, _isDarkMode);
    notifyListeners();
  }
  
  Future<void> toggleSound() async {
    _isSoundEnabled = !_isSoundEnabled;
    await _prefs.setBool(_soundKey, _isSoundEnabled);
    notifyListeners();
  }
  
  Future<void> toggleVibration() async {
    _isVibrationEnabled = !_isVibrationEnabled;
    await _prefs.setBool(_vibrationKey, _isVibrationEnabled);
    notifyListeners();
  }
  
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _prefs.setBool(_darkModeKey, _isDarkMode);
    notifyListeners();
  }
  
  Future<void> setSound(bool value) async {
    _isSoundEnabled = value;
    await _prefs.setBool(_soundKey, _isSoundEnabled);
    notifyListeners();
  }
  
  Future<void> setVibration(bool value) async {
    _isVibrationEnabled = value;
    await _prefs.setBool(_vibrationKey, _isVibrationEnabled);
    notifyListeners();
  }
}
