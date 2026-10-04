import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/personal_bests_service.dart';
import '../../../core/services/puzzle_service.dart';
import '../../../core/services/scan_position_service.dart';
import '../models/chess_vision_state.dart';
import '../services/fork_skewer_engine.dart';
import '../services/knight_engine.dart';
import '../services/pawn_attack_engine.dart';
import '../services/scan_engine.dart';

/// Auto-disposed: a round never outlives its screen. Leaving the drill
/// disposes the notifier, which cancels every timer, and the next visit
/// starts from a fresh, neutral state. Personal bests live in the keep-alive
/// [personalBestsProvider].
final chessVisionProvider =
    NotifierProvider.autoDispose<ChessVisionNotifier, ChessVisionState>(
  ChessVisionNotifier.new,
);

class ChessVisionNotifier extends Notifier<ChessVisionState> {
  /// Share of Forks & Skewers rounds (outside concentric) whose answer is
  /// "None". Fixed, so the piece/target pairing doesn't decide it — rook vs
  /// rook used to be about 70% None.
  static const noneRoundChance = 0.15;

  /// Length of a speed round's countdown.
  static const speedRoundSeconds = 60;

  /// Timed Pawn Attack climbs from 3 pawns to 8 (practice wraps back to 3).
  static const pawnAttackFirstLevel = 3;
  static const pawnAttackLastLevel = 8;

  final _random = Random();
  Timer? _flashTimer;
  Timer? _advanceTimer;
  Timer? _countdownTimer;
  Timer? _stopwatchTimer;

  /// Forks & Skewers answers for every target square, for this game's
  /// piece/target pairing (computed once in [startGame]).
  Map<Square, Set<Square>> _forkSolutions = const {};
  Square? _lastForkTarget;
  List<Square> _filteredConcentricPath = const [];
  ScanPosition? _currentScanPosition;
  bool _knightSightPickEdge = false;

  // Bumped by every startGame and on dispose; an asset load that finishes
  // after a newer game started (or after the screen closed) is dropped.
  int _gameGeneration = 0;

  // Read once in build(), so nothing that runs after an await or in a timer
  // needs to go back through `ref`.
  late AudioService _audio;
  late AnalyticsService _analytics;
  late ScanPositionService _scanPositions;
  late PuzzleService _matePuzzles;
  late PersonalBestsNotifier _bests;

  @override
  ChessVisionState build() {
    _audio = ref.read(audioServiceProvider);
    _analytics = ref.read(analyticsServiceProvider);
    _scanPositions = ref.read(scanPositionServiceProvider);
    _matePuzzles = ref.read(mateInOnePuzzleServiceProvider);
    _bests = ref.read(personalBestsProvider.notifier);
    ref.onDispose(_dispose);
    // Neutral until the screen calls startGame: `isLoading` blocks input and
    // keeps the screen from drawing any drill's board or results.
    return const ChessVisionState(
      drillType: VisionDrillType.forksAndSkewers,
      mode: VisionMode.practice,
      whitePiece: WhitePiece.queen,
      isLoading: true,
    );
  }

  /// Personal-best key, e.g. `vision.forksAndSkewers_queen_rook_speed`.
  String get _bestKey {
    final drill = state.drillType.name;
    final mode = state.mode.name;
    return switch (state.drillType) {
      VisionDrillType.forksAndSkewers =>
        'vision.${drill}_${state.whitePiece.name}_${state.targetPiece.name}_$mode',
      VisionDrillType.pawnAttack =>
        'vision.${drill}_${state.whitePiece.name}_$mode',
      _ => 'vision.${drill}_$mode',
    };
  }

  /// Concentric and timed Pawn Attack run on a stopwatch and rank by time
  /// (lower is better); speed rounds count down and rank by positions solved.
  bool get _isTimedByStopwatch =>
      state.mode == VisionMode.concentric ||
      (state.drillType == VisionDrillType.pawnAttack &&
          state.mode == VisionMode.speed);

  static bool _usesPiece(VisionDrillType drill) =>
      drill == VisionDrillType.forksAndSkewers ||
      drill == VisionDrillType.pawnAttack;

