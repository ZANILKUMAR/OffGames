import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/scores_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_utils.dart';
import '../../core/utils/audio_utils.dart';
import '../../shared/widgets/game_scaffold.dart';
import '../../shared/widgets/game_dialogs.dart';

class FlappyBirdScreen extends StatefulWidget {
  const FlappyBirdScreen({super.key});

  @override
  State<FlappyBirdScreen> createState() => _FlappyBirdScreenState();
}

class _FlappyBirdScreenState extends State<FlappyBirdScreen> {
  static const double gravity = 0.0008;
  static const double jumpVelocity = -0.018;
  static const double pipeSpeed = 0.005;
  static const double pipeGap = 0.28;
  static const double pipeWidth = 0.12;
  static const double birdSize = 0.05;

  double birdY = 0.5;
  double birdVelocity = 0;
  List<Map<String, double>> pipes = [];
  Timer? gameTimer;
  int score = 0;
  int highScore = 0;
  bool isPlaying = false;
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _initGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void _loadHighScore() {
    highScore = context.read<ScoresProvider>().getHighScore('flappy_bird');
  }

  void _initGame() {
    birdY = 0.5;
    birdVelocity = 0;
    pipes = [];
    score = 0;
    isPlaying = false;
    gameOver = false;
    setState(() {});
  }

  void _startGame() {
    if (gameOver) {
      _initGame();
    }
    isPlaying = true;
    _addPipe();
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _update();
    });
    setState(() {});
  }

  void _addPipe() {
    final random = Random();
    double gapTop = 0.2 + random.nextDouble() * 0.4;
    pipes.add({
      'x': 1.2,
      'gapTop': gapTop,
      'passed': 0,
    });
  }

  void _jump() {
    if (!isPlaying) {
      _startGame();
      return;
    }
    if (gameOver) return;

    HapticUtils.lightImpact(context);
    AudioUtils.playClick(context);
    birdVelocity = jumpVelocity;
  }

  void _update() {
    if (!isPlaying || gameOver) return;

    // Apply gravity
    birdVelocity += gravity;
    birdY += birdVelocity;

    // Check bounds (leave space for ground)
    if (birdY <= 0.02 || birdY >= 0.92) {
      _gameOver();
      return;
    }

    // Move pipes
    for (int i = pipes.length - 1; i >= 0; i--) {
      pipes[i]['x'] = pipes[i]['x']! - pipeSpeed;

      // Check collision
      if (_checkCollision(pipes[i])) {
        _gameOver();
        return;
      }

      // Check if passed
      if (pipes[i]['x']! < 0.15 && pipes[i]['passed'] == 0) {
        pipes[i]['passed'] = 1;
        score++;
        HapticUtils.mediumImpact(context);
      }

      // Remove off-screen pipes
      if (pipes[i]['x']! < -pipeWidth) {
        pipes.removeAt(i);
      }
    }

    // Add new pipes
    if (pipes.isEmpty || pipes.last['x']! < 0.6) {
      _addPipe();
    }

    setState(() {});
  }

  bool _checkCollision(Map<String, double> pipe) {
    double pipeX = pipe['x']!;
    double gapTop = pipe['gapTop']! * 0.92; // Account for ground
    double gapBottom = gapTop + pipeGap * 0.92;

    // Bird hitbox (centered at 0.15 horizontally)
    double birdLeft = 0.15 - birdSize / 2;
    double birdRight = 0.15 + birdSize / 2;
    double birdTop = birdY - birdSize / 2;
    double birdBottom = birdY + birdSize / 2;

    // Pipe hitbox
    double pipeLeft = pipeX;
    double pipeRight = pipeX + pipeWidth;

    // Check horizontal overlap
    if (birdRight > pipeLeft && birdLeft < pipeRight) {
      // Check vertical collision (hit top or bottom pipe)
      if (birdTop < gapTop || birdBottom > gapBottom) {
        return true;
      }
    }

    return false;
  }

  void _gameOver() {
    gameTimer?.cancel();
    gameOver = true;
    isPlaying = false;

    if (score > highScore) {
      highScore = score;
      context.read<ScoresProvider>().updateHighScore('flappy_bird', score);
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
          _initGame();
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
      title: 'Flappy Bird',
      onRestart: () {
        gameTimer?.cancel();
        _initGame();
      },
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildScoreBar(),
          const SizedBox(height: 10),
          Expanded(child: _buildGameArea()),
          _buildInstructions(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildScoreBar() {
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    return GestureDetector(
      onTap: _jump,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.lightBlue[300]!,
              Colors.lightBlue[100]!,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              
              return Stack(
                children: [
                  // Ground
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 20,
                    child: Container(
                      color: Colors.green[700],
                    ),
                  ),
                  // Pipes
                  ...pipes.map((pipe) => _buildPipeWidget(pipe, width, height)),
                  // Bird
                  Positioned(
                    left: width * 0.15 - 20,
                    top: birdY * (height - 40),
                    child: Transform.rotate(
                      angle: birdVelocity * 20,
                      child: Container(
                        width: 40,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.gameYellow,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.orange, width: 2),
                        ),
                        child: const Center(
                          child: Text('🐦', style: TextStyle(fontSize: 20)),
                        ),
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
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildPipeWidget(Map<String, double> pipe, double width, double height) {
    final pipeX = pipe['x']! * width;
    final gapTop = pipe['gapTop']! * (height - 20);
    final gapHeight = pipeGap * (height - 20);
    final pipeW = pipeWidth * width;

    return Stack(
      children: [
        // Top pipe
        Positioned(
          left: pipeX,
          top: 0,
          child: Container(
            width: pipeW,
            height: gapTop,
            decoration: BoxDecoration(
              color: Colors.green[600],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border: Border.all(color: Colors.green[800]!, width: 2),
            ),
          ),
        ),
        // Bottom pipe
        Positioned(
          left: pipeX,
          top: gapTop + gapHeight,
          bottom: 20,
          child: Container(
            width: pipeW,
            decoration: BoxDecoration(
              color: Colors.green[600],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border.all(color: Colors.green[800]!, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Text(
        'Tap anywhere to flap and avoid the pipes!',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
    );
  }
}
