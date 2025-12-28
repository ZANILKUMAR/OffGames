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

class WhackAMoleScreen extends StatefulWidget {
  const WhackAMoleScreen({super.key});

  @override
  State<WhackAMoleScreen> createState() => _WhackAMoleScreenState();
}

class _WhackAMoleScreenState extends State<WhackAMoleScreen> {
  static const int gridSize = 9;
  static const int gameDuration = 30;

  List<bool> moles = List.filled(gridSize, false);
  List<bool> bombs = List.filled(gridSize, false);
  Timer? gameTimer;
  Timer? moleTimer;
  int score = 0;
  int highScore = 0;
  int timeLeft = gameDuration;
  bool isPlaying = false;
  int lives = 3;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    moleTimer?.cancel();
    super.dispose();
  }

  void _loadHighScore() {
    highScore = context.read<ScoresProvider>().getHighScore('whack_a_mole');
  }

  void _startGame() {
    score = 0;
    timeLeft = gameDuration;
    lives = 3;
    isPlaying = true;
    moles = List.filled(gridSize, false);
    bombs = List.filled(gridSize, false);

    gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        timeLeft--;
        if (timeLeft <= 0) {
          _endGame();
        }
      });
    });

    moleTimer = Timer.periodic(Duration(milliseconds: 800 - min(score * 10, 400)), (_) {
      if (isPlaying) {
        _spawnMole();
      }
    });

    setState(() {});
  }

  void _spawnMole() {
    final random = Random();
    
    // Hide previous moles
    for (int i = 0; i < gridSize; i++) {
      if (random.nextDouble() < 0.5) {
        moles[i] = false;
        bombs[i] = false;
      }
    }

    // Spawn new mole or bomb
    List<int> emptyHoles = [];
    for (int i = 0; i < gridSize; i++) {
      if (!moles[i] && !bombs[i]) {
        emptyHoles.add(i);
      }
    }

    if (emptyHoles.isNotEmpty) {
      int index = emptyHoles[random.nextInt(emptyHoles.length)];
      if (random.nextDouble() < 0.2) {
        bombs[index] = true;
      } else {
        moles[index] = true;
      }
    }

    setState(() {});
  }

  void _onHoleTap(int index) {
    if (!isPlaying) return;

    if (bombs[index]) {
      HapticUtils.heavyImpact(context);
      AudioUtils.playError(context);
      lives--;
      bombs[index] = false;
      if (lives <= 0) {
        _endGame();
      }
    } else if (moles[index]) {
      HapticUtils.lightImpact(context);
      AudioUtils.playClick(context);
      score++;
      moles[index] = false;
    }

    setState(() {});
  }

  void _endGame() {
    gameTimer?.cancel();
    moleTimer?.cancel();
    isPlaying = false;

    if (score > highScore) {
      highScore = score;
      context.read<ScoresProvider>().updateHighScore('whack_a_mole', score);
    }

    HapticUtils.heavyImpact(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameOverDialog(
        title: lives <= 0 ? 'Boom!' : 'Time\'s Up!',
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
      title: 'Whack-A-Mole',
      onRestart: () {
        gameTimer?.cancel();
        moleTimer?.cancel();
        setState(() {
          isPlaying = false;
          score = 0;
          timeLeft = gameDuration;
          lives = 3;
          moles = List.filled(gridSize, false);
          bombs = List.filled(gridSize, false);
        });
      },
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildStats(),
          const SizedBox(height: 20),
          Expanded(child: _buildGrid()),
          _buildInstructions(),
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
          _buildStatCard('Lives', '$lives', AppColors.gamePink),
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

  Widget _buildGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[300],
            borderRadius: BorderRadius.circular(16),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: gridSize,
            itemBuilder: (context, index) => _buildHole(index),
          ),
        ),
      ),
    );
  }

  Widget _buildHole(int index) {
    bool hasMole = moles[index];
    bool hasBomb = bombs[index];

    return GestureDetector(
      onTap: () => _onHoleTap(index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.brown[700],
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: hasMole
                ? const Text('🐹', key: ValueKey('mole'), style: TextStyle(fontSize: 40))
                : hasBomb
                    ? const Text('💣', key: ValueKey('bomb'), style: TextStyle(fontSize: 36))
                    : Container(
                        key: const ValueKey('empty'),
                        width: 30,
                        height: 15,
                        decoration: BoxDecoration(
                          color: Colors.brown[900],
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Tap the ',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.orange[800],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          Text(
            ' moles, avoid the ',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red, width: 1),
            ),
            child: Icon(Icons.warning, color: Colors.red[600], size: 12),
          ),
          Text(
            ' bombs',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
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