  Future<void> startGame(
      VisionDrillType drillType, VisionMode mode, WhitePiece piece,
      {TargetPiece targetPiece = TargetPiece.rook}) async {
    _cancelTimers();
    final generation = ++_gameGeneration;
    var effectiveMode = drillType.effectiveMode(mode);

    _forkSolutions = const {};
    _filteredConcentricPath = const [];
    _lastForkTarget = null;
    _currentScanPosition = null;
    if (drillType == VisionDrillType.forksAndSkewers) {
      _forkSolutions = {
        for (final target in Square.values)
          if (target != ChessVisionState.blackKingSquare)
            target: ForkSkewerEngine.computeValidSquares(
              whitePiece: piece,
              kingSquare: ChessVisionState.blackKingSquare,
              targetSquare: target,
              targetRole: targetPiece.role,
            ),
      };
      if (effectiveMode == VisionMode.concentric) {
        _filteredConcentricPath = [
          for (final target in concentricPath)
            if (_forkSolutions[target]!.isNotEmpty) target,
        ];
        // A pairing with no fork or skewer anywhere (knight vs knight: the
        // knights can always take each other) has no spiral to walk. Never a
        // dead end — fall back to practice, where its rounds are None rounds.
        if (_filteredConcentricPath.isEmpty) {
          effectiveMode = VisionMode.practice;
        }
      }
    }

    final usesCountdown = effectiveMode == VisionMode.speed &&
        drillType != VisionDrillType.pawnAttack;
    state = ChessVisionState(
      drillType: drillType,
      mode: effectiveMode,
      whitePiece: piece,
      targetPiece: targetPiece,
      timeRemainingSeconds: usesCountdown ? speedRoundSeconds : null,
      concentricTotal: _filteredConcentricPath.length,
      isLoading: drillType.isScanDrill,
    );

    _analytics.logVisionDrillStarted(
      drill: drillType.name,
      mode: effectiveMode.name,
      piece: _usesPiece(drillType) ? piece.name : null,
      target: drillType == VisionDrillType.forksAndSkewers
          ? targetPiece.name
          : null,
    );

    switch (drillType) {
      case VisionDrillType.forksAndSkewers:
        _generateNextConfiguration();
      case VisionDrillType.knightSight:
        _generateKnightSightConfig();
      case VisionDrillType.knightFlight:
        _generateKnightFlightConfig();
      case VisionDrillType.pawnAttack:
        _generatePawnAttackConfig();
      case VisionDrillType.findChecks:
      case VisionDrillType.findCaptures:
      case VisionDrillType.hangingPieces:
      case VisionDrillType.mateInOne:
        final loaded = await _loadScanAssets(drillType);
        // The screen may have closed, or a newer game started, meanwhile.
        if (!ref.mounted || generation != _gameGeneration) return;
        if (!loaded) {
          state = state.copyWith(isLoading: false, loadFailed: true);
          return;
        }
        state = state.copyWith(isLoading: false);
        if (drillType == VisionDrillType.mateInOne) {
          _loadNextMatePuzzle();
        } else {
          _loadNextScanPosition();
        }
    }

    if (_isTimedByStopwatch) {
      _startStopwatch();
    } else if (usesCountdown) {
      _startCountdown();
    }
  }

  /// Loads a scanning drill's curated set. False when it can't be read or
  /// holds nothing playable — the screen then offers a retry instead of an
  /// endless spinner.
  Future<bool> _loadScanAssets(VisionDrillType drill) async {
    try {
      if (drill == VisionDrillType.mateInOne) {
        await _matePuzzles.loadPuzzles();
        return _matePuzzles.puzzleCount > 0;
      }
      await _scanPositions.load(_scanKindFor(drill));
      return true;
    } catch (e) {
      dev.log('ChessVision: could not load the ${drill.name} set: $e');
      return false;
    }
  }

  // --- Tap routing ---

  /// False whenever the player's input must not count: before the game is
  /// ready, between rounds, during a reveal, and after game over.
  bool get _acceptingInput =>
      !state.isLoading &&
      !state.loadFailed &&
      !state.isGameOver &&
      !state.isRoundComplete &&
      !state.showingRevealedAnswer;

