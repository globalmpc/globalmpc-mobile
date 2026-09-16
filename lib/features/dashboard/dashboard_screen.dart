import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../projects/projects_provider.dart';
import '../wallet/wallet_provider.dart';
import 'widgets/dashboard_token_card.dart';
import 'widgets/dashboard_balance_hero.dart';
import 'widgets/dashboard_sections.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _tourSeenKey = 'home_tour_seen_v2';
  final GlobalKey _balanceKey = GlobalKey();
  final GlobalKey _projectsKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  bool _tourChecked = false;

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
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([projects.load(), wallet.load()]);
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                  Showcase(
                    key: _balanceKey,
                    title: context.tr('tour.balance.title'),
                    description: context.tr('tour.balance.body'),
                    child: DashboardBalanceHero(
                      state: wallet.state,
                      settingsKey: _settingsKey,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                              const SizedBox(height: 12),
                              DashboardFeaturedProject(state: projects.state),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const DashboardTokenHeroCard(),
                        const SizedBox(height: 16),
                        SectionHeader(context.tr('dash.howItWorks')),
                        const SizedBox(height: 12),
                        const DashboardInfraStackCard(),
                        const SizedBox(height: 16),
                        Text(
                          context.tr('app.trust'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: p.textLo,
                            fontSize: 11,
                            height: 13 / 11,
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
