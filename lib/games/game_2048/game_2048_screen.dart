import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/scores_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_utils.dart';
import '../../core/utils/audio_utils.dart';
import '../../shared/widgets/game_scaffold.dart';
import '../../shared/widgets/game_dialogs.dart';

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen>
    with TickerProviderStateMixin {
  static const int gridSize = 4;
  List<List<int>> grid = [];
  int score = 0;
  int highScore = 0;
  bool gameOver = false;
  bool hasWon = false;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _startNewGame();
  }

  void _loadHighScore() {
    highScore = context.read<ScoresProvider>().getHighScore('game_2048');
  }

  void _startNewGame() {
    grid = List.generate(gridSize, (_) => List.filled(gridSize, 0));
    score = 0;
    gameOver = false;
    hasWon = false;
    _addRandomTile();
    _addRandomTile();
    setState(() {});
  }

  void _addRandomTile() {
    List<List<int>> emptyTiles = [];
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j] == 0) {
          emptyTiles.add([i, j]);
        }
      }
    }

    if (emptyTiles.isNotEmpty) {
      final random = Random();
      final tile = emptyTiles[random.nextInt(emptyTiles.length)];
      grid[tile[0]][tile[1]] = random.nextInt(10) < 9 ? 2 : 4;
    }
  }

  void _move(String direction) {
    if (gameOver) return;

    bool moved = false;

    switch (direction) {
      case 'up':
        moved = _moveUp();
        break;
      case 'down':
        moved = _moveDown();
        break;
      case 'left':
        moved = _moveLeft();
        break;
      case 'right':
        moved = _moveRight();
        break;
    }

    if (moved) {
      HapticUtils.lightImpact(context);
      AudioUtils.playClick(context);
      _addRandomTile();
      _checkGameState();
      setState(() {});
    }
  }

  bool _moveLeft() {
    bool moved = false;
    for (int i = 0; i < gridSize; i++) {
      List<int> row = grid[i].where((x) => x != 0).toList();
      for (int j = 0; j < row.length - 1; j++) {
        if (row[j] == row[j + 1]) {
          row[j] *= 2;
          score += row[j];
          row[j + 1] = 0;
          moved = true;
        }
      }
      row = row.where((x) => x != 0).toList();
      while (row.length < gridSize) {
        row.add(0);
      }
      if (grid[i].toString() != row.toString()) moved = true;
      grid[i] = row;
    }
    return moved;
  }

  bool _moveRight() {
    bool moved = false;
    for (int i = 0; i < gridSize; i++) {
      List<int> row = grid[i].where((x) => x != 0).toList();
      for (int j = row.length - 1; j > 0; j--) {
        if (row[j] == row[j - 1]) {
          row[j] *= 2;
          score += row[j];
          row[j - 1] = 0;
          moved = true;
        }
      }
      row = row.where((x) => x != 0).toList();
      while (row.length < gridSize) {
        row.insert(0, 0);
      }
      if (grid[i].toString() != row.toString()) moved = true;
      grid[i] = row;
    }
    return moved;
  }

  bool _moveUp() {
    bool moved = false;
    for (int j = 0; j < gridSize; j++) {
      List<int> column = [];
      for (int i = 0; i < gridSize; i++) {
        if (grid[i][j] != 0) column.add(grid[i][j]);
      }
      for (int i = 0; i < column.length - 1; i++) {
        if (column[i] == column[i + 1]) {
          column[i] *= 2;
          score += column[i];
          column[i + 1] = 0;
          moved = true;
        }
      }
      column = column.where((x) => x != 0).toList();
      while (column.length < gridSize) {
        column.add(0);
      }
      for (int i = 0; i < gridSize; i++) {
        if (grid[i][j] != column[i]) moved = true;
        grid[i][j] = column[i];
      }
    }
    return moved;
  }

  bool _moveDown() {
    bool moved = false;
    for (int j = 0; j < gridSize; j++) {
      List<int> column = [];
      for (int i = 0; i < gridSize; i++) {
        if (grid[i][j] != 0) column.add(grid[i][j]);
      }
      for (int i = column.length - 1; i > 0; i--) {
        if (column[i] == column[i - 1]) {
          column[i] *= 2;
          score += column[i];
          column[i - 1] = 0;
          moved = true;
        }
      }
      column = column.where((x) => x != 0).toList();
      while (column.length < gridSize) {
        column.insert(0, 0);
      }
      for (int i = 0; i < gridSize; i++) {
        if (grid[i][j] != column[i]) moved = true;
        grid[i][j] = column[i];
      }
    }
    return moved;
  }

  void _checkGameState() {
    // Check for win
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j] == 2048 && !hasWon) {
          hasWon = true;
        }
      }
    }

    // Update high score
    if (score > highScore) {
      highScore = score;
      context.read<ScoresProvider>().updateHighScore('game_2048', score);
    }

    // Check for game over
    bool hasEmpty = false;
    bool canMerge = false;

    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j] == 0) hasEmpty = true;
        if (j < gridSize - 1 && grid[i][j] == grid[i][j + 1]) canMerge = true;
        if (i < gridSize - 1 && grid[i][j] == grid[i + 1][j]) canMerge = true;
      }
    }

    if (!hasEmpty && !canMerge) {
      gameOver = true;
      HapticUtils.heavyImpact(context);
      AudioUtils.playGameOver(context);
      _showGameOverDialog();
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameOverDialog(
        title: hasWon ? 'You Win!' : 'Game Over',
        score: score,
        highScore: highScore,
        isNewHighScore: score >= highScore,
        onRestart: () {
          Navigator.pop(ctx);
          _startNewGame();
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
      title: '2048',
      onRestart: _startNewGame,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            _move('up');
          } else if (details.primaryVelocity! > 0) {
            _move('down');
          }
        },
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            _move('left');
          } else if (details.primaryVelocity! > 0) {
            _move('right');
          }
        },
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildScoreSection(),
            const SizedBox(height: 20),
            _buildGrid(),
            const SizedBox(height: 20),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreSection() {
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
            '$value',
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

  Widget _buildGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFBBADA0),
        borderRadius: BorderRadius.circular(12),
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
          itemBuilder: (context, index) {
            int row = index ~/ gridSize;
            int col = index % gridSize;
            return _buildTile(grid[row][col]);
          },
        ),
      ),
    );
  }

  Widget _buildTile(int value) {
    Color bgColor = AppColors.tile2048Colors[value] ?? const Color(0xFF3C3A32);
    Color textColor = value <= 4 ? const Color(0xFF776E65) : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: value == 0
            ? null
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontSize: value < 100 ? 36 : (value < 1000 ? 28 : 22),
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
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
        'Swipe to move tiles. Merge same numbers to reach 2048!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
