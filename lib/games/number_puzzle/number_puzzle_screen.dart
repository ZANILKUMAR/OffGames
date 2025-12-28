import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/scores_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_utils.dart';
import '../../core/utils/audio_utils.dart';
import '../../shared/widgets/game_scaffold.dart';
import '../../shared/widgets/game_dialogs.dart';

class NumberPuzzleScreen extends StatefulWidget {
  const NumberPuzzleScreen({super.key});

  @override
  State<NumberPuzzleScreen> createState() => _NumberPuzzleScreenState();
}

class _NumberPuzzleScreenState extends State<NumberPuzzleScreen> {
  static const int gridSize = 4;
  List<int> tiles = [];
  int moves = 0;
  int highScore = 0;
  bool gameWon = false;
  late Stopwatch stopwatch;
  String timeString = '00:00';

  @override
  void initState() {
    super.initState();
    stopwatch = Stopwatch();
    _loadHighScore();
    _initGame();
  }

  void _loadHighScore() {
    highScore = context.read<ScoresProvider>().getHighScore('number_puzzle');
  }

  void _initGame() {
    tiles = List.generate(gridSize * gridSize - 1, (i) => i + 1);
    tiles.add(0); // Empty tile
    _shuffleTiles();
    moves = 0;
    gameWon = false;
    timeString = '00:00';
    stopwatch.reset();
    setState(() {});
  }

  void _shuffleTiles() {
    final random = Random();
    do {
      for (int i = tiles.length - 1; i > 0; i--) {
        int j = random.nextInt(i + 1);
        int temp = tiles[i];
        tiles[i] = tiles[j];
        tiles[j] = temp;
      }
    } while (!_isSolvable() || _isWon());
  }

  bool _isSolvable() {
    int inversions = 0;
    for (int i = 0; i < tiles.length; i++) {
      for (int j = i + 1; j < tiles.length; j++) {
        if (tiles[i] != 0 && tiles[j] != 0 && tiles[i] > tiles[j]) {
          inversions++;
        }
      }
    }
    
    int emptyRow = tiles.indexOf(0) ~/ gridSize;
    
    if (gridSize % 2 == 1) {
      return inversions % 2 == 0;
    } else {
      return (inversions + emptyRow) % 2 == 1;
    }
  }

  bool _isWon() {
    for (int i = 0; i < tiles.length - 1; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return tiles.last == 0;
  }

  void _onTileTap(int index) {
    if (gameWon) return;

    int emptyIndex = tiles.indexOf(0);
    
    if (!_isAdjacent(index, emptyIndex)) return;
    
    if (moves == 0) {
      stopwatch.start();
    }

    HapticUtils.lightImpact(context);
    AudioUtils.playClick(context);

    setState(() {
      tiles[emptyIndex] = tiles[index];
      tiles[index] = 0;
      moves++;
    });

    if (_isWon()) {
      _onGameWon();
    }
  }

  bool _isAdjacent(int index1, int index2) {
    int row1 = index1 ~/ gridSize;
    int col1 = index1 % gridSize;
    int row2 = index2 ~/ gridSize;
    int col2 = index2 % gridSize;
    
    return (row1 == row2 && (col1 - col2).abs() == 1) ||
           (col1 == col2 && (row1 - row2).abs() == 1);
  }

  void _onGameWon() {
    stopwatch.stop();
    gameWon = true;
    
    int score = _calculateScore();
    if (highScore == 0 || score < highScore) {
      highScore = score;
      context.read<ScoresProvider>().updateHighScore('number_puzzle', score);
    }

    HapticUtils.heavyImpact(context);
    AudioUtils.playGameOver(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameOverDialog(
        title: 'Puzzle Solved!',
        score: moves,
        highScore: highScore,
        isNewHighScore: moves <= highScore || highScore == 0,
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

  int _calculateScore() {
    return moves;
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Number Puzzle',
      onRestart: _initGame,
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildStats(),
          const Spacer(),
          _buildPuzzle(),
          const Spacer(),
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
          _buildStatCard('Moves', '$moves', AppColors.primary),
          _buildStatCard('Best', highScore > 0 ? '$highScore' : '-', AppColors.gameOrange),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: 16,
          itemBuilder: (context, index) => _buildTile(index),
        ),
      ),
    );
  }

  Widget _buildTile(int index) {
    int value = tiles[index];
    bool isEmpty = value == 0;
    bool isCorrect = value == index + 1;

    return GestureDetector(
      onTap: isEmpty ? null : () => _onTileTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isEmpty
              ? Colors.transparent
              : isCorrect
                  ? AppColors.success.withOpacity(0.2)
                  : AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          border: isEmpty
              ? null
              : Border.all(
                  color: isCorrect ? AppColors.success : AppColors.primary,
                  width: 2,
                ),
          boxShadow: isEmpty
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: isEmpty
            ? null
            : Center(
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? AppColors.success : Colors.white,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        'Tap tiles to slide them. Arrange numbers 1-15 in order!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
