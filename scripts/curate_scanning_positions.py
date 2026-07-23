#!/usr/bin/env python3
"""Curate position sets for the Chess Vision scanning drills.

Produces four JSON assets from the Lichess puzzle database in a single pass:

  assets/puzzles/scan_checks.json        Find Checks      {"fen", "n"}
  assets/puzzles/scan_captures.json      Find Captures    {"fen", "n"}
  assets/puzzles/scan_hanging.json       Hanging Pieces   {"fen", "n"}
  assets/puzzles/mate_in_one_puzzles.json  Mate in 1      {"fen", "moves"}

The scan sets store the position AFTER the puzzle's setup move (the "opponent
just moved" moment) plus the target count `n`. The app recomputes the actual
target squares at runtime with dartchess (ScanEngine); this script only
SELECTS positions, using predicates that mirror ScanEngine exactly. The mate
set keeps the original {fen, moves} schema so PuzzleService parses it
unchanged.

Regeneration workflow (CSV is a one-time local download, never committed):

  curl -O https://database.lichess.org/lichess_db_puzzle.csv.zst   # ~250 MB
  zstd -d lichess_db_puzzle.csv.zst                                # ~1 GB CSV
  python3 -m pip install 'chess>=1.10,<2'
  python3 scripts/curate_scanning_positions.py lichess_db_puzzle.csv

Deterministic: same CSV + same --seed => byte-identical output.

--self-test runs the embedded cross-language fixtures (mirrored in
test/scan_engine_test.dart) through the python predicates and exits 0/1.
"""

import argparse
import csv
import json
import random
import sys
from pathlib import Path

try:
    import chess
except ImportError:
    sys.exit("python-chess is required: python3 -m pip install 'chess>=1.10,<2'")

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

SEED = 42
MIN_PLAYS = 500          # proven quality gates shared with curate_puzzles.py
MIN_POPULARITY = 50
SCAN_RATING = (600, 1500)
MATE_RATING = (600, 1200)  # mateIn1 skews low; >1200 is trappy for kids
MAX_PIECES = 24          # cut hyper-cluttered boards on a phone screen
SCAN_RESERVOIR = 60_000
MATE_RESERVOIR = 25_000

# Hanging = UNDEFENDED (zero defenders), pieces only (user decisions).
# Whether the side to move can currently capture the piece is irrelevant —
# the drill trains spotting loose pieces (LPDO). The companion honesty
# filter (undefended-enemy-pawn reject below) guarantees a kid tapping a
# genuinely loose pawn can never happen: such positions are excluded.
HANGING_ROLES = {chess.KNIGHT, chess.BISHOP, chess.ROOK, chess.QUEEN}

# Per-set quotas: n (target count) -> number of positions. Each is split
# 50/50 white/black to move (white takes the odd one).
CHECKS_QUOTAS = {1: 90, 2: 120, 3: 60, 4: 30}
CAPTURES_QUOTAS = {1: 75, 2: 105, 3: 75, 4: 45}
HANGING_QUOTAS = {1: 180, 2: 90, 3: 30}
# Mate set: rating band -> count, also split 50/50 by side.
MATE_QUOTAS = {(600, 800): 160, (800, 1000): 160, (1000, 1200): 80}

EXPECTED_COLUMNS = [
    'PuzzleId', 'FEN', 'Moves', 'Rating', 'RatingDeviation', 'Popularity',
    'NbPlays', 'Themes', 'GameUrl', 'OpeningTags',
]

REPO_ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = REPO_ROOT / 'assets' / 'puzzles'
EXISTING_PUZZLES = OUT_DIR / 'moves_puzzles.json'

OUT_CHECKS = OUT_DIR / 'scan_checks.json'
OUT_CAPTURES = OUT_DIR / 'scan_captures.json'
OUT_HANGING = OUT_DIR / 'scan_hanging.json'
OUT_MATE = OUT_DIR / 'mate_in_one_puzzles.json'

rng = random.Random(SEED)

# ---------------------------------------------------------------------------
# Predicates — these MUST mirror lib/features/chess_vision/services/
# scan_engine.dart exactly. The fixtures below are the cross-language
# contract test (same values asserted in test/scan_engine_test.dart).
# ---------------------------------------------------------------------------


