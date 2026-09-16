import 'dart:ui' as ui;

import 'package:flutter/material.dart';

enum MiningHeroKind { strategicMinerals, forthcoming }

class MiningHeroArt extends StatelessWidget {
  const MiningHeroArt({
    super.key,
    this.kind = MiningHeroKind.strategicMinerals,
  });

  final MiningHeroKind? kind;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiningLandscapePainter(
        kind: kind ?? MiningHeroKind.strategicMinerals,
      ),
      child: const SizedBox.expand(),
    );
  }
}

const double _refW = 390;
const double _refH = 176;

class _MiningLandscapePainter extends CustomPainter {
  const _MiningLandscapePainter({required this.kind});

  final MiningHeroKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final forthcoming = kind == MiningHeroKind.forthcoming;
    double sx(double x) => x / _refW * w;
    double sy(double y) => y / _refH * h;

    final skyColors = forthcoming
        ? const [Color(0xFFE9DFC8), Color(0xFFA89684), Color(0xFF4A473F)]
        : const [Color(0xFFFAC96B), Color(0xFFE06B26), Color(0xFF404F33)];
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.5, 0),
          Offset(w * 0.5, h),
          skyColors,
          const [0.0, 0.52, 1.0],
        ),
    );

    canvas.drawCircle(
      Offset(sx(316), sy(58)),
      sy(38),
      Paint()
        ..color =
            (forthcoming ? const Color(0xFFD8D0C4) : const Color(0xFFFFD46A))
                .withValues(alpha: 0.75),
    );

    const apexes = [
      Offset(195, 64),
      Offset(227, 74),
      Offset(259, 84),
      Offset(291, 94),
    ];
    const bases = [
      (Offset(95.4071, 139), Offset(294.593, 139)),
      (Offset(138.665, 158), Offset(315.335, 158)),
      (Offset(181.924, 177), Offset(336.076, 177)),
      (Offset(225.182, 196), Offset(356.818, 196)),
    ];
    final ridgeColors = forthcoming
        ? const [
            Color(0xFFB8ACA0),
            Color(0xFF8A7F74),
            Color(0xFF5C5850),
            Color(0xFF3A3833),
          ]
        : const [
            Color(0xFFB86D2D),
            Color(0xFF754C2E),
            Color(0xFF44502E),
            Color(0xFF263B30),
          ];
    for (var i = 0; i < apexes.length; i++) {
      final (left, right) = bases[i];
      final path = Path()
        ..moveTo(sx(apexes[i].dx), sy(apexes[i].dy))
        ..lineTo(sx(right.dx), sy(right.dy))
        ..lineTo(sx(left.dx), sy(left.dy))
        ..close();
      canvas.drawPath(path, Paint()..color = ridgeColors[i]);
    }
  }

  @override
  bool shouldRepaint(covariant _MiningLandscapePainter oldDelegate) =>
      oldDelegate.kind != kind;
}
