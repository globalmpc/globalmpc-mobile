import 'package:flutter/foundation.dart';

enum NotificationCategory { transaction, security, project }

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.category,
    required this.titleKey,
    required this.bodyKey,
    required this.createdAt,
    this.args = const {},
  });

  final String id;
  final NotificationCategory category;
  final String titleKey;
  final String bodyKey;
  final DateTime createdAt;
  final Map<String, String> args;

  String fill(String template) => args.entries.fold(
    template,
    (text, entry) => text.replaceAll('{${entry.key}}', entry.value),
  );

  Map<String, Object> toJson() => {
    'id': id,
    'category': category.name,
    'titleKey': titleKey,
    'bodyKey': bodyKey,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'args': args,
  };

  static AppNotification? fromJson(Object? json) {
    if (json is! Map) return null;
    final category = NotificationCategory.values.asNameMap()[json['category']];
    final id = json['id'];
    final titleKey = json['titleKey'];
    final bodyKey = json['bodyKey'];
    final createdAt = json['createdAt'];
    final args = json['args'];
    if (category == null ||
        id is! String ||
        titleKey is! String ||
        bodyKey is! String ||
        createdAt is! int) {
      return null;
    }
    return AppNotification(
      id: id,
      category: category,
      titleKey: titleKey,
      bodyKey: bodyKey,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      args: args is Map
          ? {for (final entry in args.entries) '${entry.key}': '${entry.value}'}
          : const {},
    );
  }
}
