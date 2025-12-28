import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class AudioUtils {
  // Use separate players for each sound to avoid conflicts on mobile
  static final Map<String, AudioPlayer> _players = {};
  
  static AudioPlayer _getPlayer(String soundName) {
    if (!_players.containsKey(soundName)) {
      _players[soundName] = AudioPlayer();
      _players[soundName]!.setReleaseMode(ReleaseMode.stop);
      _players[soundName]!.setVolume(0.5);
    }
    return _players[soundName]!;
  }
  
  static Future<void> _playSound(BuildContext context, String soundFile) async {
    try {
      final settings = context.read<SettingsProvider>();
      if (!settings.isSoundEnabled) return;
      
      final player = _getPlayer(soundFile);
      // Don't await, let it play asynchronously for better performance
      player.play(AssetSource('sounds/$soundFile.mp3'), volume: 0.5);
    } catch (e) {
      debugPrint('Audio error ($soundFile): $e');
    }
  }
  
  static Future<void> playClick(BuildContext context) async {
    await _playSound(context, 'click');
  }
  
  static Future<void> playSuccess(BuildContext context) async {
    await _playSound(context, 'success');
  }
  
  static Future<void> playError(BuildContext context) async {
    await _playSound(context, 'error');
  }
  
  static Future<void> playGameOver(BuildContext context) async {
    await _playSound(context, 'game_over');
  }
  
  static Future<void> playScore(BuildContext context) async {
    await _playSound(context, 'score');
  }
  
  static void dispose() {
    for (var player in _players.values) {
      player.dispose();
    }
    _players.clear();
  }
}
