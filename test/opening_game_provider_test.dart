import 'dart:async';

import 'package:calvinchesstrainer/core/audio/audio_service.dart';
import 'package:calvinchesstrainer/core/services/analytics_service.dart';
import 'package:calvinchesstrainer/core/services/opening_book_service.dart';
import 'package:calvinchesstrainer/core/services/stockfish_service.dart';
import 'package:calvinchesstrainer/features/opening_trainer/models/opening_game_state.dart';
import 'package:calvinchesstrainer/features/opening_trainer/models/uci_move.dart';
import 'package:calvinchesstrainer/features/opening_trainer/providers/opening_game_provider.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// An engine that answers at once (or holds chosen searches until stopped),
/// and records everything it is asked.
class FakeEngine implements StockfishService {
  int initializeCalls = 0;
  int stopCalls = 0;
  int disposeWhenIdleCalls = 0;
  int disposeCalls = 0;

  /// Delays the start until completed.
  Completer<void>? initGate;

  /// While set, starting fails.
  Object? initError;

  /// Searches matching this are held until [stopSearch] cancels them.
  bool Function(String fen, int? depth) holds = (_, __) => false;

  List<ScoredMove> Function(String fen) topMovesFor = firstLegalMove;

  final evaluated = <String>[];
  final topMovesRequests = <(String, int?)>[];

  bool _ready = false;
  Future<void>? _starting;
  int _active = 0;
  int _epoch = 0;
  final _held = <Completer<void>>[];

  int get heldCount => _held.length;

  List<int?> depthsFor(String fen) => [
        for (final (f, d) in topMovesRequests)
          if (f == fen) d,
      ];

  @override
  bool get isReady => _ready;

  @override
  bool get isBusy => _active > 0 || _starting != null;

  @override
  Future<void> initialize() {
    initializeCalls++;
    return _start();
  }

  Future<void> _start() {
    if (_ready) return Future.value();
    final pending = _starting;
    if (pending != null) return pending;
    final done = Completer<void>();
    _starting = done.future;
    () async {
      final gate = initGate;
      if (gate != null) await gate.future;
      _starting = null;
      final error = initError;
      if (error != null) {
        done.completeError(EngineUnavailableException(error));
      } else {
        _ready = true;
        done.complete();
      }
    }();
    return done.future;
  }

  /// Lets every held search finish normally.
  void releaseHeld() {
    for (final gate in _held) {
      gate.complete();
    }
    _held.clear();
  }

  Future<T> _op<T>(
    String fen,
    int? depth,
    T Function() answer, {
    void Function()? onRun,
  }) async {
    final epoch = _epoch;
    _active++;
    try {
      await _start();
      if (epoch != _epoch) throw const SearchCancelledException();
      onRun?.call(); // recorded only once it really searches
      if (holds(fen, depth)) {
        final gate = Completer<void>();
        _held.add(gate);
        await gate.future;
      }
      return answer();
    } finally {
      _active--;
    }
  }

  @override
  void stopSearch() {
    stopCalls++;
    _epoch++;
    for (final gate in _held) {
      gate.completeError(const SearchCancelledException());
    }
    _held.clear();
  }

  @override
  Future<EvalResult> evaluate(String fen, {int? depth, int? movetime}) =>
      _op(fen, depth, () {
        evaluated.add(fen);
        return EvalResult(centipawns: 10, depth: depth ?? 10);
      });

  @override
  Future<String?> getBestMove(String fen,
          {int? depth, int? movetime, int skillLevel = 20}) =>
      _op(fen, depth, () => null);

  @override
  Future<List<ScoredMove>> getTopMoves(
    String fen, {
    int count = 3,
    int? depth,
    int? movetime,
    void Function(int depth)? onDepth,
  }) {
    return _op(
      fen,
      depth,
      () {
        onDepth?.call(depth ?? 1);
        return topMovesFor(fen);
      },
      onRun: () => topMovesRequests.add((fen, depth)),
    );
  }

  @override
  void disposeWhenIdle() => disposeWhenIdleCalls++;

  @override
  void dispose() => disposeCalls++;
}

/// The position's first legal move, scored +0.2 — enough to count as an
/// analysis result.
List<ScoredMove> firstLegalMove(String fen) {
  final pos = Chess.fromSetup(Setup.parseFen(fen));
  for (final entry in pos.legalMoves.entries) {
    for (final to in entry.value.squares) {
      final move = standardMove(pos, NormalMove(from: entry.key, to: to));
      return [ScoredMove(uci: move.uci, centipawns: 20, multipvIndex: 1)];
    }
  }
  return const [];
}