def check_dests_info(board):
    """(dests, ambiguous, castle_check) for the side to move.

    dests: destination squares of non-castling legal moves that give check
    (promotion variants collapse onto one destination). Castling is skipped
    on both sides of the contract because python-chess and dartchess encode
    the move differently; castle_check positions are rejected outright so
    the shipped sets never silently omit a real check.
    ambiguous: some destination is reached by checking moves from >= 2
    distinct origin squares (would make tap-a-square feedback ambiguous).
    """
    origins_by_dest = {}
    castle_check = False
    for m in board.legal_moves:
        if board.is_castling(m):
            if board.gives_check(m):
                castle_check = True
            continue
        if board.gives_check(m):
            origins_by_dest.setdefault(m.to_square, set()).add(m.from_square)
    ambiguous = any(len(o) > 1 for o in origins_by_dest.values())
    return set(origins_by_dest), ambiguous, castle_check


def capture_dests(board):
    """Squares of enemy men capturable by a legal move, by destination
    occupancy (NOT board.is_capture — that would include en passant, whose
    destination square is empty and therefore untappable)."""
    them = not board.turn
    out = set()
    for m in board.legal_moves:
        p = board.piece_at(m.to_square)
        if p is not None and p.color == them:
            out.add(m.to_square)
    return out


def hanging_dests(board, roles=HANGING_ROLES):
    """Enemy pieces (roles only) with ZERO defenders — loose pieces (LPDO).

    Capturability is deliberately NOT required. Defenders via
    board.attackers(owner, sq): pseudo-attack — pins ignored, king included —
    byte-equivalent to dartchess Board.attacksTo."""
    them = not board.turn
    out = set()
    for sq, p in board.piece_map().items():
        if p.color != them or p.piece_type not in roles:
            continue
        if not board.attackers(them, sq):
            out.add(sq)
    return out


def has_undefended_enemy_pawn(board):
    """True if any enemy PAWN has zero defenders — the honesty filter for the
    hanging set (pieces-only definition must never mark a genuinely loose
    pawn tap as wrong)."""
    them = not board.turn
    for sq, p in board.piece_map().items():
        if p.color == them and p.piece_type == chess.PAWN \
                and not board.attackers(them, sq):
            return True
    return False


def has_defended_enemy_piece(board, roles=HANGING_ROLES):
    """True if some enemy piece IS defended — the drill's distractor: the
    defended-vs-loose discrimination is the pedagogical point."""
    them = not board.turn
    for sq, p in board.piece_map().items():
        if p.color == them and p.piece_type in roles \
                and board.attackers(them, sq):
            return True
    return False


def mating_moves(board):
    """UCI strings of all legal moves that deliver checkmate."""
    out = set()
    for m in board.legal_moves:
        if not board.gives_check(m):
            continue
        board.push(m)
        if board.is_checkmate():
            out.add(m.uci())
        board.pop()
    return out


# ---------------------------------------------------------------------------
# Cross-language fixtures (machine-verified with python-chess; mirrored in
# test/scan_engine_test.dart — keep the two in sync).
# ---------------------------------------------------------------------------

