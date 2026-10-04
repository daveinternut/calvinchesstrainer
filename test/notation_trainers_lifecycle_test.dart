import 'dart:io';
import 'dart:math';

import 'package:calvinchesstrainer/core/audio/audio_service.dart';
import 'package:calvinchesstrainer/core/services/analytics_service.dart';
import 'package:calvinchesstrainer/core/services/personal_bests_service.dart';
import 'package:calvinchesstrainer/core/services/puzzle_service.dart';
import 'package:calvinchesstrainer/features/file_rank_trainer/models/file_rank_game_state.dart';
import 'package:calvinchesstrainer/features/file_rank_trainer/providers/file_rank_game_provider.dart';
import 'package:calvinchesstrainer/features/file_rank_trainer/screens/file_rank_game_screen.dart';
import 'package:calvinchesstrainer/features/letter_trainer/models/letter_game_state.dart';
import 'package:calvinchesstrainer/features/letter_trainer/providers/letter_game_provider.dart';
import 'package:calvinchesstrainer/features/letter_trainer/screens/letter_game_screen.dart';
import 'package:calvinchesstrainer/features/move_trainer/models/move_game_state.dart';
import 'package:calvinchesstrainer/features/move_trainer/providers/move_game_provider.dart';
import 'package:calvinchesstrainer/features/move_trainer/screens/move_game_screen.dart';
import 'package:calvinchesstrainer/features/pieces/models/which_side_wins_state.dart';
import 'package:calvinchesstrainer/features/pieces/providers/which_side_wins_provider.dart';
import 'package:calvinchesstrainer/features/pieces/screens/which_side_wins_screen.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _RecordingAudio implements AudioService {
  final calls = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(_name(invocation));
    return Future<void>.value();
  }
}

class _RecordingAnalytics implements AnalyticsService {
  final calls = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(_name(invocation));
    return null;
  }
}

String _name(Invocation invocation) {
  final symbol = invocation.memberName.toString(); // Symbol("name")
  return symbol.substring(8, symbol.length - 2);
}

/// One trainer, as the leave-mid-round test drives it.
class _Trainer {
  const _Trainer(this.name, this.screen, this.answerCorrectly);

  final String name;
  final Widget Function() screen;

  /// Answers the current question correctly through the notifier.
  final void Function(ProviderContainer container) answerCorrectly;
}

final _trainers = [
  _Trainer(
    'file/rank',
    () => const FileRankGameScreen(
      subject: TrainerSubject.files,
      mode: TrainerMode.speed,
    ),
    (c) => c
        .read(fileRankGameProvider.notifier)
        .handleBoardTap(c.read(fileRankGameProvider).currentTargetIndex!, 0),
  ),
  _Trainer(
    'letters',
    () => const LetterGameScreen(mode: LetterTrainerMode.speed),
    (c) => c
        .read(letterGameProvider.notifier)
        .handleAnswer(c.read(letterGameProvider).currentQuestion!.target),
  ),
  _Trainer(
    'which side wins',
    () => const WhichSideWinsScreen(mode: WhichSideWinsMode.speed),
    (c) => c
        .read(whichSideWinsProvider.notifier)
        .handleAnswer(c.read(whichSideWinsProvider).currentPuzzle!.correctSide),
  ),
  _Trainer(
    'moves',
    () => const MoveGameScreen(mode: MoveTrainerMode.speed),
    (c) => c.read(moveGameProvider.notifier).handleMove(
        c.read(moveGameProvider).currentPuzzle!.expectedMove),
  ),
];

