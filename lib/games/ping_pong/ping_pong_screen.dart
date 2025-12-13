import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/scores_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_utils.dart';
import '../../shared/widgets/game_scaffold.dart';
import '../../shared/widgets/game_dialogs.dart';

class PingPongScreen extends StatefulWidget {
  const PingPongScreen({super.key});

  @override
  State<PingPongScreen> createState() => _PingPongScreenState();
}

class _PingPongScreenState extends State<PingPongScreen> {
  double paddleX = 0.5;
  double ballX = 0.5;
  double ballY = 0.5;
  double ballDX = 0.012;
  double ballDY = 0.012;
  Timer? gameTimer;
  int score = 0;
  int highScore = 0;
  bool isPlaying = false;
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void _loadHighScore() {
    highScore = context.read<ScoresProvider>().getHighScore('ping_pong');
  }

  void _startGame() {
    paddleX = 0.5;
    ballX = 0.5;
    ballY = 0.3;
    ballDX = 0.012;
    ballDY = 0.012;
    score = 0;
    isPlaying = true;
    gameOver = false;

    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _update();
    });

    setState(() {});
  }

  void _update() {
    if (!isPlaying || gameOver) return;

    // Move ball
    ballX += ballDX;
    ballY += ballDY;

    // Wall collision (left/right)
    if (ballX <= 0.02 || ballX >= 0.98) {
      ballDX = -ballDX;
      ballX = ballX.clamp(0.02, 0.98);
      HapticUtils.lightImpact(context);
    }

    // Top wall collision
    if (ballY <= 0.02) {
      ballDY = -ballDY;
      ballY = 0.02;
      HapticUtils.lightImpact(context);
    }

    // Paddle collision
    double paddleTop = 0.88;
    double paddleWidth = 0.25;
    if (ballY >= paddleTop - 0.02 && ballY <= paddleTop + 0.02) {
      if (ballX >= paddleX - paddleWidth / 2 && ballX <= paddleX + paddleWidth / 2) {
        ballDY = -ballDY.abs();
        // Add angle based on where ball hits paddle
        double hitPos = (ballX - paddleX) / (paddleWidth / 2);
        ballDX = hitPos * 0.015;
        score++;
        HapticUtils.mediumImpact(context);
        
        // Increase speed slightly
        if (ballDY.abs() < 0.025) {
          ballDY *= 1.02;
        }
      }
    }

    // Ball out of bounds
    if (ballY > 1) {
      _gameOver();
    }

    setState(() {});
  }

  void _gameOver() {
    gameTimer?.cancel();
    gameOver = true;
    isPlaying = false;

    if (score > highScore) {
      highScore = score;
      context.read<ScoresProvider>().updateHighScore('ping_pong', score);
    }

    HapticUtils.heavyImpact(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameOverDialog(
        title: 'Game Over',
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
      title: 'Ping Pong',
      onRestart: () {
        gameTimer?.cancel();
        setState(() {
          isPlaying = false;
          gameOver = false;
          score = 0;
        });
      },
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildStats(),
          const SizedBox(height: 20),
          Expanded(child: _buildGameArea()),
          _buildInstructions(),
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
          _buildStatCard('Score', '$score', AppColors.primary),
          _buildStatCard('Best', '$highScore', AppColors.gameOrange),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    return GestureDetector(
      onPanUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localX = details.localPosition.dx / box.size.width;
        setState(() {
          paddleX = localX.clamp(0.125, 0.875);
        });
      },
      onTap: () {
        if (!isPlaying) _startGame();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1A1A)
              : Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: LayoutBuilder(
            builder: (context, constraints) {
              double paddleWidth = constraints.maxWidth * 0.25;
              double paddleHeight = 15;
              double ballSize = 15;

              return Stack(
                children: [
                  // Center line
                  Positioned(
                    top: constraints.maxHeight / 2 - 1,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  // Ball
                  Positioned(
                    left: ballX * constraints.maxWidth - ballSize / 2,
                    top: ballY * constraints.maxHeight - ballSize / 2,
                    child: Container(
                      width: ballSize,
                      height: ballSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Paddle
                  Positioned(
                    left: paddleX * constraints.maxWidth - paddleWidth / 2,
                    bottom: constraints.maxHeight * 0.08,
                    child: Container(
                      width: paddleWidth,
                      height: paddleHeight,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Start hint
                  if (!isPlaying && !gameOver)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Tap to Start',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Text(
        'Slide to move the paddle. Keep the ball in play!',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
    );
  }
}
