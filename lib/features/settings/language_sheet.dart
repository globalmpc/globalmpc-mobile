import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/localization/app_strings.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';

const _lightSheetBg = Color(0xFFF8F5F1);
const _selectedColor = Color(0xFFC96B28);

class LanguageSheet {
  const LanguageSheet._();

  static Future<void> show(BuildContext context) {
    final initial = LocaleControllerScope.of(context).language;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? _lightSheetBg : context.palette.surfaceHi,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _LanguageSheetContent(initial: initial),
    );
  }
}

class _LanguageSheetContent extends StatefulWidget {
  const _LanguageSheetContent({required this.initial});
  final AppLanguage initial;

  @override
  State<_LanguageSheetContent> createState() => _LanguageSheetContentState();
}

class _LanguageSheetContentState extends State<_LanguageSheetContent> {
  late AppLanguage _selected;

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
              context.tr('lang.chooseLanguage'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 24 / 20,
                color: p.textHi,
              ),
            ),
            const SizedBox(height: 12),
            for (final lang in AppLanguage.values)
              _LanguageTile(
                language: lang,
                selected: _selected == lang,
                onTap: () => setState(() => _selected = lang),
              ),
            const SizedBox(height: 12),
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
                final controller = LocaleControllerScope.of(context);
                await controller.setLanguage(_selected);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(
                context.tr('lang.applyLanguage'),
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

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.nativeName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 17 / 14,
                      color: p.textHi,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    language.englishName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 15 / 12,
                      color: p.textLo,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Text(
                context.tr('lang.selected'),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 15 / 12,
                  color: _selectedColor,
                ),
              ),
              const SizedBox(width: 8),
              SvgPicture.asset(
                'assets/icons/wallet/check-filled.svg',
                width: 15,
                height: 12,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
