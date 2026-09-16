import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/localization/locale_controller.dart';
import 'core/notifications/notification_center.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final localeController = LocaleController(prefs);
  await NotificationCenter.instance.start(
    prefs: prefs,
    translate: localeController.t,
  );

  runApp(
    MpcApp(
      localeController: localeController,
      themeController: ThemeController(prefs),
    ),
  );
}
