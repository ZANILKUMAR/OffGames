import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/scores_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_utils.dart';
import '../../shared/widgets/game_scaffold.dart';
import '../../shared/widgets/game_dialogs.dart';

class TowerBuilderScreen extends StatefulWidget {
  const TowerBuilderScreen({super.key});

  @override
  State<TowerBuilderScreen> createState() => _TowerBuilderScreenState();
}

class _TowerBuilderScreenState extends State<TowerBuilderScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> blocks = [];
  double currentBlockX = 0;
  double currentBlockWidth = 0.4;
  bool movingRight = true;
  Timer? gameTimer;
  int score = 0;
  int highScore = 0;
  bool isPlaying = false;
  bool gameOver = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadHighScore();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _loadHighScore() {
    highScore = context.read<ScoresProvider>().getHighScore('tower_builder');
  }

  void _startGame() {
    blocks = [];
    currentBlockX = 0.3;
    currentBlockWidth = 0.4;
    movingRight = true;
    score = 0;
    isPlaying = true;
    gameOver = false;

    // Add base block
    blocks.add({
      'x': 0.3,
      'width': 0.4,
      'color': _getBlockColor(0),
    });

    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _update();
    });

    setState(() {});
  }

  void _update() {
    if (!isPlaying || gameOver) return;

    double speed = 0.008 + (score * 0.0005);
    
    if (movingRight) {
      currentBlockX += speed;
      if (currentBlockX + currentBlockWidth >= 1) {
        movingRight = false;
      }
    } else {
      currentBlockX -= speed;
      if (currentBlockX <= 0) {
        movingRight = true;
      }
    }

    setState(() {});
  }

  void _placeBlock() {
    if (!isPlaying || gameOver) {
      _startGame();
      return;
    }

    HapticUtils.lightImpact(context);

    // Get previous block
    var prevBlock = blocks.last;
    double prevX = prevBlock['x'];
    double prevWidth = prevBlock['width'];

    // Calculate overlap
    double overlapStart = max(currentBlockX, prevX);
    double overlapEnd = min(currentBlockX + currentBlockWidth, prevX + prevWidth);
    double overlapWidth = overlapEnd - overlapStart;

    if (overlapWidth <= 0) {
      // Missed completely
      _gameOver();
      return;
    }

    // Perfect placement bonus
    if ((currentBlockX - prevX).abs() < 0.02) {
      HapticUtils.mediumImpact(context);
      overlapWidth = prevWidth; // Keep full width for perfect placement
      overlapStart = prevX;
    }

    // Add new block
    blocks.add({
      'x': overlapStart,
      'width': overlapWidth,
      'color': _getBlockColor(blocks.length),
    });

    currentBlockX = overlapStart;
    currentBlockWidth = overlapWidth;
    score++;

    setState(() {});
  }

  Color _getBlockColor(int index) {
    List<Color> colors = [
      AppColors.gameRed,
      AppColors.gameOrange,
      AppColors.gameYellow,
      AppColors.gameGreen,
      AppColors.gameBlue,
      AppColors.gamePurple,
      AppColors.gamePink,
      AppColors.gameTeal,
    ];
    return colors[index % colors.length];
  }

  void _gameOver() {
    gameTimer?.cancel();
    gameOver = true;
    isPlaying = false;

    if (score > highScore) {
      highScore = score;
      context.read<ScoresProvider>().updateHighScore('tower_builder', score);
    }

    HapticUtils.heavyImpact(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameOverDialog(
        title: 'Tower Collapsed!',
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
      title: 'Tower Builder',
      onRestart: () {
        gameTimer?.cancel();
        setState(() {
          isPlaying = false;
          gameOver = false;
          blocks = [];
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
          _buildStatCard('Height', '$score', AppColors.primary),
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
      onTap: _placeBlock,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.lightBlue[200]!,
              Colors.lightBlue[400]!,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              double blockHeight = 25;
              double maxVisibleBlocks = constraints.maxHeight / blockHeight;
              int startIndex = max(0, blocks.length - maxVisibleBlocks.floor() + 5);

              return Stack(
                children: [
                  // Ground
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 30,
                    child: Container(color: Colors.brown[400]),
                  ),
                  // Placed blocks
                  ...List.generate(blocks.length - startIndex, (i) {
                    int index = startIndex + i;
                    var block = blocks[index];
                    double bottom = 30 + (index - startIndex) * blockHeight;
                    return Positioned(
                      left: block['x'] * constraints.maxWidth,
                      bottom: bottom,
                      child: Container(
                        width: block['width'] * constraints.maxWidth,
                        height: blockHeight - 2,
                        decoration: BoxDecoration(
                          color: block['color'],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.black26, width: 1),
                        ),
                      ),
                    );
                  }),
                  // Moving block
                  if (isPlaying && !gameOver)
                    Positioned(
                      left: currentBlockX * constraints.maxWidth,
                      bottom: 30 + blocks.length * blockHeight,
                      child: Container(
                        width: currentBlockWidth * constraints.maxWidth,
                        height: blockHeight - 2,
                        decoration: BoxDecoration(
                          color: _getBlockColor(blocks.length),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.black26, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
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
        'Tap to place blocks. Stack them perfectly!',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
    );
  }
}
