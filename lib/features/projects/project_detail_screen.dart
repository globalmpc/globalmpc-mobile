import 'package:mpc_mining_app/core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/mining_hero_art.dart';
import '../../data/models/mining_project.dart';
import 'widgets/pipeline_widgets.dart';
import 'widgets/project_detail_cards.dart';
import 'projects_provider.dart';

class ProjectDetailScreen extends StatelessWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectsProvider>();
    final project = provider.byId(projectId);

    if (project == null) {
      return Scaffold(
        appBar: AppBar(),
        body: StateMessage(
          icon: AppIcons.search_off_outlined,
          title: context.tr('proj.notFound'),
          onRetry: () =>
              context.canPop() ? context.pop() : context.go('/projects'),
        ),
      );
    }

    return _ProjectDetailView(project: project);
  }
}

class _ProjectDetailView extends StatefulWidget {
  const _ProjectDetailView({required this.project});
  final MiningProject project;

  @override
  State<_ProjectDetailView> createState() => _ProjectDetailViewState();
}

class _ProjectDetailViewState extends State<_ProjectDetailView> {
  static const _expandedHeight = 176.0;
  final _scroll = ScrollController();
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final next =
        _scroll.hasClients &&
        _scroll.offset > (_expandedHeight - kToolbarHeight - 24);
    if (next != _collapsed) setState(() => _collapsed = next);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final project = widget.project;
    final name = context.tr(project.nameKey);

    return Scaffold(
      backgroundColor: p.bg,
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: _expandedHeight,
            backgroundColor: p.bg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: _collapsed ? 0.5 : 0,
            foregroundColor: p.textHi,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: _collapsed
                    ? Colors.transparent
                    : isDark
                    ? const Color(0xE616120F)
                    : p.surface.withValues(alpha: 0.9),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: MpcBackButton(
                  fallbackRoute: '/projects',
                  iconAsset: isDark
                      ? null
                      : 'assets/icons/projects/arrow-back.svg',
                ),
              ),
            ),

            title: AnimatedOpacity(
              opacity: _collapsed ? 1 : 0,
              duration: const Duration(milliseconds: 160),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: p.textHi,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  MiningHeroArt(kind: project.artKind),

                  Align(
                    alignment: Alignment.bottomCenter,
                    child: IgnorePointer(
                      child: Container(
                        height: 61,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isDark
                                ? const [
                                    Color(0x00BF7C42),
                                    Color(0x480C0A09),
                                    Color(0xFF0C0A09),
                                  ]
                                : [p.bg.withValues(alpha: 0), p.bg],
                            stops: isDark ? const [0.0, 0.4611, 0.9426] : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
            sliver: SliverList.list(
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: p.textHi,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 31 / 24,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(AppIcons.place_outlined, size: 16, color: p.textLo),
                    const SizedBox(width: 4),
                    Text(
                      context.tr(project.location),
                      style: TextStyle(
                        color: p.textLo,
                        fontSize: 12,
                        height: 17 / 12,
                      ),
                    ),
                    const Spacer(),
                    Pill(
                      context.tr(project.stage.key),
                      color: switch (project.stage) {
                        ProjectStage.inDiscussion => AppColors.copper,
                        ProjectStage.secured => AppColors.positive,
                        ProjectStage.toBeSecured => AppColors.copper,
                        ProjectStage.comingSoon => p.textLo,
                      },
                      backgroundColor: switch (project.stage) {
                        ProjectStage.inDiscussion => AppColors.goldSoft,
                        ProjectStage.secured => null,
                        ProjectStage.toBeSecured => AppColors.goldSoft,
                        ProjectStage.comingSoon => null,
                      },
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                      fontSize: 10,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    for (final c in project.commodities)
                      if (c == 'commodity.lithium' ||
                          c == 'commodity.silicon' ||
                          c == 'commodity.rareEarth')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: SvgPicture.asset(
                            'assets/icons/commodities/${c.split('.').last == 'rareEarth' ? 'rare_earth' : c.split('.').last}.svg',
                            height: 12,
                          ),
                        )
                      else
                        Pill(
                          context.tr(c),
                          color: AppColors.copper,
                          backgroundColor: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          icon: AppIcons.diamond_outlined,
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                          fontSize: 10,
                        ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr(project.description),
                  style: TextStyle(
                    color: p.textLo,
                    fontSize: 12,
                    height: 17 / 12,
                  ),
                ),
                const SizedBox(height: 20),
                SectionHeader(context.tr('proj.pipeline'), fontSize: 18),
                const SizedBox(height: 14),
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  borderColor: isDark ? null : AppColors.layerCardBorder,
                  child: PipelineList(pipeline: project.pipeline),
                ),
                const SizedBox(height: 20),
                SectionHeader(context.tr('proj.verification'), fontSize: 18),
                const SizedBox(height: 14),
                ProjectVerificationCard(methods: project.verificationMethods),
                const SizedBox(height: 20),
                SectionHeader(context.tr('proj.governance'), fontSize: 18),
                const SizedBox(height: 14),
                const ProjectRiskCard(),
                const SizedBox(height: 20),
                SectionHeader(context.tr('proj.partners'), fontSize: 18),
                const SizedBox(height: 14),
                const ProjectPartnersCard(),
                const SizedBox(height: 20),
                SectionHeader(context.tr('proj.contract'), fontSize: 18),
                const SizedBox(height: 14),
                const ProjectContractCard(),
                const SizedBox(height: 20),
                ProjectCtaButtons(project: project),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
