import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class SafetyNote extends StatelessWidget {
  const SafetyNote({
    super.key,
    this.icon,
    this.iconWidget,
    required this.message,
  }) : assert(icon != null || iconWidget != null);
  final IconData? icon;
  final Widget? iconWidget;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: context.palette.noteBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.palette.noteBorder),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        iconWidget ?? Icon(icon!, size: 24, color: const Color(0xFFB96829)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: context.palette.textLo,
              fontSize: 12,
              height: 15 / 12,
            ),
          ),
        ),
      ],
    ),
  );
}