FIXTURES = [
    {   # F1 basic knight check, nothing to take
        'fen': '6k1/8/8/8/4N3/8/8/6K1 w - - 0 1',
        'checks': {'f6'}, 'ambiguous': False, 'castle_check': False,
        'captures': set(), 'hanging': set(), 'mates': set(),
    },
    {   # F2 pinned attacker: Be2 pinned by Re8 can't take g4, so g4 is NOT a
        # capture target — but ALL THREE black pieces (Re8, Nb6, Ng4) have
        # zero defenders, so all three hang. Capturability is irrelevant.
        'fen': '4r1k1/8/1n6/8/6n1/8/4B3/1R2K3 w - - 0 1',
        'checks': set(), 'ambiguous': False, 'castle_check': False,
        'captures': {'b6'}, 'hanging': {'b6', 'e8', 'g4'}, 'mates': set(),
    },
    {   # F3 king-defended distractor: Bb7 capturable but defended; Rh5 hangs
        'fen': '1k6/1b6/8/3Q3r/8/8/8/6K1 w - - 0 1',
        'checks': {'b7', 'd6', 'd8', 'e5', 'g8'}, 'ambiguous': False,
        'castle_check': False,
        'captures': {'b7', 'h5'}, 'hanging': {'h5'}, 'mates': set(),
    },
    {   # F4 castling check: O-O checks via Rf1 -> castle_check True (curation
        # rejects); plain Rf1 still counts; g1/h1 never targets
        'fen': '5k2/8/8/8/8/8/8/4K2R w K - 0 1',
        'checks': {'f1', 'h8'}, 'ambiguous': False, 'castle_check': True,
        'captures': set(), 'hanging': set(), 'mates': set(),
    },
    {   # F5 en passant: exd6 e.p. and e6 both discover Bb2+; d5 pawn is
        # ep-capturable yet NOT a capture target (empty destination)
        'fen': '7k/8/8/3pP3/8/8/1B6/4K3 w - d6 0 2',
        'checks': {'d6', 'e6'}, 'ambiguous': False, 'castle_check': False,
        'captures': set(), 'hanging': set(), 'mates': set(),
    },
    {   # F6 promotion: g8=Q+ push check (catches missing promo expansion),
        # gxh8=Q+ promo-capture; king always escapes to a7 so no mate
        'fen': 'k6r/6P1/8/8/8/8/8/6K1 w - - 0 1',
        'checks': {'g8', 'h8'}, 'ambiguous': False, 'castle_check': False,
        'captures': {'h8'}, 'hanging': {'h8'}, 'mates': set(),
    },
    {   # F7 back-rank mate: Re8# is the only mate; Re7 is not even check
        'fen': '6k1/5ppp/8/8/8/8/5PPP/4R1K1 w - - 0 1',
        'checks': {'e8'}, 'ambiguous': False, 'castle_check': False,
        'captures': set(), 'hanging': set(), 'mates': {'e1e8'},
    },
]


def run_self_test():
    names = lambda squares: {chess.square_name(s) for s in squares}
    failures = 0
    for i, fx in enumerate(FIXTURES, 1):
        board = chess.Board(fx['fen'])
        dests, ambiguous, castle_check = check_dests_info(board)
        caps = capture_dests(board)
        got = {
            'checks': names(dests), 'ambiguous': ambiguous,
            'castle_check': castle_check, 'captures': names(caps),
            'hanging': names(hanging_dests(board)),
            'mates': mating_moves(board),
        }
        ok = all(got[k] == fx[k] for k in got)
        print(f"  F{i} {'PASS' if ok else 'FAIL'}  {fx['fen']}")
        if not ok:
            failures += 1
            for k in got:
                if got[k] != fx[k]:
                    print(f"      {k}: expected {fx[k]!r} got {got[k]!r}")
    print(f"self-test: {len(FIXTURES) - failures}/{len(FIXTURES)} fixtures passed")
    return failures == 0


# ---------------------------------------------------------------------------
# Phase A — stream the CSV with cheap gates into seeded reservoirs
# ---------------------------------------------------------------------------


class Reservoir:
    """Algorithm R reservoir sampling, deterministic under the module rng."""

    def __init__(self, cap):
        self.cap = cap
        self.items = []
        self.seen = 0

    def offer(self, item):
        self.seen += 1
        if len(self.items) < self.cap:
            self.items.append(item)
        else:
            j = rng.randrange(self.seen)
            if j < self.cap:
                self.items[j] = item


def stream_csv(csv_path, limit=None):
    scan_res = Reservoir(SCAN_RESERVOIR)
    mate_res = Reservoir(MATE_RESERVOIR)
    rows = 0
    with open(csv_path, newline='') as f:
        reader = csv.DictReader(f)
        missing = [c for c in EXPECTED_COLUMNS if c not in (reader.fieldnames or [])]
        if missing:
            sys.exit(f"CSV header is missing expected columns {missing} — "
                     f"got {reader.fieldnames}. Lichess DB format drift?")
        for row in reader:
            rows += 1
            if rows % 500_000 == 0:
                print(f"  streamed {rows:,} rows "
                      f"(scan pool seen {scan_res.seen:,}, mate pool seen {mate_res.seen:,})")
            if limit and rows >= limit:
                break
            try:
                rating = int(row['Rating'])
                plays = int(row['NbPlays'])
                popularity = int(row['Popularity'])
            except ValueError:
                continue
            if plays < MIN_PLAYS or popularity < MIN_POPULARITY:
                continue
            moves = row['Moves'].split()
            if len(moves) < 2:
                continue
            themes = row['Themes']
            if (MATE_RATING[0] <= rating <= MATE_RATING[1]
                    and len(moves[0]) == 4 and len(moves[1]) == 4
                    and 'mateIn1' in themes and 'mateIn1' in themes.split()):
                mate_res.offer((row['FEN'], moves[0], moves[1], rating))
            elif SCAN_RATING[0] <= rating <= SCAN_RATING[1]:
                scan_res.offer((row['FEN'], moves[0], rating))
    print(f"  streamed {rows:,} rows total; "
          f"scan candidates seen {scan_res.seen:,} (kept {len(scan_res.items):,}), "
          f"mate candidates seen {mate_res.seen:,} (kept {len(mate_res.items):,})")
    return scan_res.items, mate_res.items


