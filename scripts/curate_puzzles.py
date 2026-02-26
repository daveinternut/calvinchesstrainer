#!/usr/bin/env python3
"""
Curate a subset of the Lichess puzzle database for the Moves Trainer.

Downloads and filters the Lichess puzzle CSV to produce a compact JSON file
containing ~500 puzzles with good variety of piece types and difficulty levels.

Usage:
  # First, download the puzzle database (one-time, ~300MB compressed):
  wget https://database.lichess.org/lichess_db_puzzle.csv.zst
  zstd -d lichess_db_puzzle.csv.zst

  # Then run this script:
  python3 scripts/curate_puzzles.py lichess_db_puzzle.csv

  # Output: assets/puzzles/moves_puzzles.json
"""

import csv
import json
import random
import sys
from collections import defaultdict
from pathlib import Path
from typing import Optional

TARGET_COUNT = 500
MIN_RATING = 600
MAX_RATING = 1500
MIN_PLAYS = 500
MIN_POPULARITY = 50

PIECE_FROM_LETTER = {
    'K': 'king', 'Q': 'queen', 'R': 'rook',
    'B': 'bishop', 'N': 'knight',
}

def uci_move_length(move: str) -> int:
    return len(move)

def infer_piece_from_fen_and_uci(fen: str, uci_move: str) -> Optional[str]:
    """Determine which piece type is moving based on FEN board and UCI origin square."""
    board_part = fen.split()[0]
    from_sq = uci_move[:2]
    file_idx = ord(from_sq[0]) - ord('a')
    rank_idx = int(from_sq[1]) - 1

    rows = board_part.split('/')
    row = rows[7 - rank_idx]

    col = 0
    for ch in row:
        if ch.isdigit():
            col += int(ch)
        else:
            if col == file_idx:
                upper = ch.upper()
                if upper == 'P':
                    return 'pawn'
                return PIECE_FROM_LETTER.get(upper)
            col += 1
    return None

def is_castling(fen: str, uci_move: str) -> bool:
    """Check if a UCI move is castling (king moves 2+ squares horizontally)."""
    from_file = ord(uci_move[0]) - ord('a')
    to_file = ord(uci_move[2]) - ord('a')
    piece = infer_piece_from_fen_and_uci(fen, uci_move)
    return piece == 'king' and abs(to_file - from_file) >= 2

def process_puzzle(row: dict) -> Optional[dict]:
    """Validate and extract a puzzle row. Returns None if it should be filtered out."""
    try:
        rating = int(row['Rating'])
        nb_plays = int(row['NbPlays'])
        popularity = int(row['Popularity'])
    except (ValueError, KeyError):
        return None

    if not (MIN_RATING <= rating <= MAX_RATING):
        return None
    if nb_plays < MIN_PLAYS:
        return None
    if popularity < MIN_POPULARITY:
        return None

    fen = row.get('FEN', '')
    moves_str = row.get('Moves', '')
    moves = moves_str.split()

    if len(moves) < 2:
        return None

    setup_move = moves[0]
    answer_move = moves[1]

    # Exclude promotions (UCI promotion moves have 5 chars, e.g., "e7e8q")
    if len(answer_move) != 4:
        return None
    if len(setup_move) != 4:
        return None

    # Play setup move mentally to get puzzle position FEN for piece inference.
    # We need the position AFTER the setup move to determine the answer piece.
    # Since we don't have a chess engine here, we infer from the ORIGINAL fen
    # and the answer move's origin. But the setup move changes the board...
    # 
    # For accurate piece detection, we rely on dartchess at runtime.
    # Here we just do a rough filter to ensure variety.
    piece = infer_piece_from_fen_and_uci(fen, answer_move)

    # Exclude castling as answer moves
    if is_castling(fen, answer_move):
        return None

    return {
        'fen': fen,
        'moves': f"{setup_move} {answer_move}",
        'rating': rating,
        'piece_hint': piece,
    }

def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    csv_path = Path(sys.argv[1])
    if not csv_path.exists():
        print(f"Error: {csv_path} not found.")
        print("Download from: https://database.lichess.org/lichess_db_puzzle.csv.zst")
        sys.exit(1)

    output_path = Path(__file__).parent.parent / 'assets' / 'puzzles' / 'moves_puzzles.json'
    output_path.parent.mkdir(parents=True, exist_ok=True)

    print(f"Reading {csv_path}...")
    candidates = defaultdict(list)
    total_read = 0

    with open(csv_path, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            total_read += 1
            if total_read % 500_000 == 0:
                print(f"  ...processed {total_read:,} rows")

            result = process_puzzle(row)
            if result is None:
                continue

            piece = result['piece_hint'] or 'unknown'
            candidates[piece].append(result)

    print(f"\nProcessed {total_read:,} total puzzles.")
    print("Candidates by piece type:")
    for piece, puzzles in sorted(candidates.items()):
        print(f"  {piece}: {len(puzzles):,}")

    # Sample evenly across piece types for variety
    selected = []
    known_pieces = ['pawn', 'knight', 'bishop', 'rook', 'queen', 'king']
    per_piece = TARGET_COUNT // len(known_pieces)
    remainder = TARGET_COUNT % len(known_pieces)

    for i, piece in enumerate(known_pieces):
        pool = candidates.get(piece, [])
        count = per_piece + (1 if i < remainder else 0)
        if len(pool) <= count:
            selected.extend(pool)
        else:
            selected.extend(random.sample(pool, count))

    # Fill any shortfall from the general pool
    if len(selected) < TARGET_COUNT:
        all_remaining = []
        selected_fens = {p['fen'] for p in selected}
        for puzzles in candidates.values():
            for p in puzzles:
                if p['fen'] not in selected_fens:
                    all_remaining.append(p)
        needed = TARGET_COUNT - len(selected)
        if len(all_remaining) >= needed:
            selected.extend(random.sample(all_remaining, needed))
        else:
            selected.extend(all_remaining)

    random.shuffle(selected)

    # Strip internal fields, keep only what the app needs
    output = [{'fen': p['fen'], 'moves': p['moves']} for p in selected]

    with open(output_path, 'w') as f:
        json.dump(output, f, separators=(',', ':'))

    print(f"\nWrote {len(output)} puzzles to {output_path}")
    size_kb = output_path.stat().st_size / 1024
    print(f"File size: {size_kb:.1f} KB")

if __name__ == '__main__':
    main()
