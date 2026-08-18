import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpc_mining_app/core/theme/app_icons.dart';

import '../localization/locale_controller.dart';
import '../theme/app_colors.dart';

/// Small, reusable presentational pieces shared across features.

class MpcBackButton extends StatelessWidget {
  const MpcBackButton({super.key, this.fallbackRoute, this.onPressedOverride});

  final String? fallbackRoute;
  final VoidCallback? onPressedOverride;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (onPressedOverride != null) {
          onPressedOverride!();
          return;
        }
        if (context.canPop()) {
          context.pop();
        } else if (fallbackRoute != null) {
          context.go(fallbackRoute!);
        }
      },
      icon: const Icon(AppIcons.back, size: 20),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              letterSpacing: -0.2,
              height: 1.2,
            ),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.color, this.icon});

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = color ?? p.textLo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: c),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Labelled progress line used for the four-layer readiness bars.
class LabeledProgress extends StatelessWidget {
  const LabeledProgress({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
    this.color,
  });

  final String label;
  final double value; // 0..1
  final String? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = color ?? p.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: p.textLo, fontSize: 13),
              ),
            ),
            Text(
              trailing ?? '${(value * 100).round()}%',
              style: TextStyle(
                color: p.textHi,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 6,
            backgroundColor: p.border,
            valueColor: AlwaysStoppedAnimation(c),
          ),
        ),
      ],
    );
  }
}

class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: p.textLo),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textLo),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(AppIcons.refresh, size: 18),
                label: Text(context.tr('common.retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
