import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';

/// Bottom-nav shell hosting the primary destinations. Uses go_router's
/// StatefulNavigationShell so each tab keeps its own navigation stack.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final index = navigationShell.currentIndex;

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border.all(color: p.bg),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _NavItem(
                  asset: 'home',
                  label: context.tr('nav.home'),
                  selected: index == 0,
                  onTap: () => _go(0),
                ),
                _NavItem(
                  asset: 'projects',
                  label: context.tr('nav.projects'),
                  selected: index == 1,
                  onTap: () => _go(1),
                ),
                _NavItem(
                  asset: 'trend-up',
                  label: context.tr('nav.earn'),
                  selected: index == 2,
                  onTap: () => _go(2),
                ),
                _NavItem(
                  asset: 'wallet',
                  label: context.tr('nav.wallet'),
                  selected: index == 3,
                  onTap: () => _go(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _go(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.asset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// Icon name under `assets/icons/bottom-nav/`.
  final String asset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? AppColors.amber : p.textLo;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        // The active pill wraps the icon AND the label together (Figma),
        // not the icon alone.
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.gold.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/bottom-nav/$asset.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
