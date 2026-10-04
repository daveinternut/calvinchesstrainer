import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../models/letter_game_state.dart';
import 'letter_strings.dart';

/// Explore mode: a gallery of all six pieces with their letters and names.
/// Tapping a card speaks the piece name and shows its mnemonic above.
class LetterExploreGrid extends StatelessWidget {
  final LetterGameState gameState;
  final ValueChanged<LetterPiece> onTap;

  const LetterExploreGrid({
    super.key,
    required this.gameState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
        children: [
          for (final piece in LetterPiece.values)
            _ExploreCard(
              key: ValueKey('explore_${piece.name}'),
              piece: piece,
              selected: gameState.lastFeedback?.tapped == piece,
              onTap: () => onTap(piece),
            ),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final LetterPiece piece;
  final bool selected;
  final VoidCallback onTap;

  const _ExploreCard({
    super.key,
    required this.piece,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asset = PieceSet.cburnett.assets[piece.pieceKind(black: false)];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0F0E1B16),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: asset != null ? Image(image: asset) : const SizedBox(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    piece.hasLetter ? piece.letter : '–',
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      pieceNameFor(l10n, piece),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
