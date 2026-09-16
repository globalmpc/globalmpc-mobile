import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';

const _lightSheetBg = Color(0xFFF8F5F1);
const _radioBorder = Color(0xFFD7CEC6);
const _checkColor = Color(0xFFB96829);

class ThemeSheet {
  const ThemeSheet._();

  static const _options = <(ThemeMode, String)>[
    (ThemeMode.light, 'theme.light'),
    (ThemeMode.dark, 'theme.dark'),
    (ThemeMode.system, 'theme.system'),
  ];

  static Future<void> show(BuildContext context) {
    final current = context.read<ThemeController>().mode;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? _lightSheetBg : context.palette.surfaceHi,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ThemeSheetContent(initial: current),
    );
  }
}

class _ThemeSheetContent extends StatefulWidget {
  const _ThemeSheetContent({required this.initial});
  final ThemeMode initial;

  @override
  State<_ThemeSheetContent> createState() => _ThemeSheetContentState();
}

class _ThemeSheetContentState extends State<_ThemeSheetContent> {
  late ThemeMode _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SvgPicture.asset(
                'assets/icons/wallet/sheet-handle.svg',
                width: 50,
                height: 5,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('settings.appearance'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 24 / 20,
                color: p.textHi,
              ),
            ),
            const SizedBox(height: 8),
            for (final (mode, key) in ThemeSheet._options)
              _ThemeTile(
                label: context.tr(key),
                selected: _selected == mode,
                onTap: () => setState(() => _selected = mode),
              ),
            const SizedBox(height: 40),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.lightTextHi,
                padding: const EdgeInsets.fromLTRB(10, 16, 10, 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await context.read<ThemeController>().setMode(_selected);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(
                context.tr('theme.apply'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 16 / 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 17 / 14,
                  color: p.textHi,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.gold : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _radioBorder),
              ),
              child: selected
                  ? SvgPicture.asset(
                      'assets/icons/wallet/check.svg',
                      width: 12,
                      height: 12,
                      colorFilter: const ColorFilter.mode(
                        _checkColor,
                        BlendMode.srcIn,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
