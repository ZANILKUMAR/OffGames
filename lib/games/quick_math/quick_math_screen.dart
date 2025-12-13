import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/scores_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_utils.dart';
import '../../shared/widgets/game_scaffold.dart';
import '../../shared/widgets/game_dialogs.dart';

class QuickMathScreen extends StatefulWidget {
  const QuickMathScreen({super.key});

  @override
  State<QuickMathScreen> createState() => _QuickMathScreenState();
}

class _QuickMathScreenState extends State<QuickMathScreen> {
  static const int gameDuration = 60;
  static const List<String> operators = ['+', '-', '×'];

  int num1 = 0;
  int num2 = 0;
  String operator = '+';
  int correctAnswer = 0;
  List<int> answers = [];
  Timer? gameTimer;
  int score = 0;
  int highScore = 0;
  int timeLeft = gameDuration;
  bool isPlaying = false;
  int streak = 0;
  int maxStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _generateQuestion();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void _loadHighScore() {
    highScore = context.read<ScoresProvider>().getHighScore('quick_math');
  }

  void _startGame() {
    score = 0;
    timeLeft = gameDuration;
    streak = 0;
    maxStreak = 0;
    isPlaying = true;
    _generateQuestion();

    gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        timeLeft--;
        if (timeLeft <= 0) {
          _endGame();
        }
      });
    });

    setState(() {});
  }

  void _generateQuestion() {
    final random = Random();
    
    // Adjust difficulty based on score
    int maxNum = 10 + (score ~/ 5) * 5;
    maxNum = min(maxNum, 50);

    operator = operators[random.nextInt(operators.length)];
    
    switch (operator) {
      case '+':
        num1 = random.nextInt(maxNum) + 1;
        num2 = random.nextInt(maxNum) + 1;
        correctAnswer = num1 + num2;
        break;
      case '-':
        num1 = random.nextInt(maxNum) + 1;
        num2 = random.nextInt(num1) + 1; // Ensure positive result
        correctAnswer = num1 - num2;
        break;
      case '×':
        num1 = random.nextInt(12) + 1;
        num2 = random.nextInt(12) + 1;
        correctAnswer = num1 * num2;
        break;
    }

    // Generate wrong answers
    Set<int> answerSet = {correctAnswer};
    while (answerSet.length < 4) {
      int wrongAnswer = correctAnswer + random.nextInt(21) - 10;
      if (wrongAnswer != correctAnswer && wrongAnswer >= 0) {
        answerSet.add(wrongAnswer);
      }
    }

    answers = answerSet.toList()..shuffle();
    setState(() {});
  }

  void _onAnswerTap(int answer) {
    if (!isPlaying) return;

    if (answer == correctAnswer) {
      HapticUtils.lightImpact(context);
      streak++;
      maxStreak = max(maxStreak, streak);
      
      // Bonus points for streaks
      int points = 1;
      if (streak >= 5) {
        points = 3;
      } else if (streak >= 3) {
        points = 2;
      }
      
      score += points;
      _generateQuestion();
    } else {
      HapticUtils.mediumImpact(context);
      streak = 0;
      // Time penalty
      timeLeft = max(0, timeLeft - 3);
    }

    setState(() {});
  }

  void _endGame() {
    gameTimer?.cancel();
    isPlaying = false;

    if (score > highScore) {
      highScore = score;
      context.read<ScoresProvider>().updateHighScore('quick_math', score);
    }

    HapticUtils.heavyImpact(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameOverDialog(
        title: 'Time\'s Up!',
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
      title: 'Quick Math',
      onRestart: () {
        gameTimer?.cancel();
        setState(() {
          isPlaying = false;
          score = 0;
          timeLeft = gameDuration;
          streak = 0;
        });
      },
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildStats(),
          const SizedBox(height: 30),
          _buildQuestion(),
          const SizedBox(height: 30),
          _buildAnswerGrid(),
          const Spacer(),
          if (streak >= 3) _buildStreakIndicator(),
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
          _buildStatCard('Best', '$highScore', AppColors.gameOrange),
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

  Widget _buildQuestion() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$num1',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 20),
          Text(
            operator,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 20),
          Text(
            '$num2',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 20),
          const Text(
            '=',
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 20),
          const Text(
            '?',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.gameOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2,
        ),
        itemCount: 4,
        itemBuilder: (context, index) => _buildAnswerButton(answers[index]),
      ),
    );
  }

  Widget _buildAnswerButton(int answer) {
    return GestureDetector(
      onTap: isPlaying ? () => _onAnswerTap(answer) : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(isPlaying ? 1 : 0.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$answer',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.gameOrange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            '$streak streak!',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.gameOrange,
            ),
          ),
          if (streak >= 5) const Text(' (3x)', style: TextStyle(color: AppColors.gameOrange)),
          if (streak >= 3 && streak < 5) const Text(' (2x)', style: TextStyle(color: AppColors.gameOrange)),
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
