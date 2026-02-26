import 'dart:convert';
import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final puzzleServiceProvider = Provider<PuzzleService>((ref) {
  return PuzzleService();
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
}

class PuzzleService {
  List<ParsedPuzzle>? _puzzles;
  final _random = Random();

  Future<void> loadPuzzles() async {
    if (_puzzles != null) return;

    final jsonStr = await rootBundle.loadString('assets/puzzles/moves_puzzles.json');
    final List<dynamic> raw = json.decode(jsonStr);

    final parsed = <ParsedPuzzle>[];
    for (final entry in raw) {
      final puzzle = _parsePuzzle(entry);
      if (puzzle != null) parsed.add(puzzle);
    }

    _puzzles = parsed;
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

  ParsedPuzzle getRandomPuzzle({ParsedPuzzle? exclude, Side? sideToMove}) {
    var puzzles = _puzzles!;
    if (sideToMove != null) {
      puzzles = puzzles.where((p) => p.sideToMove == sideToMove).toList();
    }
    if (puzzles.isEmpty) puzzles = _puzzles!;
    if (puzzles.length <= 1) return puzzles.first;

    ParsedPuzzle candidate;
    do {
      candidate = puzzles[_random.nextInt(puzzles.length)];
    } while (candidate == exclude);
    return candidate;
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
