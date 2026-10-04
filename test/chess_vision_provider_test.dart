import 'package:calvinchesstrainer/core/audio/audio_service.dart';
import 'package:calvinchesstrainer/core/services/analytics_service.dart';
import 'package:calvinchesstrainer/core/services/personal_bests_service.dart';
import 'package:calvinchesstrainer/features/chess_vision/models/chess_vision_state.dart';
import 'package:calvinchesstrainer/features/chess_vision/providers/chess_vision_provider.dart';
import 'package:calvinchesstrainer/features/chess_vision/services/knight_engine.dart';
import 'package:calvinchesstrainer/features/chess_vision/services/pawn_attack_engine.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Provider-level flows for the Chess Vision notifier. testWidgets runs in
/// fake time, so the 60 s countdown, stopwatches and feedback beats are
/// driven with `tester.pump(duration)`.

String _member(Invocation invocation) {
  final name = invocation.memberName.toString(); // Symbol("playCorrect")
  return name.substring(8, name.length - 2);
}

class _RecordingAudio implements AudioService {
  final calls = <String>[];
  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(_member(invocation));
    return Future<void>.value();
  }
}

class _RecordingAnalytics implements AnalyticsService {
  final events = <String>[];
  @override
  dynamic noSuchMethod(Invocation invocation) {
    events.add(_member(invocation));
    return null;
  }
}

class _RecordingBests extends PersonalBestsNotifier {
  final submits = <(String, int, bool)>[];
  @override
  bool submit(String key, int score, {bool lowerIsBetter = false}) {
    submits.add((key, score, lowerIsBetter));
    return super.submit(key, score, lowerIsBetter: lowerIsBetter);
  }
}

class _Harness {
  _Harness() {
    container = ProviderContainer(overrides: [
      audioServiceProvider.overrideWithValue(audio),
      analyticsServiceProvider.overrideWithValue(analytics),
      personalBestsProvider.overrideWith(_RecordingBests.new),
    ]);
    // Stands in for the game screen's listener (the provider is autoDispose).
    subscription = container.listen(chessVisionProvider, (_, _) {});
  }

  final audio = _RecordingAudio();
  final analytics = _RecordingAnalytics();
  late final ProviderContainer container;
  late final ProviderSubscription<ChessVisionState> subscription;

  ChessVisionNotifier get notifier =>
      container.read(chessVisionProvider.notifier);
  ChessVisionState get state => container.read(chessVisionProvider);
  _RecordingBests get bests =>
      container.read(personalBestsProvider.notifier) as _RecordingBests;

  /// Solves the current Forks & Skewers round: every square, or None.
  void solveForksRound() {
    final s = state;
    if (s.correctSquares.isEmpty) {
      notifier.handleNoneTap();
    } else {
      for (final sq in s.correctSquares) {
        notifier.handleBoardTap(sq);
      }
    }
  }

  void dispose() => container.dispose();
}

