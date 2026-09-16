import 'package:flutter/material.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/notifications/app_notification.dart';
import '../../core/notifications/notification_center.dart';
import 'settings_widgets.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final center = NotificationCenter.instance;
    return ListenableBuilder(
      listenable: center,
      builder: (context, _) => SimpleSettingsPage(
        title: context.tr('settings.notify.title'),
        children: [
          NotificationToggleCard(
            label: context.tr('settings.notify.transactions'),
            description: context.tr('settings.notify.transactionsBody'),
            value: center.isEnabled(NotificationCategory.transaction),
            onChanged: (enabled) =>
                center.setEnabled(NotificationCategory.transaction, enabled),
          ),
          const SizedBox(height: 20),
          NotificationToggleCard(
            label: context.tr('settings.notify.security'),
            description: context.tr('settings.notify.securityBody'),
            value: center.isEnabled(NotificationCategory.security),
            onChanged: (enabled) =>
                center.setEnabled(NotificationCategory.security, enabled),
          ),
          const SizedBox(height: 20),
          NotificationToggleCard(
            label: context.tr('settings.notify.projects'),
            description: context.tr('settings.notify.projectsBody'),
            value: center.isEnabled(NotificationCategory.project),
            onChanged: (enabled) =>
                center.setEnabled(NotificationCategory.project, enabled),
          ),
        ],
      ),
    );
  }
}
