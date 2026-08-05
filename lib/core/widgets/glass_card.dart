import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Frosted, bordered surface used across the app. Matches Must's glassmorphism
/// language while staying cheap to render (single blur layer, optional).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.blur = false,
    this.accent,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool blur;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(16);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: blur ? 0.72 : 1),
        borderRadius: radius,
        border: Border.all(
          color: accent?.withValues(alpha: 0.45) ?? p.border,
          width: accent == null ? 0.7 : 1,
        ),
        boxShadow: accent == null
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (blur) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: content,
        ),
      );
    }

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(borderRadius: radius, onTap: onTap, child: content),
    );
  }
}