void main() {
  group('lifecycle — a round never outlives its screen', () {
    testWidgets('closing the last listener disposes the round: no ghost '
        'audio, analytics or personal best afterwards', (tester) async {
      final h = _Harness();
      final bests = h.bests;
      await h.notifier.startGame(
          VisionDrillType.forksAndSkewers, VisionMode.speed, WhitePiece.queen);
      h.solveForksRound();
      await tester.pump(const Duration(milliseconds: 450));
      expect(h.state.configurationsCompleted, 1);

      h.subscription.close(); // the game screen goes away
      await tester.pump();
      await tester.pump();
      final audioMark = h.audio.calls.length;
      final eventMark = h.analytics.events.length;

      await tester.pump(const Duration(seconds: 70));
      expect(h.audio.calls.sublist(audioMark), isEmpty);
      expect(h.analytics.events.sublist(eventMark), isEmpty);
      expect(bests.submits, isEmpty);
      expect(h.container.read(personalBestsProvider), isEmpty);
      h.dispose();
    });

    testWidgets('disposing the container mid-round stops every timer',
        (tester) async {
      final h = _Harness();
      final bests = h.bests;
      await h.notifier.startGame(VisionDrillType.forksAndSkewers,
          VisionMode.concentric, WhitePiece.queen);
      h.solveForksRound();
      final audioMark = h.audio.calls.length;
      final eventMark = h.analytics.events.length;
      h.dispose();

      await tester.pump(const Duration(seconds: 70));
      expect(h.audio.calls.sublist(audioMark), isEmpty);
      expect(h.analytics.events.sublist(eventMark), isEmpty);
      expect(bests.submits, isEmpty);
    });

    test('a fresh provider starts neutral (no stale game, input blocked)', () {
      final h = _Harness();
      final s = h.state;
      expect(s.isLoading, isTrue);
      expect(s.isGameOver, isFalse);
      expect(s.isNewRecord, isFalse);
      h.notifier.handleNoneTap();
      h.notifier.handleBoardTap(Square.e4);
      expect(h.state.totalErrors, 0);
      expect(h.state.configurationsCompleted, 0);
      h.dispose();
    });
  });

  group('Forks & Skewers scoring', () {
    testWidgets('a wrong None reveals, costs the streak and is NOT counted',
        (tester) async {
      final h = _Harness();
      await h.notifier.startGame(VisionDrillType.forksAndSkewers,
          VisionMode.practice, WhitePiece.queen);
      var guard = 0;
      while (h.state.correctSquares.isEmpty && guard++ < 100) {
        h.solveForksRound();
        await tester.pump(const Duration(milliseconds: 900));
      }
      expect(h.state.correctSquares, isNotEmpty);
      final solved = h.state.configurationsCompleted;
      final errors = h.state.totalErrors;

      h.notifier.handleNoneTap(); // solutions exist: wrong
      expect(h.state.showingRevealedAnswer, isTrue);
      expect(h.state.streak, 0);
      await tester.pump(const Duration(milliseconds: 1600));
      expect(h.state.configurationsCompleted, solved);
      expect(h.state.totalErrors, errors + 1);
      expect(h.state.showingRevealedAnswer, isFalse);
      h.dispose();
    });

    testWidgets('a correct None is counted at once', (tester) async {
      final h = _Harness();
      await h.notifier.startGame(VisionDrillType.forksAndSkewers,
          VisionMode.practice, WhitePiece.queen);
      var guard = 0;
      while (h.state.correctSquares.isNotEmpty && guard++ < 300) {
        h.solveForksRound();
        await tester.pump(const Duration(milliseconds: 900));
      }
      expect(h.state.correctSquares, isEmpty);
      final solved = h.state.configurationsCompleted;
      final streak = h.state.streak;
      h.notifier.handleNoneTap();
      expect(h.state.configurationsCompleted, solved + 1);
      expect(h.state.streak, streak + 1);
      h.notifier.handleNoneTap(); // a double tap counts once
      expect(h.state.configurationsCompleted, solved + 1);
      await tester.pump(const Duration(milliseconds: 900));
      h.dispose();
    });

    testWidgets('None rounds come at a fixed rate, whatever the pairing',
        (tester) async {
      // Rook vs rook: only 6 of 63 targets have a solution, which used to
      // make about 70% of rounds None rounds.
      final h = _Harness();
      await h.notifier.startGame(VisionDrillType.forksAndSkewers,
          VisionMode.practice, WhitePiece.rook,
          targetPiece: TargetPiece.rook);
      const rounds = 600;
      var noneRounds = 0;
      for (var i = 0; i < rounds; i++) {
        if (h.state.correctSquares.isEmpty) noneRounds++;
        h.solveForksRound();
        await tester.pump(const Duration(milliseconds: 850));
      }
      final rate = noneRounds / rounds;
      expect(rate, inInclusiveRange(0.08, 0.24),
          reason: 'expected about ${ChessVisionNotifier.noneRoundChance}');
      h.dispose();
    });

    testWidgets('a solve in the last moments of a speed round still counts',
        (tester) async {
      final h = _Harness();
      await h.notifier.startGame(
          VisionDrillType.forksAndSkewers, VisionMode.speed, WhitePiece.queen);
      await tester.pump(const Duration(milliseconds: 59700));
      expect(h.state.isGameOver, isFalse);
      h.solveForksRound(); // the 400 ms beat would end after the buzzer
      await tester.pump(const Duration(seconds: 1));
      expect(h.state.isGameOver, isTrue);
      expect(h.state.configurationsCompleted, 1);
      h.dispose();
    });
  });

  group('personal bests', () {
    testWidgets('speed: the record flag is set in state at game over, saved, '
        'and reset by the next game', (tester) async {
      final h = _Harness();
      await h.notifier.startGame(
          VisionDrillType.forksAndSkewers, VisionMode.speed, WhitePiece.queen);
      for (var i = 0; i < 2; i++) {
        h.solveForksRound();
        await tester.pump(const Duration(milliseconds: 450));
      }
      await tester.pump(const Duration(seconds: 61));
      expect(h.state.isGameOver, isTrue);
      expect(h.state.isNewRecord, isTrue);
      expect(h.audio.calls.where((c) => c == 'playNewRecord'), hasLength(1));
      expect(h.container.read(personalBestsProvider),
          {'vision.forksAndSkewers_queen_rook_speed': 2});

      // A worse run: no record, no cheer.
      await h.notifier.startGame(
          VisionDrillType.forksAndSkewers, VisionMode.speed, WhitePiece.queen);
      expect(h.state.isNewRecord, isFalse);
      h.solveForksRound();
      await tester.pump(const Duration(seconds: 61));
      expect(h.state.isGameOver, isTrue);
      expect(h.state.isNewRecord, isFalse);
      expect(h.audio.calls.where((c) => c == 'playNewRecord'), hasLength(1));
      h.dispose();
    });

    testWidgets('concentric: ranked by time (lower is better), clock stops '
        'at the last solve', (tester) async {
      final h = _Harness();
      await h.notifier.startGame(VisionDrillType.forksAndSkewers,
          VisionMode.concentric, WhitePiece.knight,
          targetPiece: TargetPiece.rook);
      final total = h.state.concentricTotal;
      expect(total, greaterThan(0));
      var guard = 0;
      while (h.state.configurationsCompleted < total && guard++ < 100) {
        await tester.pump(const Duration(milliseconds: 1100));
        h.solveForksRound();
      }
      final elapsedAtLastSolve = h.state.elapsedSeconds;
      await tester.pump(const Duration(seconds: 2));
      expect(h.state.isGameOver, isTrue);
      expect(h.state.elapsedSeconds, elapsedAtLastSolve);
      expect(h.state.isNewRecord, isTrue);
      expect(h.bests.submits.single,
          ('vision.forksAndSkewers_knight_rook_concentric',
              elapsedAtLastSolve, true));
      h.dispose();
    });
  });

  group('concentric with no solutions anywhere', () {
    testWidgets('knight vs knight falls back to practice — never a dead end',
        (tester) async {
      final h = _Harness();
      await h.notifier.startGame(VisionDrillType.forksAndSkewers,
          VisionMode.concentric, WhitePiece.knight,
          targetPiece: TargetPiece.knight);
      expect(h.state.mode, VisionMode.practice);
      expect(h.state.concentricTotal, 0);
      expect(h.state.correctSquares, isEmpty); // a None round
      h.notifier.handleNoneTap();
      expect(h.state.configurationsCompleted, 1);
      await tester.pump(const Duration(milliseconds: 900));
      expect(h.state.isRoundComplete, isFalse); // next round is playable
      await tester.pump(const Duration(seconds: 5));
      expect(h.state.elapsedSeconds, 0); // no stopwatch running
      h.dispose();
    });
  });

  group('Pawn Attack', () {
    Square firstQuietMove(ChessVisionState s) => PawnAttackEngine.validMoves(
          role: s.whitePiece.role,
          from: s.pieceSquare!,
          remainingPawns: s.remainingPawns,
        ).firstWhere((sq) => !s.remainingPawns.contains(sq));

    testWidgets('Start over restores the dealt board and costs nothing',
        (tester) async {
      final h = _Harness();
      await h.notifier.startGame(
          VisionDrillType.pawnAttack, VisionMode.practice, WhitePiece.rook);
      final dealt = h.state.remainingPawns;
      expect(h.state.pawnAttackStartPawns, dealt);

      h.notifier.startOverPawnBoard(); // nothing to undo yet: no-op
      expect(h.state.pawnAttackMoves, 0);

      h.notifier.handleBoardTap(firstQuietMove(h.state));
      final invalid = Square.values.firstWhere((sq) =>
          sq != h.state.pieceSquare &&
          !PawnAttackEngine.validMoves(
                  role: Role.rook,
                  from: h.state.pieceSquare!,
                  remainingPawns: h.state.remainingPawns)
              .contains(sq));
      h.notifier.handleBoardTap(invalid);
      expect(h.state.pawnAttackMoves, 1);
      expect(h.state.totalErrors, 1);

      h.notifier.startOverPawnBoard();
      final s = h.state;
      expect(s.pieceSquare, Square.a1);
      expect(s.remainingPawns, dealt);
      expect(s.pawnThreatSquares, PawnAttackEngine.pawnThreats(dealt));
      expect(s.pawnAttackMoves, 0);
      expect(s.totalErrors, 1); // no extra cost
      expect(s.configurationsCompleted, 0);
      expect(s.streak, 0);
      await tester.pump(const Duration(milliseconds: 500));
      h.dispose();
    });

    testWidgets('timed: the clock keeps running through Start over',
        (tester) async {
      final h = _Harness();
      await h.notifier.startGame(
          VisionDrillType.pawnAttack, VisionMode.speed, WhitePiece.queen);
      await tester.pump(const Duration(seconds: 3));
      h.notifier.handleBoardTap(firstQuietMove(h.state));
      h.notifier.startOverPawnBoard();
      await tester.pump(const Duration(seconds: 2));
      expect(h.state.elapsedSeconds, 5);
      expect(h.state.pawnAttackMoves, 0);
      h.dispose();
    });

    testWidgets('a self-made dead end is flagged, and Start over clears it',
        (tester) async {
      // A solvable knight board (dealt by the generator, seed 101)...
      final board = {Square.b3, Square.a4, Square.d3, Square.e4};
      expect(
          PawnAttackEngine.isSolvable(
              role: Role.knight, from: Square.a1, pawns: board),
          isTrue);

      final h = _Harness();
      await h.notifier.startGame(
          VisionDrillType.pawnAttack, VisionMode.practice, WhitePiece.knight);
      h.notifier.debugSetPawnBoard(board);
      expect(h.state.pawnAttackDeadEnd, isFalse);

      // ...that the knight wrecks by taking b3 and hopping back to a1: b3 is
      // now attacked by the a4 pawn and c2 by d3, so it can never leave.
      h.notifier.handleBoardTap(Square.b3);
      expect(h.state.pawnAttackDeadEnd, isFalse);
      h.notifier.handleBoardTap(Square.a1);
      expect(h.state.pawnAttackMoves, 2);
      expect(h.state.pawnAttackDeadEnd, isTrue);

      h.notifier.startOverPawnBoard();
      expect(h.state.pawnAttackDeadEnd, isFalse);
      expect(h.state.remainingPawns, board);
      expect(h.state.pieceSquare, Square.a1);
      h.dispose();
    });

    testWidgets('every dealt knight board is solvable from a1', (tester) async {
      final h = _Harness();
      for (var i = 0; i < 40; i++) {
        await h.notifier.startGame(
            VisionDrillType.pawnAttack, VisionMode.practice, WhitePiece.knight);
        expect(h.state.pawnAttackDeadEnd, isFalse);
        expect(
            PawnAttackEngine.validMoves(
                role: Role.knight,
                from: Square.a1,
                remainingPawns: h.state.remainingPawns),
            isNotEmpty);
      }
      h.dispose();
    });
  });

  group('Knight Flight', () {
    testWidgets('a double tap on Skip after a long route counts once',
        (tester) async {
      final h = _Harness();
      await h.notifier.startGame(
          VisionDrillType.knightFlight, VisionMode.practice, WhitePiece.queen);
      final start = h.state.knightSquare!;
      final target = h.state.flightTargetSquare!;
      // Detour: hop away and back, then take a shortest route.
      final away = KnightEngine.knightMoves(start).firstWhere((s) => s != target);
      h.notifier.handleBoardTap(away);
      h.notifier.handleBoardTap(start);
      var current = start;
      while (current != target) {
        final next = KnightEngine.knightMoves(current).firstWhere((s) =>
            KnightEngine.shortestPath(s, target) <
            KnightEngine.shortestPath(current, target));
        h.notifier.handleBoardTap(next);
        current = next;
      }
      expect(h.state.flightComplete, isTrue);
      expect(h.state.isRoundComplete, isFalse); // not optimal: retry/skip

      h.notifier.skipFlight();
      h.notifier.skipFlight();
      expect(h.state.configurationsCompleted, 1);
      expect(h.state.streak, 0);
      await tester.pump(const Duration(milliseconds: 900));
      expect(h.state.flightComplete, isFalse); // next flight
      h.dispose();
    });
  });
}
