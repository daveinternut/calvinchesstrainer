import 'package:calvinchesstrainer/core/audio/audio_service.dart';
import 'package:calvinchesstrainer/core/services/analytics_service.dart';
import 'package:calvinchesstrainer/core/services/puzzle_service.dart';
import 'package:calvinchesstrainer/core/services/scan_position_service.dart';
import 'package:calvinchesstrainer/features/chess_vision/models/chess_vision_state.dart';
import 'package:calvinchesstrainer/features/chess_vision/providers/chess_vision_provider.dart';
import 'package:calvinchesstrainer/features/chess_vision/screens/chess_vision_game_screen.dart';
import 'package:calvinchesstrainer/features/chess_vision/services/pawn_attack_engine.dart';
import 'package:calvinchesstrainer/features/chess_vision/services/scan_engine.dart';
import 'package:calvinchesstrainer/features/file_rank_trainer/widgets/milestone_banner.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:chessground/chessground.dart' show Chessboard;
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Screen-level checks for the Chess Vision game screen: its mode, prompts,
/// layouts, error state and results. (Drill setup is covered by
/// drill_section_screen_test.dart.)
class _SilentAudio implements AudioService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _NoopAnalytics implements AnalyticsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Fails its first load (as if the asset couldn't be read), then works.
class _FlakyScanService extends ScanPositionService {
  var failuresLeft = 1;

  Future<void> preload(ScanSetKind kind) => super.load(kind);

  @override
  Future<void> load(ScanSetKind kind) async {
    if (failuresLeft > 0) {
      failuresLeft--;
      throw Exception('asset unavailable');
    }
    return super.load(kind);
  }
}

ProviderContainer _container([List<Object> extra = const []]) =>
    ProviderContainer(overrides: [
      audioServiceProvider.overrideWithValue(_SilentAudio()),
      analyticsServiceProvider.overrideWithValue(_NoopAnalytics()),
      ...extra.cast(),
    ]);

Widget _app(ProviderContainer container, Widget home, {Locale? locale}) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

void _setSize(WidgetTester tester, Size logicalSize) {
  tester.view.physicalSize = logicalSize * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Future<void> _pumpGame(WidgetTester tester, ProviderContainer container,
    VisionDrillType drill, VisionMode mode,
    {WhitePiece piece = WhitePiece.queen,
    TargetPiece target = TargetPiece.rook}) async {
  await tester.pumpWidget(_app(
    container,
    ChessVisionGameScreen(
        drill: drill, piece: piece, target: target, mode: mode),
  ));
  await tester.pump(); // first frame's startGame
}

Future<void> _leave(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  container.dispose();
}

void main() {
  group('ChessVisionGameScreen', () {
    testWidgets('reads the mode the game really runs in (pawn + concentric '
        'link runs Timed)', (tester) async {
      _setSize(tester, const Size(820, 1180));
      final container = _container();
      await _pumpGame(
          tester, container, VisionDrillType.pawnAttack, VisionMode.concentric);

      expect(find.text('Pawn Attack'), findsOneWidget);
      expect(find.text('Queen · Timed'), findsOneWidget);
      expect(find.textContaining('Position'), findsNothing);
      expect(find.text('0/6'), findsOneWidget);
      expect(find.text('Level 3 of 8'), findsWidgets);
      await _leave(tester, container);
    });

    for (final (drill, prompt) in const [
      (
        VisionDrillType.forksAndSkewers,
        'Tap every square where your piece attacks the king and the other '
            'piece!'
      ),
      (VisionDrillType.knightSight, 'Tap every square your knight can jump to!'),
      (
        VisionDrillType.knightFlight,
        'Jump your knight to the ring in as few moves as you can!'
      ),
      (
        VisionDrillType.pawnAttack,
        'Capture every pawn — never stop on a shaded square!'
      ),
    ]) {
      testWidgets('${drill.name} shows its instruction line', (tester) async {
        _setSize(tester, const Size(820, 1180));
        final container = _container();
        await _pumpGame(tester, container, drill, VisionMode.practice);
        expect(find.text(prompt), findsOneWidget);
        await _leave(tester, container);
      });
    }

    testWidgets('landscape puts the board left and the controls beside it',
        (tester) async {
      for (final (size, landscape) in const [
        (Size(1180, 820), true),
        (Size(820, 1180), false),
      ]) {
        _setSize(tester, size);
        final container = _container();
        await _pumpGame(tester, container, VisionDrillType.forksAndSkewers,
            VisionMode.speed);
        expect(tester.takeException(), isNull);

        final board = tester.getRect(find.byType(Chessboard));
        final none = tester.getRect(find.text('None'));
        if (landscape) {
          expect(none.left, greaterThan(board.right), reason: '$size');
          expect(board.height, greaterThan(size.height * 0.75));
        } else {
          expect(none.top, greaterThan(board.bottom), reason: '$size');
        }
        await _leave(tester, container);
      }
    });

    // Phones stay portrait, but the web app on a phone held sideways (and a
    // short desktop window) is this shape.
    for (final size in const [Size(750, 369), Size(568, 320)]) {
      testWidgets('every drill fits a short landscape window ($size)',
          (tester) async {
        _setSize(tester, size);
        final scans = ScanPositionService();
        final mates =
            PuzzleService(assetPath: 'assets/puzzles/mate_in_one_puzzles.json');
        await tester.runAsync(() async {
          for (final kind in ScanSetKind.values) {
            await scans.load(kind);
          }
          await mates.loadPuzzles();
        });
        for (final drill in VisionDrillType.values) {
          final container = _container([
            scanPositionServiceProvider.overrideWithValue(scans),
            mateInOnePuzzleServiceProvider.overrideWithValue(mates),
          ]);
          await _pumpGame(tester, container, drill, VisionMode.practice);
          await tester.pump(const Duration(milliseconds: 50));
          expect(tester.takeException(), isNull, reason: drill.name);
          expect(find.byType(Chessboard), findsOneWidget, reason: drill.name);
          final board = tester.getRect(find.byType(Chessboard));
          final close = tester.getRect(find.byTooltip('End drill'));
          expect(close.left, greaterThan(board.right), reason: drill.name);
          await _leave(tester, container);
        }
      });
    }

    testWidgets('landscape: the streak banner stays off the board',
        (tester) async {
      _setSize(tester, const Size(1180, 820));
      final container = _container();
      await _pumpGame(tester, container, VisionDrillType.knightSight,
          VisionMode.practice);
      final notifier = container.read(chessVisionProvider.notifier);
      for (var round = 0; round < 5; round++) {
        for (final sq in container.read(chessVisionProvider).correctSquares) {
          notifier.handleBoardTap(sq);
        }
        await tester.pump(const Duration(milliseconds: 900));
      }
      expect(container.read(chessVisionProvider).streak, 5);
      await tester.pump(const Duration(milliseconds: 300)); // banner entering

      final board = tester.getRect(find.byType(Chessboard));
      final star = tester.getRect(find
          .descendant(
            of: find.byType(MilestoneBanner),
            matching: find.byIcon(Icons.star_rounded),
          )
          .first);
      expect(star.left, greaterThanOrEqualTo(board.right));
      await tester.pump(const Duration(seconds: 3));
      await _leave(tester, container);
    });

    testWidgets('a failed load shows a retry, and Retry recovers',
        (tester) async {
      _setSize(tester, const Size(820, 1180));
      final scans = _FlakyScanService();
      await tester.runAsync(() => scans.preload(ScanSetKind.checks));
      final container =
          _container([scanPositionServiceProvider.overrideWithValue(scans)]);
      await _pumpGame(
          tester, container, VisionDrillType.findChecks, VisionMode.speed);
      await tester.pump();

      expect(find.text("Couldn't load the puzzles."), findsOneWidget);
      expect(find.text('Skip'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();
      expect(find.text("Couldn't load the puzzles."), findsNothing);
      expect(find.byType(Chessboard), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      await _leave(tester, container);
    });

    testWidgets('a correct mate highlights the mated king', (tester) async {
      _setSize(tester, const Size(820, 1180));
      final mates =
          PuzzleService(assetPath: 'assets/puzzles/mate_in_one_puzzles.json');
      await tester.runAsync(mates.loadPuzzles);
      final container = _container(
          [mateInOnePuzzleServiceProvider.overrideWithValue(mates)]);
      await _pumpGame(
          tester, container, VisionDrillType.mateInOne, VisionMode.practice);
      await tester.pump();

      final puzzle = container.read(chessVisionProvider).currentMatePuzzle!;
      var board = tester.widget<Chessboard>(find.byType(Chessboard));
      expect(board.game!.sideToMove, puzzle.sideToMove);

      container
          .read(chessVisionProvider.notifier)
          .handleMateMove(ScanEngine.matingMoves(puzzle.position).first);
      await tester.pump();
      board = tester.widget<Chessboard>(find.byType(Chessboard));
      expect(board.game!.isCheck, isTrue);
      expect(board.game!.sideToMove, puzzle.sideToMove.opposite);
      await tester.pump(const Duration(seconds: 1));
      await _leave(tester, container);
    });

    testWidgets('the results card shows the new-record badge',
        (tester) async {
      _setSize(tester, const Size(820, 1180));
      final container = _container();
      await _pumpGame(tester, container, VisionDrillType.forksAndSkewers,
          VisionMode.speed);
      final notifier = container.read(chessVisionProvider.notifier);
      final s = container.read(chessVisionProvider);
      if (s.correctSquares.isEmpty) {
        notifier.handleNoneTap();
      } else {
        for (final sq in s.correctSquares) {
          notifier.handleBoardTap(sq);
        }
      }
      await tester.pump(const Duration(seconds: 61));
      expect(find.text("Time's Up!"), findsOneWidget);
      expect(find.text('New Record!'), findsOneWidget);
      await _leave(tester, container);
    });

    testWidgets('a new game never flashes the previous game (first frame is '
        'neutral)', (tester) async {
      _setSize(tester, const Size(820, 1180));
      final container = _container();
      await _pumpGame(tester, container, VisionDrillType.forksAndSkewers,
          VisionMode.speed);
      await tester.pump(const Duration(seconds: 61));
      expect(find.text("Time's Up!"), findsOneWidget);

      // Swap screens in one frame: the finished round is still alive when
      // the new screen builds for the first time. (The key makes it a new
      // screen, as a pushed route would be.)
      await tester.pumpWidget(_app(
        container,
        const ChessVisionGameScreen(
          key: ValueKey('second game'),
          drill: VisionDrillType.knightFlight,
          piece: WhitePiece.queen,
          mode: VisionMode.practice,
        ),
      ));
      expect(find.text("Time's Up!"), findsNothing);
      await tester.pump();
      expect(find.text("Time's Up!"), findsNothing);
      expect(container.read(chessVisionProvider).drillType,
          VisionDrillType.knightFlight);
      await _leave(tester, container);
    });

    testWidgets('Pawn Attack: Start over is enabled once the piece moves',
        (tester) async {
      _setSize(tester, const Size(820, 1180));
      final container = _container();
      await _pumpGame(tester, container, VisionDrillType.pawnAttack,
          VisionMode.practice,
          piece: WhitePiece.rook);

      OutlinedButton startOver() => tester.widget<OutlinedButton>(
          find.ancestor(
              of: find.text('Start over'),
              matching: find.byWidgetPredicate((w) => w is OutlinedButton)));
      expect(startOver().onPressed, isNull);

      final s = container.read(chessVisionProvider);
      final quiet = PawnAttackEngine.validMoves(
        role: Role.rook,
        from: s.pieceSquare!,
        remainingPawns: s.remainingPawns,
      ).firstWhere((sq) => !s.remainingPawns.contains(sq));
      container.read(chessVisionProvider.notifier).handleBoardTap(quiet);
      await tester.pump();
      expect(startOver().onPressed, isNotNull);

      await tester.tap(find.text('Start over'));
      await tester.pump();
      final after = container.read(chessVisionProvider);
      expect(after.pieceSquare, Square.a1);
      expect(after.pawnAttackMoves, 0);
      await _leave(tester, container);
    });
  });
}
