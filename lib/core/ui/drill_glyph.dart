import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:chessground/chessground.dart' show PieceSet;
import 'package:dartchess/dartchess.dart' show PieceKind;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A cell on a glyph's 5×5 board: (column, row) from the top-left.
typedef GlyphCell = (int, int);

class GlyphArrow {
  const GlyphArrow(this.from, this.to, {this.color = AppColors.brand});
  final GlyphCell from;
  final GlyphCell to;
  final Color color;
}

class GlyphPath {
  const GlyphPath(this.cells, {this.color = AppColors.brand});
  final List<GlyphCell> cells;
  final Color color;
}

class GlyphRing {
  const GlyphRing(this.color, {this.dashed = false});
  final Color color;
  final bool dashed;
}

/// What a drill's glyph shows: a few pieces on a 5×5 corner of a board,
/// plus the marks that tell the drill's idea (arrows, dots, a target square).
class GlyphSpec {
  const GlyphSpec({
    this.pieces = const {},
    this.fills = const {},
    this.rings = const {},
    this.dots = const {},
    this.arrows = const [],
    this.paths = const [],
    this.pill,
  });

  final Map<GlyphCell, PieceKind> pieces;
  final Map<GlyphCell, Color> fills;
  final Map<GlyphCell, GlyphRing> rings;
  final Map<GlyphCell, Color> dots;
  final List<GlyphArrow> arrows;
  final List<GlyphPath> paths;

  /// Optional notation tag in the corner ("e3", "Nf3").
  final String? pill;
}

/// A drill's icon: a tiny board drawn from a real board state, in the app's
/// own board colours and pieces. Contains no words, so it needs no
/// translating. Decorative: the drill's name always sits beside it.
class DrillGlyph extends StatelessWidget {
  const DrillGlyph({super.key, required this.spec, this.size = 60});

  static const cells = 5;

  final GlyphSpec spec;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = size / cells;
    final radius = math.max(6.0, s * 0.95);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _BoardPainter(spec)),
              ),
              for (final entry in spec.pieces.entries)
                Positioned(
                  left: entry.key.$1 * s,
                  top: entry.key.$2 * s,
                  width: s,
                  height: s,
                  child: Padding(
                    padding: EdgeInsets.all(s * 0.03),
                    child: Image(
                      image: PieceSet.cburnett.assets[entry.value]!,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              Positioned.fill(
                child: CustomPaint(painter: _MarksPainter(spec)),
              ),
              if (spec.pill != null)
                Positioned(
                  right: math.max(2, s * 0.22),
                  bottom: math.max(2, s * 0.22),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: math.max(4, s * 0.36),
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(math.max(4, s * 0.45)),
                    ),
                    child: Text(
                      spec.pill!,
                      style: AppText.mono.copyWith(
                        fontSize: math.max(9, s * 0.78),
                        height: 1.4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter(this.spec);
  final GlyphSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / DrillGlyph.cells;
    for (var r = 0; r < DrillGlyph.cells; r++) {
      for (var c = 0; c < DrillGlyph.cells; c++) {
        final fill = spec.fills[(c, r)] ??
            ((c + r).isEven ? AppColors.boardLight : AppColors.boardDark);
        canvas.drawRect(
          Rect.fromLTWH(c * s, r * s, s + 0.5, s + 0.5),
          Paint()..color = fill,
        );
      }
    }
    for (final entry in spec.rings.entries) {
      final (c, r) = entry.key;
      final inset = math.max(1.0, s * 0.06);
      final width = math.max(2.0, s * 0.075);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(c * s, r * s, s, s).deflate(inset + width / 2),
        Radius.circular(math.max(3, s * 0.2)),
      );
      final paint = Paint()
        ..color = entry.value.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width;
      final path = Path()..addRRect(rect);
      canvas.drawPath(
        entry.value.dashed ? _dash(path, width * 1.6, width * 1.2) : path,
        paint,
      );
    }
    for (final entry in spec.dots.entries) {
      final (c, r) = entry.key;
      canvas.drawCircle(
        Offset((c + .5) * s, (r + .5) * s),
        math.max(2, s * 0.15),
        Paint()..color = entry.value,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => old.spec != spec;
}

class _MarksPainter extends CustomPainter {
  _MarksPainter(this.spec);
  final GlyphSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / DrillGlyph.cells;
    Offset center(GlyphCell cell) => Offset((cell.$1 + .5) * s, (cell.$2 + .5) * s);

    for (final path in spec.paths) {
      final width = math.max(2.0, s * 0.13);
      final p = Path();
      for (var i = 0; i < path.cells.length; i++) {
        final o = center(path.cells[i]);
        i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        _dash(p, width * 0.1, width * 2.1),
        Paint()
          ..color = path.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    for (final arrow in spec.arrows) {
      final from = center(arrow.from);
      final to = center(arrow.to);
      final width = math.max(2.4, s * 0.17);
      final head = math.max(6.5, s * 0.44);
      final gap = spec.pieces.containsKey(arrow.to) ? s * 0.36 : s * 0.08;
      final dir = (to - from) / (to - from).distance;
      final normal = Offset(-dir.dy, dir.dx);
      final tip = to - dir * gap;
      final base = tip - dir * head;
      final paint = Paint()..color = arrow.color.withValues(alpha: 0.92);
      canvas.drawLine(
        from + dir * width * 0.4,
        base + dir,
        Paint()
          ..color = arrow.color.withValues(alpha: 0.92)
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
      final hw = head * 0.62;
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo((base + normal * hw).dx, (base + normal * hw).dy)
          ..lineTo((base - normal * hw).dx, (base - normal * hw).dy)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MarksPainter old) => old.spec != spec;
}

/// [path] as a dash pattern of [on]-long dashes with [off] gaps.
Path _dash(Path path, double on, double off) {
  final out = Path();
  for (final PathMetric metric in path.computeMetrics()) {
    var d = 0.0;
    while (d < metric.length) {
      out.addPath(metric.extractPath(d, math.min(d + on, metric.length)), Offset.zero);
      d += on + off;
    }
  }
  return out;
}
