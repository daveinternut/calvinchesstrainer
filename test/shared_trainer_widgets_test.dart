import 'package:calvinchesstrainer/core/audio/audio_service.dart';
import 'package:calvinchesstrainer/core/services/analytics_service.dart';
import 'package:calvinchesstrainer/features/file_rank_trainer/models/file_rank_game_state.dart';
import 'package:calvinchesstrainer/features/file_rank_trainer/providers/file_rank_game_provider.dart';
import 'package:calvinchesstrainer/features/file_rank_trainer/screens/file_rank_game_screen.dart';
import 'package:calvinchesstrainer/features/file_rank_trainer/widgets/streak_counter.dart';
import 'package:calvinchesstrainer/features/file_rank_trainer/widgets/timer_bar.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingAudio implements AudioService {
  final calls = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final symbol = invocation.memberName.toString(); // Symbol("name")
    calls.add(symbol.substring(8, symbol.length - 2));
    return Future<void>.value();
  }
}

class _NoopAnalytics implements AnalyticsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );

double _scaleIn(WidgetTester tester, Type widget) {
  final transition = tester.widget<ScaleTransition>(find.descendant(
    of: find.byType(widget),
    matching: find.byType(ScaleTransition),
  ));
  return transition.scale.value;
}

void main() {
  group('StreakCounter', () {
    testWidgets('the pulse settles back to rest size', (tester) async {
      await tester.pumpWidget(
          _wrap(const StreakCounter(streak: 0, bestStreak: 0)));
      await tester.pumpWidget(
          _wrap(const StreakCounter(streak: 1, bestStreak: 1)));
      await tester.pump(const Duration(milliseconds: 120));
      expect(_scaleIn(tester, StreakCounter), greaterThan(1.0));
      await tester.pumpAndSettle();
      expect(_scaleIn(tester, StreakCounter), 1.0);
    });

    testWidgets('a reset mid-milestone drops the celebration',
        (tester) async {
      await tester.pumpWidget(
          _wrap(const StreakCounter(streak: 4, bestStreak: 4)));
      await tester.pumpWidget(
          _wrap(const StreakCounter(streak: 5, bestStreak: 5)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Nice!'), findsOneWidget);

      await tester.pumpWidget(
          _wrap(const StreakCounter(streak: 0, bestStreak: 5)));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Legendary!'), findsNothing);
      expect(find.text('Nice!'), findsNothing);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Best: 5'), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('TimerBar', () {
    testWidgets('beats once per second, not on every rebuild',
        (tester) async {
      await tester.pumpWidget(_wrap(const TimerBar(remainingSeconds: 6)));
      await tester.pumpWidget(_wrap(const TimerBar(remainingSeconds: 5)));
      await tester.pump(const Duration(milliseconds: 250));
      expect(_scaleIn(tester, TimerBar), greaterThan(1.0));

      // A rebuild with the same second (an answer tapped) must not restart
      // the beat: it finishes on schedule.
      await tester.pumpWidget(_wrap(const TimerBar(remainingSeconds: 5)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_scaleIn(tester, TimerBar), 1.0);

      // The next second beats again.
      await tester.pumpWidget(_wrap(const TimerBar(remainingSeconds: 4)));
      await tester.pump(const Duration(milliseconds: 250));
      expect(_scaleIn(tester, TimerBar), greaterThan(1.0));
      await tester.pumpAndSettle();
    });
  });

  group('MilestoneBanner', () {
    Future<(Rect banner, ProviderContainer container)> reachFiveInARow(
      WidgetTester tester,
      Size size,
      _RecordingAudio audio,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(audio),
          analyticsServiceProvider.overrideWithValue(_NoopAnalytics()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FileRankGameScreen(
            subject: TrainerSubject.files,
            mode: TrainerMode.practice,
          ),
        ),
      ));
      await tester.pump(); // post-frame startGame
      final container = ProviderScope.containerOf(
          tester.element(find.byType(FileRankGameScreen)));
      for (var i = 0; i < 5; i++) {
        container.read(fileRankGameProvider.notifier).handleBoardTap(
            container.read(fileRankGameProvider).currentTargetIndex!, 0);
        await tester.pump(const Duration(milliseconds: 450));
      }
      // Into the banner's hold phase; the next prompt is up.
      await tester.pump(const Duration(milliseconds: 100));
      final banner = tester.getRect(find
          .ancestor(
            of: find.text('5 in a row!'),
            matching: find.byType(Container),
          )
          .first);
      return (banner, container);
    }

    void expectClearOfPrompt(
        WidgetTester tester, Rect banner, ProviderContainer container) {
      final prompt = container.read(fileRankGameProvider).currentPrompt!;
      for (final text in [find.text('Tap file'), find.text(prompt)]) {
        final rect = tester.getRect(text);
        expect(banner.overlaps(rect), isFalse,
            reason: 'banner $banner covers prompt $rect');
      }
    }

    testWidgets('iPad portrait: below the prompt, cheer played once',
        (tester) async {
      final audio = _RecordingAudio();
      final (banner, container) =
          await reachFiveInARow(tester, const Size(820, 1180), audio);
      expectClearOfPrompt(tester, banner, container);
      expect(audio.calls.where((c) => c == 'playMilestone'), hasLength(1));
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('iPad landscape: in the side panel, off the board',
        (tester) async {
      final audio = _RecordingAudio();
      final (banner, container) =
          await reachFiveInARow(tester, const Size(1180, 820), audio);
      expectClearOfPrompt(tester, banner, container);
      final board = tester.getRect(find.byType(Chessboard));
      expect(banner.left, greaterThanOrEqualTo(board.right));
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('phone portrait: below the prompt', (tester) async {
      final audio = _RecordingAudio();
      final (banner, container) =
          await reachFiveInARow(tester, const Size(375, 812), audio);
      expectClearOfPrompt(tester, banner, container);
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
