import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/language_selector_pill.dart';
import '../../../core/widgets/mpc_logo.dart';

class UnlockPinPanel extends StatelessWidget {
  const UnlockPinPanel({
    super.key,
    required this.pinController,
    required this.busy,
    required this.error,
    required this.onPinChanged,
    required this.onUnlock,
    required this.onRestore,
    required this.onShowBiometrics,
    required this.onCreateWallet,
    this.showLanguageSelector = true,
  });

  final TextEditingController pinController;
  final bool busy;
  final String? error;
  final VoidCallback onPinChanged;
  final VoidCallback onUnlock;
  final VoidCallback onRestore;
  final VoidCallback onShowBiometrics;
  final VoidCallback onCreateWallet;
  final bool showLanguageSelector;

  static OutlineInputBorder _pinBorder() => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.darkBorder),
  );

  @override
  Widget build(BuildContext context) {
    final welcomeBack = context.tr('unlock.welcomeBack');
    final enterPin = context.tr('unlock.enterPin');
    final forgotPin = context.tr('unlock.forgotPin');
    final unlockLabel = context.tr('unlock.unlock');
    final unlockingLabel = context.tr('unlock.unlocking');
    final useBiometrics = context.tr('unlock.useBiometrics');
    final newToMpc = context.tr('unlock.newToMpc');
    final createWallet = context.tr('onboard.create');

    return Scaffold(
      backgroundColor: const Color(0xFF01020C),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/brand/hero_terrain_portrait.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x0001020C),
                    Color(0x0001020C),
                    Color(0xFF01020C),
                  ],
                  stops: [0.0, 0.5545, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: _KeyboardLift(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _KeyboardLift.designWidth,
                  height: _KeyboardLift.designHeight,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 24,
                        top: 38,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                MpcLogo(size: 24),
                                SizedBox(width: 14),
                                Text(
                                  'MPC',
                                  style: TextStyle(
                                    color: AppColors.darkTextHi,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
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
                      ),
                      Positioned(
                        right: 20,
                        top: 36,
                        child: Visibility(
                          visible: showLanguageSelector,
                          child: const LanguageSelectorPill(outlined: true),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        top: 292,
                        width: 350,
                        child: Column(
                          children: [
                            Text(
                              welcomeBack,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.darkTextHi,
                                fontFamily: AppTheme.displayFont,
                                fontSize: 34,
                                height: 43 / 34,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              enterPin,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.darkTextLo,
                                fontSize: 14,
                                height: 17 / 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 20,
                        top: 396,
                        child: SizedBox(
                          width: 350,
                          height: 62,
                          child: TextField(
                            controller: pinController,
                            autofocus: true,
                            obscureText: true,
                            obscuringCharacter: '●',
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(
                              color: AppColors.darkTextHi,
                              fontSize: 25,
                              height: 30 / 25,
                              letterSpacing: 8,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '••••••',
                              filled: true,
                              fillColor: AppColors.darkSurface,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              border: _pinBorder(),
                              enabledBorder: _pinBorder(),
                              focusedBorder: _pinBorder(),
                            ),
                            onChanged: (_) => onPinChanged(),
                            onSubmitted: (_) => onUnlock(),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        top: 482,
                        width: 350,
                        child: Row(
                          children: [
                            Expanded(
                              child: error == null
                                  ? const SizedBox()
                                  : Text(
                                      error!,
                                      style: const TextStyle(
                                        color: AppColors.danger,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                            TextButton(
                              onPressed: onRestore,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.darkTextLo,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 24),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                forgotPin,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 15 / 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 20,
                        top: 548,
                        child: SizedBox(
                          width: 350,
                          height: 52,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              foregroundColor: AppColors.darkBg,
                              disabledBackgroundColor:
                                  AppColors.unlockButtonBusy,
                              disabledForegroundColor: busy
                                  ? AppColors.darkTextHi
                                  : AppColors.darkBg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: pinController.text.length == 6 && !busy
                                ? onUnlock
                                : null,
                            child: busy
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: AppColors.darkTextHi,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(unlockingLabel),
                                    ],
                                  )
                                : Text(unlockLabel),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 627,
                        child: Center(
                          child: TextButton.icon(
                            onPressed: onShowBiometrics,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.gold,
                            ),
                            icon: SvgPicture.asset(
                              'assets/icons/auth/fingerprint.svg',
                              width: 22,
                              height: 26,
                            ),
                            label: Text(
                              useBiometrics,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 17 / 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        top: 760,
                        width: 350,
                        height: 52,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  newToMpc,
                                  style: const TextStyle(
                                    color: AppColors.darkTextHi,
                                    fontSize: 14,
                                    height: 17 / 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: onCreateWallet,
                                  child: Text(
                                    createWallet,
                                    style: const TextStyle(
                                      color: AppColors.amber,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _KeyboardLift extends StatelessWidget {
  const _KeyboardLift({required this.child});

  static const designWidth = 390.0;
  static const designHeight = 844.0;
  static const _lastActionBottom = 812.0;
  static const _keyboardGap = 16.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final widthScale = size.width / designWidth;
        final heightScale = size.height / designHeight;
        final scale = widthScale < heightScale ? widthScale : heightScale;
        final top = (size.height - designHeight * scale) / 2;
        final actionsBottom = top + _lastActionBottom * scale + _keyboardGap;
        final lift = keyboard == 0
            ? 0.0
            : (actionsBottom - (size.height - keyboard)).clamp(
                0.0,
                double.infinity,
              );
        return SingleChildScrollView(
          reverse: true,
          physics: lift == 0 ? const NeverScrollableScrollPhysics() : null,
          padding: EdgeInsets.only(bottom: lift),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Center(child: child),
          ),
        );
      },
    );
  }
}