  void handleBoardTap(Square square) {
    if (!_acceptingInput) return;

    switch (state.drillType) {
      case VisionDrillType.forksAndSkewers:
        _handleForksSkewersTap(square);
      case VisionDrillType.knightSight:
        _handleKnightSightTap(square);
      case VisionDrillType.knightFlight:
        _handleKnightFlightTap(square);
      case VisionDrillType.pawnAttack:
        _handlePawnAttackTap(square);
      case VisionDrillType.findChecks:
      case VisionDrillType.findCaptures:
      case VisionDrillType.hangingPieces:
        _handleScanTap(square);
      case VisionDrillType.mateInOne:
        break; // moves arrive via handleMateMove, not square taps
    }
  }

  // --- Forks & Skewers ---

  void _handleForksSkewersTap(Square square) {
    if (square == ChessVisionState.blackKingSquare ||
        square == state.targetSquare) {
      return;
    }
    if (state.foundSquares.contains(square)) return;

    if (state.correctSquares.contains(square)) {
      _handleCorrectTap(square);
    } else {
      _handleIncorrectTap(square);
    }
  }

  void handleNoneTap() {
    if (state.drillType != VisionDrillType.forksAndSkewers) return;
    if (!_acceptingInput) return;

    if (state.correctSquares.isEmpty) {
      _audio.playCorrect();
      _completeConfiguration(madeError: false);
    } else {
      // Wrong: show the answer, cost the streak, count nothing.
      _audio.playIncorrect();
      _revealAndMoveOn();
    }
  }

  void _generateNextConfiguration() {
    final Square target;

    if (state.mode == VisionMode.concentric) {
      if (state.concentricIndex >= _filteredConcentricPath.length) return;
      target = _filteredConcentricPath[state.concentricIndex];
      state = state.copyWith(concentricIndex: state.concentricIndex + 1);
    } else {
      target = _pickForkTarget();
    }
    _lastForkTarget = target;

    state = state.copyWith(
      targetSquare: target,
      correctSquares: _forkSolutions[target] ?? const {},
      foundSquares: const {},
      incorrectFlashSquare: () => null,
      showingRevealedAnswer: false,
      hadErrorThisRound: false,
      isRoundComplete: false,
    );
  }

  /// A None round [noneRoundChance] of the time, otherwise a target with at
  /// least one solution — never the previous round's target.
  Square _pickForkTarget() {
    final withSolutions = <Square>[];
    final withoutSolutions = <Square>[];
    _forkSolutions.forEach((target, solutions) {
      if (target == _lastForkTarget) return;
      (solutions.isEmpty ? withoutSolutions : withSolutions).add(target);
    });
    final wantNone = _random.nextDouble() < noneRoundChance;
    final pool = (wantNone && withoutSolutions.isNotEmpty) ||
            withSolutions.isEmpty
        ? withoutSolutions
        : withSolutions;
    return pool[_random.nextInt(pool.length)];
  }

  // --- Knight Sight ---

  void _handleKnightSightTap(Square square) {
    if (square == state.knightSquare) return;
    if (state.foundSquares.contains(square)) return;

    if (state.correctSquares.contains(square)) {
      _handleCorrectTap(square);
    } else {
      _handleIncorrectTap(square);
    }
  }

  static const _centralSquares = [
    Square.c3, Square.c4, Square.c5, Square.c6,
    Square.d3, Square.d4, Square.d5, Square.d6,
    Square.e3, Square.e4, Square.e5, Square.e6,
    Square.f3, Square.f4, Square.f5, Square.f6,
  ];

  static const _edgeSquares = [
    Square.a1, Square.a2, Square.a3, Square.a4,
    Square.a5, Square.a6, Square.a7, Square.a8,
    Square.b1, Square.b2, Square.b7, Square.b8,
    Square.g1, Square.g2, Square.g7, Square.g8,
    Square.h1, Square.h2, Square.h3, Square.h4,
    Square.h5, Square.h6, Square.h7, Square.h8,
  ];

