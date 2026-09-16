import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/language_selector_pill.dart';
import '../../core/widgets/mpc_logo.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final badge = context.tr('onboard.badge');
    final headline = context.tr('onboard.headline');
    final subhead = context.tr('onboard.subhead');
    final createLabel = context.tr('onboard.create');
    final importLabel = context.tr('onboard.import');

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: Image.asset(
              'assets/brand/hero_terrain.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              semanticLabel: 'Topographic mining terrain',
            ),
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, .48, .59, 1],
                  colors: [
                    Color(0x08000000),
                    Color(0x180C0A09),
                    Color(0xF00C0A09),
                    Color(0xFF0C0A09),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (_, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 56),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 0),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        MpcLogo(size: 24),
                                        SizedBox(width: 8),
                                        Text(
                                          'MPC',
                                          style: TextStyle(
                                            color: Color(0xFFFFFDF9),
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'RWA INFRASTRUCTURE',
                                      style: TextStyle(
                                        color: Color(0xFFB8AEA7),
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                const LanguageSelectorPill(),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3A241D),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  badge,
                                  style: const TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.35,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                headline,
                                style: const TextStyle(
                                  color: AppColors.darkTextHi,
                                  fontSize: 36,
                                  height: 1.2,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                subhead,
                                style: const TextStyle(
                                  color: AppColors.darkTextLo,
                                  fontSize: 14,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 56),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton(
                                  onPressed: () =>
                                      context.push('/wallet/create'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.gold,
                                    foregroundColor: AppColors.darkBg,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    createLabel,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      context.push('/wallet/import'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.lightTextHi,
                                    backgroundColor: AppColors.lightBg,
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    importLabel,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
