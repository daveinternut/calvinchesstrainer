import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/services/stockfish_service.dart';

class EvalBar extends StatelessWidget {
  final EvalResult eval;

  const EvalBar({
    super.key,
    required this.eval,
  });

  @override
  Widget build(BuildContext context) {
    final whiteFraction = _evalToFraction(eval.centipawns);

    final label = eval.isMate
        ? 'M${eval.mateIn!.abs()}'
        : (eval.centipawns >= 0
            ? '+${eval.pawns.toStringAsFixed(1)}'
            : eval.pawns.toStringAsFixed(1));

    final isWhiteAdvantage = eval.centipawns >= 0;

    return Container(
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final whiteWidth = totalWidth * whiteFraction;

          return Stack(
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    width: whiteWidth,
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Container(color: Colors.grey.shade800),
                  ),
                ],
              ),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isWhiteAdvantage
                        ? Colors.black.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isWhiteAdvantage ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _evalToFraction(int cp) {
    const scale = 400.0;
    final sigmoid = 1.0 / (1.0 + math.exp(-cp / scale));
    return sigmoid.clamp(0.05, 0.95);
  }
}
