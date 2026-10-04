import 'dart:convert';
import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final puzzleServiceProvider = Provider<PuzzleService>((ref) {
  return PuzzleService();
});

/// Mate-in-one puzzles for the Chess Vision "Mate in 1" scanning drill.
/// Same {fen, moves} schema as the move-trainer set, curated by
/// scripts/curate_scanning_positions.py from Lichess `mateIn1`-themed puzzles.
final mateInOnePuzzleServiceProvider = Provider<PuzzleService>((ref) {
  return PuzzleService(assetPath: 'assets/puzzles/mate_in_one_puzzles.json');
});

class ParsedPuzzle {
  final Chess position;
  final NormalMove expectedMove;
  final String san;
  final Role pieceRole;
  final String pieceName;
  final Side sideToMove;
  final NormalMove setupMove;

  final bool isCapture;
  final bool isCheck;
  final bool isCheckmate;

  ParsedPuzzle({
    required this.position,
    required this.expectedMove,
    required this.san,
    required this.pieceRole,
    required this.pieceName,
    required this.sideToMove,
    required this.setupMove,
    required this.isCapture,
    required this.isCheck,
    required this.isCheckmate,
  });

  String get targetFile => expectedMove.to.file.name;
  String get targetRank => expectedMove.to.rank.name;

  bool get isCastling =>
      pieceRole == Role.king &&
      (expectedMove.from.file.value - expectedMove.to.file.value).abs() >= 2;

  /// Whether [move] plays this puzzle's answer.
  ///
  /// Compares origin and destination only — the board auto-queens, so the
  /// promotion piece is never what's being tested — after normalising
  /// castling: the puzzle data writes it king-two-squares (`e1g1`), while
  /// dropping the king on its own rook (`e1h1`) is an equally legal way to
  /// play it.
  bool matches(NormalMove move) {
    final played = position.normalizeMove(move);
    final answer = position.normalizeMove(expectedMove);
    return played is NormalMove &&
        answer is NormalMove &&
        played.from == answer.from &&
        played.to == answer.to;
  }
}

class PuzzleService {
  PuzzleService({
    this.assetPath = 'assets/puzzles/moves_puzzles.json',
    Random? random,
  }) : _random = random ?? Random();

  final String assetPath;
  final Random _random;

  List<ParsedPuzzle>? _puzzles;
  Future<void>? _loadFuture;

  /// Puzzles per side-to-move filter (`null` = all of them), built on demand.
  final Map<Side?, List<ParsedPuzzle>> _pools = {};

  /// A shuffled deck per filter: every puzzle is dealt once before any
  /// puzzle repeats, then the deck is reshuffled.
  final Map<Side?, List<ParsedPuzzle>> _decks = {};

  /// Loads and parses the puzzle file. Safe to call repeatedly or
  /// concurrently: callers during a load share it (a failed load is
  /// forgotten, so a later call retries), and once loaded this returns at
  /// once — with a future of the caller's own zone, so a fake-async test
  /// that preloaded in real time doesn't wait on the real event loop.
  Future<void> loadPuzzles() async {
    if (_puzzles != null) return;
    await (_loadFuture ??= _load());
  }

  Future<void> _load() async {
    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      _setPuzzles(_parseAll(jsonStr));
    } catch (_) {
      _loadFuture = null;
      rethrow;
    }
  }

  /// Parses [jsonStr] (the asset's schema) instead of reading the asset, so
  /// tests can load real puzzle data without the asset bundle.
  @visibleForTesting
  void loadFromJson(String jsonStr) => _setPuzzles(_parseAll(jsonStr));

  void _setPuzzles(List<ParsedPuzzle> puzzles) {
    _puzzles = puzzles;
    _pools.clear();
    _decks.clear();
  }

  List<ParsedPuzzle> _parseAll(String jsonStr) {
    final raw = json.decode(jsonStr) as List<dynamic>;
    final parsed = <ParsedPuzzle>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      final puzzle = _parsePuzzle(entry);
      if (puzzle != null) parsed.add(puzzle);
    }
    return parsed;
  }

  ParsedPuzzle? _parsePuzzle(Map<String, dynamic> entry) {
    try {
      final fen = entry['fen'] as String;
      final movesStr = entry['moves'] as String;
      final uciMoves = movesStr.split(' ');
      if (uciMoves.length < 2) return null;

      final initialPosition = Chess.fromSetup(Setup.parseFen(fen));

      final setupUci = uciMoves[0];
      final setupMove = NormalMove.fromUci(setupUci);
      final puzzlePosition = initialPosition.playUnchecked(setupMove);

      final answerUci = uciMoves[1];
      final answerMove = NormalMove.fromUci(answerUci);

      final (_, san) = puzzlePosition.makeSan(answerMove);
      final piece = puzzlePosition.board.pieceAt(answerMove.from);
      if (piece == null) return null;

      return ParsedPuzzle(
        position: puzzlePosition as Chess,
        expectedMove: answerMove,
        san: san,
        pieceRole: piece.role,
        pieceName: _roleName(piece.role),
        sideToMove: puzzlePosition.turn,
        setupMove: setupMove,
        isCapture: san.contains('x'),
        isCheck: san.endsWith('+') && !san.endsWith('#'),
        isCheckmate: san.endsWith('#'),
      );
    } catch (_) {
      return null;
    }
  }

  int get puzzleCount => _puzzles?.length ?? 0;

  /// The next puzzle, drawn without repeats: each puzzle matching
  /// [sideToMove] is dealt once before any comes round again. Never returns
  /// [exclude] (the puzzle just played) unless it is the only candidate.
  ///
  /// Never falls back to a puzzle with the other side to move — a trainer
  /// that asked for Black would hand the child a board they cannot move.
  /// Throws a [StateError] if no puzzle matches, or before [loadPuzzles]
  /// completes.
  ParsedPuzzle getRandomPuzzle({ParsedPuzzle? exclude, Side? sideToMove}) {
    final puzzles = _puzzles;
    if (puzzles == null) {
      throw StateError('PuzzleService($assetPath): puzzles are not loaded');
    }
    final pool = _pools[sideToMove] ??= sideToMove == null
        ? puzzles
        : [
            for (final p in puzzles)
              if (p.sideToMove == sideToMove) p,
          ];
    if (pool.isEmpty) {
      throw StateError(
        'PuzzleService($assetPath): no puzzles with '
        '${sideToMove?.name ?? 'either side'} to move',
      );
    }
    if (pool.length == 1) return pool.single;

    final deck = _decks.putIfAbsent(sideToMove, () => []);
    if (deck.isEmpty) _shuffleInto(deck, pool);
    if (identical(deck.last, exclude)) {
      if (deck.length == 1) {
        // The puzzle just played is all that's left of this round: start
        // the next round now, with it kept off the top.
        _shuffleInto(deck, pool);
        if (identical(deck.last, exclude)) deck.insert(0, deck.removeLast());
      } else {
        deck.insert(0, deck.removeLast());
      }
    }
    return deck.removeLast();
  }

  void _shuffleInto(List<ParsedPuzzle> deck, List<ParsedPuzzle> pool) {
    deck
      ..clear()
      ..addAll(pool)
      ..shuffle(_random);
  }

  static String _roleName(Role role) {
    return switch (role) {
      Role.king => 'king',
      Role.queen => 'queen',
      Role.rook => 'rook',
      Role.bishop => 'bishop',
      Role.knight => 'knight',
      Role.pawn => 'pawn',
    };
  }
}
