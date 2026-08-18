import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/mpc_logo.dart';
import '../settings/language_sheet.dart';

/// Wallet entry built on top of the existing DApp shell.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            // Scrolls only when it has to. On a normal phone the viewport is
            // taller than the content, so the [Spacer] below still pushes the
            // call to action to the bottom and the screen looks unchanged. On
            // a short device, or in a language whose copy runs longer, the
            // overflow becomes a scroll instead of a clipped first screen.
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
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
                                        MpcLogo(size: 24, tint: AppColors.gold),
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
                                const _WelcomeLanguageSelector(),
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
                                  color: AppColors.copper.withValues(
                                    alpha: .16,
                                  ),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(
                                      alpha: .35,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  context.tr('onboard.badge'),
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
                                context.tr('onboard.headline'),
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
                                context.tr('onboard.subhead'),
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
                                    context.tr('onboard.create'),
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
                                    context.tr('onboard.import'),
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

class _WelcomeLanguageSelector extends StatelessWidget {
  const _WelcomeLanguageSelector();

  @override
  Widget build(BuildContext context) {
    final language = LocaleControllerScope.of(context).language;

    // Opens the same sheet Settings uses, so every language the app ships is
    // reachable from the first screen.
    return Semantics(
      label: 'Language',
      value: language.englishName,
      button: true,
      child: InkWell(
        onTap: () => LanguageSheet.show(context),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .28),
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language_rounded,
                size: 15,
                color: AppColors.darkTextLo,
              ),
              const SizedBox(width: 6),
              Text(
                // The two-letter code, not the native name: it keeps the
                // control a fixed width in every language, so the header row
                // cannot overflow on a narrow device.
                language.locale.languageCode.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.darkTextHi,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 15,
                color: AppColors.darkTextLo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
