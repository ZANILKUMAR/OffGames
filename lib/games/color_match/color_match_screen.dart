import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/scores_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_utils.dart';
import '../../shared/widgets/game_scaffold.dart';
import '../../shared/widgets/game_dialogs.dart';

class ColorMatchScreen extends StatefulWidget {
  const ColorMatchScreen({super.key});

  @override
  State<ColorMatchScreen> createState() => _ColorMatchScreenState();
}

class _ColorMatchScreenState extends State<ColorMatchScreen> {
  static const List<Color> colors = [
    AppColors.gameRed,
    AppColors.gameBlue,
    AppColors.gameGreen,
    AppColors.gameYellow,
    AppColors.gamePurple,
    AppColors.gameOrange,
  ];

  static const List<String> colorNames = [
    'Red', 'Blue', 'Green', 'Yellow', 'Purple', 'Orange'
  ];

  static const int gameDuration = 30;

  int displayedColorIndex = 0;
  int targetColorIndex = 0;
  Timer? gameTimer;
  int score = 0;
  int highScore = 0;
  int timeLeft = gameDuration;
  bool isPlaying = false;
  int lives = 3;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _generateNewRound();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void _loadHighScore() {
    highScore = context.read<ScoresProvider>().getHighScore('color_match');
  }

  void _startGame() {
    score = 0;
    timeLeft = gameDuration;
    lives = 3;
    isPlaying = true;
    _generateNewRound();

    gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        timeLeft--;
        if (timeLeft <= 0) {
          _endGame();
        }
      });
    });

    setState(() {});
  }

  void _generateNewRound() {
    final random = Random();
    targetColorIndex = random.nextInt(colors.length);
    // Sometimes the text color matches, sometimes it doesn't
    displayedColorIndex = random.nextBool() 
        ? targetColorIndex 
        : random.nextInt(colors.length);
    setState(() {});
  }

  void _onColorTap(int colorIndex) {
    if (!isPlaying) return;

    bool isCorrect = colorIndex == displayedColorIndex;

    if (isCorrect) {
      HapticUtils.lightImpact(context);
      score++;
    } else {
      HapticUtils.mediumImpact(context);
      lives--;
      if (lives <= 0) {
        _endGame();
        return;
      }
    }

    _generateNewRound();
  }

  void _endGame() {
    gameTimer?.cancel();
    isPlaying = false;

    if (score > highScore) {
      highScore = score;
      context.read<ScoresProvider>().updateHighScore('color_match', score);
    }

    HapticUtils.heavyImpact(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameOverDialog(
        title: lives <= 0 ? 'No Lives Left!' : 'Time\'s Up!',
        score: score,
        highScore: highScore,
        isNewHighScore: score >= highScore,
        onRestart: () {
          Navigator.pop(ctx);
          _startGame();
        },
        onHome: () {
          Navigator.pop(ctx);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Color Match',
      onRestart: () {
        gameTimer?.cancel();
        setState(() {
          isPlaying = false;
          score = 0;
          timeLeft = gameDuration;
          lives = 3;
        });
      },
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildStats(),
          const SizedBox(height: 30),
          _buildColorDisplay(),
          const SizedBox(height: 20),
          Text(
            'Tap the COLOR of the text (not the word!)',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),
          _buildColorButtons(),
          const Spacer(),
          if (!isPlaying) _buildStartButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCard('Time', '$timeLeft s', AppColors.gameRed),
          _buildStatCard('Score', '$score', AppColors.primary),
          _buildStatCard('Lives', '❤️ × $lives', AppColors.gamePink),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildColorDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          colorNames[targetColorIndex],
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: colors[displayedColorIndex],
          ),
        ),
      ),
    );
  }

  Widget _buildColorButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: List.generate(colors.length, (index) {
          return GestureDetector(
            onTap: isPlaying ? () => _onColorTap(index) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors[index],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colors[index].withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  colorNames[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: _startGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('Start Game', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
