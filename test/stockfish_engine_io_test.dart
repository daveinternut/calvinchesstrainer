import 'dart:async';

import 'package:calvinchesstrainer/core/services/stockfish_engine_api.dart';
import 'package:calvinchesstrainer/core/services/stockfish_engine_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockfish/stockfish.dart';

/// A scriptable stand-in for the package's native engine: same surface
/// (`state`, `stdout`, `stdin`, `dispose`) and the same rule that commands
/// are only accepted once it is running. Output is delivered asynchronously,
/// like the real engine's port messages.
class FakeStockfish implements Stockfish {
  FakeStockfish({this.autoStart = true}) {
    if (autoStart) Timer.run(start);
  }

  final bool autoStart;
  final _state = ValueNotifier<StockfishState>(StockfishState.starting);
  final _stdout = StreamController<String>.broadcast();
  final commands = <String>[];

  /// Withhold `readyok` until [answerIsready] is called.
  bool holdReadyok = false;

  /// The next N searches never finish on their own; only `stop` ends them.
  int hangingSearches = 0;

  /// Ignore `stop` (a wedged engine).
  bool ignoresStop = false;

  /// The score reported for a position, by FEN.
  int Function(String fen) scoreFor = (fen) => 0;

  /// Raw `score ...` text override, e.g. `mate 3`.
  String? scoreText;

  /// Report `bestmove (none)`.
  bool noLegalMove = false;

  int quitCount = 0;
  String _fen = '';
  String? _searchFen;

  void start() {
    if (_state.value == StockfishState.starting) {
      _state.value = StockfishState.ready;
    }
  }

  void answerIsready() => _emit('readyok');

  /// The native side dies on its own.
  void crash() {
    _state.value = StockfishState.disposed;
    _stdout.close();
  }

  @override
  Completer<Stockfish>? get completer => null;

  @override
  ValueListenable<StockfishState> get state => _state;

  @override
  Stream<String> get stdout => _stdout.stream;

  @override
  set stdin(String line) {
    if (_state.value != StockfishState.ready) {
      throw StateError('Stockfish is not ready (${_state.value})');
    }
    commands.add(line);
    _handle(line);
  }

  @override
  void dispose() {
    stdin = 'quit';
  }

  int get searchCount => commands.where((c) => c.startsWith('go')).length;

  void _emit(String line) => Timer.run(() {
        if (!_stdout.isClosed) _stdout.add(line);
      });

  void _handle(String line) {
    if (line == 'uci') {
      _emit('id name Fake');
      _emit('uciok');
    } else if (line == 'isready') {
      if (!holdReadyok) _emit('readyok');
    } else if (line.startsWith('position fen ')) {
      _fen = line.substring('position fen '.length);
    } else if (line.startsWith('go')) {
      _searchFen = _fen;
      if (hangingSearches > 0) {
        hangingSearches--;
      } else {
        _finish();
      }
    } else if (line == 'stop') {
      if (!ignoresStop) _finish();
    } else if (line == 'quit') {
      quitCount++;
      Timer.run(() {
        _state.value = StockfishState.disposed;
        _stdout.close();
      });
    }
  }

  void _finish() {
    final fen = _searchFen;
    if (fen == null) return; // `stop` with nothing searching: no output.
    _searchFen = null;
    if (noLegalMove) {
      _emit('info depth 0 score mate 0');
      _emit('bestmove (none)');
      return;
    }
    final score = scoreText ?? 'cp ${scoreFor(fen)}';
    _emit('info depth 10 seldepth 12 multipv 1 score $score nodes 1 pv e2e4');
    _emit('bestmove e2e4');
  }
}

const _fenA = 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1';
const _fenB = 'rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq - 0 1';
const _fenWhite = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

