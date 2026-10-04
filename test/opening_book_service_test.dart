import 'package:calvinchesstrainer/core/services/opening_book_service.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

/// Replay a space-separated SAN sequence from the initial position.
Position replay(String sans) {
  Position pos = Chess.initial;
  for (final san in sans.split(' ')) {
    final move = pos.parseSan(san);
    if (move == null) {
      fail('illegal SAN "$san" in "$sans"');
    }
    pos = pos.playUnchecked(move);
  }
  return pos;
}

NormalMove san(Position pos, String sanStr) {
  final move = pos.parseSan(sanStr);
  if (move == null) fail('illegal SAN "$sanStr"');
  return move as NormalMove;
}

/// All legal moves of [pos] as SAN → move, mirroring the provider's map.
Map<String, NormalMove> legalSans(Position pos) {
  final result = <String, NormalMove>{};
  for (final entry in pos.legalMoves.entries) {
    for (final dest in entry.value.squares) {
      final move = NormalMove(from: entry.key, to: dest);
      if (pos.isLegal(move)) {
        final (_, sanStr) = pos.makeSan(move);
        result[sanStr] = move;
      }
    }
  }
  return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final book = OpeningBookService();

  setUpAll(() async {
    await book.load();
  });

  test('concurrent loads share one load (no duplicated openings)', () async {
    final fresh = OpeningBookService();
    await Future.wait([fresh.load(), fresh.load(), fresh.load()]);
    expect(fresh.getAllOpenings(), hasLength(book.getAllOpenings().length));
    expect(fresh.getAllOpenings(), hasLength(3640));
  });

  group('OpeningBookService (position-based)', () {
    // 1. e4 c6 2. Nc3 d5 — white to move (the Caro-Kann test position).
    late Position pos;

    setUp(() {
      pos = replay('e4 c6 Nc3 d5');
    });

    test('recognizes a main-line move reached only by transposition (3.d4)',
        () {
      // "1. e4 c6 2. Nc3 d5 3. d4" appears in NO dataset line literally —
      // the position only exists via "1. e4 c6 2. d4 d5 3. Nc3". The double
      // push also sets a phantom ep square that the canonical order lacks,
      // so this additionally covers the ep-field exclusion in position keys.
      expect(book.isBookMove(pos, san(pos, 'd4')), isTrue);
    });

    test('recognizes literal dataset continuations', () {
      expect(book.isBookMove(pos, san(pos, 'Nf3')), isTrue); // Two Knights
      expect(book.isBookMove(pos, san(pos, 'Qf3')), isTrue); // Goldman
      expect(book.isBookMove(pos, san(pos, 'd3')), isTrue); // Scorpion-Horus
      expect(book.isBookMove(pos, san(pos, 'h3')), isTrue); // St. Patrick's
    });

    test('rejects non-book moves', () {
      expect(book.isBookMove(pos, san(pos, 'a4')), isFalse);
      expect(book.isBookMove(pos, san(pos, 'Rb1')), isFalse);
    });

    test('ranks main lines above exotic sidelines', () {
      final continuations = book.getBookContinuations(pos, legalSans(pos));
      final bySan = {for (final c in continuations) c.san: c.lineCount};

      expect(bySan.keys, containsAll(['d4', 'Nf3', 'd3', 'h3']));
      // d4 transposes into the whole B15+ main-line tree; Nf3 heads the
      // Two Knights complex; d3/h3 are single exotic lines.
      expect(bySan['d4']!, greaterThan(bySan['d3']!));
      expect(bySan['d4']!, greaterThan(bySan['h3']!));
      expect(bySan['Nf3']!, greaterThan(bySan['d3']!));
      // Popularity ordering: the first entries are the main lines.
      expect(continuations.first.san, anyOf('d4', 'Nf3'));
    });

    test('names a position reached via any move order', () {
      final direct = book.getOpeningForPosition(pos);
      expect(direct?.name, 'Caro-Kann Defense');

      // Position after 3.d4 (our order) == terminal position of the B15
      // "1. e4 c6 2. d4 d5 3. Nc3" entry.
      final transposed =
          book.getOpeningForPosition(replay('e4 c6 Nc3 d5 d4'));
      expect(transposed?.name, 'Caro-Kann Defense');
      expect(transposed?.eco, 'B15');
    });
  });
}