  void _generateKnightSightConfig() {
    final pool = _knightSightPickEdge ? _edgeSquares : _centralSquares;
    _knightSightPickEdge = !_knightSightPickEdge;

    Square sq;
    do {
      sq = pool[_random.nextInt(pool.length)];
    } while (sq == state.knightSquare);

    final moves = KnightEngine.knightMoves(sq);

    state = state.copyWith(
      knightSquare: () => sq,
      correctSquares: moves,
      foundSquares: const {},
      incorrectFlashSquare: () => null,
      hadErrorThisRound: false,
      isRoundComplete: false,
    );
  }

  // --- Knight Flight ---

  void _handleKnightFlightTap(Square square) {
    if (state.flightComplete) return;

    final currentPos = state.flightPath.isNotEmpty
        ? state.flightPath.last
        : state.knightSquare;
    if (currentPos == null) return;

    // Tapping the knight on its own square is a no-op (selecting your piece must
    // never cost a point). This also absorbs the harmless second callback when a
    // tap-to-select or drag move resolves: by then the knight is already on
    // `square`, so currentPos == square.
    if (square == currentPos) return;

    if (!KnightEngine.isKnightMove(currentPos, square)) {
      _handleIncorrectTap(square);
      return;
    }

    _audio.playCorrect();
    final newPath = [...state.flightPath, square];
    state = state.copyWith(flightPath: newPath);

    if (square == state.flightTargetSquare) {
      final isOptimal = newPath.length == state.minimumMoves;
      state = state.copyWith(flightComplete: true);
      if (isOptimal) {
        _completeConfiguration(madeError: state.hadErrorThisRound);
      }
    }
  }

  void retryFlight() {
    if (state.drillType != VisionDrillType.knightFlight) return;
    if (!_acceptingInput) return;
    if (!state.flightComplete || state.knightSquare == null) return;
    state = state.copyWith(
      flightPath: const [],
      flightComplete: false,
      hadErrorThisRound: false,
      incorrectFlashSquare: () => null,
    );
  }

  /// Accepts a non-optimal arrival and moves on (counted, streak reset). The
  /// input gate makes a double tap on Skip count once.
  void skipFlight() {
    if (state.drillType != VisionDrillType.knightFlight) return;
    if (!_acceptingInput) return;
    if (!state.flightComplete) return;
    _completeConfiguration(madeError: true);
  }

  void _generateKnightFlightConfig() {
    final from = _randomSquare(exclude: state.knightSquare);
    Square to;
    do {
      to = _randomSquare();
    } while (to == from);

    final minMoves = KnightEngine.shortestPath(from, to);

    state = state.copyWith(
      knightSquare: () => from,
      flightTargetSquare: () => to,
      flightPath: const [],
      minimumMoves: () => minMoves,
      flightComplete: false,
      correctSquares: const {},
      foundSquares: const {},
      incorrectFlashSquare: () => null,
      hadErrorThisRound: false,
      isRoundComplete: false,
    );
  }

  Square _randomSquare({Square? exclude}) {
    final candidates = Square.values.where((s) => s != exclude).toList();
    return candidates[_random.nextInt(candidates.length)];
  }

  // --- Pawn Attack ---

  void _handlePawnAttackTap(Square square) {
    final from = state.pieceSquare;
    if (from == null) return;
    if (square == from) return;

    final role = state.whitePiece.role;
    final valid = PawnAttackEngine.validMoves(
      role: role,
      from: from,
      remainingPawns: state.remainingPawns,
    );

    if (!valid.contains(square)) {
      _handleIncorrectTap(square);
      return;
    }

    final isCapture = state.remainingPawns.contains(square);
    if (isCapture) {
      _audio.playCorrect();
    }

    final newPawns = isCapture
        ? ({...state.remainingPawns}..remove(square))
        : state.remainingPawns;

    state = state.copyWith(
      pieceSquare: () => square,
      remainingPawns: newPawns,
      pawnThreatSquares: isCapture
          ? PawnAttackEngine.pawnThreats(newPawns)
          : state.pawnThreatSquares,
      pawnAttackMoves: state.pawnAttackMoves + 1,
      pawnAttackDeadEnd: !PawnAttackEngine.isSolvable(
        role: role,
        from: square,
        pawns: newPawns,
      ),
      incorrectFlashSquare: () => null,
    );

    if (newPawns.isEmpty) {
      _completeConfiguration(
        madeError: state.hadErrorThisRound,
        delay: const Duration(milliseconds: 800),
      );
    }
  }

