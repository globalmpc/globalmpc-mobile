import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../core/constants/mpc_facts.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/notifications/notification_center.dart';
import '../../../core/state/view_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/mpc_logo.dart';

class DashboardBalanceHero extends StatefulWidget {
  const DashboardBalanceHero({
    super.key,
    required this.state,
    required this.settingsKey,
  });
  final ViewState state;
  final GlobalKey settingsKey;

  @override
  State<DashboardBalanceHero> createState() => _BalanceHeroState();
}

class _BalanceHeroState extends State<DashboardBalanceHero> {
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
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF201A16)),
                    ),
                  ),
                  child: Row(
                    children: [
                      const MpcLogo(size: 24),
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
                      DashboardHeaderIconButton(
                        tooltip: context.tr('notif.title'),
                        onTap: () => context.push('/notifications'),
                        child: ListenableBuilder(
                          listenable: NotificationCenter.instance,
                          builder: (context, bell) => Stack(
                            clipBehavior: Clip.none,
                            children: [
                              bell!,
                              if (NotificationCenter.instance.unreadCount > 0)
                                const Positioned(
                                  top: 1,
                                  right: 2,
                                  child: _UnreadDot(),
                                ),
                            ],
                          ),
                          child: SvgPicture.asset(
                            'assets/icons/dashboard/notification-bing.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Showcase(
                        key: widget.settingsKey,
                        title: context.tr('tour.settings.title'),
                        description: context.tr('tour.settings.body'),
                        child: DashboardHeaderIconButton(
                          tooltip: context.tr('tour.settings.title'),
                          onTap: () => context.push('/settings'),
                          child: SvgPicture.asset(
                            'assets/icons/dashboard/setting-2.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                              decoration: BoxDecoration(
                                color: AppColors.darkSurface,
                                border: Border.all(
                                  color: const Color(0xFF673A1B),
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 6,
                                    backgroundColor: AppColors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
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
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 14,
                                    color: AppColors.darkTextLo,
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Pill(
                              MpcFacts.networkShort,
                              color: const Color(0xFFC2773F),
                              backgroundColor: const Color(0xFF322F28),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  context.tr('dash.balance'),
                                  style: const TextStyle(
                                    color: Color(0xFFE8E0D8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                GestureDetector(
                                  key: const Key('balance-visibility-toggle'),
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () =>
                                      setState(() => _hidden = !_hidden),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      3,
                                      6,
                                      8,
                                      6,
                                    ),
                                    child: Icon(
                                      _hidden
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 14,
                                      color: const Color(0xFFE8E0D8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                                color: Color(0xFFD8D0C8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: FilledButton.icon(
                                  onPressed: () =>
                                      context.push('/wallet/receive'),
                                  style: FilledButton.styleFrom(
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  icon: SvgPicture.asset(
                                    'assets/icons/wallet/line-arrow-down.svg',
                                    width: 16,
                                    height: 16,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFF201A16),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  label: Text(context.tr('wallet.receive')),
                                ),
                              ),
                            ),
                            const SizedBox(width: 21),
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push('/wallet/send'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.lightTextHi,
                                    backgroundColor: AppColors.lightBg,
                                    side: const BorderSide(
                                      color: AppColors.darkBorder,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  icon: SvgPicture.asset(
                                    'assets/icons/wallet/line-arrow-up.svg',
                                    width: 16,
                                    height: 16,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFF201A16),
                                      BlendMode.srcIn,
                                    ),
                                  ),
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
          ),
        ],
      ),
    );
  }
}

class DashboardHeaderIconButton extends StatelessWidget {
  const DashboardHeaderIconButton({
    super.key,
    required this.onTap,
    required this.tooltip,
    required this.child,
  });

  final VoidCallback onTap;
  final String tooltip;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(width: 24, height: 24, child: child),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.warning,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.darkBg, width: 1.5),
      ),
    );
  }
}
