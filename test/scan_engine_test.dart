import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calvinchesstrainer/features/chess_vision/services/scan_engine.dart';

// Cross-language contract fixtures: the SAME positions and expectations are
// embedded in scripts/curate_scanning_positions.py (--self-test). If a change
// here is intentional, mirror it there — curation-time selection and runtime
// ground truth must never disagree.
Position posFromFen(String fen) => Chess.fromSetup(Setup.parseFen(fen));

Set<Square> squares(List<String> names) =>
    names.map(Square.fromName).toSet();

void main() {
  group('ScanEngine fixtures (mirrored in curate_scanning_positions.py)', () {
    test('F1 basic knight check, nothing to take', () {
      final pos = posFromFen('6k1/8/8/8/4N3/8/8/6K1 w - - 0 1');
      expect(ScanEngine.checkTargets(pos), squares(['f6']));
      expect(ScanEngine.captureTargets(pos), isEmpty);
      expect(ScanEngine.hangingTargets(pos), isEmpty);
      expect(ScanEngine.matingMoves(pos), isEmpty);
    });

    test('F2 pinned attacker cannot capture; every loose piece hangs', () {
      final pos = posFromFen('4r1k1/8/1n6/8/6n1/8/4B3/1R2K3 w - - 0 1');
      // Be2 is absolutely pinned by Re8, so Ng4 is not capturable — but
      // hanging = undefended (LPDO), capturability irrelevant: Re8, Nb6 and
      // Ng4 all have zero defenders.
      expect(ScanEngine.checkTargets(pos), isEmpty);
      expect(ScanEngine.captureTargets(pos), squares(['b6']));
      expect(ScanEngine.hangingTargets(pos), squares(['b6', 'e8', 'g4']));
    });

    test('F3 king-defended distractor: Bb7 capturable but not hanging', () {
      final pos = posFromFen('1k6/1b6/8/3Q3r/8/8/8/6K1 w - - 0 1');
      expect(
        ScanEngine.checkTargets(pos),
        squares(['b7', 'd6', 'd8', 'e5', 'g8']),
      );
      expect(ScanEngine.captureTargets(pos), squares(['b7', 'h5']));
      expect(ScanEngine.hangingTargets(pos), squares(['h5']));
    });

    test('F4 castling check is skipped; the plain rook move still counts', () {
      final pos = posFromFen('5k2/8/8/8/8/8/8/4K2R w K - 0 1');
      final targets = ScanEngine.checkTargets(pos);
      expect(targets, squares(['f1', 'h8']));
      // Neither castling encoding may leak in as a target square.
      expect(targets.contains(Square.g1), isFalse);
      expect(targets.contains(Square.h1), isFalse);
    });

    test('F5 en passant: discovered checks count, ep victim is untappable', () {
      final pos = posFromFen('7k/8/8/3pP3/8/8/1B6/4K3 w - d6 0 2');
      // exd6 e.p. and e5-e6 both discover Bb2+ along the long diagonal.
      expect(ScanEngine.checkTargets(pos), squares(['d6', 'e6']));
      // The d5 pawn is ep-capturable, but no legal move LANDS on d5 — this is
      // exactly why curation drops ep positions from the captures set.
      expect(ScanEngine.captureTargets(pos), isEmpty);
    });

    test('F6 promotion: push- and capture-promotion checks; no mate', () {
      final pos = posFromFen('k6r/6P1/8/8/8/8/8/6K1 w - - 0 1');
      // g8=Q+ catches the missing-promotion-expansion bug (a bare NormalMove
      // to the last rank would leave a pawn on g8 and see no check).
      expect(ScanEngine.checkTargets(pos), squares(['g8', 'h8']));
      expect(ScanEngine.captureTargets(pos), squares(['h8']));
      expect(ScanEngine.hangingTargets(pos), squares(['h8']));
      expect(ScanEngine.matingMoves(pos), isEmpty);
    });

    test('F7 back-rank mate: Re8# only', () {
      final pos = posFromFen('6k1/5ppp/8/8/8/8/5PPP/4R1K1 w - - 0 1');
      expect(ScanEngine.checkTargets(pos), squares(['e8']));
      expect(
        ScanEngine.matingMoves(pos),
        {const NormalMove(from: Square.e1, to: Square.e8)},
      );
      expect(
        ScanEngine.isMatingMove(
            pos, const NormalMove(from: Square.e1, to: Square.e8)),
        isTrue,
      );
      expect(
        ScanEngine.isMatingMove(
            pos, const NormalMove(from: Square.e1, to: Square.e7)),
        isFalse,
      );
    });
  });

  group('ScanEngine edge behavior', () {
    test('hangingTargets honors a pawn-inclusive victimRoles override', () {
      // White to move; black pawn a5 is undefended (loose).
      final pos = posFromFen('6k1/8/8/p7/8/8/8/R5K1 w - - 0 1');
      expect(ScanEngine.hangingTargets(pos), isEmpty);
      expect(
        ScanEngine.hangingTargets(pos, victimRoles: {...ScanEngine.defaultHangingRoles, Role.pawn}),
        squares(['a5']),
      );
    });

    test('hanging ignores capturability but respects defense', () {
      // Black Nb8 is defended by Ra8 — capturable (Rxb8) yet NOT hanging.
      // Ra8 and Bh3 are defended by nothing — neither is capturable, both
      // hang anyway (loose pieces). Machine-verified with python-chess.
      final pos = posFromFen('rn4k1/8/8/8/8/7b/8/1R4K1 w - - 0 1');
      expect(ScanEngine.captureTargets(pos), squares(['b8']));
      expect(ScanEngine.hangingTargets(pos), squares(['a8', 'h3']));
    });

    test('isMatingMove rejects illegal moves', () {
      final pos = posFromFen('6k1/5ppp/8/8/8/8/5PPP/4R1K1 w - - 0 1');
      expect(
        ScanEngine.isMatingMove(
            pos, const NormalMove(from: Square.e1, to: Square.a5)),
        isFalse,
      );
    });

    test('a queen-promotion mate is judged correct (autoQueen path)', () {
      // Black Kh8 + pawn h7; white Kf6 covers g7, so f8=Q is mate along the
      // back rank (machine-verified: f8=Q# and f8=R# are the only mates).
      final pos = posFromFen('7k/5P1p/5K2/8/8/8/8/8 w - - 0 1');
      expect(
        ScanEngine.isMatingMove(
          pos,
          const NormalMove(
              from: Square.f7, to: Square.f8, promotion: Role.queen),
        ),
        isTrue,
      );
      expect(
        ScanEngine.matingMoves(pos),
        containsAll(const [
          NormalMove(from: Square.f7, to: Square.f8, promotion: Role.queen),
          NormalMove(from: Square.f7, to: Square.f8, promotion: Role.rook),
        ]),
      );
    });
  });
}
