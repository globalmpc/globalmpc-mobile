import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/wallet_models.dart';
import '../utils/formatters.dart';
import 'app_notification.dart';

class NotificationCenter extends ChangeNotifier {
  NotificationCenter._({DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  static final NotificationCenter instance = NotificationCenter._();

  @visibleForTesting
  static NotificationCenter forTesting({DateTime Function()? clock}) =>
      NotificationCenter._(clock: clock);

  static const _inboxPref = 'notifications_inbox_v1';
  static const _transactionsEnabledPref =
      'notifications_transactions_enabled_v1';
  static const _securityEnabledPref = 'notifications_security_enabled_v1';
  static const _projectsEnabledPref = 'notifications_projects_enabled_v1';
  static const _lastReadAtPref = 'notifications_last_read_at_v1';
  static const _permissionAskedPref = 'notifications_permission_asked_v1';
  static const _seenTransactionsPrefix = 'notifications_seen_transactions_v1_';

  static const int maxStored = 50;

  final DateTime Function() _now;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  SharedPreferences? _prefs;
  String Function(String key) _translate = _identity;
  bool _pluginReady = false;
  List<AppNotification> _inbox = const [];
  DateTime? _lastReadAt;

  static String _identity(String key) => key;

  List<AppNotification> get inbox => _inbox;

  bool isUnread(AppNotification notification) {
    final lastReadAt = _lastReadAt;
    return lastReadAt == null || notification.createdAt.isAfter(lastReadAt);
  }

  int get unreadCount => _inbox.where(isUnread).length;

  Future<void> markAllRead() async {
    final prefs = _prefs;
    if (prefs == null || unreadCount == 0) return;
    final readAt = _now();
    _lastReadAt = readAt;
    await prefs.setInt(_lastReadAtPref, readAt.millisecondsSinceEpoch);
    notifyListeners();
  }

  Future<void> start({
    required SharedPreferences prefs,
    required String Function(String key) translate,
    bool usePlatformNotifications = true,
  }) async {
    _prefs = prefs;
    _translate = translate;
    _inbox = _readInbox(prefs);
    final lastReadAt = prefs.getInt(_lastReadAtPref);
    _lastReadAt = lastReadAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(lastReadAt);
    notifyListeners();
    if (!usePlatformNotifications) return;
    try {
      _pluginReady =
          await _plugin.initialize(
            const InitializationSettings(
              android: AndroidInitializationSettings('@mipmap/ic_launcher'),
              iOS: DarwinInitializationSettings(
                requestAlertPermission: false,
                requestBadgePermission: false,
                requestSoundPermission: false,
              ),
            ),
          ) ??
          false;
    } on MissingPluginException {
      _pluginReady = false;
    } on PlatformException {
      _pluginReady = false;
    }
  }

  static String _enabledPref(NotificationCategory category) =>
      switch (category) {
        NotificationCategory.transaction => _transactionsEnabledPref,
        NotificationCategory.security => _securityEnabledPref,
        NotificationCategory.project => _projectsEnabledPref,
      };

  bool isEnabled(NotificationCategory category) =>
      _prefs?.getBool(_enabledPref(category)) ?? true;

  Future<void> setEnabled(NotificationCategory category, bool enabled) async {
    final prefs = _prefs;
    final key = _enabledPref(category);
    if (prefs == null) return;
    await prefs.setBool(key, enabled);
    notifyListeners();
    if (enabled) await requestPermission();
  }

  Future<bool> requestPermission() async {
    if (!_pluginReady) return false;
    await _prefs?.setBool(_permissionAskedPref, true);
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> notifySecurity(String titleKey, String bodyKey) => notify(
    category: NotificationCategory.security,
    titleKey: titleKey,
    bodyKey: bodyKey,
  );

  Future<void> notify({
    required NotificationCategory category,
    required String titleKey,
    required String bodyKey,
    Map<String, String> args = const {},
  }) async {
    final prefs = _prefs;
    if (prefs == null || !isEnabled(category)) return;
    final createdAt = _now();
    final notification = AppNotification(
      id: '${createdAt.microsecondsSinceEpoch}',
      category: category,
      titleKey: titleKey,
      bodyKey: bodyKey,
      createdAt: createdAt,
      args: args,
    );
    _inbox = [notification, ..._inbox].take(maxStored).toList(growable: false);
    await prefs.setString(
      _inboxPref,
      jsonEncode([for (final item in _inbox) item.toJson()]),
    );
    notifyListeners();
    await _showOnDevice(notification);
  }

  Future<void> reviewTransactions(WalletAccount wallet) async {
    final prefs = _prefs;
    if (prefs == null || wallet.isDemo) return;
    final key = '$_seenTransactionsPrefix${wallet.address.toLowerCase()}';
    final previous = _readSeen(prefs.getString(key));
    await prefs.setString(
      key,
      jsonEncode({
        for (final tx in wallet.transactions) tx.hash: tx.status.name,
      }),
    );
    if (previous == null) return;
    for (final tx in wallet.transactions) {
      final before = previous[tx.hash];
      if (before == tx.status.name) continue;
      final event = _transactionEvent(tx, isNew: before == null);
      if (event == null) continue;
      await notify(
        category: NotificationCategory.transaction,
        titleKey: event.titleKey,
        bodyKey: event.bodyKey,
        args: {'amount': Fmt.token(tx.amount)},
      );
    }
  }

  static ({String titleKey, String bodyKey})? _transactionEvent(
    WalletTransaction tx, {
    required bool isNew,
  }) {
    if (tx.status == TxStatus.failed) {
      if (tx.isIncoming) return null;
      return (
        titleKey: 'notif.tx.failed.title',
        bodyKey: 'notif.tx.failed.body',
      );
    }
    final confirmed = tx.status == TxStatus.confirmed;
    if (tx.isIncoming) {
      if (confirmed) {
        return (
          titleKey: 'notif.tx.received.title',
          bodyKey: 'notif.tx.received.body',
        );
      }
      if (!isNew) return null;
      return (
        titleKey: 'notif.tx.incoming.title',
        bodyKey: 'notif.tx.incoming.body',
      );
    }
    if (!confirmed) return null;
    return (titleKey: 'notif.tx.sent.title', bodyKey: 'notif.tx.sent.body');
  }

  static Map<String, String>? _readSeen(String? raw) {
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return {
        for (final entry in decoded.entries) '${entry.key}': '${entry.value}',
      };
    } on FormatException {
      return null;
    }
  }

  static List<AppNotification> _readInbox(SharedPreferences prefs) {
    final raw = prefs.getString(_inboxPref);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map(AppNotification.fromJson)
          .whereType<AppNotification>()
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  Future<void> _showOnDevice(AppNotification notification) async {
    if (!_pluginReady) return;
    final prefs = _prefs;
    try {
      if (prefs != null && !(prefs.getBool(_permissionAskedPref) ?? false)) {
        await requestPermission();
      }
      final channel = switch (notification.category) {
        NotificationCategory.transaction => (
          'transactions',
          'settings.notify.transactions',
        ),
        NotificationCategory.security => (
          'security',
          'settings.notify.security',
        ),
        NotificationCategory.project => (
          'projects',
          'settings.notify.projects',
        ),
      };
      await _plugin.show(
        notification.createdAt.millisecondsSinceEpoch.remainder(0x7fffffff),
        notification.fill(_translate(notification.titleKey)),
        notification.fill(_translate(notification.bodyKey)),
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.$1,
            _translate(channel.$2),
            importance: Importance.high,
            priority: Priority.high,
            visibility: NotificationVisibility.private,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentList: true,
            presentSound: true,
          ),
        ),
      );
    } on PlatformException {
      return;
    }
  }
}
