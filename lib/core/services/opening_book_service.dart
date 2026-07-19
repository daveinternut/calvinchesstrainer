import 'dart:convert';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final openingBookServiceProvider = Provider<OpeningBookService>((ref) {
  return OpeningBookService();
});

class OpeningInfo {
  final String eco;
  final String name;
  final String pgn;

  const OpeningInfo({
    required this.eco,
    required this.name,
    required this.pgn,
  });
}

class BookContinuation {
  final String san;
  final int lineCount;

  const BookContinuation({required this.san, required this.lineCount});
}

/// Position-based opening book built from the ECO dataset.
///
/// Every dataset line is replayed at load time and each resulting *position*
/// is indexed, so book detection is transposition-aware: 1.e4 c6 2.Nc3 d5
/// 3.d4 is recognized as book because the position also arises from the
/// canonical 1.e4 c6 2.d4 d5 3.Nc3 move order.
class OpeningBookService {
  final List<OpeningInfo> _all = [];

  /// Every position (keyed by [_positionKey]) reachable along any book line.
  final Set<String> _bookPositions = {};

  /// How many dataset lines pass through each position.
  /// Higher count = more popular/established (main lines have big subtrees,
  /// exotic sidelines count 1) — used to rank continuations.
  final Map<String, int> _lineCount = {};

  /// Opening name for each line's final position (first dataset entry wins).
  final Map<String, OpeningInfo> _positionNames = {};

  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;

    final jsonStr = await rootBundle.loadString('assets/data/eco_openings.json');
    final List<dynamic> entries = json.decode(jsonStr);

    for (final entry in entries) {
      final pgn = entry['pgn'] as String;
      final info = OpeningInfo(
        eco: entry['eco'] as String,
        name: entry['name'] as String,
        pgn: pgn,
      );
      _all.add(info);

      final tokens = pgn
          .replaceAll(RegExp(r'\d+\.\s*'), '')
          .trim()
          .split(RegExp(r'\s+'));

      Position pos = Chess.initial;
      var replayedFully = true;
      for (final token in tokens) {
        if (token.isEmpty) continue;
        final move = pos.parseSan(token);
        if (move == null) {
          replayedFully = false;
          break;
        }
        pos = pos.playUnchecked(move);
        final key = _positionKey(pos);
        _bookPositions.add(key);
        _lineCount[key] = (_lineCount[key] ?? 0) + 1;
      }

      if (replayedFully) {
        _positionNames.putIfAbsent(_positionKey(pos), () => info);
      }
    }

    _loaded = true;
  }

  /// The opening name for the current position, if a dataset line ends here
  /// (reached via any move order).
  OpeningInfo? getOpeningForPosition(Position position) {
    if (!_loaded) return null;
    return _positionNames[_positionKey(position)];
  }

  /// Whether playing [move] from [position] leads into any known opening
  /// line. [move] must be legal.
  bool isBookMove(Position position, NormalMove move) {
    if (!_loaded) return false;
    final child = position.playUnchecked(move);
    return _bookPositions.contains(_positionKey(child));
  }

  /// All book continuations from [position], sorted by popularity (number of
  /// dataset lines passing through the resulting position, across all move
  /// orders). [legalSans] maps each legal move's SAN to the move itself.
  List<BookContinuation> getBookContinuations(
    Position position,
    Map<String, NormalMove> legalSans,
  ) {
    if (!_loaded) return [];

    final results = <BookContinuation>[];
    for (final entry in legalSans.entries) {
      final child = position.playUnchecked(entry.value);
      final count = _lineCount[_positionKey(child)];
      if (count != null && count > 0) {
        results.add(BookContinuation(san: entry.key, lineCount: count));
      }
    }

    results.sort((a, b) => b.lineCount.compareTo(a.lineCount));
    return results;
  }

  /// Get all openings, optionally filtered by ECO letter prefix.
  List<OpeningInfo> getAllOpenings({String? ecoPrefix}) {
    if (!_loaded) return [];
    var openings = List<OpeningInfo>.from(_all);
    if (ecoPrefix != null) {
      openings =
          openings.where((o) => o.eco.startsWith(ecoPrefix)).toList();
    }
    openings.sort((a, b) => a.eco.compareTo(b.eco));
    return openings;
  }

  /// Pieces + side to move + castling rights. The en-passant FEN field is
  /// deliberately excluded: transposed move orders reach the same position
  /// with different phantom ep squares (e.g. ...2.Nc3 d5 3.d4 has ep=d3 while
  /// ...2.d4 d5 3.Nc3 has ep=-), which would defeat transposition matching.
  String _positionKey(Position pos) {
    final parts = pos.fen.split(' ');
    return parts.take(3).join(' ');
  }
}
