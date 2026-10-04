import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:calvinchesstrainer/core/audio/audio_service.dart';
import 'package:calvinchesstrainer/core/services/analytics_service.dart';
import 'package:calvinchesstrainer/core/services/puzzle_service.dart';
import 'package:calvinchesstrainer/features/move_trainer/models/move_game_state.dart';
import 'package:calvinchesstrainer/features/move_trainer/providers/move_game_provider.dart';
import 'package:calvinchesstrainer/features/move_trainer/widgets/move_prompt_display.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

/// A puzzle service whose load finishes only when the test says so.
class _GatedPuzzleService extends PuzzleService {
  _GatedPuzzleService(String json) : super(random: Random(1)) {
    loadFromJson(json);
  }

  final gate = Completer<void>();

  @override
  Future<void> loadPuzzles() => gate.future;
}

String _json(List<(String fen, String moves)> puzzles) => jsonEncode([
      for (final (fen, moves) in puzzles) {'fen': fen, 'moves': moves},
    ]);

ParsedPuzzle _single(String fen, String moves) =>
    (PuzzleService()..loadFromJson(_json([(fen, moves)]))).getRandomPuzzle();

/// White-to-move puzzles: castling both ways.
final _castlingJson = _json([
  ('4k3/8/8/8/8/8/8/R3K2R b KQ - 0 1', 'e8d8 e1g1'),
  ('4k3/8/8/8/8/8/8/R3K2R b KQ - 0 1', 'e8f8 e1c1'),
]);

/// White-to-move puzzles: one starts in check (the answer escapes it), one
/// answer gives check.
final _checkJson = _json([
  ('4k3/8/8/8/8/8/r7/4K3 b - - 0 1', 'a2a1 e1e2'),
  ('4k3/8/8/8/8/8/8/R3K3 b - - 0 1', 'e8f8 a1a8'),
]);

