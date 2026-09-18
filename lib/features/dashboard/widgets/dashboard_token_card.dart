import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/constants/mpc_facts.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/glass_card.dart';

class DashboardTokenHeroCard extends StatelessWidget {
  const DashboardTokenHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final chain = AppEnvironment.current.chain;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: p.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Pill(
                '◇ ${context.tr('dash.utilityToken')}',
                color: p.pillNeutralText,
                backgroundColor: p.pillNeutralBg,
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                fontSize: 10,
              ),
              Pill(
                chain.networkShort,
                color: AppColors.info,
                backgroundColor: p.pillInfoBg,
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                fontSize: 10,
              ),
              Pill(
                context.tr('facts.plannedStandard'),
                color: AppColors.copper,
                backgroundColor: p.pillAmberBg,
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                fontSize: 10,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.tr(MpcFacts.taglineKey),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 17 / 12,
              color: p.textLo,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              DashboardMetric(
                label: context.tr('dash.totalSupply'),
                value: Fmt.compact(MpcFacts.totalSupply),
              ),
              _divider(p),
              DashboardMetric(
                label: context.tr('dash.network'),
                value: chain.networkShort,
              ),
              _divider(p),
              DashboardMetric(
                label: context.tr('dash.listing'),
                value: context.tr('common.pending'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: p.insetBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DashboardMetaRow(
              iconAsset: 'assets/icons/dashboard/building.svg',
              label: context.tr('dash.issuer'),
              value: MpcFacts.issuer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(AppPalette p) => Container(
    width: 1,
    height: 32,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: p.border,
  );
}

class DashboardMetaRow extends StatelessWidget {
  const DashboardMetaRow({
    super.key,
    this.icon,
    this.iconAsset,
    required this.label,
    required this.value,
    this.mono = false,
  }) : assert(
         (icon != null) ^ (iconAsset != null),
         'Provide either icon or iconAsset',
       );

  final IconData? icon;
  final String? iconAsset;
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null)
            Icon(icon, size: 14, color: p.textLo)
          else
            SvgPicture.asset(iconAsset!, width: 14, height: 14),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(color: p.textLo, fontSize: 11, height: 13 / 11),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: p.textHi,
                fontSize: 11,
                height: 13 / 11,
                fontWeight: FontWeight.w600,
                fontFamily: mono ? AppTheme.monoFont : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardMetric extends StatelessWidget {
  const DashboardMetric({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: p.textHi,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 17 / 14,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(color: p.textLo, fontSize: 10, height: 12 / 10),
          ),
        ],
      ),
    );
  }
}
