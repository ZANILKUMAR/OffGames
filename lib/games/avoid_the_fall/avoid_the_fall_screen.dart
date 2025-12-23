import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/scores_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_utils.dart';
import '../../shared/widgets/game_scaffold.dart';
import '../../shared/widgets/game_dialogs.dart';

class AvoidTheFallScreen extends StatefulWidget {
  const AvoidTheFallScreen({super.key});

  @override
  State<AvoidTheFallScreen> createState() => _AvoidTheFallScreenState();
}

class _AvoidTheFallScreenState extends State<AvoidTheFallScreen> {
  static const int lanes = 3;

  int currentLane = 1;
  List<Map<String, dynamic>> platforms = [];
  double characterY = 0.2;
  double fallingSpeed = 0.003;
  Timer? gameTimer;
  int score = 0;
  int highScore = 0;
  bool isPlaying = false;
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHighScore();
    });
    _initGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void _loadHighScore() {
    if (mounted) {
      setState(() {
        highScore =
            context.read<ScoresProvider>().getHighScore('avoid_the_fall');
      });
    }
  }

  void _initGame() {
    currentLane = 1;
    platforms = [];
    characterY = 0.15;
    fallingSpeed = 0.003;
    score = 0;
    isPlaying = false;
    gameOver = false;

    // Add initial platforms - only ONE lane per platform row!
    for (int i = 0; i < 6; i++) {
      _addPlatformAt(0.2 + i * 0.15);
    }

    setState(() {});
  }

  void _addPlatformAt(double y) {
    final random = Random();
    // Only ONE or TWO lanes have platforms - forces player to move!
    List<bool> lanePlatforms = List.generate(lanes, (_) => false);

    // Pick 1-2 random lanes to have platforms
    int numPlatforms = random.nextBool() ? 1 : 2;
    List<int> availableLanes = [0, 1, 2];
    availableLanes.shuffle(random);

    for (int i = 0; i < numPlatforms; i++) {
      lanePlatforms[availableLanes[i]] = true;
    }

    platforms.add({
      'y': y,
      'lanes': List<bool>.from(lanePlatforms),
    });
  }

  void _startGame() {
    if (gameOver) {
      _initGame();
    }
    isPlaying = true;

    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _update();
    });

    setState(() {});
  }

  void _update() {
    if (!isPlaying || gameOver) return;

    // Move all platforms UP
    for (int i = platforms.length - 1; i >= 0; i--) {
      platforms[i]['y'] -= fallingSpeed;

      // Remove platforms that go off top of screen
      if (platforms[i]['y'] < -0.05) {
        platforms.removeAt(i);
        score++;

        // Increase difficulty every 10 platforms
        if (score % 10 == 0) {
          fallingSpeed += 0.0003;
          HapticUtils.mediumImpact(context);
        }
      }
    }

    // Add new platforms from bottom when needed
    if (platforms.isEmpty || platforms.last['y'] < 0.85) {
      _addPlatformAt(1.0);
    }

    // Character always falls down
    characterY += 0.004;

    // Check if character lands on a platform
    for (var platform in platforms) {
      double platformY = platform['y'];
      List<bool> platformLanes = List<bool>.from(platform['lanes']);

      // Check if current lane has a platform
      if (currentLane < platformLanes.length && platformLanes[currentLane]) {
        // Character lands if within platform zone
        if (characterY >= platformY - 0.02 && characterY <= platformY + 0.05) {
          // Keep character on platform surface
          characterY = platformY;
          break;
        }
      }
    }

    // Game over if character falls off bottom
    if (characterY > 0.95) {
      _gameOver();
    }

    setState(() {});
  }

  void _moveLeft() {
    if (currentLane > 0 && isPlaying) {
      HapticUtils.lightImpact(context);
      setState(() {
        currentLane--;
      });
    }
  }

  void _moveRight() {
    if (currentLane < lanes - 1 && isPlaying) {
      HapticUtils.lightImpact(context);
      setState(() {
        currentLane++;
      });
    }
  }

  void _gameOver() {
    if (gameOver) return; // Prevent multiple game over calls

    gameTimer?.cancel();
    gameOver = true;
    isPlaying = false;

    bool isNewHighScore = score > highScore;
    if (isNewHighScore) {
      highScore = score;
      context.read<ScoresProvider>().updateHighScore('avoid_the_fall', score);
    }

    HapticUtils.heavyImpact(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameOverDialog(
        title: 'You Fell!',
        score: score,
        highScore: highScore,
        isNewHighScore: isNewHighScore,
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
      title: 'Avoid the Fall',
      onRestart: () {
        gameTimer?.cancel();
        _initGame();
      },
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildStats(),
          const SizedBox(height: 10),
          Expanded(child: _buildGameArea()),
          _buildControls(),
          const SizedBox(height: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          _moveRight();
        } else {
          _moveLeft();
        }
      },
      onTap: () {
        if (!isPlaying) _startGame();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[900]!,
              Colors.purple[900]!,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              double laneWidth = constraints.maxWidth / lanes;
              double gameHeight = constraints.maxHeight;

              // Build platform widgets
              List<Widget> platformWidgets = [];
              for (var platform in platforms) {
                List<bool> lanePlatforms = List<bool>.from(platform['lanes']);
                double y = (platform['y'] as double) * gameHeight;

                // Only render if visible
                if (y > -30 && y < gameHeight + 30) {
                  for (int lane = 0; lane < lanes; lane++) {
                    if (lanePlatforms[lane]) {
                      platformWidgets.add(
                        Positioned(
                          left: lane * laneWidth + 4,
                          top: y,
                          child: Container(
                            width: laneWidth - 8,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.gameGreen,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gameGreen.withOpacity(0.5),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  }
                }
              }

              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Lane dividers
                  ...List.generate(
                      lanes - 1,
                      (i) => Positioned(
                            left: (i + 1) * laneWidth - 1,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 2,
                              color: Colors.white.withOpacity(0.15),
                            ),
                          )),
                  // Platforms
                  ...platformWidgets,
                  // Character
                  Positioned(
                    left: currentLane * laneWidth + laneWidth / 2 - 15,
                    top: characterY * gameHeight - 15,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.gameYellow,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gameYellow.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('😊', style: TextStyle(fontSize: 16)),
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
                              fontWeight: FontWeight.bold),
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

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildControlButton(Icons.arrow_back, _moveLeft),
          Text(
            'Stay on platforms!',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          _buildControlButton(Icons.arrow_forward, _moveRight),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
        ),
        child: Icon(icon, color: AppColors.primary, size: 28),
      ),
    );
  }
}
