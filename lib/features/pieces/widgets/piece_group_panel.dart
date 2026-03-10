import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import '../models/which_side_wins_state.dart';

class PieceGroupPanel extends StatelessWidget {
  final List<PieceType> pieces;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final bool enabled;

  const PieceGroupPanel({
    super.key,
    required this.pieces,
    required this.onTap,
    this.backgroundColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: backgroundColor != null
                  ? backgroundColor!.withValues(alpha: 0.6)
                  : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (backgroundColor ?? Colors.grey)
                    .withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: pieces.map((piece) {
                  final asset = PieceSet.cburnett.assets[piece.pieceKind];
                  return SizedBox(
                    width: _pieceSize(pieces.length),
                    height: _pieceSize(pieces.length),
                    child: asset != null
                        ? Image(image: asset)
                        : const SizedBox(),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _pieceSize(int count) {
    if (count <= 1) return 72;
    if (count <= 2) return 60;
    if (count <= 3) return 52;
    return 44;
  }
}
