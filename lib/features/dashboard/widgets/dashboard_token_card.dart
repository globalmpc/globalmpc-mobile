import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/mpc_facts.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/glass_card.dart';
import '../../web/web_view_screen.dart';

class DashboardTokenHeroCard extends StatelessWidget {
  const DashboardTokenHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: p.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pill(
                '◇ ${context.tr('dash.utilityToken')}',
                color: p.pillNeutralText,
                backgroundColor: p.pillNeutralBg,
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                fontSize: 10,
              ),
              const SizedBox(width: 6),
              Pill(
                MpcFacts.networkShort,
                color: AppColors.info,
                backgroundColor: p.pillInfoBg,
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                fontSize: 10,
              ),
              const SizedBox(width: 6),
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
                value: MpcFacts.networkShort,
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
            child: Column(
              children: [
                DashboardMetaRow(
                  icon: AppIcons.tag,
                  label: context.tr('dash.contract'),
                  value: Fmt.shortAddress(
                    MpcFacts.contractAddress,
                    lead: 6,
                    tail: 6,
                  ),
                  mono: true,
                  onCopy: () async {
                    await Clipboard.setData(
                      const ClipboardData(text: MpcFacts.contractAddress),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(context.tr('wallet.addressCopied')),
                          ),
                        );
                    }
                  },
                  onOpen: () => context.push(
                    '/webview',
                    extra: WebViewArgs(
                      url: MpcFacts.explorerTokenUrl,
                      title: MpcFacts.networkShort,
                    ),
                  ),
                ),
                Divider(color: p.insetDivider, height: 1),
                DashboardMetaRow(
                  iconAsset: 'assets/icons/dashboard/building.svg',
                  label: context.tr('dash.issuer'),
                  value: MpcFacts.issuer,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () => context.push(
                '/webview',
                extra: WebViewArgs(
                  url: MpcFacts.explorerTokenUrl,
                  title: MpcFacts.networkShort,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: p.textHi,
                side: const BorderSide(color: AppColors.amber),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/dashboard/external-link.svg',
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.tr('dash.explorer'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 15 / 12,
                      color: p.textHi,
                    ),
                  ),
                ],
              ),
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
    this.onCopy,
    this.onOpen,
  }) : assert(
         (icon != null) ^ (iconAsset != null),
         'Provide either icon or iconAsset',
       );

  final IconData? icon;
  final String? iconAsset;
  final String label;
  final String value;
  final bool mono;
  final VoidCallback? onCopy;
  final VoidCallback? onOpen;

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
          if (onCopy != null)
            DashboardMiniIconButton(
              svgAsset: 'assets/icons/dashboard/copy.svg',
              onTap: onCopy!,
            ),
          if (onOpen != null)
            DashboardMiniIconButton(
              svgAsset: 'assets/icons/dashboard/external-link.svg',
              onTap: onOpen!,
            ),
        ],
      ),
    );
  }
}

class DashboardMiniIconButton extends StatelessWidget {
  const DashboardMiniIconButton({
    super.key,
    required this.svgAsset,
    required this.onTap,
  });
  final String svgAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
        child: SvgPicture.asset(svgAsset, width: 14, height: 14),
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
