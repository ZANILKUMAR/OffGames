# Quick Integration Guide for Other Games

## How to Add Sound & Vibration to Your Games

### 1. Import the Utils

Add these imports to your game screen:
```dart
import '../../core/utils/haptic_utils.dart';
import '../../core/utils/audio_utils.dart';
```

### 2. Common Game Events

#### Button Clicks / UI Interactions
```dart
onPressed: () {
  HapticUtils.lightImpact(context);
  AudioUtils.playClick(context);
  // your logic here
}
```

#### Scoring Points (light)
```dart
// Small score
HapticUtils.lightImpact(context);
AudioUtils.playClick(context);
```

#### Scoring Points (medium)
```dart
// Good score
HapticUtils.mediumImpact(context);
AudioUtils.playScore(context);
```

#### Big Achievement (bullseye, high combo)
```dart
// Excellent score
HapticUtils.heavyImpact(context);
AudioUtils.playSuccess(context);
```

#### Errors / Misses
```dart
// Failed action, game over due to mistake
AudioUtils.playError(context);
```

#### New High Score
```dart
if (isNewHighScore) {
  HapticUtils.vibratePattern(context); // Special pattern
  AudioUtils.playSuccess(context);
}
```

#### Game Over
```dart
void _gameOver() {
  AudioUtils.playGameOver(context);
  // rest of game over logic
}
```

### 3. Pattern Examples

#### Whack-a-Mole Style (rapid feedback)
```dart
void _onMoleHit() {
  HapticUtils.lightImpact(context);
  AudioUtils.playClick(context);
  score++;
}

void _onBombHit() {
  HapticUtils.mediumImpact(context);
  AudioUtils.playError(context);
  lives--;
}
```

#### Ping Pong / Ball Bounce
```dart
void _onBallHit() {
  HapticUtils.lightImpact(context);
  AudioUtils.playClick(context);
  score++;
}

void _onMiss() {
  HapticUtils.heavyImpact(context);
  AudioUtils.playError(context);
}
```

#### Flappy Bird Style
```dart
void _onJump() {
  HapticUtils.lightImpact(context);
  AudioUtils.playClick(context);
}

void _onPipePass() {
  AudioUtils.playScore(context);
  score++;
}

void _onCollision() {
  HapticUtils.heavyImpact(context);
  AudioUtils.playError(context);
  _gameOver();
}
```

#### 2048 / Puzzle Games
```dart
void _onTileMerge(int value) {
  if (value >= 2048) {
    HapticUtils.heavyImpact(context);
    AudioUtils.playSuccess(context);
  } else if (value >= 512) {
    HapticUtils.mediumImpact(context);
    AudioUtils.playScore(context);
  } else {
    HapticUtils.lightImpact(context);
    AudioUtils.playClick(context);
  }
}
```

### 4. Custom Durations

For custom vibration durations:
```dart
// Short vibration (30ms)
HapticUtils.vibrate(context, duration: 30);

// Long vibration (200ms)
HapticUtils.vibrate(context, duration: 200);

// Pattern (advanced)
HapticUtils.vibratePattern(context);
```

### 5. Settings Respect

**Good news!** Both `AudioUtils` and `HapticUtils` automatically check the user's settings. You don't need to manually check `isSoundEnabled` or `isVibrationEnabled`.

```dart
// This already checks settings internally
HapticUtils.lightImpact(context); // Only vibrates if enabled
AudioUtils.playClick(context);     // Only plays if enabled
```

### 6. Performance Tips

- Don't call audio/haptics in rapid loops (>30 times/second)
- For game loops, throttle to important events only
- Use lighter feedback for frequent events
- Save heavier feedback for special moments

### 7. Testing Checklist

Before committing your game:
- [ ] Test with vibration ON
- [ ] Test with vibration OFF
- [ ] Test with sound ON (after adding sound files)
- [ ] Test with sound OFF
- [ ] Verify feedback feels appropriate (not too much/little)
- [ ] Check on both Android and iOS (if possible)

## Summary

**Minimum integration:**
```dart
import '../../core/utils/haptic_utils.dart';
import '../../core/utils/audio_utils.dart';

// On any important game event:
HapticUtils.lightImpact(context);
AudioUtils.playClick(context);
```

That's it! The utils handle everything else.
