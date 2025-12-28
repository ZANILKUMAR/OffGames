import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/scores_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_utils.dart';
import '../../core/utils/audio_utils.dart';
import '../../shared/widgets/game_scaffold.dart';
import '../../shared/widgets/game_dialogs.dart';

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen>
    with SingleTickerProviderStateMixin {
  List<String> board = List.filled(9, '');
  bool isXTurn = true;
  String? winner;
  List<int> winningLine = [];
  int xWins = 0;
  int oWins = 0;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (board[index].isNotEmpty || winner != null) return;

    HapticUtils.lightImpact(context);
    setState(() {
      board[index] = isXTurn ? 'X' : 'O';
      isXTurn = !isXTurn;
      _checkWinner();
    });
  }

  void _checkWinner() {
    const winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6], // Diagonals
    ];

    for (var pattern in winPatterns) {
      if (board[pattern[0]].isNotEmpty &&
          board[pattern[0]] == board[pattern[1]] &&
          board[pattern[1]] == board[pattern[2]]) {
        setState(() {
          winner = board[pattern[0]];
          winningLine = pattern;
          if (winner == 'X') {
            xWins++;
            context.read<ScoresProvider>().updateHighScore('tic_tac_toe', xWins);
          } else {
            oWins++;
          }
        });
        HapticUtils.mediumImpact(context);
        AudioUtils.playSuccess(context);
        _showGameOverDialog();
        return;
      }
    }

    if (!board.contains('')) {
      setState(() {
        winner = 'Draw';
      });
      _showGameOverDialog();
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(
        title: winner == 'Draw' ? 'Draw!' : '$winner Wins!',
        score: winner == 'X' ? xWins : oWins,
        highScore: context.read<ScoresProvider>().getHighScore('tic_tac_toe'),
        onRestart: () {
          Navigator.pop(context);
          _resetGame();
        },
        onHome: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _resetGame() {
    HapticUtils.lightImpact(context);
    setState(() {
      board = List.filled(9, '');
      isXTurn = true;
      winner = null;
      winningLine = [];
    });
  }

  void _resetAll() {
    _resetGame();
    setState(() {
      xWins = 0;
      oWins = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Tic Tac Toe',
      onRestart: _resetAll,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate board size based on available space
          final availableHeight = constraints.maxHeight;
          final availableWidth = constraints.maxWidth;
          final boardSize = (availableWidth < availableHeight 
              ? availableWidth 
              : availableHeight * 0.55).clamp(200.0, 350.0);
          
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(height: 16),
                  _buildScoreBoard(),
                  const SizedBox(height: 16),
                  _buildTurnIndicator(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: boardSize,
                    height: boardSize,
                    child: _buildBoard(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildScoreCard('X', xWins, AppColors.gameBlue, isXTurn && winner == null),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildScoreCard('O', oWins, AppColors.gameRed, !isXTurn && winner == null),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String player, int score, Color color, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? color : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            player,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
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

  Widget _buildTurnIndicator() {
    if (winner != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          winner == 'Draw' ? "It's a Draw!" : '$winner Wins!',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: (isXTurn ? AppColors.gameBlue : AppColors.gameRed).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isXTurn ? 'X' : 'O',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isXTurn ? AppColors.gameBlue : AppColors.gameRed,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "Player's Turn",
            style: TextStyle(
              fontSize: 16,
              color: isXTurn ? AppColors.gameBlue : AppColors.gameRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: 9,
        itemBuilder: (context, index) => _buildCell(index),
      ),
    );
  }

  Widget _buildCell(int index) {
    final isWinningCell = winningLine.contains(index);
    final cellValue = board[index];

    return GestureDetector(
      onTap: () => _handleTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isWinningCell
              ? AppColors.success.withOpacity(0.3)
              : Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2A2A2A)
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isWinningCell
                ? AppColors.success
                : Colors.grey.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: cellValue.isEmpty
                ? const SizedBox.shrink()
                : Text(
                    cellValue,
                    key: ValueKey(cellValue),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: cellValue == 'X'
                          ? AppColors.gameBlue
                          : AppColors.gameRed,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