void main() {
  late _RecordingAudio audio;
  late _RecordingAnalytics analytics;

  setUp(() {
    audio = _RecordingAudio();
    analytics = _RecordingAnalytics();
  });

  List<Object> overrides() => [
        audioServiceProvider.overrideWithValue(audio),
        analyticsServiceProvider.overrideWithValue(analytics),
        puzzleServiceProvider.overrideWithValue(
          PuzzleService(random: Random(2))
            ..loadFromJson(
              File('assets/puzzles/moves_puzzles.json').readAsStringSync(),
            ),
        ),
      ];

  group('leaving mid speed-round ends the round', () {
    for (final trainer in _trainers) {
      testWidgets(trainer.name, (tester) async {
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const Scaffold(body: Text('home')),
            ),
            GoRoute(path: '/game', builder: (_, __) => trainer.screen()),
          ],
        );
        await tester.pumpWidget(ProviderScope(
          overrides: overrides().cast(),
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ));
        router.push('/game');
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(
          tester.element(find.text('home', skipOffstage: false)),
        );

        // One right answer: a first round's score would be a "record".
        trainer.answerCorrectly(container);
        await tester.pump();

        router.pop();
        await tester.pumpAndSettle();
        final audioAtLeave = audio.calls.length;
        final analyticsAtLeave = analytics.calls.length;

        await tester.pump(const Duration(seconds: 40));

        expect(audio.calls.sublist(audioAtLeave), isEmpty,
            reason: 'no late prompt, game-over buzz or new-record cheer');
        expect(analytics.calls.sublist(analyticsAtLeave), isEmpty,
            reason: 'an abandoned round is not a completed drill');
        expect(container.read(personalBestsProvider), isEmpty,
            reason: 'an abandoned round sets no personal best');
      });
    }
  });

  group('new-record flag', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(overrides: overrides().cast());
      addTearDown(container.dispose);
    });

    Future<void> playSpeedRound(
      WidgetTester tester, {
      required int correctAnswers,
    }) async {
      final notifier = container.read(fileRankGameProvider.notifier);
      notifier.startGame(TrainerSubject.files, TrainerMode.speed);
      expect(container.read(fileRankGameProvider).isNewRecord, isFalse);
      for (var i = 0; i < correctAnswers; i++) {
        notifier.handleBoardTap(
          container.read(fileRankGameProvider).currentTargetIndex!,
          0,
        );
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.pump(const Duration(seconds: 31));
      expect(container.read(fileRankGameProvider).isGameOver, isTrue);
    }

    testWidgets('is set by a new best, reset by the next round, '
        'and not set by a lower score', (tester) async {
      final sub = container.listen(fileRankGameProvider, (_, __) {});
      addTearDown(sub.close);
      final bests = container.read(personalBestsProvider.notifier);

      await playSpeedRound(tester, correctAnswers: 3);
      expect(container.read(fileRankGameProvider).isNewRecord, isTrue);
      expect(bests.best('fileRank.files_speed_false'), 3);
      expect(audio.calls.where((c) => c == 'playNewRecord'), hasLength(1));

      await playSpeedRound(tester, correctAnswers: 2);
      expect(container.read(fileRankGameProvider).isNewRecord, isFalse);
      expect(bests.best('fileRank.files_speed_false'), 3);
      expect(audio.calls.where((c) => c == 'playNewRecord'), hasLength(1));
      expect(
        analytics.calls.where((c) => c == 'logFileRankDrillCompleted'),
        hasLength(2),
      );
    });

    testWidgets('a round with no correct answers is never a record',
        (tester) async {
      final sub = container.listen(fileRankGameProvider, (_, __) {});
      addTearDown(sub.close);
      await playSpeedRound(tester, correctAnswers: 0);
      expect(container.read(fileRankGameProvider).isNewRecord, isFalse);
      expect(container.read(personalBestsProvider), isEmpty);
    });

    testWidgets('the results card shows the badge', (tester) async {
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WhichSideWinsScreen(mode: WhichSideWinsMode.speed),
        ),
      ));
      await tester.pump(); // post-frame startGame
      final notifier = container.read(whichSideWinsProvider.notifier);
      notifier.handleAnswer(
          container.read(whichSideWinsProvider).currentPuzzle!.correctSide);
      for (var i = 0; i < 31; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.text("Time's Up!"), findsOneWidget);
      expect(find.text('New Record!'), findsOneWidget);
      expect(
          container.read(personalBestsProvider.notifier).best('pieces.speed'),
          1);
    });
  });
}