  /// Puts the current Pawn Attack board back the way it was dealt — the way
  /// out of a position the player has trapped themselves in. It costs
  /// nothing (errors already made still count); in timed mode the clock
  /// keeps running.
  void startOverPawnBoard() {
    if (state.drillType != VisionDrillType.pawnAttack) return;
    if (!_acceptingInput) return;
    if (state.pawnAttackMoves == 0) return;
    _setPawnBoard(state.pawnAttackStartPawns);
  }

  void _generatePawnAttackConfig() {
    final pawns = PawnAttackEngine.generatePawns(
      state.pawnAttackDifficulty,
      _random,
      role: state.whitePiece.role,
    );
    _setPawnBoard(pawns, newRound: true);
  }

  void _advancePawnLevel() {
    final next = state.pawnAttackDifficulty + 1;
    state = state.copyWith(
      pawnAttackDifficulty:
          next > pawnAttackLastLevel ? pawnAttackFirstLevel : next,
    );
    _generatePawnAttackConfig();
  }

  /// Deals [pawns] with the piece back on its start square.
  void _setPawnBoard(Set<Square> pawns, {bool newRound = false}) {
    state = state.copyWith(
      pieceSquare: () => PawnAttackEngine.startSquare,
      remainingPawns: pawns,
      pawnAttackStartPawns: pawns,
      pawnThreatSquares: PawnAttackEngine.pawnThreats(pawns),
      pawnAttackMoves: 0,
      pawnAttackDeadEnd: !PawnAttackEngine.isSolvable(
        role: state.whitePiece.role,
        from: PawnAttackEngine.startSquare,
        pawns: pawns,
      ),
      incorrectFlashSquare: () => null,
      hadErrorThisRound: newRound ? false : null,
      isRoundComplete: newRound ? false : null,
    );
  }

  /// Test hook: deals a specific Pawn Attack board for the current game.
  @visibleForTesting
  void debugSetPawnBoard(Set<Square> pawns) =>
      _setPawnBoard(pawns, newRound: true);

  // --- Scanning drills (findChecks / findCaptures / hangingPieces / mateInOne) ---

  static ScanSetKind _scanKindFor(VisionDrillType drill) => switch (drill) {
        VisionDrillType.findChecks => ScanSetKind.checks,
        VisionDrillType.findCaptures => ScanSetKind.captures,
        VisionDrillType.hangingPieces => ScanSetKind.hanging,
        _ => throw ArgumentError('not a tap scanning drill: $drill'),
      };

  void _loadNextScanPosition() {
    final drill = state.drillType;
    final entry = _scanPositions.getRandom(
      _scanKindFor(drill),
      exclude: _currentScanPosition,
    );
    _currentScanPosition = entry;
    final position = entry.position;

    final targets = switch (drill) {
      VisionDrillType.findChecks => ScanEngine.checkTargets(position),
      VisionDrillType.findCaptures => ScanEngine.captureTargets(position),
      VisionDrillType.hangingPieces => ScanEngine.hangingTargets(position),
      _ => <Square>{},
    };
    // Curation computed the same predicate in python-chess; a mismatch means
    // the pipeline and ScanEngine have drifted apart.
    assert(
      targets.length == entry.targetCount,
      'ScanEngine disagrees with curated n for ${entry.fen}: '
      'engine ${targets.length} vs curated ${entry.targetCount}',
    );

    state = state.copyWith(
      scanPosition: () => position,
      scanDisplayFen: () => entry.fen,
      scanSideToMove: position.turn,
      checkGhosts: drill == VisionDrillType.findChecks
          ? ScanEngine.checkTargetDetails(position)
          : const {},
      correctSquares: targets,
      foundSquares: const {},
      incorrectFlashSquare: () => null,
      showingRevealedAnswer: false,
      hadErrorThisRound: false,
      isRoundComplete: false,
    );
  }

