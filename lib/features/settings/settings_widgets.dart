import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SettingsAppBar({
    super.key,
    required this.title,
    this.fallbackRoute = '/settings',
    this.actions,
    this.backgroundColor,
  });

  final String title;
  final String fallbackRoute;
  final List<Widget>? actions;
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppBar(
      backgroundColor: backgroundColor ?? p.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      leadingWidth: 56,
      leading: GestureDetector(
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(fallbackRoute);
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: SvgPicture.asset(
            'assets/icons/wallet/back-arrow-circle.svg',
            width: 28,
            height: 28,
          ),
        ),
      ),
      centerTitle: true,
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 22 / 18,
          color: Theme.of(context).brightness == Brightness.light
              ? const Color(0xFF181310)
              : p.textHi,
        ),
      ),
      actions: actions,
    );
  }
}

class SimpleSettingsPage extends StatelessWidget {
  const SimpleSettingsPage({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.palette.bg,
    appBar: SettingsAppBar(title: title),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: children,
    ),
  );
}

class SettingsLabel extends StatelessWidget {
  const SettingsLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.lightSectionLabel,
      ),
    ),
  );
}

Color settingsCardBorder(BuildContext context, Color lightColor) =>
    Theme.of(context).brightness == Brightness.dark
    ? Colors.transparent
    : lightColor;

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.children,
    this.borderColor = const Color(0xFFF1EBE5),
  });
  final List<Widget> children;

  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(Container(height: 1, color: p.cardDivider));
      }
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: settingsCardBorder(context, borderColor)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.label,
    this.onTap,
    this.value,
    this.trailing,
  });

  final String label;
  final String? value;

  /// Null renders a plain informational row with no tap affordance.
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: p.textHi,
                ),
              ),
            ),
            if (value != null) ...[
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.55,
                ),
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, color: p.textLo),
                ),
              ),
              const SizedBox(width: 4),
            ],
            trailing ??
                SvgPicture.asset(
                  'assets/icons/wallet/arrow-right.svg',
                  width: 16,
                  height: 16,
                ),
          ],
        ),
      ),
    );
  }
}

class NotificationToggleCard extends StatelessWidget {
  const NotificationToggleCard({
    super.key,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(
          color: settingsCardBorder(context, const Color(0xFFF1EBE5)),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: p.textHi,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(fontSize: 11, color: p.textLo),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 28,
              padding: const EdgeInsets.all(4),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: value ? const Color(0xFFFFD077) : p.border,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SixBoxPinInput extends StatelessWidget {
  const SixBoxPinInput({
    super.key,
    required this.controller,
    required this.focusNode,
    this.error,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 50,
      child: Stack(
        children: [
          ListenableBuilder(
            listenable: controller,
            builder: (_, __) => Row(
              children: List.generate(6, (i) {
                final filled = i < controller.text.length;
                return Container(
                  width: 42,
                  height: 50,
                  margin: EdgeInsets.only(right: i < 5 ? 13 : 0),
                  decoration: BoxDecoration(
                    color: isDark ? p.bg : const Color(0xFFFFFDF9),
                    border: Border.all(
                      color: error != null
                          ? AppColors.danger
                          : (isDark ? p.border : const Color(0xFFE7E0D9)),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: filled
                      ? Center(
                          child: SvgPicture.asset(
                            'assets/icons/wallet/pin-asterisk.svg',
                            width: 10,
                            height: 10,
                            colorFilter: ColorFilter.mode(
                              p.textHi,
                              BlendMode.srcIn,
                            ),
                          ),
                        )
                      : null,
                );
              }),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.01,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PinField extends StatelessWidget {
  const PinField({
    super.key,
    required this.controller,
    required this.label,
    this.error,
  });

  final TextEditingController controller;
  final String label;
  final String? error;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: true,
    maxLength: 6,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(
      labelText: label,
      counterText: '',
      errorText: error,
    ),
  );
}