void main() {
  late List<FakeStockfish> engines;
  late FakeStockfish Function() nextEngine;

  NativeStockfishService service({
    Duration searchTimeout = const Duration(seconds: 30),
    Duration drainTimeout = const Duration(seconds: 5),
    Duration startTimeout = const Duration(seconds: 10),
  }) =>
      NativeStockfishService.forTesting(
        createEngine: () {
          final engine = nextEngine();
          engines.add(engine);
          return engine;
        },
        searchTimeout: searchTimeout,
        drainTimeout: drainTimeout,
        startTimeout: startTimeout,
        retryDelay: const Duration(milliseconds: 1),
      );

  setUp(() {
    engines = [];
    nextEngine = FakeStockfish.new;
  });

  group('lifecycle', () {
    test('one engine serves every operation; nothing restarts between them',
        () async {
      final sf = service();
      await sf.initialize();
      for (var i = 0; i < 5; i++) {
        await sf.evaluate(_fenA, depth: 8);
        await sf.getTopMoves(_fenB, count: 5, depth: 12);
      }
      expect(engines, hasLength(1));
      expect(engines.single.quitCount, 0);
      expect(sf.isReady, isTrue);
    });

    test('an in-flight start counts as busy', () async {
      nextEngine = () => FakeStockfish(autoStart: false);
      final sf = service();
      final start = sf.initialize();
      await pumpEventQueue();
      expect(sf.isBusy, isTrue);
      engines.single.start();
      await start;
      expect(sf.isBusy, isFalse);
      expect(sf.isReady, isTrue);
    });

    test('a release requested during the handshake waits for it, then quits',
        () async {
      nextEngine = () => FakeStockfish()..holdReadyok = true;
      final sf = service();
      final start = sf.initialize();
      await pumpEventQueue();

      sf.disposeWhenIdle();
      await pumpEventQueue();
      expect(engines.single.quitCount, 0, reason: 'never quit mid-start');
      expect(sf.isBusy, isTrue);

      engines.single.answerIsready();
      await start;
      await pumpEventQueue();
      expect(engines.single.quitCount, 1);
      expect(sf.isReady, isFalse, reason: 'never ready without an engine');
    });

    test('an engine that times out while starting is quit once it is up',
        () async {
      nextEngine = () => FakeStockfish(autoStart: false);
      final sf = service(startTimeout: const Duration(milliseconds: 20));
      final start = sf.initialize();
      sf.disposeWhenIdle(); // the screen closing mid-start
      await expectLater(start, throwsA(isA<EngineUnavailableException>()));
      expect(sf.isReady, isFalse);
      expect(engines.single.quitCount, 0, reason: 'still starting: no quit');

      // The native side comes up late: it must be quit, not orphaned (an
      // orphan keeps the package's one-engine slot taken for good).
      engines.single.start();
      await pumpEventQueue();
      expect(engines.single.quitCount, 1);
    });

    test('disposeWhenIdle waits for running work, and a new request cancels it',
        () async {
      nextEngine = () => FakeStockfish()..hangingSearches = 1;
      final sf = service();
      await sf.initialize();
      final search = sf.evaluate(_fenA, depth: 18);
      await pumpEventQueue();

      sf.disposeWhenIdle();
      expect(engines.single.quitCount, 0);
      // A new request (a screen reopening) keeps the engine.
      final next = sf.evaluate(_fenB, depth: 8);
      sf.stopSearch(); // ends the hanging search; drops `next` too
      await search;
      await expectLater(next, throwsA(isA<SearchCancelledException>()));
      await pumpEventQueue();
      expect(engines.single.quitCount, 0);
      expect(sf.isReady, isTrue);

      sf.disposeWhenIdle();
      await pumpEventQueue();
      expect(engines.single.quitCount, 1);
      expect(sf.isReady, isFalse);
    });

    test('an engine that exited on its own is replaced on the next request',
        () async {
      final sf = service();
      await sf.initialize();
      engines.single.crash();
      await pumpEventQueue();
      final eval = await sf.evaluate(_fenA, depth: 8);
      expect(eval.depth, 10);
      expect(engines, hasLength(2));
    });
  });

  group('timeouts', () {
    test('a timed-out search is drained, so its late bestmove cannot be read '
        'as the next result', () async {
      nextEngine = () => FakeStockfish()
        ..hangingSearches = 1
        ..scoreFor = (fen) => fen == _fenA ? 111 : 222;
      final sf = service(searchTimeout: const Duration(milliseconds: 30));
      await sf.initialize();

      final first = await sf.evaluate(_fenA, depth: 18);
      final second = await sf.evaluate(_fenB, depth: 8);

      // Both black to move, so scores come back negated.
      expect(first.centipawns, -111, reason: 'A got its own (stopped) search');
      expect(second.centipawns, -222, reason: 'B was not handed A\'s output');
      expect(engines, hasLength(1));
    });

    test('an engine that ignores stop is restarted', () async {
      var made = 0;
      nextEngine = () {
        made++;
        final engine = FakeStockfish();
        if (made == 1) {
          engine
            ..hangingSearches = 1
            ..ignoresStop = true;
        }
        return engine;
      };
      final sf = service(
        searchTimeout: const Duration(milliseconds: 20),
        drainTimeout: const Duration(milliseconds: 20),
      );
      await sf.initialize();
      await sf.evaluate(_fenA, depth: 18);
      expect(engines.first.quitCount, 1);

      final eval = await sf.evaluate(_fenB, depth: 8);
      expect(eval.depth, 10);
      expect(engines, hasLength(2));
    });
  });

  group('stopSearch', () {
    test('aborts the running search and drops queued ones; later ones run',
        () async {
      nextEngine = () => FakeStockfish()..hangingSearches = 1;
      final sf = service();
      await sf.initialize();

      final running = sf.evaluate(_fenA, depth: 18);
      final queued = sf.getTopMoves(_fenB, count: 5, depth: 12);
      await pumpEventQueue();
      sf.stopSearch();

      await running; // answered by its stopped search
      await expectLater(queued, throwsA(isA<SearchCancelledException>()));
      final after = await sf.evaluate(_fenB, depth: 8);
      expect(after.depth, 10);
      expect(engines.single.searchCount, 2, reason: 'the queued op never ran');
    });
  });

  group('start failures', () {
    test('fail fast until initialize() is called again', () async {
      var fail = true;
      var attempts = 0;
      nextEngine = () {
        attempts++;
        if (fail) throw StateError('Multiple instances are not supported');
        return FakeStockfish();
      };
      final sf = service();

      await expectLater(
          sf.initialize(), throwsA(isA<EngineUnavailableException>()));
      final attemptsAfterStart = attempts;

      // Operations don't each sit out another start.
      await expectLater(sf.evaluate(_fenA, depth: 8),
          throwsA(isA<EngineUnavailableException>()));
      expect(attempts, attemptsAfterStart);

      fail = false;
      await sf.initialize(); // the Retry button
      final eval = await sf.evaluate(_fenA, depth: 8);
      expect(eval.depth, 10);
    });
  });

  group('protocol', () {
    test('bestmove (none) means no move', () async {
      nextEngine = () => FakeStockfish()..noLegalMove = true;
      final sf = service();
      expect(await sf.getBestMove(_fenA, movetime: 100), isNull);
    });

    test('mate scores keep their sign from white\'s perspective', () async {
      nextEngine = () => FakeStockfish()..scoreText = 'mate 3';
      final sf = service();
      final blackToMove = await sf.evaluate(_fenA, depth: 8);
      expect(blackToMove.mateIn, -3);
      expect(blackToMove.centipawns, -10000);

      final whiteToMove = await sf.evaluate(_fenWhite, depth: 8);
      expect(whiteToMove.mateIn, 3);
      expect(whiteToMove.centipawns, 10000);
    });

    test('mate 0 is reported as mate 0, signed by centipawns', () async {
      nextEngine = () => FakeStockfish()..scoreText = 'mate 0';
      final sf = service();
      final mated = await sf.evaluate(_fenA, depth: 8); // black to move
      expect(mated.mateIn, 0);
      expect(mated.centipawns, 10000, reason: 'black is mated: white wins');
    });

    test('top moves come back in multipv order, white-perspective', () async {
      final sf = service();
      final moves = await sf.getTopMoves(_fenWhite, count: 1, depth: 8);
      expect(moves.single.uci, 'e2e4');
      expect(moves.single.multipvIndex, 1);
    });
  });
}