# ---------------------------------------------------------------------------
# Phase B — analyze reservoir rows with python-chess
# ---------------------------------------------------------------------------


def analyze_scan_row(fen, setup_uci, rating):
    """One analysis record per position serving all three scan sets, or None."""
    try:
        board = chess.Board(fen)
        setup = chess.Move.from_uci(setup_uci)
        if setup not in board.legal_moves:
            return None
        board.push(setup)
    except (ValueError, AssertionError):
        return None
    if board.is_check():
        return None  # evasion-only positions contradict the scanning lesson
    if len(board.piece_map()) > MAX_PIECES:
        return None
    caps = capture_dests(board)
    dests, ambiguous, castle_check = check_dests_info(board)
    return {
        'fen': board.fen(),  # en_passant='legal' default: ep field only when a legal ep exists
        'side': 'w' if board.turn == chess.WHITE else 'b',
        'rating': rating,
        'checks': len(dests),
        'check_ok': not ambiguous and not castle_check,
        'caps': len(caps),
        'ep': board.has_legal_en_passant(),
        'hang': len(hanging_dests(board)),
        'free_pawn': has_undefended_enemy_pawn(board),
        'distractor': has_defended_enemy_piece(board),
    }


def verify_mate_row(fen, setup_uci, answer_uci, rating):
    try:
        board = chess.Board(fen)
        setup = chess.Move.from_uci(setup_uci)
        if setup not in board.legal_moves:
            return None
        board.push(setup)
        answer = chess.Move.from_uci(answer_uci)
        if answer not in board.legal_moves or board.is_castling(answer):
            return None
    except (ValueError, AssertionError):
        return None
    if len(board.piece_map()) > MAX_PIECES:
        return None
    post_fen = board.fen()
    n_mates = len(mating_moves(board))
    board.push(answer)
    if not board.is_checkmate():
        return None
    return {
        'fen': fen,
        'moves': f'{setup_uci} {answer_uci}',
        'post_fen': post_fen,
        'side': 'b' if 'w' in fen.split()[1] else 'w',  # placeholder, fixed below
        'rating': rating,
        'n_mates': n_mates,
    }


# ---------------------------------------------------------------------------
# Selection — stratified quotas, global dedup, deterministic
# ---------------------------------------------------------------------------


def fen_key(fen):
    return ' '.join(fen.split()[:4])


def _make_pool(candidates, prefer=None):
    """Deterministically shuffled pool; prefer=True candidates come first."""
    if prefer is None:
        pool = candidates[:]
        rng.shuffle(pool)
    else:
        yes = [c for c in candidates if c.get(prefer)]
        no = [c for c in candidates if not c.get(prefer)]
        rng.shuffle(yes)
        rng.shuffle(no)
        pool = yes + no
    return {'items': pool, 'i': 0}


def _take(pool, count, claimed, picked, key_field='fen'):
    taken = 0
    while taken < count and pool['i'] < len(pool['items']):
        rec = pool['items'][pool['i']]
        pool['i'] += 1
        k = fen_key(rec[key_field])
        if k in claimed:
            continue
        claimed.add(k)
        picked.append(rec)
        taken += 1
    return taken


def select_scan_set(records, n_field, ok_fn, quotas, claimed, prefer=None):
    buckets = {(n, s): [] for n in quotas for s in 'wb'}
    for rec in records:
        n = rec[n_field]
        if n in quotas and ok_fn(rec):
            buckets[(n, rec['side'])].append(rec)
    pools = {k: _make_pool(v, prefer) for k, v in buckets.items()}
    picked = []
    deficits = []
    for n in sorted(quotas, reverse=True):
        for s in 'wb':
            target = (quotas[n] + (1 if s == 'w' else 0)) // 2
            got = _take(pools[(n, s)], target, claimed, picked)
            if got < target:
                deficits.append((n, s, target - got))
    # Fill shortfall from easier bins: same side first, then the other side.
    for n, s, d in deficits:
        for side in (s, 'wb'.replace(s, '')):
            for n2 in sorted((m for m in quotas if m < n), reverse=True):
                if d == 0:
                    break
                d -= _take(pools[(n2, side)], d, claimed, picked)
            if d == 0:
                break
    rng.shuffle(picked)
    return picked


