import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass_card.dart';
import '../registry_provider.dart';

/// Dashboard entry for the public registry feed. Shows the anchor count and
/// the latest anchor date when connected, and says plainly when this build
/// has no anchor to read.
class DashboardRegistryCard extends StatelessWidget {
  const DashboardRegistryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final registry = context.watch<RegistryProvider>();
    final p = context.palette;
    final state = registry.state;

    Widget detail;
    if (!registry.isConnected) {
      detail = _Detail(context.tr('registry.notConnected.body'));
    } else if (state.isError) {
      detail = _Detail(context.tr('registry.unavailable.body'));
    } else if (state.isSuccess) {
      final feed = state.data!;
      detail = feed.isEmpty
          ? _Detail(context.tr('registry.empty.body'))
          : _Detail(
              '${context.tr('registry.count').replaceFirst('{count}', Fmt.grouped(feed.batchCount))}'
              ' · '
              '${context.tr('registry.latest').replaceFirst('{date}', Fmt.date(feed.latest.first.submittedAt.toLocal()))}',
              emphasis: true,
            );
    } else {
      detail = Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: p.textLo),
          ),
        ],
      );
    }

    return GlassCard(
      borderColor: p.cardBorder,
      onTap: registry.isConnected ? () => context.push('/registry') : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.pillAmberBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SvgPicture.asset(
              'assets/icons/verification/independent_report.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                AppColors.copper,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('registry.card.title'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 17 / 14,
                    color: p.textHi,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('registry.card.body'),
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: p.textLo,
                  ),
                ),
                const SizedBox(height: 8),
                detail,
              ],
            ),
          ),
          if (registry.isConnected) ...[
            const SizedBox(width: 8),
            SvgPicture.asset(
              'assets/icons/wallet/arrow-right.svg',
              width: 16,
              height: 16,
            ),
          ],
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.text, {this.emphasis = false});

  final String text;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        height: 15 / 12,
        fontWeight: emphasis ? FontWeight.w600 : FontWeight.w400,
        color: emphasis ? AppColors.copper : p.textLo,
      ),
    );
  }
}
