import 'package:mpc_mining_app/core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/mpc_facts.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/mining_hero_art.dart';
import '../../data/models/mining_project.dart';
import 'widgets/pipeline_widgets.dart';
import '../web/web_view_screen.dart';
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

/// Keeps the hero image free of overlaid copy. Title lives on the page surface;
/// the collapsed app bar re-shows it once the hero is scrolled away.
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
    // Show toolbar title once most of the hero has scrolled under the bar.
    final next =
        _scroll.hasClients &&
        _scroll.offset > (_expandedHeight - kToolbarHeight - 24);
    if (next != _collapsed) setState(() => _collapsed = next);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
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
            backgroundColor: p.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: _collapsed ? 0.5 : 0,
            foregroundColor: p.textHi,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: _collapsed
                    ? Colors.transparent
                    : p.surface.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: const MpcBackButton(fallbackRoute: '/projects'),
              ),
            ),
            // Image-only when expanded; title fades in after collapse.
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
                  // Blend hero into the page background — no text on gold.
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: IgnorePointer(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [p.bg.withValues(alpha: 0), p.bg],
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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
            sliver: SliverList.list(
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: p.textHi,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(AppIcons.place_outlined, size: 15, color: p.textLo),
                    const SizedBox(width: 4),
                    Text(
                      context.tr(project.location),
                      style: TextStyle(color: p.textLo, fontSize: 13),
                    ),
                    const Spacer(),
                    Pill(context.tr(project.stage.key), color: p.primary),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in project.commodities)
                      Pill(
                        context.tr(c),
                        color: p.accent,
                        icon: AppIcons.diamond_outlined,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr(project.description),
                  style: TextStyle(color: p.textHi, height: 1.5, fontSize: 14),
                ),
                const SizedBox(height: 24),
                SectionHeader(context.tr('proj.pipeline')),
                const SizedBox(height: 10),
                GlassCard(child: PipelineList(pipeline: project.pipeline)),
                const SizedBox(height: 24),
                SectionHeader(context.tr('proj.verification')),
                const SizedBox(height: 10),
                _VerificationCard(methods: project.verificationMethods),
                const SizedBox(height: 24),
                SectionHeader(context.tr('proj.governance')),
                const SizedBox(height: 10),
                const _RiskCard(),
                const SizedBox(height: 24),
                SectionHeader(context.tr('proj.partners')),
                const SizedBox(height: 10),
                const _PartnersCard(),
                const SizedBox(height: 24),
                SectionHeader(context.tr('proj.contract')),
                const SizedBox(height: 10),
                const _ContractCard(),
                const SizedBox(height: 24),
                _CtaButtons(project: project),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Verification methods with their real status.
///
/// No completed-check icon is used here: per whitepaper Appendix D nothing in
/// this list is complete yet, so a tick would read as "verified" and overstate
/// the position. The status pill carries the truth instead.
class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.methods});
  final List<VerificationMethod> methods;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      child: Column(
        children: [
          for (var i = 0; i < methods.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.circle_outlined, size: 16, color: p.textLo),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(methods[i].labelKey),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Pill(
                        context.tr(methods[i].status.key),
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (i != methods.length - 1) Divider(color: p.border, height: 20),
          ],
        ],
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  const _RiskCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      child: Column(
        children: [
          for (var i = 0; i < MpcFacts.riskLayers.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: p.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(MpcFacts.riskLayers[i].titleKey),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr(MpcFacts.riskLayers[i].detailKey),
                        style: TextStyle(
                          color: p.textLo,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (i != MpcFacts.riskLayers.length - 1)
              Divider(color: p.border, height: 20),
          ],
          Divider(color: p.border, height: 22),
          Row(
            children: [
              Icon(Icons.event_note_outlined, size: 16, color: p.textLo),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr(MpcFacts.disclosureKey),
                  style: TextStyle(
                    color: p.textLo,
                    fontSize: 12.5,
                    height: 1.3,
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

class _PartnersCard extends StatelessWidget {
  const _PartnersCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      child: Column(
        children: [
          for (var i = 0; i < MpcFacts.partners.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: p.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    MpcFacts.partners[i].name.substring(0, 1),
                    style: TextStyle(
                      color: p.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        MpcFacts.partners[i].name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr(MpcFacts.partners[i].roleKey),
                        style: TextStyle(
                          color: p.textLo,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Pill(
                          context.tr(MpcFacts.partners[i].status.key),
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (i != MpcFacts.partners.length - 1)
              Divider(color: p.border, height: 24),
          ],
          Divider(color: p.border, height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.info_outline, size: 15, color: p.textLo),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('proj.orchestrationNote'),
                  style: TextStyle(
                    color: p.textLo,
                    fontSize: 12.5,
                    height: 1.35,
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

class _ContractCard extends StatelessWidget {
  const _ContractCard();

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
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.push(
              '/webview',
              extra: WebViewArgs(
                url: MpcFacts.explorerTokenUrl,
                title: MpcFacts.networkShort,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    context.tr('dash.contract'),
                    style: TextStyle(color: p.textLo),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      Fmt.shortAddress(MpcFacts.contractAddress),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(AppIcons.open_in_new, size: 16, color: p.primary),
                ],
              ),
            ),
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

class _CtaButtons extends StatelessWidget {
  const _CtaButtons({required this.project});
  final MiningProject project;

  @override
  Widget build(BuildContext context) {
    // Holding is not open for any asset pre-listing — stay honest, disable it.
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: null,
            icon: const Icon(AppIcons.add_circle_outline),
            label: Text(context.tr('proj.notOpen')),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push(
              '/webview',
              extra: WebViewArgs(
                url: MpcFacts.explorerTokenUrl,
                title: context.tr('proj.viewExplorer'),
              ),
            ),
            icon: const Icon(AppIcons.open_in_new, size: 18),
            label: Text(context.tr('proj.viewExplorer')),
          ),
        ),
      ],
    );
  }
}
