import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';

import '../../../core/services/puzzle_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../letter_trainer/models/letter_game_state.dart';
import '../../letter_trainer/widgets/letter_strings.dart';
import '../models/move_game_state.dart';

class MovePromptDisplay extends StatelessWidget {
  final MoveGameState gameState;

  const MovePromptDisplay({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final puzzle = gameState.currentPuzzle;
    if (puzzle == null || gameState.isLoading) {
      return const SizedBox(height: 64);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.makeTheMove,
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
          friendlyDescription(puzzle, l10n),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
        ),
      ],
    );
  }

  /// The plain-language reading of the move under the SAN: "Knight takes on
  /// e5", "Castle kingside".
  ///
  /// Built from the move itself rather than by picking the SAN apart, so a
  /// disambiguated move (`Qfc8+`) still names its real square (c8), and the
  /// piece name comes from the active locale.
  static String friendlyDescription(
      ParsedPuzzle puzzle, AppLocalizations l10n) {
    final move = puzzle.expectedMove;
    if (puzzle.isCastling) {
      return move.to.file.value > move.from.file.value
          ? l10n.castleKingside
          : l10n.castleQueenside;
    }

    final piece =
        pieceNameFor(l10n, LetterPiece.values.byName(puzzle.pieceRole.name));
    final square = move.to.name;
    return puzzle.isCapture
        ? l10n.pieceTakesOn(piece, square)
        : l10n.pieceToSquare(piece, square);
  }
}
