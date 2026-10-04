import 'package:calvinchesstrainer/core/audio/audio_service.dart';
import 'package:calvinchesstrainer/core/services/analytics_service.dart';
import 'package:calvinchesstrainer/features/drills/models/drill.dart';
import 'package:calvinchesstrainer/features/drills/providers/drill_prefs_provider.dart';
import 'package:calvinchesstrainer/features/drills/providers/warmup_provider.dart';
import 'package:calvinchesstrainer/features/drills/screens/drill_section_screen.dart';
import 'package:calvinchesstrainer/features/file_rank_trainer/models/file_rank_game_state.dart';
import 'package:calvinchesstrainer/features/file_rank_trainer/screens/file_rank_game_screen.dart';
import 'package:calvinchesstrainer/features/home/screens/home_screen.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Home, the section screens (drill setup) and the warm-up hand-off between
/// game screens.
class _SilentAudio implements AudioService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _NoopAnalytics implements AnalyticsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

const _gameRoutes = [
  '/chess-vision/game',
  '/file-rank-trainer/game',
  '/move-trainer/game',
  '/letter-trainer/game',
  '/the-pieces/which-side-wins',
  '/warm-up/done',
  '/chess-vision',
  '/file-rank-trainer',
  '/opening-trainer',
  '/about',
];