def select_mate_set(records, claimed):
    buckets = {(band, s): [] for band in MATE_QUOTAS for s in 'wb'}
    for rec in records:
        for lo, hi in MATE_QUOTAS:
            if lo <= rec['rating'] < hi or (hi == MATE_RATING[1] and rec['rating'] == hi):
                buckets[((lo, hi), rec['side'])].append(rec)
                break
    pools = {k: _make_pool(v) for k, v in buckets.items()}
    picked = []
    deficits = []
    for band in sorted(MATE_QUOTAS):
        for s in 'wb':
            target = (MATE_QUOTAS[band] + (1 if s == 'w' else 0)) // 2
            got = _take(pools[(band, s)], target, claimed, picked, key_field='post_fen')
            if got < target:
                deficits.append((band, s, target - got))
    for band, s, d in deficits:
        for side in (s, 'wb'.replace(s, '')):
            for band2 in sorted(MATE_QUOTAS):
                if band2 == band or d == 0:
                    continue
                d -= _take(pools[(band2, side)], d, claimed, picked, key_field='post_fen')
            if d == 0:
                break
    rng.shuffle(picked)
    return picked


# ---------------------------------------------------------------------------
# Self-validation — re-verify every entry from the exact output strings
# ---------------------------------------------------------------------------


def validate_outputs(checks, captures, hanging, mates):
    def fail(set_name, entry, reason):
        sys.exit(f"SELF-VALIDATION FAILED [{set_name}] {reason}: {entry}")

    for entry in checks:
        board = chess.Board(entry['fen'])
        dests, ambiguous, castle_check = check_dests_info(board)
        if board.is_check():
            fail('checks', entry, 'position in check')
        if ambiguous or castle_check:
            fail('checks', entry, 'ambiguous or castle-check')
        if len(dests) != entry['n']:
            fail('checks', entry, f'n mismatch (recomputed {len(dests)})')
    for entry in captures:
        board = chess.Board(entry['fen'])
        if board.is_check():
            fail('captures', entry, 'position in check')
        if board.has_legal_en_passant() or entry['fen'].split()[3] != '-':
            fail('captures', entry, 'en passant present')
        if len(capture_dests(board)) != entry['n']:
            fail('captures', entry, 'n mismatch')
    for entry in hanging:
        board = chess.Board(entry['fen'])
        if board.is_check():
            fail('hanging', entry, 'position in check')
        if has_undefended_enemy_pawn(board):
            fail('hanging', entry, 'undefended enemy pawn present')
        if len(hanging_dests(board)) != entry['n']:
            fail('hanging', entry, 'n mismatch')
    for entry in mates:
        board = chess.Board(entry['fen'])
        setup_uci, answer_uci = entry['moves'].split()
        board.push(chess.Move.from_uci(setup_uci))
        board.push(chess.Move.from_uci(answer_uci))
        if not board.is_checkmate():
            fail('mate', entry, 'answer does not checkmate')
    print('  self-validation: all entries re-verified OK')


# ---------------------------------------------------------------------------
# Stats
# ---------------------------------------------------------------------------


