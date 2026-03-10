import 'dart:convert';

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

class OpeningBookService {
  final Map<String, OpeningInfo> _lookup = {};

  /// All move-sequence prefixes that appear in any known opening.
  final Set<String> _prefixes = {};

  /// How many opening lines pass through each prefix.
  /// Higher count = more popular/established continuation.
  final Map<String, int> _prefixCount = {};

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
      final key = _normalizeKey(pgn);
      _lookup[key] = info;

      final moves = key.split(' ');
      for (int i = 1; i <= moves.length; i++) {
        final prefix = moves.sublist(0, i).join(' ');
        _prefixes.add(prefix);
        _prefixCount[prefix] = (_prefixCount[prefix] ?? 0) + 1;
      }
    }

    _loaded = true;
  }

  /// Look up the opening name for a list of SAN moves.
  /// Tries the full sequence first, then progressively shorter prefixes
  /// to find the longest matching opening.
  OpeningInfo? getOpening(List<String> sanMoves) {
    if (sanMoves.isEmpty || !_loaded) return null;

    for (int length = sanMoves.length; length > 0; length--) {
      final key = _buildKey(sanMoves.sublist(0, length));
      final info = _lookup[key];
      if (info != null) return info;
    }

    return null;
  }

  /// Check if playing [candidateSan] from the current [sanMoves] position
  /// leads into any known opening line (the candidate is a "book" move).
  bool isBookMove(List<String> sanMoves, String candidateSan) {
    if (!_loaded) return false;
    final key = _buildKey([...sanMoves, candidateSan]);
    return _prefixes.contains(key);
  }

  /// Get all book continuations from the current position, sorted by
  /// popularity (how many ECO opening lines pass through each move).
  /// Pass in the list of legal SAN moves to filter against.
  List<BookContinuation> getBookContinuations(
    List<String> sanMoves,
    List<String> legalSanMoves,
  ) {
    if (!_loaded) return [];

    final results = <BookContinuation>[];
    for (final san in legalSanMoves) {
      final key = _buildKey([...sanMoves, san]);
      final count = _prefixCount[key];
      if (count != null && count > 0) {
        results.add(BookContinuation(san: san, lineCount: count));
      }
    }

    results.sort((a, b) => b.lineCount.compareTo(a.lineCount));
    return results;
  }

  /// Get all openings, optionally filtered by ECO letter prefix.
  List<OpeningInfo> getAllOpenings({String? ecoPrefix}) {
    if (!_loaded) return [];
    var openings = _lookup.values.toList();
    if (ecoPrefix != null) {
      openings =
          openings.where((o) => o.eco.startsWith(ecoPrefix)).toList();
    }
    openings.sort((a, b) => a.eco.compareTo(b.eco));
    return openings;
  }

  String _normalizeKey(String pgn) {
    return pgn
        .replaceAll(RegExp(r'\d+\.\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _buildKey(List<String> sanMoves) {
    return sanMoves.join(' ');
  }
}
