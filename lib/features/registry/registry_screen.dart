import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/services/registry_anchor_service.dart';
import '../settings/settings_widgets.dart';
import '../web/web_view_screen.dart';
import 'registry_provider.dart';

/// Lists the batches the registry has anchored on chain, newest first. Every
/// value on this screen is read from the anchor contract; nothing is
/// interpreted or summarised on the app's behalf.
class RegistryScreen extends StatelessWidget {
  const RegistryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final registry = context.watch<RegistryProvider>();
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: SettingsAppBar(
        title: context.tr('registry.title'),
        fallbackRoute: '/',
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: registry.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                context.tr('registry.subtitle'),
                style: TextStyle(fontSize: 13, color: p.textLo, height: 1.4),
              ),
              const SizedBox(height: 16),
              ..._body(context, registry),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, RegistryProvider registry) {
    if (!registry.isConnected) {
      return [
        GlassCard(
          child: StateMessage(
            icon: AppIcons.cloud_off_outlined,
            title: context.tr('registry.notConnected.title'),
            message: context.tr('registry.notConnected.body'),
          ),
        ),
      ];
    }
    final state = registry.state;
    if (state.isError) {
      return [
        GlassCard(
          child: StateMessage(
            icon: AppIcons.error_outline,
            title: context.tr('registry.unavailable.title'),
            message: context.tr('registry.unavailable.body'),
            onRetry: registry.load,
          ),
        ),
      ];
    }
    if (!state.isSuccess) {
      return const [
        SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ];
    }
    final feed = state.data!;
    if (feed.isEmpty) {
      return [
        GlassCard(
          child: StateMessage(
            icon: AppIcons.inbox_outlined,
            title: context.tr('registry.empty.title'),
            message: context.tr('registry.empty.body'),
          ),
        ),
      ];
    }
    return [
      _FeedHeader(feed: feed, explorerUrl: registry.explorerUrl),
      const SizedBox(height: 16),
      for (final batch in feed.latest) ...[
        _BatchCard(batch: batch),
        const SizedBox(height: 12),
      ],
    ];
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({required this.feed, required this.explorerUrl});

  final RegistryFeed feed;
  final String? explorerUrl;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final latest = feed.latest.first.submittedAt.toLocal();
    return GlassCard(
      accent: AppColors.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context
                .tr('registry.count')
                .replaceFirst('{count}', Fmt.grouped(feed.batchCount)),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: p.textHi,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context
                .tr('registry.latest')
                .replaceFirst('{date}', Fmt.dateTime(latest)),
            style: TextStyle(fontSize: 12, color: p.textLo),
          ),
          if (explorerUrl != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () => context.push(
                  '/webview',
                  extra: WebViewArgs(
                    url: explorerUrl!,
                    title: context.tr('registry.viewContract'),
                  ),
                ),
                icon: const Icon(AppIcons.open_in_new, size: 16),
                label: Text(
                  context.tr('registry.viewContract'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.textHi,
                  side: const BorderSide(color: AppColors.amber),
                  minimumSize: Size.zero,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  const _BatchCard({required this.batch});

  final RegistryBatch batch;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (statusKey, statusColor) = switch (batch.status) {
      RegistryBatchStatus.active => (
        'registry.status.active',
        AppColors.positive,
      ),
      RegistryBatchStatus.revoked => (
        'registry.status.revoked',
        AppColors.danger,
      ),
      RegistryBatchStatus.superseded => (
        'registry.status.superseded',
        AppColors.warning,
      ),
    };
    final labelStyle = TextStyle(fontSize: 12, color: p.textLo);
    final valueStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: p.textHi,
    );

    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(flex: 2, child: Text(label, style: labelStyle)),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: value),
        ],
      ),
    );

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(context.tr('registry.batch'), style: labelStyle),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Fmt.shortAddress(batch.batchId, lead: 10, tail: 6),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: valueStyle.copyWith(fontFamily: AppTheme.monoFont),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: Pill(context.tr(statusKey), color: statusColor)),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: p.cardDivider, height: 1),
          row(
            context.tr('registry.records'),
            Text(
              Fmt.grouped(batch.recordCount),
              textAlign: TextAlign.right,
              style: valueStyle,
            ),
          ),
          row(
            context.tr('registry.anchoredAt'),
            Text(
              Fmt.dateTime(batch.submittedAt.toLocal()),
              textAlign: TextAlign.right,
              style: valueStyle,
            ),
          ),
          row(
            context.tr('registry.root'),
            _HashValue(hash: batch.root, style: valueStyle),
          ),
          row(
            context.tr('registry.manifest'),
            _HashValue(hash: batch.manifestHash, style: valueStyle),
          ),
          if (batch.supersededBy != null)
            row(
              context.tr('registry.status.superseded'),
              _HashValue(hash: batch.supersededBy!, style: valueStyle),
            ),
        ],
      ),
    );
  }
}

class _HashValue extends StatelessWidget {
  const _HashValue({required this.hash, required this.style});

  final String hash;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            Fmt.shortAddress(hash, lead: 10, tail: 6),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: style.copyWith(fontFamily: AppTheme.monoFont),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: hash));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(context.tr('registry.copied'))),
              );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(
              AppIcons.copy_rounded,
              size: 15,
              color: context.palette.textLo,
            ),
          ),
        ),
      ],
    );
  }
}
