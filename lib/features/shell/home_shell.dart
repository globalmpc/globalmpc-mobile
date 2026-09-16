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
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _NavItem(
                  asset: 'home',
                  label: context.tr('nav.home'),
                  selected: index == 0,
                  onTap: () => _go(0),
                ),
                const SizedBox(width: 12),
                _NavItem(
                  asset: 'projects',
                  label: context.tr('nav.projects'),
                  selected: index == 1,
                  onTap: () => _go(1),
                  iconSize: 20,
                ),
                const SizedBox(width: 12),
                _NavItem(
                  asset: 'trend-up',
                  label: context.tr('nav.earn'),
                  selected: index == 2,
                  onTap: () => _go(2),
                ),
                const SizedBox(width: 12),
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
    this.iconSize = 16,
  });

  /// Icon name under `assets/icons/bottom-nav/`.
  final String asset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final iconColor = selected ? p.navActiveIcon : p.navInactive;
    final labelColor = selected ? p.navActiveLabel : p.navInactive;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(100),
        // The active pill wraps the icon AND the label together (Figma),
        // not the icon alone.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 6),
          decoration: BoxDecoration(
            color: selected ? p.navActiveFill : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/bottom-nav/$asset.svg',
                width: iconSize,
                height: iconSize,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  height: 12 / 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
