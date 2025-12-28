# Adding Sound Files to OffGames

## Overview
The app now has audio support built in, but you need to add actual sound files to make it work properly.

## Steps to Add Sound Files

### 1. Create the sounds directory
Create a folder: `assets/sounds/`

### 2. Add sound files
Add the following audio files (MP3, WAV, or OGG format):
- `click.mp3` - Button clicks and light interactions
- `success.mp3` - High score achievements (bullseye, etc.)
- `error.mp3` - Misses or errors
- `game_over.mp3` - End of game
- `score.mp3` - Scoring points

### 3. Update pubspec.yaml
Add the sounds directory to the assets section:

```yaml
flutter:
  uses-material-design: true
  
  assets:
    - assets/logo.png
    - assets/sounds/
```

### 4. Update audio_utils.dart
Uncomment and update the audio playing code in `lib/core/utils/audio_utils.dart`:

```dart
static Future<void> playSound(BuildContext context, String soundType) async {
  final settings = context.read<SettingsProvider>();
  if (!settings.isSoundEnabled) return;
  
  try {
    await _player.stop(); // Stop any currently playing sound
    await _player.play(AssetSource('sounds/$soundType.mp3'));
  } catch (e) {
    debugPrint('Error playing sound: $e');
  }
}
```

## Sound File Recommendations

### Free Sound Resources
- **Freesound.org** - Large library of free sounds
- **OpenGameArt.org** - Game-specific sounds
- **Zapsplat.com** - Free sound effects (attribution required)

### Sound Characteristics
- **Format**: MP3 (best compatibility) or OGG
- **Duration**: 0.5-2 seconds for effects
- **Quality**: 44.1kHz, 128kbps is sufficient for game sounds
- **Volume**: Normalize all sounds to similar levels

## Testing
After adding sounds:
1. Run `flutter pub get`
2. Test with sound enabled in settings
3. Verify sounds play on different devices
4. Check volume levels are appropriate

## Current Implementation
Without sound files, the app will:
- Still work normally
- Honor sound settings (on/off)
- Only show debug messages in console
- Not play any actual audio

The vibration will work immediately as it doesn't require additional assets.
