import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';

import 'package:calvinchesstrainer/core/services/puzzle_service.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

/// The move-trainer set, read straight from disk (no asset bundle needed).
String _movesJson() =>
    io.File('assets/puzzles/moves_puzzles.json').readAsStringSync();

PuzzleService _serviceWith(String json, {int seed = 7}) =>
    PuzzleService(random: Random(seed))..loadFromJson(json);

ParsedPuzzle _single(String fen, String moves) =>
    _serviceWith(jsonEncode([
      {'fen': fen, 'moves': moves},
    ])).getRandomPuzzle();

void main() {
  group('parsing', () {
    test('every move-trainer puzzle parses with a legal answer', () {
      final service = _serviceWith(_movesJson());
      expect(service.puzzleCount, 500);

      // Deal the whole deck once: every puzzle, exactly once.
      final dealt = <ParsedPuzzle>{};
      for (var i = 0; i < service.puzzleCount; i++) {
        dealt.add(service.getRandomPuzzle());
      }
      expect(dealt, hasLength(500));

      for (final p in dealt) {
        final legal = makeLegalMoves(p.position);
        expect(legal[p.expectedMove.from], contains(p.expectedMove.to),
            reason: '${p.san} should be legal');
        expect(p.sideToMove, p.position.turn);
      }
      // Both sides are represented, so Hard Mode (Black) always has puzzles.
      expect(dealt.where((p) => p.sideToMove == Side.white), hasLength(246));
      expect(dealt.where((p) => p.sideToMove == Side.black), hasLength(254));
    });
  });

  group('getRandomPuzzle', () {
    test('deals every puzzle for a side once before any repeats', () {
      final service = _serviceWith(_movesJson());
      for (final side in Side.values) {
        final count = side == Side.white ? 246 : 254;
        final seen = <ParsedPuzzle>{};
        ParsedPuzzle? previous;
        for (var i = 0; i < count; i++) {
          final p = service.getRandomPuzzle(exclude: previous, sideToMove: side);
          expect(p.sideToMove, side);
          expect(seen.add(p), isTrue, reason: 'repeated before exhaustion');
          previous = p;
        }
        expect(seen, hasLength(count));
      }
    });

    test('never hands back the excluded puzzle, across reshuffles', () {
      final service = _serviceWith(_movesJson(), seed: 99);
      ParsedPuzzle? previous;
      for (var i = 0; i < 3000; i++) {
        final p =
            service.getRandomPuzzle(exclude: previous, sideToMove: Side.black);
        expect(identical(p, previous), isFalse);
        previous = p;
      }
    });

    test('never falls back to a puzzle with the wrong side to move', () {
      // Only Black-to-move puzzles here (the setup move is White's).
      final service = _serviceWith(jsonEncode([
        {
          'fen': '4k3/8/8/8/8/8/8/R3K2R w - - 0 1',
          'moves': 'a1a2 e8d8',
        },
        {
          'fen': '4k3/8/8/8/8/8/8/R3K2R w - - 0 1',
          'moves': 'a1a3 e8f8',
        },
      ]));
      expect(service.getRandomPuzzle(sideToMove: Side.black).sideToMove,
          Side.black);
      expect(() => service.getRandomPuzzle(sideToMove: Side.white),
          throwsStateError);
    });

    test('throws before the puzzles are loaded', () {
      expect(() => PuzzleService().getRandomPuzzle(), throwsStateError);
    });
  });

  group('ParsedPuzzle.matches (castling normalisation)', () {
    // Black's setup move, then White to castle.
    const fen = '4k3/8/8/8/8/8/8/R3K2R b KQ - 0 1';

    test('king-two-squares answer accepts the king-onto-rook drop', () {
      final puzzle = _single(fen, 'e8d8 e1g1');
      expect(puzzle.isCastling, isTrue);
      expect(puzzle.san, 'O-O');
      expect(puzzle.matches(NormalMove.fromUci('e1g1')), isTrue);
      expect(puzzle.matches(NormalMove.fromUci('e1h1')), isTrue);
      expect(puzzle.matches(NormalMove.fromUci('e1f1')), isFalse);
      expect(puzzle.matches(NormalMove.fromUci('e1c1')), isFalse);
    });

    test('queenside works both ways too', () {
      // Black's king steps to f8, out of the castled rook's d-file.
      final puzzle = _single(fen, 'e8f8 e1c1');
      expect(puzzle.san, 'O-O-O');
      expect(puzzle.matches(NormalMove.fromUci('e1a1')), isTrue);
      expect(puzzle.matches(NormalMove.fromUci('e1c1')), isTrue);
      expect(puzzle.matches(NormalMove.fromUci('e1g1')), isFalse);
    });

    test('ordinary moves compare origin and destination only', () {
      final puzzle = _single(fen, 'e8d8 a1a8');
      expect(puzzle.matches(NormalMove.fromUci('a1a8')), isTrue);
      expect(puzzle.matches(NormalMove.fromUci('h1h8')), isFalse);
    });
  });
}