def print_stats(name, picked, n_field=None):
    if not picked:
        print(f"  {name}: EMPTY")
        return
    ratings = sorted(r['rating'] for r in picked)
    sides = sum(1 for r in picked if r['side'] == 'w')
    line = (f"  {name}: {len(picked)} positions | side w/b {sides}/{len(picked) - sides}"
            f" | rating {ratings[0]}/{ratings[len(ratings) // 2]}/{ratings[-1]}")
    if n_field:
        hist = {}
        for r in picked:
            hist[r[n_field]] = hist.get(r[n_field], 0) + 1
        line += ' | n ' + ' '.join(f'{k}:{v}' for k, v in sorted(hist.items()))
    print(line)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main():
    global rng
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('csv_path', nargs='?', help='path to lichess_db_puzzle.csv')
    parser.add_argument('--seed', type=int, default=SEED)
    parser.add_argument('--limit', type=int, default=None,
                        help='process only the first N CSV rows (dev iteration)')
    parser.add_argument('--self-test', action='store_true',
                        help='run embedded cross-language fixtures and exit')
    args = parser.parse_args()

    if args.self_test:
        sys.exit(0 if run_self_test() else 1)
    if not args.csv_path:
        parser.error('csv_path is required unless --self-test')

    rng = random.Random(args.seed)

    print(f"Phase A: streaming {args.csv_path} ...")
    scan_rows, mate_rows = stream_csv(args.csv_path, args.limit)

    print(f"Phase B: analyzing {len(scan_rows):,} scan candidates ...")
    scan_records = []
    for i, (fen, setup, rating) in enumerate(scan_rows, 1):
        if i % 10_000 == 0:
            print(f"  analyzed {i:,}/{len(scan_rows):,}")
        rec = analyze_scan_row(fen, setup, rating)
        if rec:
            scan_records.append(rec)
    print(f"  {len(scan_records):,} scan positions analyzed clean")

    print(f"Phase B: verifying {len(mate_rows):,} mate candidates ...")
    mate_records = []
    for fen, setup, answer, rating in mate_rows:
        rec = verify_mate_row(fen, setup, answer, rating)
        if rec:
            # side to move after the setup move (the player's side)
            rec['side'] = 'w' if rec['post_fen'].split()[1] == 'w' else 'b'
            mate_records.append(rec)
    print(f"  {len(mate_records):,} mates verified")

    # Global dedup, scarcity order: hanging -> checks -> mate -> captures.
    # Pre-seed with the existing move-trainer puzzle positions so no scan or
    # mate position repeats one the kid already sees in the Moves drill.
    claimed = set()
    if EXISTING_PUZZLES.exists():
        for entry in json.loads(EXISTING_PUZZLES.read_text()):
            try:
                board = chess.Board(entry['fen'])
                board.push(chess.Move.from_uci(entry['moves'].split()[0]))
                claimed.add(fen_key(board.fen()))
            except (ValueError, AssertionError, KeyError, IndexError):
                continue
        print(f"  pre-seeded dedup with {len(claimed)} existing move-trainer positions")

    hanging_picked = select_scan_set(
        scan_records, 'hang',
        lambda r: not r['free_pawn'],
        HANGING_QUOTAS, claimed, prefer='distractor')
    checks_picked = select_scan_set(
        scan_records, 'checks', lambda r: r['check_ok'],
        CHECKS_QUOTAS, claimed)
    mate_picked = select_mate_set(mate_records, claimed)
    captures_picked = select_scan_set(
        scan_records, 'caps', lambda r: not r['ep'],
        CAPTURES_QUOTAS, claimed)

    checks_out = [{'fen': r['fen'], 'n': r['checks']} for r in checks_picked]
    captures_out = [{'fen': r['fen'], 'n': r['caps']} for r in captures_picked]
    hanging_out = [{'fen': r['fen'], 'n': r['hang']} for r in hanging_picked]
    mate_out = [{'fen': r['fen'], 'moves': r['moves']} for r in mate_picked]

    print('Self-validating every selected entry ...')
    validate_outputs(checks_out, captures_out, hanging_out, mate_out)

    print('Stats:')
    print_stats('scan_checks', checks_picked, 'checks')
    print_stats('scan_captures', captures_picked, 'caps')
    print_stats('scan_hanging', hanging_picked, 'hang')
    distractor_share = (sum(1 for r in hanging_picked if r['distractor'])
                        / max(1, len(hanging_picked)))
    print(f"    hanging positions with a defended-capturable distractor: "
          f"{distractor_share:.0%} (target >= 60%)")
    print_stats('mate_in_one', mate_picked)
    mate_hist = {}
    for r in mate_picked:
        mate_hist[r['n_mates']] = mate_hist.get(r['n_mates'], 0) + 1
    print('    distinct mating moves per puzzle: '
          + ' '.join(f'{k}:{v}' for k, v in sorted(mate_hist.items())))

    for path, data in ((OUT_CHECKS, checks_out), (OUT_CAPTURES, captures_out),
                       (OUT_HANGING, hanging_out), (OUT_MATE, mate_out)):
        path.write_text(json.dumps(data, separators=(',', ':')))
        print(f"  wrote {path} ({path.stat().st_size:,} bytes, {len(data)} entries)")


if __name__ == '__main__':
    main()