/// [home] at '/', behind a router whose other routes record where the
/// screen sends the player instead of building real games.
Future<(ProviderContainer, List<String>)> _pump(
  WidgetTester tester,
  Widget home, {
  Size size = const Size(390, 844),
  Locale? locale,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final pushed = <String>[];
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => home),
    for (final path in _gameRoutes)
      GoRoute(
        path: path,
        builder: (_, state) {
          pushed.add(state.uri.toString());
          return const Scaffold(body: Text('destination'));
        },
      ),
  ]);
  final container = ProviderContainer(overrides: [
    audioServiceProvider.overrideWithValue(_SilentAudio()),
    analyticsServiceProvider.overrideWithValue(_NoopAnalytics()),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  ));
  await tester.pumpAndSettle();
  return (container, pushed);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('Vision section (iPad: list beside the setup panel)', () {
    const ipad = Size(1180, 820);
    const vision = DrillSectionScreen(section: DrillSection.vision);

    testWidgets('lists all eight drills and opens on Find Checks',
        (tester) async {
      await _pump(tester, vision, size: ipad);
      for (final name in const [
        'Find Checks',
        'Find Captures',
        'Hanging Pieces',
        'Forks & Skewers',
        'Knight Sight',
        'Knight Flight',
        'Pawn Attack',
        'Mate in 1',
      ]) {
        expect(find.text(name), findsWidgets, reason: name);
      }
      // The panel shows the selected drill's title too.
      expect(find.text('Find Checks'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a knight cannot pick the knight target', (tester) async {
      final (_, pushed) = await _pump(tester, vision, size: ipad);
      await _tap(tester, find.text('Forks & Skewers'));

      // Piece row first, target row second: both have a 'Knight' option.
      await _tap(tester, find.byTooltip('Knight').last); // target: knight
      await _tap(tester, find.byTooltip('Knight').first); // piece: knight
      await _tap(tester, find.byTooltip('Knight').last); // disabled now
      await _tap(tester, find.text('Start'));

      final uri = Uri.parse(pushed.single);
      expect(uri.queryParameters['piece'], 'knight');
      expect(uri.queryParameters['target'], 'rook');
    });

    testWidgets('each drill keeps its own setup; Timed starts as speed',
        (tester) async {
      final (_, pushed) = await _pump(tester, vision, size: ipad);
      await _tap(tester, find.text('Forks & Skewers'));
      await _tap(tester, find.text('Concentric'));
      // Pawn Attack opens on its own (default) setup, not Forks' Concentric.
      await _tap(tester, find.text('Pawn Attack'));
      expect(find.text('Concentric'), findsNothing);
      await _tap(tester, find.text('Timed'));
      await _tap(tester, find.text('Start'));

      final uri = Uri.parse(pushed.single);
      expect(uri.queryParameters['drill'], 'pawnAttack');
      expect(uri.queryParameters['mode'], 'speed');
    });

    testWidgets('Start remembers the setup for Continue', (tester) async {
      final (container, _) = await _pump(tester, vision, size: ipad);
      await _tap(tester, find.text('Mate in 1'));
      await _tap(tester, find.text('Blitz'));
      await _tap(tester, find.text('Start'));

      final last = container.read(drillPrefsProvider).lastPlayed!;
      expect(last.drill, DrillId.mateInOne);
      expect(last.mode, DrillMode.speed);
    });
  });

  group('Notation section (phone: a sheet per drill)', () {
    const notation = DrillSectionScreen(section: DrillSection.notation);

    testWidgets('Piece Values: no Explore, no Board side; mode carries through',
        (tester) async {
      final (_, pushed) = await _pump(tester, notation);
      await _tap(tester, find.text('Piece Values'));

      expect(find.text('Explore'), findsNothing);
      expect(find.text('Board side'), findsNothing);
      expect(find.text('Build your streak — difficulty increases as you go!'),
          findsOneWidget);
      await _tap(tester, find.text('Speed Round'));
      await _tap(tester, find.text('Start'));
      expect(pushed, ['/the-pieces/which-side-wins?mode=speed']);
    });

    testWidgets('Squares: Black side appears outside Explore', (tester) async {
      final (_, pushed) = await _pump(tester, notation);
      await _tap(tester, find.text('Squares'));

      expect(find.text('Board side'), findsNothing); // Explore by default
      await _tap(tester, find.text('Practice'));
      await _tap(tester, find.text('Black'));
      await _tap(tester, find.text('Start'));
      expect(pushed,
          ['/file-rank-trainer/game?subject=squares&mode=practice&hardMode=true']);
    });

    testWidgets('the setup sheet scrolls to Start in a short landscape window',
        (tester) async {
      for (final size in const [Size(750, 369), Size(568, 320)]) {
        final (_, pushed) = await _pump(tester, notation, size: size);
        await _tap(tester, find.text('Squares'));
        await _tap(tester, find.text('Practice')); // adds the Board side row
        expect(tester.takeException(), isNull, reason: '$size');
        await _tap(tester, find.text('Start'));
        expect(pushed.single, startsWith('/file-rank-trainer/game'),
            reason: '$size');
      }
    });

    for (final locale in const ['de', 'es', 'fr', 'it', 'pt', 'ru', 'ja']) {
      testWidgets('lists and a setup sheet fit a phone in "$locale"',
          (tester) async {
        await _pump(tester, notation, locale: Locale(locale));
        await tester.tap(find.byType(InkWell).at(1)); // first drill row
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _pump(tester, const DrillSectionScreen(section: DrillSection.vision),
            locale: Locale(locale), size: const Size(320, 568));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Home', () {
    testWidgets('Continue suggests a first drill, then resumes the last one',
        (tester) async {
      final (container, pushed) = await _pump(tester, const HomeScreen(),
          size: const Size(1180, 820));
      expect(find.text('Start here'), findsOneWidget);

      container.read(drillPrefsProvider.notifier).recordStart(
            const DrillConfig(drill: DrillId.forksAndSkewers, mode: DrillMode.speed),
          );
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Queen · Rook · Speed Round'), findsOneWidget);

      await _tap(tester, find.byTooltip('Resume Forks & Skewers'));
      expect(pushed.single, contains('drill=forksAndSkewers'));
      expect(pushed.single, contains('mode=speed'));
    });

    testWidgets('Start warm-up opens its first step', (tester) async {
      final (container, pushed) = await _pump(tester, const HomeScreen());
      await _tap(tester, find.text('Start warm-up'));

      expect(container.read(warmupProvider).isActive, isTrue);
      expect(pushed.single, startsWith('/chess-vision/game?drill=findChecks'));
      expect(pushed.single, endsWith('&warmup=1'));
    });

    for (final size in const [Size(1180, 820), Size(820, 1180), Size(320, 568)]) {
      testWidgets('lays out at $size', (tester) async {
        await _pump(tester, const HomeScreen(), size: size);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Warm-up hand-off', () {
    testWidgets('a finished step offers Next, which opens the following step',
        (tester) async {
      late ProviderContainer container;
      final pushed = <String>[];
      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      container = ProviderContainer(overrides: [
        audioServiceProvider.overrideWithValue(_SilentAudio()),
        analyticsServiceProvider.overrideWithValue(_NoopAnalytics()),
      ]);
      addTearDown(container.dispose);
      // Play steps 1-3 off screen; step 4 is the squares round.
      final warmup = container.read(warmupProvider.notifier)..start();
      for (var i = 0; i < 3; i++) {
        warmup.completeStep(5);
      }

      final router = GoRouter(
        initialLocation: '/step',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('home')),
          GoRoute(
            path: '/step',
            builder: (_, _) => const FileRankGameScreen(
              subject: TrainerSubject.squares,
              mode: TrainerMode.speed,
              isHardMode: true,
              warmup: true,
            ),
          ),
          for (final path in _gameRoutes)
            GoRoute(
              path: path,
              builder: (_, state) {
                pushed.add(state.uri.toString());
                return const Scaffold(body: Text('destination'));
              },
            ),
        ],
      );
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ));
      await tester.pump();
      expect(find.text('Warm-up · 4 of 5'), findsOneWidget);

      for (var i = 0; i < 31; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.text('Next: Mate in 1'), findsOneWidget);
      expect(find.text('End warm-up'), findsOneWidget);

      await tester.tap(find.text('Next: Mate in 1'));
      await tester.pumpAndSettle();
      expect(pushed.single, startsWith('/chess-vision/game?drill=mateInOne'));
      expect(pushed.single, endsWith('&warmup=1'));
      final state = container.read(warmupProvider);
      expect(state.index, 4);
      expect(state.scores, hasLength(4));
    });
  });
}
