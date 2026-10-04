import 'package:calvinchesstrainer/core/audio/audio_service.dart';
import 'package:calvinchesstrainer/core/services/analytics_service.dart';
import 'package:calvinchesstrainer/core/services/puzzle_service.dart';
import 'package:calvinchesstrainer/core/services/scan_position_service.dart';
import 'package:calvinchesstrainer/features/chess_vision/models/chess_vision_state.dart';
import 'package:calvinchesstrainer/features/chess_vision/providers/chess_vision_provider.dart';
import 'package:calvinchesstrainer/features/chess_vision/services/scan_engine.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// End-to-end flows for the four scanning drills, driving the REAL
/// ChessVisionNotifier against the REAL curated assets (rootBundle, loaded
/// once up front) — only audio/analytics are faked (platform channels). The
/// timed flows run in testWidgets' fake time, so the advance/flash delays
/// are exercised exactly, with no wall-clock slack to go flaky.
class _SilentAudioService implements AudioService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _NoopAnalyticsService implements AnalyticsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Loaded once with real I/O; every container shares the warm caches, so
  // no test (fake-time ones included) touches rootBundle again.
  late ScanPositionService scans;
  late PuzzleService mates;
  setUpAll(() async {
    scans = ScanPositionService();
    for (final kind in ScanSetKind.values) {
      await scans.load(kind);
    }
    mates =
        PuzzleService(assetPath: 'assets/puzzles/mate_in_one_puzzles.json');
    await mates.loadPuzzles();
  });

  /// [autoDispose]: false for testWidgets, which must dispose the container
  /// (cancelling its timers) before the test body ends.
  ProviderContainer makeContainer({bool autoDispose = true}) {
    final container = ProviderContainer(overrides: [
      audioServiceProvider.overrideWithValue(_SilentAudioService()),
      analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
      scanPositionServiceProvider.overrideWithValue(scans),
      mateInOnePuzzleServiceProvider.overrideWithValue(mates),
    ]);
    if (autoDispose) addTearDown(container.dispose);
    // chessVisionProvider is autoDispose: stand in for the game screen's
    // listener so the round stays alive between awaits.
    container.listen(chessVisionProvider, (_, _) {});
    return container;
  }

  Chess parse(String fen) => Chess.fromSetup(Setup.parseFen(fen));

  group('Find Checks flow', () {
    testWidgets('serves a real position whose targets match ScanEngine, '
        'flashes wrong taps, completes and advances', (tester) async {
      final container = makeContainer(autoDispose: false);
      final notifier = container.read(chessVisionProvider.notifier);

      await notifier.startGame(
          VisionDrillType.findChecks, VisionMode.practice, WhitePiece.queen);
      var state = container.read(chessVisionProvider);

      expect(state.isLoading, isFalse);
      expect(state.scanDisplayFen, isNotNull);
      expect(state.correctSquares, isNotEmpty);
      expect(state.correctSquares.length, inInclusiveRange(1, 4));

      // Runtime truth: state targets == engine recomputation from the FEN.
      final position = parse(state.scanDisplayFen!);
      expect(state.correctSquares, ScanEngine.checkTargets(position));
      expect(state.checkGhosts.keys.toSet(), state.correctSquares);
      expect(state.scanSideToMove, position.turn);
      expect(state.boardOrientation, position.turn);
      expect(position.isCheck, isFalse); // curation: never in check

      // Wrong tap: red flash + error, then the flash clears (400 ms timer).
      final wrong = Square.values
          .firstWhere((sq) => !state.correctSquares.contains(sq));
      notifier.handleBoardTap(wrong);
      state = container.read(chessVisionProvider);
      expect(state.totalErrors, 1);
      expect(state.incorrectFlashSquare, wrong);
      await tester.pump(const Duration(milliseconds: 500));
      expect(container.read(chessVisionProvider).incorrectFlashSquare, isNull);

      // Find them all -> round complete -> advance (800 ms practice beat);
      // the earlier error resets the streak.
      for (final sq in state.correctSquares) {
        notifier.handleBoardTap(sq);
      }
      state = container.read(chessVisionProvider);
      expect(state.allFound, isTrue);
      expect(state.isRoundComplete, isTrue);
      await tester.pump(const Duration(milliseconds: 1000));
      state = container.read(chessVisionProvider);
      expect(state.configurationsCompleted, 1);
      expect(state.streak, 0);
      expect(state.foundSquares, isEmpty);
      expect(state.isRoundComplete, isFalse);

      // Clean second round -> streak 1.
      for (final sq in state.correctSquares) {
        notifier.handleBoardTap(sq);
      }
      await tester.pump(const Duration(milliseconds: 1000));
      state = container.read(chessVisionProvider);
      expect(state.configurationsCompleted, 2);
      expect(state.streak, 1);
      container.dispose();
    });
  });

  group('Skip flow', () {
    testWidgets('reveals, resets streak, counts nothing, then advances',
        (tester) async {
      final container = makeContainer(autoDispose: false);
      final notifier = container.read(chessVisionProvider.notifier);

      await notifier.startGame(
          VisionDrillType.findCaptures, VisionMode.practice, WhitePiece.queen);
      var state = container.read(chessVisionProvider);
      final firstTarget = state.correctSquares.first;

      notifier.skipScanPosition();
      state = container.read(chessVisionProvider);
      expect(state.showingRevealedAnswer, isTrue);
      expect(state.totalErrors, 1);
      expect(state.streak, 0);

      // Taps are ignored during the reveal.
      notifier.handleBoardTap(firstTarget);
      expect(container.read(chessVisionProvider).foundSquares, isEmpty);

      await tester.pump(const Duration(milliseconds: 1600));
      state = container.read(chessVisionProvider);
      expect(state.configurationsCompleted, 0); // skipped rounds don't count
      expect(state.showingRevealedAnswer, isFalse);
      expect(state.foundSquares, isEmpty);
      container.dispose();
    });
  });

  group('Captures & Hanging targets', () {
    test('match ScanEngine and respect the hanging contract', () async {
      for (final drill in [
        VisionDrillType.findCaptures,
        VisionDrillType.hangingPieces,
      ]) {
        final container = makeContainer();
        final notifier = container.read(chessVisionProvider.notifier);
        await notifier.startGame(drill, VisionMode.practice, WhitePiece.queen);
        final state = container.read(chessVisionProvider);
        final position = parse(state.scanDisplayFen!);

        expect(state.correctSquares, isNotEmpty);
        expect(state.checkGhosts, isEmpty); // ghosts are findChecks-only
        if (drill == VisionDrillType.findCaptures) {
          expect(state.correctSquares, ScanEngine.captureTargets(position));
        } else {
          final hanging = ScanEngine.hangingTargets(position);
          expect(state.correctSquares, hanging);
          final enemy = position.turn.opposite;
          // Hanging = undefended enemy piece (LPDO) — capturability NOT required.
          for (final sq in hanging) {
            final victim = position.board.pieceAt(sq)!;
            expect(victim.color, enemy);
            expect(
              ScanEngine.defaultHangingRoles.contains(victim.role),
              isTrue,
            );
            expect(position.board.attacksTo(sq, enemy).isEmpty, isTrue);
          }
          // Honesty guarantee: no loose enemy PAWN exists in curated
          // hanging positions (a tapped free pawn must never read "wrong").
          for (final (sq, piece) in position.board.pieces) {
            if (piece.color == enemy && piece.role == Role.pawn) {
              expect(position.board.attacksTo(sq, enemy).isNotEmpty, isTrue,
                  reason: 'loose enemy pawn at ${sq.name} in ${state.scanDisplayFen}');
            }
          }
        }
      }
    });
  });

  group('Mate in 1 flow', () {
    testWidgets('wrong try snaps back uncounted; any mating move wins',
        (tester) async {
      final container = makeContainer(autoDispose: false);
      final notifier = container.read(chessVisionProvider.notifier);

      await notifier.startGame(
          VisionDrillType.mateInOne, VisionMode.practice, WhitePiece.queen);
      var state = container.read(chessVisionProvider);
      final puzzle = state.currentMatePuzzle!;
      expect(state.scanDisplayFen, puzzle.position.fen);
      expect(state.scanSideToMove, puzzle.sideToMove);
      expect(ScanEngine.matingMoves(puzzle.position), isNotEmpty);
      expect(
        ScanEngine.isMatingMove(puzzle.position, puzzle.expectedMove),
        isTrue,
        reason: 'the curated answer must itself mate',
      );

      // A deliberately wrong (non-mating) try: board FEN untouched, solution
      // arrow feedback, streak reset, round advances uncounted.
      NormalMove? wrongMove;
      outer:
      for (final entry in puzzle.position.legalMoves.entries) {
        for (final to in entry.value.squares) {
          final candidate = NormalMove(from: entry.key, to: to);
          if (puzzle.position.isLegal(candidate) &&
              !ScanEngine.isMatingMove(puzzle.position, candidate)) {
            wrongMove = candidate;
            break outer;
          }
        }
      }
      expect(wrongMove, isNotNull,
          reason: 'a mate-in-1 position always has non-mating moves too');
      notifier.handleMateMove(wrongMove!);
      state = container.read(chessVisionProvider);
      expect(state.mateFeedback!.isCorrect, isFalse);
      expect(state.mateFeedback!.solutionMove, puzzle.expectedMove);
      expect(state.scanDisplayFen, puzzle.position.fen); // snap-back
      expect(state.streak, 0);
      expect(state.totalErrors, 1);
      expect(state.mateFeedbackShapes, isNotEmpty); // green solution arrow

      await tester.pump(const Duration(milliseconds: 1600));
      state = container.read(chessVisionProvider);
      expect(state.configurationsCompleted, 0); // wrong mates don't count
      final puzzle2 = state.currentMatePuzzle!;
      expect(state.mateFeedback, isNull);

      // Judged by result: ANY mating move (not just the stored answer).
      final anyMate = ScanEngine.matingMoves(puzzle2.position).first;
      notifier.handleMateMove(anyMate);
      state = container.read(chessVisionProvider);
      expect(state.mateFeedback!.isCorrect, isTrue);
      expect(state.isRoundComplete, isTrue);
      // The played move stays on the board and the shown position is mate.
      expect(state.scanDisplayFen, isNot(puzzle2.position.fen));
      expect(parse(state.scanDisplayFen!).isCheckmate, isTrue);
      // The mated position drives the board's check highlight: the mated
      // side is to move, and in check.
      expect(state.matedPosition, isNotNull);
      expect(state.matedPosition!.turn, puzzle2.sideToMove.opposite);
      expect(state.matedPosition!.isCheck, isTrue);
      // Credited at once (not after the feedback beat).
      expect(state.configurationsCompleted, 1);
      expect(state.streak, 1);

      await tester.pump(const Duration(milliseconds: 1100));
      state = container.read(chessVisionProvider);
      expect(state.configurationsCompleted, 1);
      expect(state.streak, 1);
      expect(state.matedPosition, isNull); // next puzzle loaded
      container.dispose();
    });
  });

  group('Find Checks ghosts', () {
    test('a promotion check shows the promoted piece, not the pawn', () {
      // g8=Q+ and gxh8=Q+ (fixture F6).
      final details = ScanEngine.checkTargetDetails(
          parse('k6r/6P1/8/8/8/8/8/6K1 w - - 0 1'));
      expect(details[Square.g8], Piece.whiteQueen);
      expect(details[Square.h8], Piece.whiteQueen);
    });

    test('when only the knight promotion checks, the ghost is a knight', () {
      // Black king on d6: of the four promotions on e8 only the knight
      // attacks d6 (a queen there sees d7 and d8, not d6).
      final details =
          ScanEngine.checkTargetDetails(parse('8/4P3/3k4/8/8/8/8/K7 w - - 0 1'));
      expect(details[Square.e8], Piece.whiteKnight);
    });
  });

  group('Modes', () {
    test('speed wires the 60s countdown; concentric coerces to speed',
        () async {
      final container = makeContainer();
      final notifier = container.read(chessVisionProvider.notifier);

      await notifier.startGame(
          VisionDrillType.findChecks, VisionMode.speed, WhitePiece.queen);
      expect(
          container.read(chessVisionProvider).timeRemainingSeconds, isNotNull);

      await notifier.startGame(
          VisionDrillType.mateInOne, VisionMode.concentric, WhitePiece.queen);
      final state = container.read(chessVisionProvider);
      expect(state.mode, VisionMode.speed);
      expect(state.timeRemainingSeconds, isNotNull);
    });
  });

  group('Legacy drills regression', () {
    test('forks & knight sight still start and serve configurations',
        () async {
      final container = makeContainer();
      final notifier = container.read(chessVisionProvider.notifier);

      await notifier.startGame(VisionDrillType.forksAndSkewers,
          VisionMode.practice, WhitePiece.queen);
      var state = container.read(chessVisionProvider);
      expect(state.drillType, VisionDrillType.forksAndSkewers);
      expect(state.isLoading, isFalse);
      expect(state.boardFen, isNotEmpty);

      await notifier.startGame(
          VisionDrillType.knightSight, VisionMode.speed, WhitePiece.queen);
      state = container.read(chessVisionProvider);
      expect(state.mode, VisionMode.practice); // knight coercion intact
      expect(state.knightSquare, isNotNull);
      expect(state.correctSquares, isNotEmpty);
      // No scan-state bleed into legacy drills.
      expect(state.scanPosition, isNull);
      expect(state.checkGhosts, isEmpty);
    });
  });
}
