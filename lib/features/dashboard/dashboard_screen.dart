import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpc_mining_app/core/theme/app_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../core/constants/mpc_facts.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/state/view_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/mpc_logo.dart';
import '../projects/projects_provider.dart';
import '../web/web_view_screen.dart';
import '../projects/widgets/project_card.dart';
import '../wallet/wallet_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Bump the suffix whenever the tour steps change so returning users see the
  // updated walkthrough once.
  static const _tourSeenKey = 'home_tour_seen_v2';
  final GlobalKey _balanceKey = GlobalKey();
  final GlobalKey _projectsKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  bool _tourChecked = false;

  /// Runs the coach-mark tour once, on first ever visit to Home.
  Future<void> _maybeStartTour(BuildContext showcaseContext) async {
    if (_tourChecked) return;
    _tourChecked = true;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_tourSeenKey) ?? false) return;
    if (!showcaseContext.mounted) return;
    ShowCaseWidget.of(
      showcaseContext,
    ).startShowCase([_balanceKey, _projectsKey, _settingsKey]);
    await prefs.setBool(_tourSeenKey, true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final projects = context.watch<ProjectsProvider>();
    final wallet = context.watch<WalletProvider>();

    return ShowCaseWidget(
      builder: (showcaseContext) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _maybeStartTour(showcaseContext),
        );
        return Scaffold(
          backgroundColor: p.bg,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([projects.load(), wallet.load()]);
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: 112),
                children: [
                  Showcase(
                    key: _balanceKey,
                    title: context.tr('tour.balance.title'),
                    description: context.tr('tour.balance.body'),
                    child: _BalanceHero(
                      state: wallet.state,
                      settingsKey: _settingsKey,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Showcase(
                          key: _projectsKey,
                          title: context.tr('tour.projects.title'),
                          description: context.tr('tour.projects.body'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SectionHeader(
                                context.tr('dash.projects'),
                                action: TextButton(
                                  onPressed: () => context.go('/projects'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    context.tr('common.viewAll'),
                                    style: TextStyle(
                                      color: p.textLo,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _FeaturedProject(state: projects.state),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _TokenHeroCard(),
                        const SizedBox(height: 16),
                        SectionHeader(context.tr('dash.howItWorks')),
                        const SizedBox(height: 10),
                        const _InfraStackCard(),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            context.tr('app.trust'),
                            style: TextStyle(
                              color: p.textLo,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TokenHeroCard extends StatelessWidget {
  const _TokenHeroCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pill(
                context.tr('dash.utilityToken'),
                icon: AppIcons.verified_outlined,
              ),
              const SizedBox(width: 6),
              Pill(MpcFacts.networkShort, color: AppColors.info),
              const Spacer(),
              // "planned": ERC-3643 is the whitepaper's issuance standard, not
              // a verified property of the live token.
              Pill(context.tr('facts.plannedStandard'), color: p.accent),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            context.tr(MpcFacts.taglineKey),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              height: 1.45,
              letterSpacing: 0.1,
              color: p.textLo,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Metric(
                label: context.tr('dash.totalSupply'),
                value: Fmt.compact(MpcFacts.totalSupply),
              ),
              _divider(p),
              _Metric(
                label: context.tr('dash.network'),
                value: MpcFacts.networkShort,
              ),
              _divider(p),
              _Metric(
                label: context.tr('dash.listing'),
                value: context.tr('common.pending'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: p.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _MetaRow(
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
                Divider(color: p.border, height: 1),
                _MetaRow(
                  icon: Icons.domain_outlined,
                  label: context.tr('dash.issuer'),
                  value: MpcFacts.issuer,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push(
                '/webview',
                extra: WebViewArgs(
                  url: MpcFacts.explorerTokenUrl,
                  title: MpcFacts.networkShort,
                ),
              ),
              icon: const Icon(AppIcons.open_in_new, size: 16),
              label: Text(context.tr('dash.explorer')),
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

/// One labelled row inside the contract/issuer block: left label, right value,
/// with optional copy / open-in-explorer affordances.
class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
    this.onCopy,
    this.onOpen,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool mono;
  final VoidCallback? onCopy;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: p.textLo),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: p.textLo, fontSize: 12)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: p.textHi,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: mono ? AppTheme.monoFont : null,
              ),
            ),
          ),
          if (onCopy != null)
            _MiniIconButton(
              icon: AppIcons.copy_rounded,
              color: p.textLo,
              onTap: onCopy!,
            ),
          if (onOpen != null)
            _MiniIconButton(
              icon: AppIcons.open_in_new,
              color: p.primary,
              onTap: onOpen!,
            ),
        ],
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
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
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: p.textLo, fontSize: 11)),
        ],
      ),
    );
  }
}

/// High-emphasis wallet overview inspired by the selected reference while
/// keeping the original balance data and actions.
class _BalanceHero extends StatefulWidget {
  const _BalanceHero({required this.state, required this.settingsKey});
  final ViewState state;
  final GlobalKey settingsKey;

  @override
  State<_BalanceHero> createState() => _BalanceHeroState();
}

class _BalanceHeroState extends State<_BalanceHero> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final account = state.isSuccess ? state.data : null;
    final balance = account != null
        ? (_hidden ? '••••••' : Fmt.token(account.mpcBalance))
        : '—';
    final allocated = account == null
        ? '—'
        : (_hidden ? '••' : Fmt.compact(account.allocatedTotal));
    final free = account == null
        ? '—'
        : (_hidden
              ? '••'
              : Fmt.compact(
                  (account.mpcBalance - account.allocatedTotal).clamp(
                    0,
                    double.infinity,
                  ),
                ));

    return Container(
      height: 356,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/brand/hero_terrain.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x2216100D),
                  Color(0xB8120E0B),
                  Color(0xFF0C0A09),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      const MpcLogo(size: 24, tint: AppColors.gold),
                      const SizedBox(width: 6),
                      const Text(
                        'MPC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Notifications',
                        onPressed: () => context.push('/notifications'),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        icon: const Icon(
                          AppIcons.notify,
                          size: 21,
                          color: AppColors.darkTextLo,
                        ),
                      ),
                      Showcase(
                        key: widget.settingsKey,
                        title: context.tr('tour.settings.title'),
                        description: context.tr('tour.settings.body'),
                        child: IconButton(
                          onPressed: () => context.push('/settings'),
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          icon: const Icon(
                            AppIcons.settings_outlined,
                            size: 21,
                            color: AppColors.darkTextLo,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface,
                          border: Border.all(
                            color: AppColors.copper.withValues(alpha: .7),
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 6,
                              backgroundColor: AppColors.amber,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              // Never show a stand-in address: a user could
                              // copy it as their receive address.
                              account == null
                                  ? context.tr(
                                      state.isLoading
                                          ? 'dash.addressLoading'
                                          : 'dash.addressUnavailable',
                                    )
                                  : Fmt.shortAddress(account.address),
                              style: const TextStyle(
                                color: AppColors.darkTextLo,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: AppColors.darkTextLo,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Pill(MpcFacts.networkShort, color: AppColors.gold),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.go('/wallet'),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.tr('dash.balance'),
                              style: const TextStyle(
                                color: AppColors.darkTextLo,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 3),
                            GestureDetector(
                              onTap: () => setState(() => _hidden = !_hidden),
                              child: Icon(
                                _hidden
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 14,
                                color: AppColors.darkTextLo,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          balance,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: AppColors.darkTextHi,
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                height: 1,
                                letterSpacing: -1.6,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${context.tr('wallet.allocations')} $allocated  ·  '
                          '${context.tr('wallet.unallocated')} $free',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.darkTextLo,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: () => context.go('/wallet'),
                            icon: const Icon(AppIcons.south_west, size: 17),
                            label: Text(context.tr('wallet.receive')),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () => context.go('/wallet'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.lightTextHi,
                              backgroundColor: AppColors.lightSurface,
                              side: const BorderSide(
                                color: AppColors.lightBorder,
                              ),
                            ),
                            icon: const Icon(AppIcons.north_east, size: 17),
                            label: Text(context.tr('wallet.send')),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedProject extends StatelessWidget {
  const _FeaturedProject({required this.state});
  final ViewState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading || state.status == ViewStatus.idle) {
      return const _CardSkeleton(height: 210);
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
        child: StateMessage(
          icon: AppIcons.inbox_outlined,
          title: context.tr('proj.none'),
        ),
      );
    }
    return ProjectCard(
      project: featured,
      onTap: () => context.push('/projects/${featured.id}'),
    );
  }
}

class _InfraStackCard extends StatelessWidget {
  const _InfraStackCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var i = 0; i < MpcFacts.infraStack.length; i++) ...[
            _InfraRow(layer: MpcFacts.infraStack[i]),
            if (i != MpcFacts.infraStack.length - 1)
              Divider(color: p.border, height: 20),
          ],
        ],
      ),
    );
  }
}

class _InfraRow extends StatelessWidget {
  const _InfraRow({required this.layer});
  final InfraLayerFact layer;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final onChain = layer.isOnChain;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: (onChain ? p.primary : p.accent).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '${layer.index}',
            style: TextStyle(
              color: onChain ? p.primary : p.accent,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      context.tr(layer.titleKey),
                      style: TextStyle(
                        color: p.textHi,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Pill(
                    context.tr(layer.scopeKey),
                    color: onChain ? p.primary : p.accent,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                context.tr(layer.detailKey),
                style: TextStyle(color: p.textLo, fontSize: 12, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.height});
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
