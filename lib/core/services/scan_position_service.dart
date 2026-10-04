import 'dart:convert';
import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final scanPositionServiceProvider = Provider<ScanPositionService>((ref) {
  return ScanPositionService();
});

/// Which curated scanning set to draw from (Chess Vision scanning drills).
enum ScanSetKind { checks, captures, hanging }

/// One curated real-game position. The target squares themselves are
/// recomputed at runtime by ScanEngine; [targetCount] is curation's answer
/// count, kept as a sanity cross-check and a future difficulty hook.
class ScanPosition {
  final String fen;
  final Chess position;
  final int targetCount;
  final Side sideToMove;

  ScanPosition({
    required this.fen,
    required this.position,
    required this.targetCount,
    required this.sideToMove,
  });
}

/// Lazy-loading cache for the scanning position sets, mirroring the
/// PuzzleService / OpeningBookService asset pattern.
class ScanPositionService {
  final Map<ScanSetKind, List<ScanPosition>> _cache = {};
  final _random = Random();

  static String _assetPath(ScanSetKind kind) => switch (kind) {
        ScanSetKind.checks => 'assets/puzzles/scan_checks.json',
        ScanSetKind.captures => 'assets/puzzles/scan_captures.json',
        ScanSetKind.hanging => 'assets/puzzles/scan_hanging.json',
      };

  /// Loads and parses one set. Throws when the asset can't be read or holds
  /// no playable position; nothing is cached then, so a later call (the
  /// drill's Retry) tries again, and [getRandom] can rely on a non-empty set.
  Future<void> load(ScanSetKind kind) async {
    if (_cache.containsKey(kind)) return;

    final path = _assetPath(kind);
    final raw = json.decode(await rootBundle.loadString(path));
    if (raw is! List) throw FormatException('$path: expected a JSON list');

    final parsed = <ScanPosition>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      final position = _parseEntry(entry);
      if (position != null) parsed.add(position);
    }
    if (parsed.isEmpty) throw FormatException('$path: no playable positions');
    _cache[kind] = parsed;
  }

  ScanPosition? _parseEntry(Map<String, dynamic> entry) {
    try {
      final fen = entry['fen'] as String;
      final n = entry['n'] as int;
      if (n < 1) return null;
      final position = Chess.fromSetup(Setup.parseFen(fen));
      return ScanPosition(
        fen: fen,
        position: position,
        targetCount: n,
        sideToMove: position.turn,
      );
    } catch (_) {
      return null;
    }
  }

  int count(ScanSetKind kind) => _cache[kind]?.length ?? 0;

  /// A random position from a set already [load]ed, avoiding [exclude].
  ScanPosition getRandom(ScanSetKind kind, {ScanPosition? exclude}) {
    final positions = _cache[kind];
    if (positions == null) throw StateError('load($kind) has not completed');
    if (positions.length <= 1) return positions.first;

    ScanPosition candidate;
    do {
      candidate = positions[_random.nextInt(positions.length)];
    } while (candidate == exclude);
    return candidate;
  }
}
