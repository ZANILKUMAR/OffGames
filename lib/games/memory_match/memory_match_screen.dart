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

class MemoryMatchScreen extends StatefulWidget {
  const MemoryMatchScreen({super.key});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen>
    with TickerProviderStateMixin {
  static const List<IconData> icons = [
    Icons.star, Icons.favorite, Icons.bolt, Icons.music_note,
    Icons.emoji_emotions, Icons.local_fire_department, Icons.pets, Icons.cake,
  ];
  
  List<int> cards = [];
  List<bool> revealed = [];
  List<bool> matched = [];
  int? firstIndex;
  int? secondIndex;
  int moves = 0;
  int matches = 0;
  int highScore = 0;
  bool canTap = true;
  late Stopwatch stopwatch;
  Timer? timer;
  String timeString = '00:00';

  @override
  void initState() {
    super.initState();
    stopwatch = Stopwatch();
    _loadHighScore();
    _initGame();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _loadHighScore() {
    highScore = context.read<ScoresProvider>().getHighScore('memory_match');
  }

  void _initGame() {
    cards = List.generate(8, (index) => index);
    cards = [...cards, ...cards];
    cards.shuffle(Random());
    revealed = List.filled(16, false);
    matched = List.filled(16, false);
    firstIndex = null;
    secondIndex = null;
    moves = 0;
    matches = 0;
    canTap = true;
    timeString = '00:00';
    stopwatch.reset();
    timer?.cancel();
    setState(() {});
  }

  void _startTimer() {
    stopwatch.start();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final minutes = stopwatch.elapsed.inMinutes.toString().padLeft(2, '0');
      final seconds = (stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0');
      setState(() {
        timeString = '$minutes:$seconds';
      });
    });
  }

  void _onCardTap(int index) {
    if (!canTap || revealed[index] || matched[index]) return;
    
    if (moves == 0 && firstIndex == null) {
      _startTimer();
    }

    HapticUtils.lightImpact(context);
    AudioUtils.playClick(context);

    setState(() {
      revealed[index] = true;

      if (firstIndex == null) {
        firstIndex = index;
      } else {
        secondIndex = index;
        moves++;
        canTap = false;

        if (cards[firstIndex!] == cards[secondIndex!]) {
          matched[firstIndex!] = true;
          matched[secondIndex!] = true;
          matches++;
          HapticUtils.mediumImpact(context);
          AudioUtils.playSuccess(context);
          
          firstIndex = null;
          secondIndex = null;
          canTap = true;

          if (matches == 8) {
            _onGameComplete();
          }
        } else {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              setState(() {
                revealed[firstIndex!] = false;
                revealed[secondIndex!] = false;
                firstIndex = null;
                secondIndex = null;
                canTap = true;
              });
            }
          });
        }
      }
    });
  }

  void _onGameComplete() {
    stopwatch.stop();
    timer?.cancel();
    
    final score = _calculateScore();
    if (score > highScore) {
      highScore = score;
      context.read<ScoresProvider>().updateHighScore('memory_match', score);
    }

    HapticUtils.heavyImpact(context);
    AudioUtils.playGameOver(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameOverDialog(
        title: 'Completed!',
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

  int _calculateScore() {
    // Higher score for fewer moves and less time
    int timeBonus = max(0, 300 - stopwatch.elapsed.inSeconds);
    int moveBonus = max(0, 200 - (moves * 5));
    return timeBonus + moveBonus + 100;
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Memory Match',
      onRestart: _initGame,
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildStats(),
          const SizedBox(height: 20),
          Expanded(child: _buildGrid()),
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
          _buildStatCard('Time', timeString, Icons.timer_outlined, AppColors.gameBlue),
          _buildStatCard('Moves', '$moves', Icons.touch_app_rounded, AppColors.gameOrange),
          _buildStatCard('Pairs', '$matches/8', Icons.check_circle_outline, AppColors.gameGreen),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: 16,
          itemBuilder: (context, index) => _buildCard(index),
        ),
      ),
    );
  }

  Widget _buildCard(int index) {
    final isRevealed = revealed[index];
    final isMatched = matched[index];
    final cardIcon = icons[cards[index]];
    
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isMatched
              ? AppColors.success.withOpacity(0.3)
              : isRevealed
                  ? AppColors.primary.withOpacity(0.2)
                  : Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2A2A2A)
                      : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMatched
                ? AppColors.success
                : isRevealed
                    ? AppColors.primary
                    : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (!isRevealed && !isMatched)
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isRevealed || isMatched
                ? Icon(
                    cardIcon,
                    key: ValueKey(index),
                    size: 36,
                    color: isMatched ? AppColors.success : AppColors.primary,
                  )
                : Icon(
                    Icons.question_mark_rounded,
                    key: const ValueKey('hidden'),
                    size: 28,
                    color: Colors.grey[400],
                  ),
          ),
        ),
      ),
    );
  }
}
