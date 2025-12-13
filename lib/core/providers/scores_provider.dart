import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScoresProvider extends ChangeNotifier {
  static const String _scoresPrefix = 'highScore_';
  
  late SharedPreferences _prefs;
  final Map<String, int> _scores = {};
  
  Map<String, int> get scores => Map.unmodifiable(_scores);
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadAllScores();
  }
  
  void _loadAllScores() {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_scoresPrefix)) {
        final gameId = key.replaceFirst(_scoresPrefix, '');
        _scores[gameId] = _prefs.getInt(key) ?? 0;
      }
    }
    notifyListeners();
  }
  
  int getHighScore(String gameId) {
    return _scores[gameId] ?? 0;
  }
  
  Future<void> updateHighScore(String gameId, int score) async {
    final currentHighScore = _scores[gameId] ?? 0;
    if (score > currentHighScore) {
      _scores[gameId] = score;
      await _prefs.setInt('$_scoresPrefix$gameId', score);
      notifyListeners();
    }
  }
  
  Future<void> resetAllScores() async {
    for (final gameId in _scores.keys.toList()) {
      await _prefs.remove('$_scoresPrefix$gameId');
    }
    _scores.clear();
    notifyListeners();
  }
  
  Future<void> resetScore(String gameId) async {
    await _prefs.remove('$_scoresPrefix$gameId');
    _scores.remove(gameId);
    notifyListeners();
  }
}
