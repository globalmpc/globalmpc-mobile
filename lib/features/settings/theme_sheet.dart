import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/theme_controller.dart';

/// Bottom-sheet appearance picker: System / Light / Dark. Persists via
/// [ThemeController]; the app rebuilds with the new mode immediately.
class ThemeSheet {
  const ThemeSheet._();

  static const _options = <(ThemeMode, IconData, String)>[
    (ThemeMode.system, AppIcons.settings_outlined, 'theme.system'),
    (ThemeMode.light, Icons.wb_sunny_outlined, 'theme.light'),
    (ThemeMode.dark, Icons.dark_mode_outlined, 'theme.dark'),
  ];

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
        final controller = sheetContext.watch<ThemeController>();
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
                    sheetContext.tr('settings.appearance'),
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                for (final (mode, icon, key) in _options)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: Icon(icon, color: p.textHi),
                    title: Text(
                      sheetContext.tr(key),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: controller.mode == mode
                        ? Icon(AppIcons.check_circle, color: p.primary)
                        : Icon(AppIcons.circle_outlined, color: p.border),
                    onTap: () async {
                      await sheetContext.read<ThemeController>().setMode(mode);
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
