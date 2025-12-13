import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/scores_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_utils.dart';
import '../../shared/widgets/game_scaffold.dart';
import '../../shared/widgets/game_dialogs.dart';

class TapTheDotScreen extends StatefulWidget {
  const TapTheDotScreen({super.key});

  @override
  State<TapTheDotScreen> createState() => _TapTheDotScreenState();
}

class _TapTheDotScreenState extends State<TapTheDotScreen>
    with SingleTickerProviderStateMixin {
  static const int gameDuration = 30; // seconds
  
  double dotX = 0.5;
  double dotY = 0.5;
  double dotSize = 60;
  Timer? gameTimer;
  Timer? dotTimer;
  int score = 0;
  int highScore = 0;
  int timeLeft = gameDuration;
  bool isPlaying = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _loadHighScore();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    dotTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _loadHighScore() {
    highScore = context.read<ScoresProvider>().getHighScore('tap_the_dot');
  }

  void _startGame() {
    score = 0;
    timeLeft = gameDuration;
    isPlaying = true;
    dotSize = 60;
    _moveDot();

    gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        timeLeft--;
        if (timeLeft <= 0) {
          _endGame();
        }
      });
    });

    dotTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (isPlaying) {
        _moveDot();
        // Shrink dot as time passes
        setState(() {
          dotSize = max(30, dotSize - 2);
        });
      }
    });

    setState(() {});
  }

  void _moveDot() {
    final random = Random();
    setState(() {
      dotX = 0.1 + random.nextDouble() * 0.8;
      dotY = 0.1 + random.nextDouble() * 0.8;
    });
  }

  void _onDotTap() {
    if (!isPlaying) return;
    
    HapticUtils.lightImpact(context);
    setState(() {
      score++;
    });
    _moveDot();
  }

  void _endGame() {
    gameTimer?.cancel();
    dotTimer?.cancel();
    isPlaying = false;

    if (score > highScore) {
      highScore = score;
      context.read<ScoresProvider>().updateHighScore('tap_the_dot', score);
    }

    HapticUtils.heavyImpact(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameOverDialog(
        title: 'Time\'s Up!',
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
      title: 'Tap the Dot',
      onRestart: () {
        gameTimer?.cancel();
        dotTimer?.cancel();
        setState(() {
          isPlaying = false;
          score = 0;
          timeLeft = gameDuration;
        });
      },
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildStats(),
          const SizedBox(height: 20),
          Expanded(child: _buildGameArea()),
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
          _buildStatCard('Best', '$highScore', AppColors.gameOrange),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                if (isPlaying)
                  Positioned(
                    left: dotX * constraints.maxWidth - dotSize / 2,
                    top: dotY * constraints.maxHeight - dotSize / 2,
                    child: GestureDetector(
                      onTap: _onDotTap,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1 + _pulseController.value * 0.1,
                            child: Container(
                              width: dotSize,
                              height: dotSize,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.gameRed,
                                    AppColors.gameRed.withOpacity(0.8),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gameRed.withOpacity(0.5),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (!isPlaying)
                  Center(
                    child: Text(
                      'Tap START to begin',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
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
