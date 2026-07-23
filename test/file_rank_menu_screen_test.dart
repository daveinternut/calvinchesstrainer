import 'package:calvinchesstrainer/features/file_rank_trainer/screens/file_rank_menu_screen.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The notation menu is the entry point for four features. These cover the
/// Piece Value subject specifically — it hands off to Which Side Wins, which
/// has no Explore mode and no Hard Mode.
void main() {
  /// The menu scrolls, so anything below the fold has to be brought into view
  /// before it can be tapped.
  Future<void> tapText(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  /// Pumps the menu behind a router that records where Start pushes to,
  /// instead of building the real game screens.
  Future<List<String>> pumpMenu(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final pushed = <String>[];
    final router = GoRouter(
      initialLocation: '/file-rank-trainer',
      routes: [
        GoRoute(
          path: '/file-rank-trainer',
          builder: (_, __) => const FileRankMenuScreen(),
        ),
        for (final path in const [
          '/file-rank-trainer/game',
          '/move-trainer/game',
          '/letter-trainer/game',
          '/the-pieces/which-side-wins',
        ])
          GoRoute(
            path: path,
            builder: (context, state) {
              pushed.add(state.uri.toString());
              return const Scaffold(body: Text('destination'));
            },
          ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    return pushed;
  }

  testWidgets('offers Piece Value alongside the notation subjects',
      (tester) async {
    await pumpMenu(tester);

    for (final label in const [
      'Files',
      'Ranks',
      'Squares',
      'Letters',
      'Moves',
      'Piece Value',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'missing chip: $label');
    }
  });

  testWidgets('Piece Value drops Explore and Hard Mode, and explains itself',
      (tester) async {
    await pumpMenu(tester);

    // Files (the default) has all three modes plus the Hard Mode toggle.
    expect(find.text('Explore'), findsOneWidget);
    await tapText(tester, 'Practice');
    expect(find.text('HARD MODE'), findsOneWidget);

    await tapText(tester, 'Piece Value');

    expect(find.text('Explore'), findsNothing);
    expect(find.text('HARD MODE'), findsNothing);
    expect(find.text('Which Side Wins?'), findsOneWidget);
    expect(find.text('Build your streak — difficulty increases as you go!'),
        findsOneWidget);
  });

  testWidgets('Piece Value starts Which Side Wins in the chosen mode',
      (tester) async {
    final pushed = await pumpMenu(tester);

    await tapText(tester, 'Piece Value');
    await tapText(tester, 'Start');

    expect(pushed, ['/the-pieces/which-side-wins?mode=practice']);
  });

  testWidgets('Piece Value carries Speed Round through to Which Side Wins',
      (tester) async {
    final pushed = await pumpMenu(tester);

    await tapText(tester, 'Piece Value');
    await tapText(tester, 'Speed Round');
    await tapText(tester, 'Start');

    expect(pushed, ['/the-pieces/which-side-wins?mode=speed']);
  });

  testWidgets('switching from Explore to a quiz-only subject picks Practice',
      (tester) async {
    final pushed = await pumpMenu(tester);

    // Explore is selected by default for Files.
    await tapText(tester, 'Piece Value');
    await tapText(tester, 'Start');

    expect(pushed.single, contains('mode=practice'));
  });
}
