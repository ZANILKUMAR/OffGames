import 'package:flutter/material.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/about/about_screen.dart';
import '../../games/tic_tac_toe/tic_tac_toe_screen.dart';
import '../../games/game_2048/game_2048_screen.dart';
import '../../games/memory_match/memory_match_screen.dart';
import '../../games/number_puzzle/number_puzzle_screen.dart';
import '../../games/snake/snake_screen.dart';
import '../../games/brick_breaker/brick_breaker_screen.dart';
import '../../games/flappy_bird/flappy_bird_screen.dart';
import '../../games/car_avoider/car_avoider_screen.dart';
import '../../games/tap_the_dot/tap_the_dot_screen.dart';
import '../../games/color_match/color_match_screen.dart';
import '../../games/whack_a_mole/whack_a_mole_screen.dart';
import '../../games/tower_builder/tower_builder_screen.dart';
import '../../games/ping_pong/ping_pong_screen.dart';
import '../../games/avoid_the_fall/avoid_the_fall_screen.dart';
import '../../games/quick_math/quick_math_screen.dart';
import '../../games/archery/archery_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String settings = '/settings';
  static const String about = '/about';
  static const String ticTacToe = '/tic-tac-toe';
  static const String game2048 = '/2048';
  static const String memoryMatch = '/memory-match';
  static const String numberPuzzle = '/number-puzzle';
  static const String snake = '/snake';
  static const String brickBreaker = '/brick-breaker';
  static const String flappyBird = '/flappy-bird';
  static const String carAvoider = '/car-avoider';
  static const String tapTheDot = '/tap-the-dot';
  static const String colorMatch = '/color-match';
  static const String whackAMole = '/whack-a-mole';
  static const String towerBuilder = '/tower-builder';
  static const String pingPong = '/ping-pong';
  static const String avoidTheFall = '/avoid-the-fall';
  static const String quickMath = '/quick-math';
  static const String archery = '/archery';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _buildRoute(const HomeScreen());
      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen());
      case about:
        return _buildRoute(const AboutScreen());
      case ticTacToe:
        return _buildRoute(const TicTacToeScreen());
      case game2048:
        return _buildRoute(const Game2048Screen());
      case memoryMatch:
        return _buildRoute(const MemoryMatchScreen());
      case numberPuzzle:
        return _buildRoute(const NumberPuzzleScreen());
      case snake:
        return _buildRoute(const SnakeScreen());
      case brickBreaker:
        return _buildRoute(const BrickBreakerScreen());
      case flappyBird:
        return _buildRoute(const FlappyBirdScreen());
      case carAvoider:
        return _buildRoute(const CarAvoiderScreen());
      case tapTheDot:
        return _buildRoute(const TapTheDotScreen());
      case colorMatch:
        return _buildRoute(const ColorMatchScreen());
      case whackAMole:
        return _buildRoute(const WhackAMoleScreen());
      case towerBuilder:
        return _buildRoute(const TowerBuilderScreen());
      case pingPong:
        return _buildRoute(const PingPongScreen());
      case avoidTheFall:
        return _buildRoute(const AvoidTheFallScreen());
      case quickMath:
        return _buildRoute(const QuickMathScreen());
      case archery:
        return _buildRoute(const ArcheryScreen());
      default:
        return _buildRoute(const HomeScreen());
    }
  }

  static PageRouteBuilder _buildRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
