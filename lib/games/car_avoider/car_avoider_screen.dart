import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/scores_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_utils.dart';
import '../../shared/widgets/game_scaffold.dart';
import '../../shared/widgets/game_dialogs.dart';

class CarAvoiderScreen extends StatefulWidget {
  const CarAvoiderScreen({super.key});

  @override
  State<CarAvoiderScreen> createState() => _CarAvoiderScreenState();
}

class _CarAvoiderScreenState extends State<CarAvoiderScreen> {
  static const int lanes = 3;
  static const double obstacleSpeed = 0.008;
  
  int currentLane = 1;
  List<Obstacle> obstacles = [];
  Timer? gameTimer;
  int score = 0;
  int highScore = 0;
  bool isPlaying = false;
  bool gameOver = false;
  double speedMultiplier = 1.0;

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
    highScore = context.read<ScoresProvider>().getHighScore('car_avoider');
  }

  void _initGame() {
    currentLane = 1;
    obstacles = [];
    score = 0;
    isPlaying = false;
    gameOver = false;
    speedMultiplier = 1.0;
    setState(() {});
  }

  void _startGame() {
    if (gameOver) {
      _initGame();
    }
    isPlaying = true;
    _addObstacle();
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _update();
    });
    setState(() {});
  }

  void _addObstacle() {
    final random = Random();
    int lane = random.nextInt(lanes);
    obstacles.add(Obstacle(
      lane: lane,
      y: -0.15,
      type: random.nextInt(3),
    ));
  }

  void _update() {
    if (!isPlaying || gameOver) return;

    for (int i = obstacles.length - 1; i >= 0; i--) {
      obstacles[i].y += obstacleSpeed * speedMultiplier;

      if (_checkCollision(obstacles[i])) {
        _gameOver();
        return;
      }

      if (obstacles[i].y > 1.1) {
        obstacles.removeAt(i);
        score++;
        if (score % 10 == 0) {
          speedMultiplier += 0.1;
          HapticUtils.mediumImpact(context);
        }
      }
    }

    if (obstacles.isEmpty || obstacles.last.y > 0.25) {
      if (Random().nextDouble() < 0.08) {
        _addObstacle();
      }
    }

    setState(() {});
  }

  bool _checkCollision(Obstacle obstacle) {
    if (obstacle.lane != currentLane) return false;
    double carY = 0.75;
    double obstacleY = obstacle.y;
    return (obstacleY > carY - 0.1 && obstacleY < carY + 0.1);
  }

  void _gameOver() {
    gameTimer?.cancel();
    gameOver = true;
    isPlaying = false;

    if (score > highScore) {
      highScore = score;
      context.read<ScoresProvider>().updateHighScore('car_avoider', score);
    }

    HapticUtils.heavyImpact(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameOverDialog(
        title: 'Crashed!',
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

  void _moveLeft() {
    if (currentLane > 0) {
      HapticUtils.lightImpact(context);
      setState(() => currentLane--);
    }
  }

  void _moveRight() {
    if (currentLane < lanes - 1) {
      HapticUtils.lightImpact(context);
      setState(() => currentLane++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Car Avoider',
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
          _buildControls(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildScoreBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Score', '$score', AppColors.primary),
          _buildStatCard('Speed', '${speedMultiplier.toStringAsFixed(1)}x', AppColors.gameRed),
          _buildStatCard('Best', '$highScore', AppColors.gameOrange),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
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
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Road background
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: RoadPainter(lanes, score),
                  ),
                  // Obstacles
                  ...obstacles.map((obstacle) => _buildObstacle(obstacle, constraints)),
                  // Player car
                  _buildPlayerCar(constraints),
                  // Start hint
                  if (!isPlaying && !gameOver)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Tap to Start\n\nSwipe or tap arrows\nto change lanes',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
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

  Widget _buildPlayerCar(BoxConstraints constraints) {
    double laneWidth = constraints.maxWidth / lanes;
    double carX = currentLane * laneWidth + laneWidth / 2 - 20;
    
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      left: carX,
      bottom: constraints.maxHeight * 0.15,
      child: Container(
        width: 40,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gameBlue, AppColors.gameBlue.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.gameBlue.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Text('🚗', style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }

  Widget _buildObstacle(Obstacle obstacle, BoxConstraints constraints) {
    double laneWidth = constraints.maxWidth / lanes;
    double obstacleX = obstacle.lane * laneWidth + laneWidth / 2 - 18;
    double obstacleY = obstacle.y * constraints.maxHeight;
    
    List<String> obstacleEmojis = ['🚙', '🚕', '🚌'];
    List<Color> obstacleColors = [
      AppColors.gameRed,
      AppColors.gameYellow,
      AppColors.gameOrange
    ];
    
    return Positioned(
      left: obstacleX,
      top: obstacleY,
      child: Container(
        width: 36,
        height: 50,
        decoration: BoxDecoration(
          color: obstacleColors[obstacle.type % obstacleColors.length],
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            obstacleEmojis[obstacle.type % obstacleEmojis.length],
            style: const TextStyle(fontSize: 20),
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
            'Swipe or tap to move',
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
          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
        ),
        child: Icon(icon, color: AppColors.primary, size: 28),
      ),
    );
  }
}

class Obstacle {
  final int lane;
  double y;
  final int type;

  Obstacle({required this.lane, required this.y, required this.type});
}

class RoadPainter extends CustomPainter {
  final int lanes;
  final int score;

  RoadPainter(this.lanes, this.score);

  @override
  void paint(Canvas canvas, Size size) {
    final laneWidth = size.width / lanes;

    // Draw lane dividers
    final lanePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2;

    for (int i = 1; i < lanes; i++) {
      canvas.drawLine(
        Offset(i * laneWidth, 0),
        Offset(i * laneWidth, size.height),
        lanePaint,
      );
    }

    // Draw dashed road markings
    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const dashHeight = 30.0;
    const dashGap = 50.0;
    final offset = (score * 2) % (dashHeight + dashGap);

    for (int i = 1; i < lanes; i++) {
      final x = i * laneWidth;
      for (double y = -offset; y < size.height; y += dashHeight + dashGap) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y + dashHeight),
          dashPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(RoadPainter oldDelegate) => score != oldDelegate.score;
}
