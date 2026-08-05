import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        leading: const MpcBackButton(),
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Updates about your wallet, projects and MPC.',
            style: TextStyle(color: p.textLo),
          ),
          const SizedBox(height: 20),
          const _NotificationCard(
            icon: Icons.landscape_outlined,
            title: 'Project update',
            body: 'Tsagaan Tolgoi Strategic Minerals remains in discussion.',
            time: 'Today',
            unread: true,
          ),
          const SizedBox(height: 12),
          const _NotificationCard(
            icon: Icons.verified_outlined,
            title: 'MPC token status',
            body: 'The token listing is still pending. No action is required.',
            time: '2 days ago',
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    this.unread = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final String time;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.copper),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (unread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(body, style: TextStyle(color: p.textLo, height: 1.4)),
                const SizedBox(height: 8),
                Text(time, style: TextStyle(color: p.textLo, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