class _SilentAudioService implements AudioService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _NoopAnalyticsService implements AnalyticsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Position replay(String sans) {
  Position pos = Chess.initial;
  for (final san in sans.split(' ')) {
    final move = pos.parseSan(san);
    if (move == null) fail('illegal SAN "$san" in "$sans"');
    pos = pos.playUnchecked(move);
  }
  return pos;
}

NormalMove mv(String uci) => parseUci(uci)!;

Future<void> settle() => pumpEventQueue(times: 100);

const _initialFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final book = OpeningBookService();
  setUpAll(() => book.load());

  late FakeEngine engine;
  late ProviderContainer container;
  late ProviderSubscription<OpeningGameState> screen;

  OpeningGameNotifier notifier() =>
      container.read(openingGameProvider.notifier);
  OpeningGameState state() => container.read(openingGameProvider);

  Future<void> startPractice() => notifier().startGame(
      OpeningMode.practice, OpeningDifficulty.easy, Side.white);

  /// The screen going away.
  Future<void> closeScreen() async {
    screen.close();
    await container.pump();
  }

  setUp(() {
    engine = FakeEngine();
    container = ProviderContainer.test(overrides: [
      stockfishServiceProvider.overrideWithValue(engine),
      openingBookServiceProvider.overrideWithValue(book),
      audioServiceProvider.overrideWithValue(_SilentAudioService()),
      analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
    ]);
    // What the mounted screen does: keeps the auto-disposed provider alive.
    screen = container.listen(openingGameProvider, (_, __) {});
  });

  group('standard UCI', () {
    test('castling is the king\'s two-square move, from either encoding', () {
      final white = replay('e4 e5 Nf3 Nc6 Bc4 Bc5');
      expect(toUci(white, mv('e1h1')), 'e1g1');
      expect(toUci(white, mv('e1g1')), 'e1g1');

      final black = replay('e4 e5 Nf3 Nf6 Bc4 Bc5 O-O');
      expect(toUci(black, mv('e8h8')), 'e8g8');

      final long = replay('d4 d5 Nc3 Nc6 Bf4 Bf5 Qd2 Qd7');
      expect(toUci(long, mv('e1a1')), 'e1c1');
    });

    test('promotion is always explicit, and an under-promotion is kept', () {
      final pos = Chess.fromSetup(Setup.parseFen('3r3k/4P3/8/8/8/8/8/4K3 w - - 0 1'));
      expect(toUci(pos, mv('e7e8')), 'e7e8q');
      expect(toUci(pos, mv('e7d8')), 'e7d8q');
      expect(toUci(pos, mv('e7e8n')), 'e7e8n');
    });

    test('ordinary moves are unchanged', () {
      expect(toUci(Chess.initial, mv('e2e4')), 'e2e4');
      final pos = replay('e4 e5 Bc4 Bc5');
      expect(toUci(pos, mv('e1f1')), 'e1f1');
    });

    test('parseUci reads engine output and rejects the rest', () {
      expect(parseUci('e7e8q')?.promotion, Role.queen);
      expect(parseUci('e2e4')?.to, Square.e4);
      expect(parseUci('(none)'), isNull);
      expect(parseUci('e2'), isNull);
    });

    test('formatEval: mates, and "#" for checkmate', () {
      expect(formatEval(30, null), '+0.3');
      expect(formatEval(10000, 3), 'M3');
      expect(formatEval(-10000, -2), '-M2');
      expect(formatEval(10000, 0), '#');
      expect(formatEval(-10000, 0), '#');
    });
  });

  group('engine lifecycle', () {
    test('one engine for the whole session; handed back when the screen closes',
        () async {
      await startPractice();
      await settle();
      await notifier().handlePlayerMove(mv('e2e4'));
      await notifier().handlePlayerMove(mv('e7e5'));
      await notifier().handlePlayerMove(mv('g1f3'));
      await notifier().evaluateSpecificMoves([mv('b8c6'), mv('b8a6')]);
      notifier()
        ..cancelPieceEvals()
        ..resumeHints();
      await settle();
      await notifier().pauseHints(); // the opening picker
      notifier().resumeHints();
      await settle();
      await notifier().startFromOpening('1. e4 e5 2. Nf3 Nc6 3. Bc4');
      await notifier().scrubBack();
      await notifier().scrubForward();
      notifier().pauseAnalysis(); // app backgrounded
      notifier().resumeHints();
      await settle();

      expect(engine.initializeCalls, 1);
      expect(engine.disposeWhenIdleCalls, 0,
          reason: 'no restart between moves, passes, pieces or the picker');
      expect(engine.disposeCalls, 0);

      final stops = engine.stopCalls;
      await closeScreen();
      expect(engine.stopCalls, stops + 1);
      expect(engine.disposeWhenIdleCalls, 1);
    });

    test('closing mid-analysis: nothing touches the disposed provider, and no '
        'search starts afterwards', () async {
      engine.holds = (fen, depth) => depth == 12;
      await startPractice();
      await settle();
      expect(engine.heldCount, 1, reason: 'wave 1 in flight');

      await closeScreen(); // throws "Ref after dispose" if unguarded
      await settle();
      final requests = engine.topMovesRequests.length;
      await settle();
      expect(engine.topMovesRequests.length, requests);
      expect(engine.disposeWhenIdleCalls, 1);
    });

    test('closing while the engine is still starting is safe', () async {
      engine.initGate = Completer<void>();
      unawaited(startPractice());
      await settle();
      await closeScreen();
      engine.initGate!.complete();
      await settle();
      expect(engine.disposeWhenIdleCalls, 1);
    });

    test('opening the picker during the engine start never releases it',
        () async {
      engine.initGate = Completer<void>();
      final start = startPractice();
      await settle();
      await notifier().pauseHints();
      expect(engine.disposeWhenIdleCalls + engine.disposeCalls, 0);

      engine.initGate!.complete();
      await start;
      await settle();
      expect(engine.isReady, isTrue);
      expect(engine.disposeWhenIdleCalls + engine.disposeCalls, 0);
    });

    test('a failed start shows the banner; Retry recovers and analyses',
        () async {
      engine.initError = 'no engine';
      await startPractice();
      await settle();
      expect(state().engineUnavailable, isTrue);

      engine.initError = null;
      final before = engine.topMovesRequests.length;
      await notifier().retryEngine();
      await settle();
      expect(state().engineUnavailable, isFalse);
      expect(engine.topMovesRequests.length, greaterThan(before));
    });

    test('picking an opening during a slow start runs a single hint loop',
        () async {
      engine.initGate = Completer<void>();
      final start = startPractice();
      await settle();
      final pick = notifier().startFromOpening('1. e4 e5 2. Nf3 Nc6 3. Bc4');
      await settle();
      final picked = notifier().currentPosition.fen;
      engine.initGate!.complete();
      await Future.wait([start, pick]);
      await settle();
      expect(engine.depthsFor(picked), [8, 12, 16, 18]);
      expect(engine.depthsFor(_initialFen), isEmpty,
          reason: 'the superseded start never analysed');
    });
  });

  group('analysis', () {
    test('backgrounding stops the search; returning resumes where it stopped',
        () async {
      engine.holds = (fen, depth) => depth == 16;
      await startPractice();
      await settle();
      final stops = engine.stopCalls;

      notifier().pauseAnalysis();
      expect(engine.stopCalls, stops + 1);
      expect(state().engineTargetDepth, 0);
      await settle();

      engine
        ..holds = ((_, __) => false)
        ..topMovesRequests.clear();
      notifier().resumeHints();
      await settle();
      expect(engine.depthsFor(_initialFen), [16, 18]);
    });

    test('a position left mid-analysis resumes the deeper waves', () async {
      await startPractice();
      await settle();
      final afterE4 = replay('e4').fen;
      engine.holds = (fen, depth) => fen == afterE4 && (depth ?? 0) >= 12;
      unawaited(notifier().handlePlayerMove(mv('e2e4')));
      await settle();
      expect(engine.depthsFor(afterE4), [8, 12]);

      await notifier().scrubBack(); // cancels the held wave
      await settle();
      engine
        ..holds = ((_, __) => false)
        ..topMovesRequests.clear();
      await notifier().scrubForward();
      await settle();
      expect(engine.depthsFor(afterE4), [12, 16, 18]);

      // Fully analysed now: revisiting restores it without the engine.
      await notifier().scrubBack();
      engine.topMovesRequests.clear();
      await notifier().scrubForward();
      await settle();
      expect(engine.depthsFor(afterE4), isEmpty);
    });

    test('castling: one O-O arrow, to the king\'s square', () async {
      final ruy = replay('e4 e5 Nf3 Nc6 Bb5 a6 Ba4 Nf6');
      engine.topMovesFor = (fen) => fen == ruy.fen
          ? const [
              ScoredMove(uci: 'e1g1', centipawns: 30, multipvIndex: 1),
              ScoredMove(uci: 'd2d3', centipawns: 20, multipvIndex: 2),
              ScoredMove(uci: 'b1c3', centipawns: 15, multipvIndex: 3),
              ScoredMove(uci: 'd1e2', centipawns: 10, multipvIndex: 4),
              ScoredMove(uci: 'd2d4', centipawns: 5, multipvIndex: 5),
            ]
          : firstLegalMove(fen);

      // Book arrows first (engine held), then the engine's.
      engine.holds = (fen, depth) => fen == ruy.fen;
      unawaited(notifier()
          .startFromOpening('1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6'));
      await settle();
      final bookCastle =
          state().topMoves.where((m) => m.san.startsWith('O-O')).toList();
      expect(bookCastle.map((m) => m.uci), ['e1g1']);

      engine
        ..holds = ((_, __) => false)
        ..releaseHeld();
      await settle();
      final castles =
          state().topMoves.where((m) => m.san.startsWith('O-O')).toList();
      expect(castles, hasLength(1));
      expect(castles.single.uci, 'e1g1');
      expect(state().topMoves.map((m) => m.uci), isNot(contains('e1h1')));
    });

    test('castling onto the rook is the same move as onto g1', () async {
      await notifier().startFromOpening('1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5');
      await notifier().handlePlayerMove(mv('e1h1'));
      expect(state().lines.single.moves.last.uci, 'e1g1');
      expect(state().lastMove, mv('e1g1'));

      await notifier().scrubBack();
      await notifier().handlePlayerMove(mv('e1g1'));
      expect(state().lines, hasLength(1), reason: 'no duplicate variation');
      expect(state().cursorPly, 6);
    });

    test('promotion moves are analysed as promotions, keyed like the engine',
        () async {
      await notifier()
          .startFromOpening('1. a4 b5 2. axb5 a6 3. bxa6 Nc6 4. a7 Rb8');
      engine.evaluated.clear();
      final results =
          await notifier().evaluateSpecificMoves([mv('a7a8'), mv('a7b8')]);

      expect(results.keys, containsAll(['a7a8q', 'a7b8q']));
      final children =
          engine.evaluated.where((f) => f.split(' ')[1] == 'b').toSet();
      expect(children, isNotEmpty);
      for (final fen in children) {
        expect(fen.split('/').first, contains('Q'),
            reason: 'the pawn became a queen: $fen');
      }
    });

    test('a forced mate reaches the eval bar, the line tag and revisits',
        () async {
      final afterE4 = replay('e4').fen;
      engine.topMovesFor = (fen) => fen == afterE4
          ? const [
              ScoredMove(
                  uci: 'e7e5', centipawns: 10000, mateIn: 3, multipvIndex: 1),
            ]
          : firstLegalMove(fen);
      await startPractice();
      await settle();
      await notifier().handlePlayerMove(mv('e2e4'));
      await settle();

      expect(state().currentEval.mateIn, 3);
      expect(state().lines.single.moves.last.mateIn, 3);

      await notifier().scrubBack();
      expect(state().currentEval.mateIn, isNull);
      await notifier().scrubForward();
      expect(state().currentEval.mateIn, 3);
    });
  });

  group('game end', () {
    test('checkmate: banner, verdict, and the engine is never asked', () async {
      await startPractice();
      await settle();
      for (final uci in ['f2f3', 'e7e5', 'g2g4']) {
        await notifier().handlePlayerMove(mv(uci));
      }
      await notifier().handlePlayerMove(mv('d8h4')); // Qh4#
      final matedFen = notifier().currentPosition.fen;

      expect(state().isGameOver, isTrue);
      expect(state().gameEnd, GameEnd.checkmate);
      expect(state().currentEval.mateIn, 0);
      expect(state().currentEval.centipawns, -10000, reason: 'black won');
      expect(state().lines.single.moves.last.mateIn, 0);
      expect(state().topMoves, isEmpty);

      await notifier().scrubBack();
      expect(state().isGameOver, isFalse);
      expect(state().gameEnd, isNull);
      await notifier().scrubForward();
      await settle();
      expect(state().gameEnd, GameEnd.checkmate);

      expect(engine.depthsFor(matedFen), isEmpty);
      expect(engine.evaluated, isNot(contains(matedFen)));
    });

    test('stalemate is a draw', () async {
      // Sam Loyd's ten-move stalemate, minus the last move.
      await notifier().startFromOpening(
          '1. e3 a5 2. Qh5 Ra6 3. Qxa5 h5 4. h4 Rah6 5. Qxc7 f6 '
          '6. Qxd7+ Kf7 7. Qxb7 Qd3 8. Qxb8 Qh7 9. Qxc8 Kg6');
      expect(state().cursorPly, 17);
      await notifier().handlePlayerMove(mv('c8e6'));

      expect(state().gameEnd, GameEnd.draw);
      expect(state().currentEval.centipawns, 0);
      expect(state().currentEval.mateIn, isNull);
      expect(engine.depthsFor(notifier().currentPosition.fen), isEmpty);
    });
  });
}
