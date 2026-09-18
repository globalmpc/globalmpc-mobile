import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mpc_mining_app/core/theme/app_icons.dart';

import '../localization/locale_controller.dart';
import '../theme/app_colors.dart';

class MpcBackButton extends StatelessWidget {
  const MpcBackButton({
    super.key,
    this.fallbackRoute,
    this.onPressedOverride,
    this.iconAsset,
    this.iconSize = 18,
  });

  final String? fallbackRoute;
  final VoidCallback? onPressedOverride;

  final String? iconAsset;
  final double iconSize;

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
      icon: iconAsset == null
          ? const Icon(AppIcons.back, size: 20)
          : SvgPicture.asset(iconAsset!, width: iconSize, height: iconSize),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.fontSize = 17});

  final String title;
  final Widget? action;

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
              letterSpacing: -0.2,
              height: fontSize == 18 ? 22 / 18 : 21 / 17,
            ),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(
    this.label, {
    super.key,
    this.color,
    this.icon,
    this.backgroundColor,
    this.padding,
    this.fontSize = 11,
  });

  final String label;
  final Color? color;
  final IconData? icon;

  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = color ?? p.textLo;
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor ?? c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: c),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LabeledProgress extends StatelessWidget {
  const LabeledProgress({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
    this.color,
  });

  final String label;
  final double value;
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
    this.iconWidget,
    this.contentWidth,
  });

  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final Widget? iconWidget;
  final double? contentWidth;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final textColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
      ],
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget ?? Icon(icon, size: 40, color: p.textLo),
            const SizedBox(height: 12),
            contentWidth == null
                ? textColumn
                : SizedBox(width: contentWidth, child: textColumn),
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
