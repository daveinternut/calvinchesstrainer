import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The app's mark: a knight's L-move on a 3×3 grid, from a white start to an
/// amber target square. Drawn, not an image, so it is crisp at any size.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(size: Size.square(size), painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Designed on a 40-unit grid.
    final k = size.width / 40;
    canvas.scale(k);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 40, 40),
        const Radius.circular(11),
      ),
      Paint()..color = AppColors.brand,
    );

    final cell = Paint()..color = Colors.white.withValues(alpha: 0.13);
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        if ((c + r).isEven) {
          canvas.drawRect(
            Rect.fromLTWH(5 + c * 10.0, 5 + r * 10.0, 10, 10),
            cell,
          );
        }
      }
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 6, 8, 8),
        const Radius.circular(2),
      ),
      Paint()..color = AppColors.amber,
    );

    final path = Path()
      ..moveTo(10, 30)
      ..lineTo(10, 10)
      ..lineTo(20, 10);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(const Offset(10, 30), 3.6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