  void _loadNextMatePuzzle() {
    final puzzle = _matePuzzles.getRandomPuzzle(exclude: state.currentMatePuzzle);
    state = state.copyWith(
      currentMatePuzzle: () => puzzle,
      scanPosition: () => puzzle.position,
      scanDisplayFen: () => puzzle.position.fen,
      scanSideToMove: puzzle.sideToMove,
      mateFeedback: () => null,
      matedPosition: () => null,
      correctSquares: const {},
      foundSquares: const {},
      incorrectFlashSquare: () => null,
      showingRevealedAnswer: false,
      hadErrorThisRound: false,
      isRoundComplete: false,
    );
  }

  void _handleScanTap(Square square) {
    if (state.foundSquares.contains(square)) return;

    if (state.correctSquares.contains(square)) {
      if (state.drillType == VisionDrillType.findChecks) {
        _audio.playCheckCall(); // "Check!" layered over the correct SFX
      }
      _handleCorrectTap(square);
    } else {
      _handleIncorrectTap(square);
    }
  }

  /// Reveal-and-move-on escape hatch for the tap scanning drills: costs an
  /// error and the streak, counts nothing, shows the unfound targets for
  /// 1.5 s (the same reveal as a wrong forks "None").
  void skipScanPosition() {
    if (!state.drillType.isTapScanDrill) return;
    if (!_acceptingInput) return;

    _audio.playIncorrect();
    _revealAndMoveOn();
  }

  /// Mate in 1 verdict — judged by RESULT (any legal move that mates counts,
  /// not just the dataset answer).
  void handleMateMove(NormalMove move) {
    if (state.drillType != VisionDrillType.mateInOne) return;
    if (!_acceptingInput) return;
    final puzzle = state.currentMatePuzzle;
    if (puzzle == null) return;

    final isSpeed = state.mode == VisionMode.speed;
    final isMate = ScanEngine.isMatingMove(puzzle.position, move);

    // Longer beats than the tap drills: there is something to absorb (a mated
    // board + "Checkmate!", or a solution arrow to comprehend).
    if (isMate) {
      // Play the normalized form (handles either castling encoding); keep the
      // original move for feedback so the highlight shows the square the kid
      // actually chose.
      final mated = puzzle.position.playUnchecked(
        puzzle.position.normalizeMove(move),
      );
      _audio.playCorrect();
      _audio.playCheckmateCall();
      state = state.copyWith(
        scanDisplayFen: () => mated.fen,
        matedPosition: () => mated,
        mateFeedback: () => ScanMateFeedback(
          isCorrect: true,
          attemptedMove: move,
          solutionMove: puzzle.expectedMove,
        ),
      );
      _completeConfiguration(
        madeError: false,
        delay: Duration(milliseconds: isSpeed ? 500 : 900),
      );
    } else {
      // Board FEN stays untouched, so the tried piece snaps back; the green
      // solution arrow renders via mateFeedbackShapes. Not counted.
      _audio.playIncorrect();
      state = state.copyWith(
        mateFeedback: () => ScanMateFeedback(
          isCorrect: false,
          attemptedMove: move,
          solutionMove: puzzle.expectedMove,
        ),
        streak: 0,
        totalErrors: state.totalErrors + 1,
        hadErrorThisRound: true,
        isRoundComplete: true,
      );
      _scheduleNextRound(Duration(milliseconds: isSpeed ? 800 : 1500));
    }
  }

  // --- Shared helpers ---

  void _handleCorrectTap(Square square) {
    final newFound = {...state.foundSquares, square};
    _audio.playCorrect();

    state = state.copyWith(foundSquares: newFound);

    if (newFound.length >= state.correctSquares.length) {
      _completeConfiguration(madeError: state.hadErrorThisRound);
    }
  }

