import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/which_side_wins_state.dart';

class PieceGroupPanel extends StatelessWidget {
  final List<PieceType> pieces;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final bool enabled;

  /// The group's point total, revealed during feedback so the child sees why
  /// a side won ("9" vs "8"). Null hides it.
  final int? total;

  const PieceGroupPanel({
    super.key,
    required this.pieces,
    required this.onTap,
    this.backgroundColor,
    this.enabled = true,
    this.total,
  });

  static const double _spacing = 6;
  static const double _maxPieceSize = 150;
  static const double _totalSlotHeight = 40;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: backgroundColor != null
                  ? backgroundColor!.withValues(alpha: 0.6)
                  : AppColors.line,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) =>
                        Center(child: _buildPieces(constraints)),
                  ),
                ),
                // A fixed slot, so revealing the total never shifts the
                // pieces.
                SizedBox(
                  height: _totalSlotHeight,
                  child: Center(
                    child: total == null
                        ? null
                        : Text(
                            '$total',
                            style: AppText.number.copyWith(fontSize: 30),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Lays the pieces out in whichever column count gives the biggest pieces
  /// that fit the panel — large on an iPad, still tidy on a phone.
  Widget _buildPieces(BoxConstraints constraints) {
    final count = pieces.length;
    if (count == 0) return const SizedBox.shrink();

    var size = 0.0;
    var columns = 1;
    for (var c = 1; c <= count; c++) {
      final rows = (count / c).ceil();
      final fit = math.min(
        (constraints.maxWidth - _spacing * (c - 1)) / c,
        (constraints.maxHeight - _spacing * (rows - 1)) / rows,
      );
      if (fit > size) {
        size = fit;
        columns = c;
      }
    }
    size = size.clamp(0.0, _maxPieceSize);

    return SizedBox(
      // Exactly `columns` pieces per row (plus a hair for rounding).
      width: columns * size + (columns - 1) * _spacing + 0.5,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: _spacing,
        runSpacing: _spacing,
        children: [
          for (final piece in pieces)
            SizedBox.square(
              dimension: size,
              child: switch (PieceSet.cburnett.assets[piece.pieceKind]) {
                final asset? => Image(image: asset),
                null => const SizedBox(),
              },
            ),
        ],
      ),
    );
  }
}
