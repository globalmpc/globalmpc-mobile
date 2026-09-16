import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/notifications/app_notification.dart';
import '../../core/notifications/notification_center.dart';
import '../../core/theme/app_colors.dart';

enum _NotificationFilter { all, projects, security }

const _copper = Color(0xFFC96B28);
const _markAllReadColor = Color(0xFFC2773F);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _NotificationFilter _filter = _NotificationFilter.all;

  bool _matchesFilter(AppNotification notification) => switch (_filter) {
    _NotificationFilter.all => true,
    _NotificationFilter.projects =>
      notification.category == NotificationCategory.project,
    _NotificationFilter.security =>
      notification.category == NotificationCategory.security,
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: NotificationCenter.instance,
          builder: (context, _) {
            final inbox = NotificationCenter.instance.inbox;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _NotificationsHeader(),
                ),
                if (inbox.isEmpty)
                  const Expanded(child: _EmptyInbox())
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _NotificationFilterChips(
                      selected: _filter,
                      onSelect: (filter) => setState(() => _filter = filter),
                    ),
                  ),
                  Expanded(child: _notificationList(context, inbox)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  static String _relativeDay(
    BuildContext context,
    DateTime createdAt,
    DateTime now,
  ) {
    final days = DateUtils.dateOnly(
      now,
    ).difference(DateUtils.dateOnly(createdAt)).inDays;
    return switch (days) {
      <= 0 => context.tr('notif.today'),
      1 => context.tr('notif.yesterday'),
      _ => context.tr('notif.daysAgo').replaceFirst('{count}', '$days'),
    };
  }

  Widget _notificationList(BuildContext context, List<AppNotification> inbox) {
    final center = NotificationCenter.instance;
    final visible = inbox.where(_matchesFilter).toList();
    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
        child: Text(
          context.tr('notif.filterEmpty'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: context.palette.textLo),
        ),
      );
    }
    final now = DateTime.now();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, index) {
        final notification = visible[index];
        return _NotificationCard(
          category: notification.category,
          title: notification.fill(context.tr(notification.titleKey)),
          body: notification.fill(context.tr(notification.bodyKey)),
          time: _relativeDay(context, notification.createdAt, now),
          unread: center.isUnread(notification),
        );
      },
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 32),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/notifications/inbox.svg',
              width: 40,
              height: 40,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('notif.empty.title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 22 / 18,
                color: p.textHi,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('notif.empty.body'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 16 / 13, color: p.textLo),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 28,
                height: 28,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: p.circleButtonBg,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  'assets/icons/auth/line-arrow-left.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(p.textHi, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          Text(
            context.tr('notif.title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 22 / 18,
              color: p.textHi,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: NotificationCenter.instance.markAllRead,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  context.tr('notif.markAllRead'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 13 / 11,
                    color: _markAllReadColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationFilterChips extends StatelessWidget {
  const _NotificationFilterChips({
    required this.selected,
    required this.onSelect,
  });

  final _NotificationFilter selected;
  final ValueChanged<_NotificationFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const chips = [
      (_NotificationFilter.all, 'notif.filter.all'),
      (_NotificationFilter.projects, 'notif.filter.projects'),
      (_NotificationFilter.security, 'notif.filter.security'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (filter, labelKey) in chips)
          GestureDetector(
            onTap: () => onSelect(filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected == filter ? p.pillAmberBg : p.surfaceHi,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                context.tr(labelKey),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected == filter ? _copper : p.textLo,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.category,
    required this.title,
    required this.body,
    required this.time,
    required this.unread,
  });

  final NotificationCategory category;
  final String title;
  final String body;
  final String time;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (iconAsset, iconSize) = switch (category) {
      NotificationCategory.project => (
        'assets/icons/notifications/project.svg',
        20.0,
      ),
      NotificationCategory.transaction => (
        'assets/icons/notifications/token.svg',
        24.0,
      ),
      NotificationCategory.security => (
        'assets/icons/notifications/shield.svg',
        24.0,
      ),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.cardBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: SvgPicture.asset(
                iconAsset,
                width: iconSize,
                height: iconSize,
                colorFilter: ColorFilter.mode(p.textLo, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: p.textHi,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (unread) ...[
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: const BoxDecoration(
                          color: _copper,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(time, style: TextStyle(fontSize: 11, color: p.textLo)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(fontSize: 13, height: 1.35, color: p.textLo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
