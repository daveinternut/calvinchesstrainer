import 'dart:async';
import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/services/analytics_service.dart';
import '../models/chess_vision_state.dart';
import '../services/fork_skewer_engine.dart';
import '../services/knight_engine.dart';
import '../services/pawn_attack_engine.dart';

final chessVisionProvider =
    NotifierProvider<ChessVisionNotifier, ChessVisionState>(
  ChessVisionNotifier.new,
);

class ChessVisionNotifier extends Notifier<ChessVisionState> {
  final _random = Random();
  Timer? _flashTimer;
  Timer? _advanceTimer;
  Timer? _countdownTimer;
  Timer? _stopwatchTimer;
  final Map<String, int> _personalBests = {};
  List<Square> _filteredConcentricPath = [];

  AudioService get _audio => ref.read(audioServiceProvider);
  AnalyticsService get _analytics => ref.read(analyticsServiceProvider);

  String get _bestKey {
    final drill = state.drillType.name;
    if (state.drillType == VisionDrillType.forksAndSkewers) {
      return 'vision_${drill}_${state.whitePiece.name}_${state.targetPiece.name}_${state.mode.name}';
    }
    if (state.drillType == VisionDrillType.pawnAttack) {
      return 'vision_${drill}_${state.whitePiece.name}_${state.mode.name}';
    }
    return 'vision_${drill}_${state.mode.name}';
  }

  int get personalBest => _personalBests[_bestKey] ?? 0;

  @override
  ChessVisionState build() {
    ref.onDispose(_dispose);
    return const ChessVisionState(
      drillType: VisionDrillType.forksAndSkewers,
      mode: VisionMode.practice,
      whitePiece: WhitePiece.queen,
    );
  }

  void startGame(VisionDrillType drillType, VisionMode mode, WhitePiece piece,
      {TargetPiece targetPiece = TargetPiece.rook}) {
    _cancelTimers();

    final effectiveMode = (drillType == VisionDrillType.knightSight ||
            drillType == VisionDrillType.knightFlight)
        ? VisionMode.practice
        : (drillType == VisionDrillType.pawnAttack &&
                mode != VisionMode.practice)
            ? VisionMode.speed
            : mode;

    if (effectiveMode == VisionMode.concentric) {
      _filteredConcentricPath = concentricPath.where((target) {
        return ForkSkewerEngine.computeValidSquares(
          whitePiece: piece,
          kingSquare: ChessVisionState.blackKingSquare,
          targetSquare: target,
          targetRole: targetPiece.role,
        ).isNotEmpty;
      }).toList();
    } else {
      _filteredConcentricPath = [];
    }

    state = ChessVisionState(
      drillType: drillType,
      mode: effectiveMode,
      whitePiece: piece,
      targetPiece: targetPiece,
      timeRemainingSeconds: effectiveMode == VisionMode.speed ? 60 : null,
    );

    _analytics.logVisionDrillStarted(
      drill: drillType.name,
      mode: effectiveMode.name,
      piece: piece.name,
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
    }

    if (drillType == VisionDrillType.pawnAttack &&
        effectiveMode == VisionMode.speed) {
      _startStopwatch();
    } else if (effectiveMode == VisionMode.speed) {
      _startCountdown();
    } else if (effectiveMode == VisionMode.concentric) {
      _startStopwatch();
    }
  }

  // --- Tap routing ---

  void handleBoardTap(Square square) {
    if (state.isGameOver || state.isRoundComplete) return;
    if (state.showingRevealedAnswer) return;

    switch (state.drillType) {
      case VisionDrillType.forksAndSkewers:
        _handleForksSkewersTap(square);
      case VisionDrillType.knightSight:
        _handleKnightSightTap(square);
      case VisionDrillType.knightFlight:
        _handleKnightFlightTap(square);
      case VisionDrillType.pawnAttack:
        _handlePawnAttackTap(square);
    }
  }

  // --- Forks & Skewers (existing) ---

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
    if (state.isGameOver || state.isRoundComplete) return;
    if (state.showingRevealedAnswer) return;

