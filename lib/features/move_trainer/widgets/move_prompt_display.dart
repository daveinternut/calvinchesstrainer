import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/move_game_state.dart';

class MovePromptDisplay extends StatelessWidget {
  final MoveGameState gameState;

  const MovePromptDisplay({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final puzzle = gameState.currentPuzzle;
    if (puzzle == null || gameState.isLoading) {
      return const SizedBox(height: 64);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Make the move',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          puzzle.san,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          _friendlyDescription(puzzle.pieceName, puzzle.san, puzzle.pieceRole),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
        ),
      ],
    );
  }

  String _friendlyDescription(String pieceName, String san, Role role) {
    if (san == 'O-O') return 'Castle kingside';
    if (san == 'O-O-O') return 'Castle queenside';

    final capitalizedPiece = '${pieceName[0].toUpperCase()}${pieceName.substring(1)}';
    final destination = san.replaceAll(RegExp(r'[+#!?]'), '');

    String square;
    if (role == Role.pawn) {
      if (destination.contains('x')) {
        square = destination.split('x').last;
      } else {
        square = destination;
      }
    } else {
      square = destination.replaceAll(RegExp(r'^[KQRBN]'), '');
      square = square.replaceAll('x', '');
    }

    if (san.contains('x')) {
      return '$capitalizedPiece takes on $square';
    }
    return '$capitalizedPiece to $square';
  }
}
