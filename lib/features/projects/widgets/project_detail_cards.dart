import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/mpc_facts.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/models/mining_project.dart';
import '../../web/web_view_screen.dart';

class ProjectVerificationCard extends StatelessWidget {
  const ProjectVerificationCard({super.key, required this.methods});
  final List<VerificationMethod> methods;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      cornerRadius: 18,
      child: Column(
        children: [
          for (var i = 0; i < methods.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 20,
                  child: Center(
                    child: _buildVerificationIcon(
                      methods[i].labelKey,
                      p.textLo,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        context.tr(methods[i].labelKey),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: p.textHi,
                          height: 15 / 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Pill(
                  context.tr(methods[i].status.key),
                  color: AppColors.copper,
                  backgroundColor: AppColors.goldSoft,
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  fontSize: 10,
                ),
              ],
            ),
            if (i != methods.length - 1) const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationIcon(String labelKey, Color fallbackColor) {
    return switch (labelKey) {
      'verify.jorc' => SvgPicture.asset(
        'assets/icons/verification/jorc.svg',
        width: 16,
        height: 16,
      ),
      'verify.cctv' => SvgPicture.asset(
        'assets/icons/verification/cctv.svg',
        width: 16,
        height: 16,
      ),
      'verify.cp' => SvgPicture.asset(
        'assets/icons/verification/independent_report.svg',
        width: 16,
        height: 16,
      ),
      _ => Icon(AppIcons.circle_outlined, size: 16, color: fallbackColor),
    };
  }
}

class ProjectRiskCard extends StatelessWidget {
  const ProjectRiskCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      cornerRadius: 18,
      child: Column(
        children: [
          for (var i = 0; i < MpcFacts.riskLayers.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.terracotta,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(MpcFacts.riskLayers[i].titleKey),
                        style: TextStyle(
                          color: p.textHi,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 16 / 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.tr(MpcFacts.riskLayers[i].detailKey),
                        style: TextStyle(
                          color: p.textLo,
                          fontSize: 12,
                          height: 15 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (i != MpcFacts.riskLayers.length - 1) const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          Container(height: 1, color: p.border),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.event_note_outlined, size: 17, color: p.textLo),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr(MpcFacts.disclosureKey),
                  style: TextStyle(
                    color: p.textLo,
                    fontSize: 12,
                    height: 15 / 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProjectPartnersCard extends StatelessWidget {
  const ProjectPartnersCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      cornerRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < MpcFacts.partners.length; i++) ...[
            _partnerRow(context, p, MpcFacts.partners[i]),
            const SizedBox(height: 14),
          ],
          Text(
            context.tr('proj.orchestrationNote'),
            style: TextStyle(color: p.textLo, fontSize: 12, height: 15 / 12),
          ),
        ],
      ),
    );
  }

  Widget _partnerRow(BuildContext context, AppPalette p, PartnerFact fact) {
    final role = context.tr(fact.roleKey);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.goldSoft,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            role.substring(0, 1),
            style: const TextStyle(
              color: AppColors.copper,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 16 / 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: TextStyle(
                  color: p.textHi,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 16 / 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr(fact.detailKey),
                style: TextStyle(
                  color: p.textLo,
                  fontSize: 11,
                  height: 13 / 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Pill(
          context.tr(fact.status.key),
          color: AppColors.copper,
          backgroundColor: AppColors.goldSoft,
          padding: const EdgeInsets.fromLTRB(9, 5, 9, 5),
        ),
      ],
    );
  }
}

class ProjectContractCard extends StatelessWidget {
  const ProjectContractCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      child: Column(
        children: [
          _row(
            context,
            context.tr('proj.tokenStandard'),
            MpcFacts.tokenStandard,
          ),
          Divider(color: p.border, height: 20),
          _row(context, context.tr('dash.network'), MpcFacts.network),
          Divider(color: p.border, height: 20),
          _row(
            context,
            context.tr('dash.contract'),
            Fmt.shortAddress(MpcFacts.contractAddress),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final p = context.palette;
    return Row(
      children: [
        Text(label, style: TextStyle(color: p.textLo)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class ProjectCtaButtons extends StatelessWidget {
  const ProjectCtaButtons({super.key, required this.project});
  final MiningProject project;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: null,
            child: Text(context.tr('proj.notOpen')),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => context.push(
              '/webview',
              extra: WebViewArgs(
                url: MpcFacts.explorerTokenUrl,
                title: context.tr('proj.viewExplorer'),
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.palette.textHi,
              side: const BorderSide(color: AppColors.gold),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  AppIcons.open_in_new,
                  size: 18,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 8),
                Text(
                  context.tr('proj.viewExplorer'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 16 / 13,
                    color: context.palette.textHi,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
