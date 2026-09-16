import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/mpc_facts.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/state/view_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/glass_card.dart';
import '../../projects/projects_provider.dart';
import '../../projects/widgets/home_project_card.dart';

class DashboardFeaturedProject extends StatelessWidget {
  const DashboardFeaturedProject({super.key, required this.state});
  final ViewState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading || state.status == ViewStatus.idle) {
      return const DashboardCardSkeleton(height: 210);
    }
    if (state.isError) {
      return GlassCard(
        child: StateMessage(
          icon: AppIcons.cloud_off_outlined,
          title: context.tr('proj.unavailable'),
          message: state.error,
        ),
      );
    }
    final projects = context.read<ProjectsProvider>();
    final featured = projects.featured;
    if (featured == null) {
      return GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/projects/no_projects.svg',
                width: 34,
                height: 34,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('proj.none'),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('proj.noneBody'),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.palette.textLo, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return HomeProjectCard(
      project: featured,
      onTap: () => context.push('/projects/${featured.id}'),
    );
  }
}

class DashboardInfraStackCard extends StatelessWidget {
  const DashboardInfraStackCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      borderColor: p.cardBorder,
      child: Column(
        children: [
          for (var i = 0; i < MpcFacts.infraStack.length; i++) ...[
            DashboardInfraRow(layer: MpcFacts.infraStack[i]),
            if (i != MpcFacts.infraStack.length - 1)
              Container(height: 1, color: p.cardDivider),
          ],
        ],
      ),
    );
  }
}

class DashboardInfraRow extends StatelessWidget {
  const DashboardInfraRow({super.key, required this.layer});
  final InfraLayerFact layer;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final onChain = layer.isOnChain;
    final pillBg = onChain ? p.pillOnChainBg : p.pillLayerBg;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(layer.iconAsset, width: 18, height: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(layer.titleKey),
                  style: TextStyle(
                    color: p.textHi,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 16 / 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr(layer.detailKey),
                  style: TextStyle(
                    color: AppColors.balanceLabelText,
                    fontSize: 12,
                    height: 17 / 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Pill(
            context.tr(layer.scopeKey),
            color: onChain ? AppColors.onChainText : AppColors.copper,
            backgroundColor: pillBg,
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
            fontSize: 8,
          ),
        ],
      ),
    );
  }
}

class DashboardCardSkeleton extends StatelessWidget {
  const DashboardCardSkeleton({super.key, required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
