import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/scores_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_utils.dart';
import '../../shared/widgets/game_scaffold.dart';
import '../../shared/widgets/game_dialogs.dart';

class BrickBreakerScreen extends StatefulWidget {
  const BrickBreakerScreen({super.key});

  @override
  State<BrickBreakerScreen> createState() => _BrickBreakerScreenState();
}

class _BrickBreakerScreenState extends State<BrickBreakerScreen>
    with SingleTickerProviderStateMixin {
  static const int brickRows = 5;
  static const int brickCols = 8;
  
  double paddleX = 0.5;
  double ballX = 0.5;
  double ballY = 0.7;
  double ballDX = 0.015;
  double ballDY = -0.015;
  
  List<List<bool>> bricks = [];
  Timer? gameTimer;
  int score = 0;
  int highScore = 0;
  int lives = 3;
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
    highScore = context.read<ScoresProvider>().getHighScore('brick_breaker');
  }

  void _initGame() {
    paddleX = 0.5;
    ballX = 0.5;
    ballY = 0.7;
    ballDX = 0.015 * (Random().nextBool() ? 1 : -1);
    ballDY = -0.015;
    bricks = List.generate(brickRows, (_) => List.filled(brickCols, true));
    score = 0;
    lives = 3;
    isPlaying = false;
    gameOver = false;
    setState(() {});
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
    if (!isPlaying) return;

    // Move ball
    ballX += ballDX;
    ballY += ballDY;

    // Wall collision
    if (ballX <= 0 || ballX >= 1) {
      ballDX = -ballDX;
      ballX = ballX.clamp(0.0, 1.0);
    }
    if (ballY <= 0) {
      ballDY = -ballDY;
      ballY = 0;
    }

    // Paddle collision
    double paddleTop = 0.85;
    double paddleWidth = 0.2;
    if (ballY >= paddleTop - 0.02 && ballY <= paddleTop + 0.02) {
      if (ballX >= paddleX - paddleWidth / 2 && ballX <= paddleX + paddleWidth / 2) {
        ballDY = -ballDY.abs();
        // Add angle based on where ball hits paddle
        double hitPos = (ballX - paddleX) / (paddleWidth / 2);
        ballDX = hitPos * 0.02;
        HapticUtils.lightImpact(context);
      }
    }

    // Ball out of bounds
    if (ballY > 1) {
      lives--;
      HapticUtils.mediumImpact(context);
      if (lives <= 0) {
        _gameOver();
      } else {
        ballX = 0.5;
        ballY = 0.7;
        ballDX = 0.015 * (Random().nextBool() ? 1 : -1);
        ballDY = -0.015;
        isPlaying = false;
        gameTimer?.cancel();
      }
    }

    // Brick collision
    double brickHeight = 0.04;
    double brickWidth = 1 / brickCols;
    double brickTop = 0.1;
    
    for (int row = 0; row < brickRows; row++) {
      for (int col = 0; col < brickCols; col++) {
        if (!bricks[row][col]) continue;
        
        double brickX = col * brickWidth;
        double brickY = brickTop + row * brickHeight;
        
        if (ballX >= brickX && ballX <= brickX + brickWidth &&
            ballY >= brickY && ballY <= brickY + brickHeight) {
          bricks[row][col] = false;
          ballDY = -ballDY;
          score += 10;
          HapticUtils.lightImpact(context);
          
          if (_allBricksDestroyed()) {
            _gameWon();
            return;
          }
        }
      }
    }

    setState(() {});
  }

  bool _allBricksDestroyed() {
    for (var row in bricks) {
      for (var brick in row) {
        if (brick) return false;
      }
    }
    return true;
  }

  void _gameWon() {
    gameTimer?.cancel();
    isPlaying = false;
    score += lives * 50; // Bonus for remaining lives
    _updateHighScore();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameOverDialog(
        title: 'You Win!',
        score: score,
        highScore: highScore,
        isNewHighScore: score >= highScore,
        onRestart: () {
          Navigator.pop(ctx);
          _initGame();
        },
        onHome: () {
          Navigator.pop(ctx);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _gameOver() {
    gameTimer?.cancel();
    isPlaying = false;
    gameOver = true;
    _updateHighScore();
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
        },
        onHome: () {
          Navigator.pop(ctx);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _updateHighScore() {
    if (score > highScore) {
      highScore = score;
      context.read<ScoresProvider>().updateHighScore('brick_breaker', score);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Brick Breaker',
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
          if (!isPlaying && !gameOver) _buildStartButton(),
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
          _buildStatCard('Score', '$score', AppColors.primary),
          _buildStatCard('Lives', '❤️ × $lives', AppColors.gameRed),
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
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
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
          paddleX = localX.clamp(0.1, 0.9);
        });
      },
      child: Container(
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
          child: CustomPaint(
            painter: BrickBreakerPainter(
              paddleX: paddleX,
              ballX: ballX,
              ballY: ballY,
              bricks: bricks,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
            child: Container(),
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
        child: Text(
          lives < 3 ? 'Continue' : 'Start Game',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class BrickBreakerPainter extends CustomPainter {
  final double paddleX;
  final double ballX;
  final double ballY;
  final List<List<bool>> bricks;
  final bool isDark;

  static const List<Color> brickColors = [
    AppColors.gameRed,
    AppColors.gameOrange,
    AppColors.gameYellow,
    AppColors.gameGreen,
    AppColors.gameBlue,
  ];

  BrickBreakerPainter({
    required this.paddleX,
    required this.ballX,
    required this.ballY,
    required this.bricks,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw bricks
    double brickHeight = size.height * 0.04;
    double brickWidth = size.width / bricks[0].length;
    double brickTop = size.height * 0.1;

    for (int row = 0; row < bricks.length; row++) {
      for (int col = 0; col < bricks[row].length; col++) {
        if (!bricks[row][col]) continue;
        
        final paint = Paint()..color = brickColors[row % brickColors.length];
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            col * brickWidth + 2,
            brickTop + row * brickHeight + 2,
            brickWidth - 4,
            brickHeight - 4,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(rect, paint);
      }
    }

    // Draw paddle
    final paddlePaint = Paint()..color = AppColors.primary;
    double paddleWidth = size.width * 0.2;
    double paddleHeight = size.height * 0.02;
    double paddleTop = size.height * 0.85;
    
    final paddleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        paddleX * size.width - paddleWidth / 2,
        paddleTop,
        paddleWidth,
        paddleHeight,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(paddleRect, paddlePaint);

    // Draw ball
    final ballPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(ballX * size.width, ballY * size.height),
      8,
      ballPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
