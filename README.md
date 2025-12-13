# OffGames 🎮

A collection of 15 simple, lightweight, fully offline mini-games built with Flutter.

## Features

- ✅ **15 Mini-Games** - Classic and arcade games in one app
- 🌙 **Dark/Light Mode** - Automatic theme switching
- 📴 **Fully Offline** - No internet required
- 📊 **High Score Tracking** - Persistent score storage
- 📳 **Haptic Feedback** - Tactile response on interactions
- 🎨 **Modern UI** - Clean, beautiful design with smooth animations

## Games Included

### Classic Games
1. **Tic Tac Toe** - Classic X and O game vs AI
2. **2048** - Slide and merge numbers
3. **Memory Match** - Find matching card pairs
4. **Number Puzzle** - Sliding tile puzzle (15-puzzle)
5. **Snake** - Classic snake game
6. **Brick Breaker** - Destroy bricks with a bouncing ball

### Arcade Games
7. **Flappy Bird** - Tap to fly through pipes
8. **Car Avoider** - Dodge incoming traffic
9. **Tap the Dot** - Quick reflexes tapping game
10. **Color Match** - Match colors quickly
11. **Whack-A-Mole** - Hit the moles before they hide
12. **Tower Builder** - Stack blocks to build a tower
13. **Ping Pong** - Classic paddle ball game
14. **Avoid the Fall** - Dodge falling obstacles
15. **Quick Math** - Fast arithmetic challenges

## Getting Started

### Prerequisites

- Flutter SDK (3.0+)
- Dart SDK
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/offgames.git
cd offgames
```

2. Get dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Building for Release

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── core/
│   ├── providers/            # State management
│   │   ├── scores_provider.dart
│   │   └── settings_provider.dart
│   ├── routes/
│   │   └── app_routes.dart   # Navigation routes
│   ├── theme/
│   │   ├── app_colors.dart   # Color palette
│   │   └── app_theme.dart    # Light/dark themes
│   └── utils/
│       └── haptic_utils.dart # Haptic feedback utility
├── games/                    # All 15 game screens
│   ├── avoid_the_fall/
│   ├── brick_breaker/
│   ├── car_avoider/
│   ├── color_match/
│   ├── flappy_bird/
│   ├── game_2048/
│   ├── memory_match/
│   ├── number_puzzle/
│   ├── ping_pong/
│   ├── quick_math/
│   ├── snake/
│   ├── tap_the_dot/
│   ├── tic_tac_toe/
│   ├── tower_builder/
│   └── whack_a_mole/
├── screens/
│   ├── about/                # About page
│   ├── home/                 # Home screen with game grid
│   └── settings/             # Settings screen
└── shared/
    └── widgets/              # Reusable components
        ├── game_card.dart
        ├── game_dialogs.dart
        └── game_scaffold.dart
```

## Technologies Used

- **Flutter** - UI Framework
- **Provider** - State Management
- **SharedPreferences** - Local Storage
- **Google Fonts** - Typography

## Package Name

`com.offgames.app`

## License

This project is open source and available under the MIT License.

## Screenshots

(Add screenshots of your app here)

---

Made with ❤️ using Flutter