void main() {
  group('MovePromptDisplay.friendlyDescription', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final es = lookupAppLocalizations(const Locale('es'));

    test('a disambiguated move names its real square', () {
      // Puzzle #466 in moves_puzzles.json: two queens can reach c8.
      final puzzle = _single(
        '6Q1/1kp4K/1p1p4/3PpQ2/4P3/7P/4q3/2q5 b - - 6 62',
        'e2c2 f5c8',
      );
      expect(puzzle.san, 'Qfc8+');
      expect(MovePromptDisplay.friendlyDescription(puzzle, en),
          'Queen to c8');
    });

    test('piece names follow the locale', () {
      final puzzle = _single(
        '6Q1/1kp4K/1p1p4/3PpQ2/4P3/7P/4q3/2q5 b - - 6 62',
        'e2c2 f5c8',
      );
      expect(MovePromptDisplay.friendlyDescription(puzzle, es), 'Dama a c8');
    });

    test('captures read "takes on"', () {
      final puzzle = _single('4k3/8/8/8/8/8/r7/R3K3 b - - 0 1', 'e8d8 a1a2');
      expect(puzzle.san, 'Rxa2');
      expect(MovePromptDisplay.friendlyDescription(puzzle, en),
          'Rook takes on a2');
    });

    test('castling with check still reads as castling', () {
      final puzzle = _single('5k2/8/8/8/8/8/8/4K2R b K - 0 1', 'f8f7 e1g1');
      expect(puzzle.san, 'O-O+');
      expect(MovePromptDisplay.friendlyDescription(puzzle, en),
          'Castle kingside');
    });

    testWidgets('renders under the SAN', (tester) async {
      final puzzle = _single(
        '6Q1/1kp4K/1p1p4/3PpQ2/4P3/7P/4q3/2q5 b - - 6 62',
        'e2c2 f5c8',
      );
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MovePromptDisplay(
            gameState: MoveGameState(
              mode: MoveTrainerMode.practice,
              currentPuzzle: puzzle,
              isLoading: false,
            ),
          ),
        ),
      ));
      expect(find.text('Qfc8+'), findsOneWidget);
      expect(find.text('Queen to c8'), findsOneWidget);
    });
  });

  group('MoveGameNotifier', () {
    late _RecordingAudio audio;
    late _RecordingAnalytics analytics;

    ProviderContainer containerWith(PuzzleService puzzles) {
      audio = _RecordingAudio();
      analytics = _RecordingAnalytics();
      final container = ProviderContainer(overrides: [
        audioServiceProvider.overrideWithValue(audio),
        analyticsServiceProvider.overrideWithValue(analytics),
        puzzleServiceProvider.overrideWithValue(puzzles),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    testWidgets('a king-onto-rook drop counts as the castling answer',
        (tester) async {
      final container = containerWith(
          PuzzleService(random: Random(3))..loadFromJson(_castlingJson));
      final sub = container.listen(moveGameProvider, (_, __) {});
      addTearDown(sub.close);
      final notifier = container.read(moveGameProvider.notifier);

      await notifier.startGame(MoveTrainerMode.practice);
      for (var round = 0; round < 2; round++) {
        final puzzle = container.read(moveGameProvider).currentPuzzle!;
        final kingside = puzzle.expectedMove.to == Square.g1;
        // Drop the king on its own rook instead of two squares over.
        notifier.handleMove(NormalMove(
          from: Square.e1,
          to: kingside ? Square.h1 : Square.a1,
        ));
        final state = container.read(moveGameProvider);
        expect(state.lastFeedback?.result, MoveFeedbackResult.correct);
        expect(state.streak, round + 1);
        final board = Setup.parseFen(state.displayFen!).board;
        expect(board.roleAt(kingside ? Square.g1 : Square.c1), Role.king);
        expect(board.roleAt(kingside ? Square.f1 : Square.d1), Role.rook);
        await tester.pump(const Duration(milliseconds: 800));
      }
    });

    testWidgets('check highlight follows the position on screen',
        (tester) async {
      final container = containerWith(
          PuzzleService(random: Random(5))..loadFromJson(_checkJson));
      final sub = container.listen(moveGameProvider, (_, __) {});
      addTearDown(sub.close);
      final notifier = container.read(moveGameProvider.notifier);

      await notifier.startGame(MoveTrainerMode.practice);
      for (var round = 0; round < 2; round++) {
        var state = container.read(moveGameProvider);
        final puzzle = state.currentPuzzle!;
        final startsInCheck = puzzle.position.isCheck;
        expect(state.isCheck, startsInCheck);
        expect(state.sideToMove, Side.white);

        notifier.handleMove(puzzle.expectedMove);
        state = container.read(moveGameProvider);
        expect(state.lastFeedback?.result, MoveFeedbackResult.correct);
        // Now it's Black's position on screen.
        expect(state.sideToMove, Side.black);
        // Escaping check clears it; giving check puts Black's king in it.
        expect(state.isCheck, !startsInCheck);
        await tester.pump(const Duration(milliseconds: 800));
      }
    });

    testWidgets('a start overtaken during the puzzle load gives up',
        (tester) async {
      final puzzles = _GatedPuzzleService(_checkJson);
      final container = containerWith(puzzles);
      final sub = container.listen(moveGameProvider, (_, __) {});
      addTearDown(sub.close);
      final notifier = container.read(moveGameProvider.notifier);

      final first = notifier.startGame(MoveTrainerMode.speed);
      final second = notifier.startGame(MoveTrainerMode.practice);
      puzzles.gate.complete();
      await Future.wait([first, second]);

      var state = container.read(moveGameProvider);
      expect(state.mode, MoveTrainerMode.practice);
      expect(state.isLoading, isFalse);
      expect(state.timeRemainingSeconds, isNull);

      // The overtaken speed start must not have left a countdown behind.
      await tester.pump(const Duration(seconds: 5));
      state = container.read(moveGameProvider);
      expect(state.isGameOver, isFalse);
    });

    testWidgets('two speed starts leave exactly one countdown',
        (tester) async {
      final puzzles = _GatedPuzzleService(_checkJson);
      final container = containerWith(puzzles);
      final sub = container.listen(moveGameProvider, (_, __) {});
      addTearDown(sub.close);
      final notifier = container.read(moveGameProvider.notifier);

      final first = notifier.startGame(MoveTrainerMode.speed);
      final second = notifier.startGame(MoveTrainerMode.speed);
      puzzles.gate.complete();
      await Future.wait([first, second]);

      await tester.pump(const Duration(seconds: 3));
      expect(container.read(moveGameProvider).timeRemainingSeconds, 27);
      await tester.pump(const Duration(seconds: 30));
      expect(container.read(moveGameProvider).isGameOver, isTrue);
    });

    testWidgets('closing the screen during the puzzle load is harmless',
        (tester) async {
      final puzzles = _GatedPuzzleService(_checkJson);
      final container = containerWith(puzzles);
      final sub = container.listen(moveGameProvider, (_, __) {});
      final notifier = container.read(moveGameProvider.notifier);

      final start = notifier.startGame(MoveTrainerMode.speed);
      sub.close(); // the screen goes away; autoDispose follows
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.exists(moveGameProvider), isFalse);
      final audioBefore = audio.calls.length;

      puzzles.gate.complete();
      await start; // must not throw on the disposed notifier
      await tester.pump(const Duration(seconds: 40));

      expect(audio.calls.length, audioBefore,
          reason: 'no prompt, buzz or cheer after the screen closed');
      expect(analytics.calls, isNot(contains('logMoveDrillCompleted')));
    });
  });
}
