import 'package:flutter/material.dart';
import 'package:mpc_mining_app/core/theme/app_icons.dart';

import '../../core/localization/app_strings.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';

/// Bottom-sheet language picker. Selecting a language updates the controller,
/// which rebuilds the app in the new locale and persists the choice.
class LanguageSheet {
  const LanguageSheet._();

  static Future<void> show(BuildContext context) {
    final p = context.palette;
    return showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final controller = LocaleControllerScope.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    sheetContext.tr('settings.language'),
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                for (final lang in AppLanguage.values)
                  _LanguageTile(
                    language: lang,
                    selected: controller.language == lang,
                    onTap: () async {
                      await controller.setLanguage(lang);
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
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
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(
        language.nativeName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(language.englishName, style: TextStyle(color: p.textLo)),
      trailing: selected
          ? Icon(AppIcons.check_circle, color: p.primary)
          : Icon(AppIcons.circle_outlined, color: p.border),
    );
  }
}
