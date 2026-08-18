import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Visual theme for project heroes. Rendered rather than photographic, so a
/// hero never depends on a network image and never mislabels a stock photo as
/// a specific site.
enum MiningHeroKind {
  /// Strategic-minerals framing over open terrain.
  strategicMinerals,

  /// Muted placeholder for assets still in discussion.
  forthcoming,
}

/// Illustrated Mongolian mining landscape for project heroes and card glyphs.
/// Pure CustomPainter — no network images, no runtime failure modes.
class MiningHeroArt extends StatelessWidget {
  const MiningHeroArt({
    super.key,
    this.compact = false,
    this.kind = MiningHeroKind.strategicMinerals,
  });

  /// Smaller, simpler composition for list-card thumbnails.
  final bool compact;
  final MiningHeroKind? kind;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiningLandscapePainter(
        compact: compact,
        kind: kind ?? MiningHeroKind.strategicMinerals,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _MiningLandscapePainter extends CustomPainter {
  const _MiningLandscapePainter({required this.compact, required this.kind});

  final bool compact;
  final MiningHeroKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final forthcoming = kind == MiningHeroKind.forthcoming;

    // South-Gobi dawn: cool high sky → warm earth haze (not a flat sunset card).
    final skyColors = forthcoming
        ? const [
            Color(0xFFE8EEF4),
            Color(0xFFD5DEE8),
            Color(0xFFC4B5A5),
            Color(0xFFA89078),
          ]
        : const [
            Color(0xFFDCE8F2),
            Color(0xFFF2E6D4),
            Color(0xFFE8C49A),
            Color(0xFFC48A52),
          ];
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.5, 0),
          Offset(w * 0.5, h),
          skyColors,
          const [0.0, 0.35, 0.68, 1.0],
        ),
    );

    // Soft sun / haze disc — low on the horizon like Gobi morning light.
    final sunCenter = Offset(
      w * (compact ? 0.72 : 0.78),
      h * (compact ? 0.32 : 0.26),
    );
    final sunR = math.min(w, h) * (compact ? 0.16 : 0.12);
    canvas.drawCircle(
      sunCenter,
      sunR * 2.1,
      Paint()
        ..color =
            (forthcoming ? const Color(0xFFE8E0D4) : const Color(0xFFFFE7C2))
                .withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    canvas.drawCircle(
      sunCenter,
      sunR,
      Paint()
        ..shader = ui.Gradient.radial(
          sunCenter + Offset(-sunR * 0.15, -sunR * 0.2),
          sunR,
          forthcoming
              ? const [Color(0xFFF5F2EC), Color(0xFFD8D0C4), Color(0xFFB5A898)]
              : const [Color(0xFFFFF8EA), Color(0xFFFFD077), Color(0xFFE28D4F)],
          const [0.0, 0.55, 1.0],
        ),
    );

    // Distant flat-top mesas (South Gobi silhouette language).
    _drawRidge(
      canvas,
      size,
      yBase: h * (compact ? 0.50 : 0.44),
      peaks: const [0.0, 0.12, 0.28, 0.42, 0.58, 0.74, 0.9, 1.0],
      heights: const [0.06, 0.10, 0.08, 0.14, 0.09, 0.12, 0.07, 0.05],
      color: (forthcoming ? const Color(0xFF8A8078) : const Color(0xFF8B6A4A))
          .withValues(alpha: 0.28),
    );

    _drawRidge(
      canvas,
      size,
      yBase: h * (compact ? 0.62 : 0.56),
      peaks: const [0.0, 0.18, 0.36, 0.52, 0.7, 0.88, 1.0],
      heights: const [0.08, 0.16, 0.12, 0.20, 0.11, 0.15, 0.07],
      color: (forthcoming ? const Color(0xFF6E655C) : const Color(0xFF6B4A30))
          .withValues(alpha: 0.48),
    );

    // Foreground alluvial fan / gravel plain.
    final ground = Path()
      ..moveTo(0, h * (compact ? 0.70 : 0.66))
      ..quadraticBezierTo(w * 0.22, h * 0.60, w * 0.48, h * 0.70)
      ..quadraticBezierTo(w * 0.72, h * 0.78, w, h * 0.64)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      ground,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, h * 0.62),
          Offset(0, h),
          forthcoming
              ? const [Color(0xFFB0A396), Color(0xFF7A6E62), Color(0xFF4A433C)]
              : const [Color(0xFFC49A6C), Color(0xFF8A5A34), Color(0xFF4A2E18)],
          const [0.0, 0.45, 1.0],
        ),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.4, h * 0.92),
        width: w * 0.75,
        height: h * 0.08,
      ),
      Paint()
        ..color = const Color(0xFF1A0E08).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    if (!compact && !forthcoming) {
      // Open-pit bench cue — mining, not dunes.
      _drawBench(canvas, size);

      // Strategic-mineral crystal cluster (Si / Li / REE cue, not a stock photo).
      _drawMineralCluster(
        canvas,
        origin: Offset(w * 0.62, h * 0.58),
        scale: math.min(w, h) * 0.00115,
      );
    } else if (!compact && forthcoming) {
      // Soft dashed horizon mark — "to be secured", no false specificity.
      final dash = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.35)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      final y = h * 0.58;
      var x = w * 0.2;
      while (x < w * 0.8) {
        canvas.drawLine(Offset(x, y), Offset(x + 8, y), dash);
        x += 14;
      }
    }
  }

  void _drawBench(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bench = Path()
      ..moveTo(w * 0.06, h * 0.78)
      ..lineTo(w * 0.28, h * 0.72)
      ..lineTo(w * 0.42, h * 0.74)
      ..lineTo(w * 0.38, h * 0.82)
      ..lineTo(w * 0.10, h * 0.86)
      ..close();
    canvas.drawPath(
      bench,
      Paint()
        ..color = const Color(0xFF2A1810).withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    // Terrace lines.
    final line = Paint()
      ..color = const Color(0xFFFFD077).withValues(alpha: 0.28)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.10, h * 0.80),
      Offset(w * 0.34, h * 0.75),
      line,
    );
    canvas.drawLine(
      Offset(w * 0.12, h * 0.83),
      Offset(w * 0.36, h * 0.78),
      line,
    );
  }

  /// Faceted crystal forms hinting silicon / lithium / rare-earth character.
  void _drawMineralCluster(
    Canvas canvas, {
    required Offset origin,
    required double scale,
  }) {
    void crystal(List<Offset> pts, List<Color> colors) {
      final path = Path()
        ..moveTo(origin.dx + pts[0].dx * scale, origin.dy + pts[0].dy * scale);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(
          origin.dx + pts[i].dx * scale,
          origin.dy + pts[i].dy * scale,
        );
      }
      path.close();
      final bounds = path.getBounds();
      canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(
            bounds.topLeft,
            bounds.bottomRight,
            colors,
            const [0.0, 0.55, 1.0],
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.4),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // Silicon-like prism (cool grey-blue).
    crystal(
      const [
        Offset(0, -40),
        Offset(22, -10),
        Offset(16, 36),
        Offset(-14, 32),
        Offset(-20, -8),
      ],
      [
        const Color(0xFFE8F0F8).withValues(alpha: 0.85),
        const Color(0xFF8FA8C4).withValues(alpha: 0.75),
        const Color(0xFF4A6580).withValues(alpha: 0.7),
      ],
    );
    // Lithium-like pale shard.
    crystal(
      const [Offset(28, -28), Offset(48, -6), Offset(42, 30), Offset(24, 22)],
      [
        const Color(0xFFF8FBFF).withValues(alpha: 0.8),
        const Color(0xFFB8D4E8).withValues(alpha: 0.7),
        const Color(0xFF6A90B0).withValues(alpha: 0.65),
      ],
    );
    // Rare-earth warm facet (brand copper).
    crystal(
      const [Offset(-8, 8), Offset(18, 18), Offset(10, 48), Offset(-18, 40)],
      [
        const Color(0xFFFFEDC1).withValues(alpha: 0.8),
        const Color(0xFFE28D4F).withValues(alpha: 0.75),
        const Color(0xFFC2773F).withValues(alpha: 0.7),
      ],
    );
  }

  void _drawRidge(
    Canvas canvas,
    Size size, {
    required double yBase,
    required List<double> peaks,
    required List<double> heights,
    required Color color,
  }) {
    final path = Path()..moveTo(0, size.height);
    for (var i = 0; i < peaks.length; i++) {
      final x = size.width * peaks[i];
      final y = yBase - size.height * heights[i];
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = size.width * peaks[i - 1];
        final midX = (prevX + x) / 2;
        path.quadraticBezierTo(midX, y, x, y);
      }
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MiningLandscapePainter oldDelegate) =>
      oldDelegate.compact != compact || oldDelegate.kind != kind;
}
