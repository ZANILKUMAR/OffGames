import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/scores_provider.dart';
import 'core/routes/app_routes.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize providers
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();
  
  final scoresProvider = ScoresProvider();
  await scoresProvider.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: scoresProvider),
      ],
      child: const OffGamesApp(),
    ),
  );
}

class OffGamesApp extends StatelessWidget {
  const OffGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'OffGames',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }
}
