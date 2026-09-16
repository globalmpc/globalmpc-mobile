import 'package:flutter/material.dart';

import '../../features/settings/language_sheet.dart';
import '../localization/locale_controller.dart';
import '../theme/app_colors.dart';

class LanguageSelectorPill extends StatelessWidget {
  const LanguageSelectorPill({super.key, this.outlined = false});

  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final language = LocaleControllerScope.of(context).language;
    final fg = outlined ? Colors.white : AppColors.darkBg;

    return Semantics(
      label: 'Language',
      value: language.englishName,
      button: true,
      child: InkWell(
        onTap: () => LanguageSheet.show(context),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 28,
          padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : AppColors.gold,
            border: outlined
                ? Border.all(color: Colors.white.withValues(alpha: 0.3))
                : null,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                language.shortCode,
                style: TextStyle(
                  color: fg,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}
