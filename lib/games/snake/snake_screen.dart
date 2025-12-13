import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/scores_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_utils.dart';
import '../../shared/widgets/game_scaffold.dart';
import '../../shared/widgets/game_dialogs.dart';

enum Direction { up, down, left, right }

class SnakeScreen extends StatefulWidget {
  const SnakeScreen({super.key});

  @override
  State<SnakeScreen> createState() => _SnakeScreenState();
}

class _SnakeScreenState extends State<SnakeScreen> {
  static const int rows = 20;
  static const int cols = 15;
  static const int initialLength = 3;
  
  List<Point<int>> snake = [];
  Point<int>? food;
  Direction direction = Direction.right;
  Direction nextDirection = Direction.right;
  Timer? gameTimer;
  int score = 0;
  int highScore = 0;
  bool isPlaying = false;
  bool gameOver = false;
  bool isPaused = false;

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
    highScore = context.read<ScoresProvider>().getHighScore('snake');
  }

  void _initGame() {
    snake = [];
    // Initialize snake horizontally - head at right, tail at left
    for (int i = 0; i < initialLength; i++) {
      snake.add(Point(cols ~/ 2 - i, rows ~/ 2));
    }
    direction = Direction.right;
    nextDirection = Direction.right;
    score = 0;
    isPlaying = false;
    gameOver = false;
    isPaused = false;
    _spawnFood();
    setState(() {});
  }

  void _spawnFood() {
    final random = Random();
    Point<int> newFood;
    do {
      newFood = Point(random.nextInt(cols), random.nextInt(rows));
    } while (snake.contains(newFood));
    food = newFood;
  }

  void _startGame() {
    if (gameOver) {
      _initGame();
    }
    isPlaying = true;
    isPaused = false;
    gameTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      _update();
    });
    setState(() {});
  }

  void _pauseGame() {
    isPaused = true;
    gameTimer?.cancel();
    setState(() {});
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PauseDialog(
        onResume: () {
          Navigator.pop(ctx);
          _resumeGame();
        },
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

  void _resumeGame() {
    isPaused = false;
    gameTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      _update();
    });
    setState(() {});
  }

  void _update() {
    if (!isPlaying || isPaused) return;

    direction = nextDirection;

    Point<int> head = snake.first;
    Point<int> newHead;

    switch (direction) {
      case Direction.up:
        newHead = Point(head.x, head.y - 1);
        break;
      case Direction.down:
        newHead = Point(head.x, head.y + 1);
        break;
      case Direction.left:
        newHead = Point(head.x - 1, head.y);
        break;
      case Direction.right:
        newHead = Point(head.x + 1, head.y);
        break;
    }

    // Check collision with walls
    if (newHead.x < 0 || newHead.x >= cols || newHead.y < 0 || newHead.y >= rows) {
      _gameOver();
      return;
    }

    // Check collision with self
    if (snake.contains(newHead)) {
      _gameOver();
      return;
    }

    snake.insert(0, newHead);

    // Check if food eaten
    if (newHead == food) {
      score += 10;
      HapticUtils.mediumImpact(context);
      _spawnFood();
    } else {
      snake.removeLast();
    }

    setState(() {});
  }

  void _gameOver() {
    gameTimer?.cancel();
    gameOver = true;
    isPlaying = false;

    if (score > highScore) {
      highScore = score;
      context.read<ScoresProvider>().updateHighScore('snake', score);
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

  void _changeDirection(Direction newDir) {
    if (!isPlaying || isPaused) return;

    // Prevent reversing
    if ((direction == Direction.up && newDir == Direction.down) ||
        (direction == Direction.down && newDir == Direction.up) ||
        (direction == Direction.left && newDir == Direction.right) ||
        (direction == Direction.right && newDir == Direction.left)) {
      return;
    }

    HapticUtils.lightImpact(context);
    nextDirection = newDir;
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Snake',
      onRestart: () {
        gameTimer?.cancel();
        _initGame();
      },
      onPause: isPlaying && !gameOver ? _pauseGame : null,
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildScoreBar(),
          const SizedBox(height: 10),
          Expanded(child: _buildGameArea()),
          if (!isPlaying && !gameOver) _buildStartButton(),
          _buildControls(),
          const SizedBox(height: 10),
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
          _buildScoreCard('Score', score, AppColors.primary),
          _buildScoreCard('Best', highScore, AppColors.gameOrange),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String label, int value, Color color) {
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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
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
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 0) {
              _changeDirection(Direction.down);
            } else if (details.delta.dy < 0) {
              _changeDirection(Direction.up);
            }
          },
          onHorizontalDragUpdate: (details) {
            if (details.delta.dx > 0) {
              _changeDirection(Direction.right);
            } else if (details.delta.dx < 0) {
              _changeDirection(Direction.left);
            }
          },
          child: AspectRatio(
            aspectRatio: cols / rows,
            child: CustomPaint(
              painter: SnakePainter(
                snake: snake,
                food: food,
                cols: cols,
                rows: rows,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Start Game',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildControlButton(Icons.arrow_upward, () => _changeDirection(Direction.up)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(Icons.arrow_back, () => _changeDirection(Direction.left)),
              const SizedBox(width: 64),
              _buildControlButton(Icons.arrow_forward, () => _changeDirection(Direction.right)),
            ],
          ),
          _buildControlButton(Icons.arrow_downward, () => _changeDirection(Direction.down)),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Icon(icon, color: AppColors.primary, size: 28),
      ),
    );
  }
}

class SnakePainter extends CustomPainter {
  final List<Point<int>> snake;
  final Point<int>? food;
  final int cols;
  final int rows;
  final bool isDark;

  SnakePainter({
    required this.snake,
    required this.food,
    required this.cols,
    required this.rows,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;

    // Draw grid
    final gridPaint = Paint()
      ..color = isDark ? Colors.grey[800]! : Colors.grey[300]!
      ..strokeWidth = 0.5;

    for (int i = 0; i <= cols; i++) {
      canvas.drawLine(
        Offset(i * cellWidth, 0),
        Offset(i * cellWidth, size.height),
        gridPaint,
      );
    }
    for (int i = 0; i <= rows; i++) {
      canvas.drawLine(
        Offset(0, i * cellHeight),
        Offset(size.width, i * cellHeight),
        gridPaint,
      );
    }

    // Draw food
    if (food != null) {
      final foodPaint = Paint()..color = AppColors.gameRed;
      canvas.drawCircle(
        Offset(food!.x * cellWidth + cellWidth / 2, food!.y * cellHeight + cellHeight / 2),
        min(cellWidth, cellHeight) * 0.4,
        foodPaint,
      );
    }

    // Draw snake
    for (int i = 0; i < snake.length; i++) {
      final point = snake[i];
      final isHead = i == 0;
      
      final snakePaint = Paint()
        ..color = isHead ? AppColors.gameGreen : AppColors.gameGreen.withOpacity(0.7);
      
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          point.x * cellWidth + 1,
          point.y * cellHeight + 1,
          cellWidth - 2,
          cellHeight - 2,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, snakePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
