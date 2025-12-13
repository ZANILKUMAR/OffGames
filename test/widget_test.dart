// Basic Flutter widget test for OffGames

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:offgames/main.dart';
import 'package:offgames/core/providers/settings_provider.dart';
import 'package:offgames/core/providers/scores_provider.dart';

void main() {
  testWidgets('OffGames app launches correctly', (WidgetTester tester) async {
    // Create providers for testing
    final settingsProvider = SettingsProvider();
    final scoresProvider = ScoresProvider();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settingsProvider),
          ChangeNotifierProvider.value(value: scoresProvider),
        ],
        child: const OffGamesApp(),
      ),
    );

    // Verify that the app title is shown
    expect(find.text('OffGames'), findsOneWidget);
  });
}
