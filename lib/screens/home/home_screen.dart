import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/scores_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_utils.dart';
import '../../shared/widgets/game_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scores = context.watch<ScoresProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OffGames',
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Play offline, anytime!',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  settings.isDarkMode
                                      ? Icons.light_mode_rounded
                                      : Icons.dark_mode_rounded,
                                ),
                                onPressed: () {
                                  HapticUtils.lightImpact(context);
                                  settings.toggleDarkMode();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.settings_rounded),
                                onPressed: () {
                                  HapticUtils.lightImpact(context);
                                  Navigator.pushNamed(context, AppRoutes.settings);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Classic Games',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildGameCard(
                      context,
                      'Tic Tac Toe',
                      'Classic X & O',
                      Icons.grid_3x3_rounded,
                      AppColors.gameBlue,
                      AppRoutes.ticTacToe,
                      'tic_tac_toe',
                      scores,
                    ),
                    _buildGameCard(
                      context,
                      '2048',
                      'Slide & merge',
                      Icons.filter_2_rounded,
                      AppColors.gameOrange,
                      AppRoutes.game2048,
                      'game_2048',
                      scores,
                    ),
                    _buildGameCard(
                      context,
                      'Memory Match',
                      'Find pairs',
                      Icons.psychology_rounded,
                      AppColors.gamePurple,
                      AppRoutes.memoryMatch,
                      'memory_match',
                      scores,
                    ),
                    _buildGameCard(
                      context,
                      'Number Puzzle',
                      'Sliding tiles',
                      Icons.apps_rounded,
                      AppColors.gameTeal,
                      AppRoutes.numberPuzzle,
                      'number_puzzle',
                      scores,
                    ),
                    _buildGameCard(
                      context,
                      'Snake',
                      'Eat & grow',
                      Icons.pest_control_rounded,
                      AppColors.gameGreen,
                      AppRoutes.snake,
                      'snake',
                      scores,
                    ),
                    _buildGameCard(
                      context,
                      'Brick Breaker',
                      'Break all bricks',
                      Icons.view_compact_rounded,
                      AppColors.gameRed,
                      AppRoutes.brickBreaker,
                      'brick_breaker',
                      scores,
                    ),
                    _buildGameCard(
                      context,
                      'Flappy Bird',
                      'Tap to fly',
                      Icons.flutter_dash_rounded,
                      AppColors.gameYellow,
                      AppRoutes.flappyBird,
                      'flappy_bird',
                      scores,
                    ),
                    _buildGameCard(
                      context,
                      'Car Avoider',
                      'Dodge obstacles',
                      Icons.directions_car_rounded,
                      AppColors.gamePink,
                      AppRoutes.carAvoider,
                      'car_avoider',
                      scores,
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Mini Games',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildGameCard(
                      context,
                      'Tap the Dot',
                      'Speed reaction',
                      Icons.adjust_rounded,
                      AppColors.gameRed,
                      AppRoutes.tapTheDot,
                      'tap_the_dot',
                      scores,
                    ),
                    _buildGameCard(
                      context,
                      'Color Match',
                      'Match colors fast',
                      Icons.palette_rounded,
                      AppColors.gamePurple,
                      AppRoutes.colorMatch,
                      'color_match',
                      scores,
                    ),
                    _buildGameCard(
                      context,
                      'Whack-A-Mole',
                      'Tap the mole',
                      Icons.pest_control_rodent_rounded,
                      AppColors.gameOrange,
                      AppRoutes.whackAMole,
                      'whack_a_mole',
                      scores,
                    ),
                    _buildGameCard(
                      context,
                      'Tower Builder',
                      'Stack blocks',
                      Icons.stacked_bar_chart_rounded,
                      AppColors.gameBlue,
                      AppRoutes.towerBuilder,
                      'tower_builder',
                      scores,
                    ),
                    _buildGameCard(
                      context,
                      'Ping Pong',
                      'Classic paddle',
                      Icons.sports_tennis_rounded,
                      AppColors.gameGreen,
                      AppRoutes.pingPong,
                      'ping_pong',
                      scores,
                    ),
                    _buildGameCard(
                      context,
                      'Avoid the Fall',
                      'Stay in lanes',
                      Icons.keyboard_double_arrow_down_rounded,
                      AppColors.gameTeal,
                      AppRoutes.avoidTheFall,
                      'avoid_the_fall',
                      scores,
                    ),
                    _buildGameCard(
                      context,
                      'Quick Math',
                      'Solve fast',
                      Icons.calculate_rounded,
                      AppColors.gameYellow,
                      AppRoutes.quickMath,
                      'quick_math',
                      scores,
                    ),
                    _buildGameCard(
                      context,
                      'Archery',
                      'Hit the target',
                      Icons.adjust,
                      AppColors.gameRed,
                      AppRoutes.archery,
                      'archery',
                      scores,
                    ),
                  ]),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    String route,
    String gameId,
    ScoresProvider scores,
  ) {
    return GameCard(
      title: title,
      description: description,
      icon: icon,
      iconColor: color,
      highScore: scores.getHighScore(gameId),
      onTap: () {
        HapticUtils.lightImpact(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}