    if (state.correctSquares.isEmpty) {
      _audio.playCorrect();
      _completeConfiguration(madeError: false);
    } else {
      _audio.playIncorrect();
      state = state.copyWith(
        showingRevealedAnswer: true,
        totalErrors: state.totalErrors + 1,
        streak: 0,
      );
      _advanceTimer?.cancel();
      _advanceTimer = Timer(const Duration(milliseconds: 1500), () {
        _advanceToNextConfiguration(madeError: true);
      });
    }
  }

  // --- Knight Sight ---

  void _handleKnightSightTap(Square square) {
    if (square == state.knightSquare) return;
    if (state.foundSquares.contains(square)) return;

    if (state.correctSquares.contains(square)) {
      final newFound = {...state.foundSquares, square};
      _audio.playCorrect();
      state = state.copyWith(foundSquares: newFound);

      if (newFound.length >= state.correctSquares.length) {
        _completeConfiguration(madeError: state.hadErrorThisRound);
      }
    } else {
      _handleIncorrectTap(square);
    }
  }

  bool _knightSightPickEdge = false;

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
    if (!state.flightComplete || state.knightSquare == null) return;
    state = state.copyWith(
      flightPath: const [],
      flightComplete: false,
      hadErrorThisRound: false,
      incorrectFlashSquare: () => null,
    );
  }

  void skipFlight() {
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

  // --- Pawn Attack ---

  void _handlePawnAttackTap(Square square) {
    final from = state.pieceSquare;
    if (from == null) return;
    if (square == from) return;

    final valid = PawnAttackEngine.validMoves(
      role: state.whitePiece.role,
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
    final newThreats =
        isCapture ? PawnAttackEngine.pawnThreats(newPawns) : state.pawnThreatSquares;

    state = state.copyWith(
      pieceSquare: () => square,
      remainingPawns: newPawns,
      pawnThreatSquares: newThreats,
      pawnAttackMoves: state.pawnAttackMoves + 1,
      incorrectFlashSquare: () => null,
    );

    if (newPawns.isEmpty) {
      _completePawnAttackRound();
    }
  }

  void _completePawnAttackRound() {
    state = state.copyWith(isRoundComplete: true);

    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 800), () {
      _advancePawnAttack();
    });
  }

  void _advancePawnAttack() {
    if (state.isGameOver) return;

    final newStreak = state.hadErrorThisRound ? 0 : state.streak + 1;
    final newBestStreak = max(newStreak, state.bestStreak);

    if (!state.hadErrorThisRound && newStreak > 0 && newStreak % 5 == 0) {
      _audio.playStreakMilestone(newStreak);
    }

    final nextDifficulty = state.pawnAttackDifficulty + 1;

    if (state.mode == VisionMode.speed && nextDifficulty > 8) {
      _cancelTimers();
      state = state.copyWith(
        isGameOver: true,
        streak: newStreak,
        bestStreak: newBestStreak,
        configurationsCompleted: state.configurationsCompleted + 1,
      );
      _checkAndUpdatePersonalBest();
      return;
    }

    final wrappedDifficulty = nextDifficulty > 8 ? 3 : nextDifficulty;

    state = state.copyWith(
      streak: newStreak,
      bestStreak: newBestStreak,
      configurationsCompleted: state.configurationsCompleted + 1,
      pawnAttackDifficulty: wrappedDifficulty,
    );

    _generatePawnAttackConfig();
  }

  void _generatePawnAttackConfig() {
    final darkOnly = state.whitePiece == WhitePiece.bishop;
    final pawns = PawnAttackEngine.generatePawns(
      state.pawnAttackDifficulty,
      _random,
      darkSquaresOnly: darkOnly,
    );
    final threats = PawnAttackEngine.pawnThreats(pawns);

    state = state.copyWith(
      pieceSquare: () => Square.a1,
      remainingPawns: pawns,
      pawnThreatSquares: threats,
      pawnAttackMoves: 0,
      incorrectFlashSquare: () => null,
      hadErrorThisRound: false,
      isRoundComplete: false,
    );
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

  void _completeConfiguration({required bool madeError}) {
    state = state.copyWith(isRoundComplete: true);

    final delay = state.mode == VisionMode.speed
        ? const Duration(milliseconds: 400)
        : const Duration(milliseconds: 800);

    _advanceTimer?.cancel();
    _advanceTimer = Timer(delay, () {
      _advanceToNextConfiguration(madeError: madeError);
    });
  }

  void _advanceToNextConfiguration({required bool madeError}) {
    if (state.isGameOver) return;

    final newStreak = madeError ? 0 : state.streak + 1;
    final newBestStreak = max(newStreak, state.bestStreak);
    final isMilestone = !madeError && newStreak > 0 && newStreak % 5 == 0;

    if (isMilestone) {
      _audio.playStreakMilestone(newStreak);
    }

    if (state.mode == VisionMode.concentric) {
      if (state.concentricIndex >= _filteredConcentricPath.length) {
        _cancelTimers();
        state = state.copyWith(
          isGameOver: true,
          streak: newStreak,
          bestStreak: newBestStreak,
          configurationsCompleted: state.configurationsCompleted + 1,
        );
        _checkAndUpdatePersonalBest();
        return;
      }
    }

    state = state.copyWith(
      streak: newStreak,
      bestStreak: newBestStreak,
      configurationsCompleted: state.configurationsCompleted + 1,
    );

    switch (state.drillType) {
      case VisionDrillType.forksAndSkewers:
        _generateNextConfiguration();
      case VisionDrillType.knightSight:
        _generateKnightSightConfig();
      case VisionDrillType.knightFlight:
        _generateKnightFlightConfig();
      case VisionDrillType.pawnAttack:
        _generatePawnAttackConfig();
    }
  }

  int get concentricTotal => _filteredConcentricPath.length;

  void _generateNextConfiguration() {
    final Square target;

    if (state.mode == VisionMode.concentric) {
      if (state.concentricIndex >= _filteredConcentricPath.length) return;
      target = _filteredConcentricPath[state.concentricIndex];
      state = state.copyWith(concentricIndex: state.concentricIndex + 1);
    } else {
      target = _randomTargetSquare();
    }

    final correct = ForkSkewerEngine.computeValidSquares(
      whitePiece: state.whitePiece,
      kingSquare: ChessVisionState.blackKingSquare,
      targetSquare: target,
      targetRole: state.targetPiece.role,
    );

    if (state.mode != VisionMode.concentric && correct.isEmpty) {
      if (_random.nextDouble() > 0.25) {
        _generateNextConfiguration();
        return;
      }
    }

    state = state.copyWith(
      targetSquare: target,
      correctSquares: correct,
      foundSquares: const {},
      incorrectFlashSquare: () => null,
      showingRevealedAnswer: false,
      hadErrorThisRound: false,
      isRoundComplete: false,
    );
  }

  Square _randomSquare({Square? exclude}) {
    final candidates =
        Square.values.where((s) => s != exclude).toList();
    return candidates[_random.nextInt(candidates.length)];
  }

  Square _randomTargetSquare() {
    final candidates = Square.values
        .where((s) =>
            s != ChessVisionState.blackKingSquare && s != state.targetSquare)
        .toList();
    return candidates[_random.nextInt(candidates.length)];
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = (state.timeRemainingSeconds ?? 0) - 1;
      if (remaining <= 0) {
        _cancelTimers();
        state = state.copyWith(
          timeRemainingSeconds: () => 0,
          isGameOver: true,
        );
        _checkAndUpdatePersonalBest();
        _audio.playGameOver();
      } else {
        state = state.copyWith(timeRemainingSeconds: () => remaining);
      }
    });
  }

  void _startStopwatch() {
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isGameOver) return;
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  bool get isNewRecord {
    if (state.drillType == VisionDrillType.pawnAttack &&
        state.mode == VisionMode.speed) {
      final best = _personalBests[_bestKey] ?? 0;
      if (best == 0) return state.isGameOver;
      return state.isGameOver && state.elapsedSeconds < best;
    }
    if (state.mode == VisionMode.speed) {
      final best = _personalBests[_bestKey] ?? 0;
      return state.configurationsCompleted > best &&
          state.configurationsCompleted > 0;
    }
    if (state.mode == VisionMode.concentric) {
      final best = _personalBests[_bestKey] ?? 0;
      if (best == 0) return state.isGameOver;
      return state.isGameOver && state.elapsedSeconds < best;
    }
    return false;
  }

  void _checkAndUpdatePersonalBest() {
    bool newRecord = false;

    if (state.drillType == VisionDrillType.pawnAttack &&
        state.mode == VisionMode.speed &&
        state.isGameOver) {
      final current = _personalBests[_bestKey] ?? 0;
      newRecord = current == 0 || state.elapsedSeconds < current;
      if (newRecord) {
        _personalBests[_bestKey] = state.elapsedSeconds;
        _audio.playNewRecord();
      }
    } else if (state.mode == VisionMode.speed) {
      final current = _personalBests[_bestKey] ?? 0;
      newRecord = state.configurationsCompleted > current &&
          state.configurationsCompleted > 0;
      if (newRecord) {
        _personalBests[_bestKey] = state.configurationsCompleted;
        _audio.playNewRecord();
      }
    } else if (state.mode == VisionMode.concentric && state.isGameOver) {
      final current = _personalBests[_bestKey] ?? 0;
      newRecord = current == 0 || state.elapsedSeconds < current;
      if (newRecord) {
        _personalBests[_bestKey] = state.elapsedSeconds;
        _audio.playNewRecord();
      }
    }

    _analytics.logVisionDrillCompleted(
      drill: state.drillType.name,
      mode: state.mode.name,
      piece: state.whitePiece.name,
      target: state.drillType == VisionDrillType.forksAndSkewers
          ? state.targetPiece.name
          : null,
      configurationsCompleted: state.configurationsCompleted,
      totalErrors: state.totalErrors,
      bestStreak: state.bestStreak,
      isNewRecord: newRecord,
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

  void _dispose() {
    _cancelTimers();
  }
}