  void _handleIncorrectTap(Square square) {
    _audio.playIncorrect();
    state = state.copyWith(
      incorrectFlashSquare: () => square,
      hadErrorThisRound: true,
      totalErrors: state.totalErrors + 1,
    );

    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 400), () {
      state = state.copyWith(incorrectFlashSquare: () => null);
    });
  }

  /// A solved round, scored right away — so a solve in the last moments of a
  /// speed round still counts if time runs out during the feedback beat —
  /// with the next position after [delay] (default: 400 ms speed, 800 ms
  /// otherwise).
  void _completeConfiguration({required bool madeError, Duration? delay}) {
    final streak = madeError ? 0 : state.streak + 1;
    state = state.copyWith(
      isRoundComplete: true,
      streak: streak,
      bestStreak: max(streak, state.bestStreak),
      configurationsCompleted: state.configurationsCompleted + 1,
    );
    _scheduleNextRound(delay ??
        (state.mode == VisionMode.speed
            ? const Duration(milliseconds: 400)
            : const Duration(milliseconds: 800)));
  }

  /// A wrong "None" or a Skip: show the answer for a moment, cost an error
  /// and the streak, and count nothing.
  void _revealAndMoveOn() {
    state = state.copyWith(
      showingRevealedAnswer: true,
      totalErrors: state.totalErrors + 1,
      streak: 0,
    );
    _scheduleNextRound(const Duration(milliseconds: 1500));
  }

  /// Shows the next position after [delay]. When the round that just ended
  /// was the last one (concentric spiral walked, timed pawn ladder topped),
  /// the stopwatch stops now and the results follow after [delay].
  void _scheduleNextRound(Duration delay) {
    final isLast = _wasFinalRound;
    if (isLast) _stopwatchTimer?.cancel();
    _advanceTimer?.cancel();
    _advanceTimer = Timer(delay, isLast ? _finishGame : _loadNextRound);
  }

  bool get _wasFinalRound {
    if (state.mode == VisionMode.concentric) {
      return state.concentricIndex >= _filteredConcentricPath.length;
    }
    return state.drillType == VisionDrillType.pawnAttack &&
        state.mode == VisionMode.speed &&
        state.pawnAttackDifficulty >= pawnAttackLastLevel;
  }

  void _loadNextRound() {
    if (state.isGameOver) return;

    switch (state.drillType) {
      case VisionDrillType.forksAndSkewers:
        _generateNextConfiguration();
      case VisionDrillType.knightSight:
        _generateKnightSightConfig();
      case VisionDrillType.knightFlight:
        _generateKnightFlightConfig();
      case VisionDrillType.pawnAttack:
        _advancePawnLevel();
      case VisionDrillType.findChecks:
      case VisionDrillType.findCaptures:
      case VisionDrillType.hangingPieces:
        _loadNextScanPosition();
      case VisionDrillType.mateInOne:
        _loadNextMatePuzzle();
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = (state.timeRemainingSeconds ?? 0) - 1;
      if (remaining > 0) {
        state = state.copyWith(timeRemainingSeconds: () => remaining);
        return;
      }
      state = state.copyWith(timeRemainingSeconds: () => 0);
      _finishGame();
      _audio.playGameOver();
    });
  }

  void _startStopwatch() {
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isGameOver) return;
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  /// Ends the game: stops every timer, submits the personal best, and marks
  /// a new record in state for the results card.
  void _finishGame() {
    _cancelTimers();

    final bool isNewRecord;
    if (_isTimedByStopwatch) {
      isNewRecord =
          _bests.submit(_bestKey, state.elapsedSeconds, lowerIsBetter: true);
    } else if (state.mode == VisionMode.speed) {
      isNewRecord = _bests.submit(_bestKey, state.configurationsCompleted);
    } else {
      isNewRecord = false;
    }

    state = state.copyWith(isGameOver: true, isNewRecord: isNewRecord);
    if (isNewRecord) _audio.playNewRecord();

    _analytics.logVisionDrillCompleted(
      drill: state.drillType.name,
      mode: state.mode.name,
      piece: _usesPiece(state.drillType) ? state.whitePiece.name : null,
      target: state.drillType == VisionDrillType.forksAndSkewers
          ? state.targetPiece.name
          : null,
      configurationsCompleted: state.configurationsCompleted,
      totalErrors: state.totalErrors,
      bestStreak: state.bestStreak,
      isNewRecord: isNewRecord,
      elapsedSeconds:
          state.elapsedSeconds > 0 ? state.elapsedSeconds : null,
    );
  }

  void _cancelTimers() {
    _flashTimer?.cancel();
    _advanceTimer?.cancel();
    _countdownTimer?.cancel();
    _stopwatchTimer?.cancel();
  }

  /// The round ends with its screen: drop any asset load still in flight and
  /// silence every timer.
  void _dispose() {
    _gameGeneration++;
    _cancelTimers();
  }
}
