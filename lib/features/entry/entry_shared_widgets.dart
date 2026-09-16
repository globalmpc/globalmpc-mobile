import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../wallet/wallet_provider.dart';

class AuthSvg extends StatelessWidget {
  const AuthSvg(this.name, {super.key, this.size = 22, this.tint});

  final String name;
  final double size;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/auth/$name.svg',
      width: size,
      height: size,
      colorFilter: tint == null
          ? null
          : ColorFilter.mode(tint!, BlendMode.srcIn),
    );
  }
}

InputDecoration outlinedFieldDecoration(
  BuildContext context, {
  String? hintText,
  String? errorText,
}) {
  final p = context.palette;
  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hintText,
    errorText: errorText,
    filled: true,
    fillColor: p.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    enabledBorder: border(p.border),
    focusedBorder: border(AppColors.gold, 1.5),
    errorBorder: border(AppColors.danger),
    focusedErrorBorder: border(AppColors.danger, 1.5),
  );
}

class FlowBackButton extends StatelessWidget {
  const FlowBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,

      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: Material(
            color: p.surfaceHi,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: AuthSvg('line-arrow-left', size: 20, tint: p.textHi),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void openWallet(BuildContext context) {
  context.read<WalletProvider?>()?.load();
  context.go('/wallet');
}

class Progress extends StatelessWidget {
  const Progress({super.key, required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: List.generate(
        total,
        (index) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 4,
            margin: EdgeInsets.only(right: index == total - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: index <= current ? AppColors.gold : p.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

class SafetyRow extends StatelessWidget {
  const SafetyRow({
    super.key,
    this.icon,
    this.asset,
    required this.title,
    required this.body,
  }) : assert(icon != null || asset != null);

  final IconData? icon;

  final String? asset;

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.copper.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: asset != null
              ? AuthSvg(asset!, size: 22)
              : Icon(icon, color: AppColors.gold, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(body, style: TextStyle(color: p.textLo, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class GoldPill extends StatelessWidget {
  const GoldPill(
    this.label, {
    super.key,
    this.onTap,
    this.textColor = AppColors.copper,
    this.backgroundColor,
  });

  final String label;
  final VoidCallback? onTap;
  final Color textColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
    if (onTap == null) return pill;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: pill,
    );
  }
}

class PinBox extends StatelessWidget {
  const PinBox({
    super.key,
    this.char,
    required this.active,
    required this.error,
  });

  final String? char;
  final bool active;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final borderColor = error
        ? AppColors.danger
        : active
        ? AppColors.gold
        : p.border;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 44,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(
          color: borderColor,
          width: active || error ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        char ?? '',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: error ? AppColors.danger : p.textHi,
        ),
      ),
    );
  }
}

class SuccessCheck extends StatelessWidget {
  const SuccessCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.positive.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.positive,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
      ),
    );
  }
}
