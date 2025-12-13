import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../../core/providers/scores_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_utils.dart';
import '../../shared/widgets/game_scaffold.dart';
import '../../shared/widgets/game_dialogs.dart';

class ArcheryScreen extends StatefulWidget {
  const ArcheryScreen({super.key});

  @override
  State<ArcheryScreen> createState() => _ArcheryScreenState();
}

class _ArcheryScreenState extends State<ArcheryScreen> with SingleTickerProviderStateMixin {
  bool isPlaying = false;
  int score = 0;
  int arrows = 10;
  double power = 0.0;
  bool isCharging = false;
  List<ArrowHit> hits = [];
  final Random random = Random();
  Timer? _chargingTimer;
  Offset? aimStart;
  Offset? aimCurrent;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _chargingTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      isPlaying = true;
      score = 0;
      arrows = 10;
      power = 0.0;
      isCharging = false;
      hits = [];
      aimStart = null;
      aimCurrent = null;
    });
  }

  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    if (!isPlaying || arrows <= 0) return;
    setState(() {
      aimStart = details.localPosition;
      aimCurrent = details.localPosition;
      isCharging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (!isCharging || aimStart == null) return;
    setState(() {
      aimCurrent = details.localPosition;
      // Calculate power based on drag distance
      final dx = aimCurrent!.dx - aimStart!.dx;
      final dy = aimCurrent!.dy - aimStart!.dy;
      final distance = sqrt(dx * dx + dy * dy);
      power = (distance / 100).clamp(0.0, 1.0);
    });
  }

  void _onPanEnd(DragEndDetails details, BoxConstraints constraints) {
    if (!isCharging || aimStart == null || aimCurrent == null) return;
    
    _shootArrow(constraints);
    
    setState(() {
      isCharging = false;
      aimStart = null;
      aimCurrent = null;
      power = 0.0;
    });
  }

  void _shootArrow(BoxConstraints constraints) {
    if (!isPlaying || aimStart == null || aimCurrent == null) return;

    setState(() {
      arrows--;
    });

    // Calculate aim direction and convert to target coordinates
    // Normalize to target space (-0.5 to 0.5)
    // The center of the game area should map to center of target
    final centerX = constraints.maxWidth / 2;
    final centerY = constraints.maxHeight / 2;
    
    // Calculate where the aim is pointing relative to center
    final targetX = aimStart!.dx - centerX;
    final targetY = aimStart!.dy - centerY;
    
    // Apply power and aim direction
    final powerFactor = power * 0.5 + 0.5; // 0.5 to 1.0
    final aimOffsetX = (targetX / (constraints.maxWidth * 0.4)) * powerFactor;
    final aimOffsetY = (targetY / (constraints.maxHeight * 0.4)) * powerFactor;
    
    // Add slight random variance based on power (high power = more shake)
    final shake = (1.0 - power) * 0.05;
    final offsetX = aimOffsetX + (random.nextDouble() - 0.5) * shake;
    final offsetY = aimOffsetY + (random.nextDouble() - 0.5) * shake;

    final distance = sqrt(offsetX * offsetX + offsetY * offsetY);
    
    int points = _calculatePoints(distance);
    
    setState(() {
      score += points;
      hits.add(ArrowHit(offsetX, offsetY, points));
    });

    final settings = context.read<SettingsProvider>();
    if (settings.isVibrationEnabled && points > 0) {
      if (points >= 100) {
        HapticUtils.heavyImpact(context);
      } else if (points >= 50) {
        HapticUtils.mediumImpact(context);
      } else {
        HapticUtils.lightImpact(context);
      }
    }

    if (arrows == 0) {
      _gameOver();
    }
  }

  int _calculatePoints(double distance) {
    if (distance < 0.05) return 100; // Bullseye
    if (distance < 0.12) return 50;  // Inner ring
    if (distance < 0.20) return 25;  // Middle ring
    if (distance < 0.30) return 10;  // Outer ring
    return 0; // Miss
  }

  void _gameOver() {
    final scoresProvider = context.read<ScoresProvider>();
    final highScore = scoresProvider.getHighScore('archery');
    final isNewHighScore = score > highScore;
    
    if (isNewHighScore) {
      scoresProvider.updateHighScore('archery', score);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameOverDialog(
        title: 'Game Over',
        score: score,
        highScore: isNewHighScore ? score : highScore,
        isNewHighScore: isNewHighScore,
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

    setState(() {
      isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Archery',
      onRestart: isPlaying ? _startGame : null,
      body: Column(
        children: [
          _buildScoreBoard(),
          const SizedBox(height: 16),
          Expanded(
            child: !isPlaying ? _buildStartScreen() : _buildGameArea(),
          ),
          if (isPlaying) _buildControls(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Score', score.toString(), AppColors.gameBlue),
          _buildStatCard('Arrows', arrows.toString(), AppColors.gameRed),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
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

  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.adjust,
            size: 100,
            color: AppColors.gameRed.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Archery Challenge',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Drag from anywhere to aim\nDrag distance = Power\n\n🎯 Bullseye: 100 pts\n🎯 Inner: 50 pts\n🎯 Middle: 25 pts\n🎯 Outer: 10 pts',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Start Game',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onPanStart: (details) => _onPanStart(details, constraints),
            onPanUpdate: (details) => _onPanUpdate(details, constraints),
            onPanEnd: (details) => _onPanEnd(details, constraints),
            child: Stack(
              children: [
                // Target
                _buildTarget(),
                // Arrow hits
                ...hits.map((hit) => _buildArrowHit(hit, constraints)),
                // Aiming line
                if (isCharging && aimStart != null && aimCurrent != null)
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: AimLinePainter(aimStart!, aimCurrent!),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTarget() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(40),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring - white
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
            // 30% region - Blue
            FractionallySizedBox(
              widthFactor: 0.60,
              heightFactor: 0.60,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gameBlue.withOpacity(0.7),
                ),
              ),
            ),
            // 20% region - Red
            FractionallySizedBox(
              widthFactor: 0.40,
              heightFactor: 0.40,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gameRed.withOpacity(0.7),
                ),
              ),
            ),
            // 12% region - Yellow (inner)
            FractionallySizedBox(
              widthFactor: 0.24,
              heightFactor: 0.24,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.yellow,
                ),
              ),
            ),
            // 5% Bullseye - Red center
            FractionallySizedBox(
              widthFactor: 0.10,
              heightFactor: 0.10,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gameRed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrowHit(ArrowHit hit, BoxConstraints parentConstraints) {
    final centerX = parentConstraints.maxWidth / 2;
    final centerY = parentConstraints.maxHeight / 2;
    final targetRadius = (parentConstraints.maxWidth - 80) / 2;
    
    return Positioned(
      left: centerX + (hit.x * targetRadius) - 3,
      top: centerY + (hit.y * targetRadius) - 15,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.brown,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          if (hit.points > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${hit.points}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Power meter
          Container(
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: LinearProgressIndicator(
                value: power,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  power < 0.3
                      ? AppColors.gameGreen
                      : power < 0.7
                          ? AppColors.gameYellow
                          : AppColors.gameRed,
                ),
                minHeight: 30,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isCharging
                ? 'Power: ${(power * 100).toInt()}% - Release to shoot!'
                : 'Drag on target area to aim and shoot',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ArrowHit {
  final double x;
  final double y;
  final int points;

  ArrowHit(this.x, this.y, this.points);
}

class AimLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;

  AimLinePainter(this.start, this.end);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gameRed.withOpacity(0.6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Draw line from start to end
    canvas.drawLine(start, end, paint);

    // Draw circle at start point
    canvas.drawCircle(
      start,
      8,
      Paint()
        ..color = AppColors.gameRed
        ..style = PaintingStyle.fill,
    );

    // Draw arrowhead at end point
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final angle = atan2(dy, dx);
    
    final arrowSize = 15.0;
    final path = Path();
    path.moveTo(end.dx, end.dy);
    path.lineTo(
      end.dx - arrowSize * cos(angle - 0.4),
      end.dy - arrowSize * sin(angle - 0.4),
    );
    path.lineTo(
      end.dx - arrowSize * cos(angle + 0.4),
      end.dy - arrowSize * sin(angle + 0.4),
    );
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.gameRed
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(AimLinePainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.end != end;
  }
}
