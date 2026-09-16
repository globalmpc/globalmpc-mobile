import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

Future<String?> showBiometricChoiceDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    useSafeArea: false,
    barrierColor: const Color(0x2616120F),
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 390,
          height: 844,
          child: Stack(
            children: [
              Positioned(
                left: 32,
                top: 267,
                width: 318,
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: AppColors.biometricSheetBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.biometricSheetBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/auth/fingerprint-lg.svg',
                          width: 80,
                          height: 80,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('unlock.biometricSheet.title'),
                          style: const TextStyle(
                            color: AppColors.darkTextHi,
                            fontSize: 24,
                            height: 29 / 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('unlock.biometricSheet.body'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.darkTextLo,
                            fontSize: 13,
                            height: 16 / 13,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: 250,
                          height: 46,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.darkBg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                height: 17 / 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () =>
                                Navigator.pop(context, 'biometrics'),
                            child: Text(context.tr('unlock.useBiometrics')),
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
  );
}

Future<bool?> showRestoreConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    useSafeArea: false,
    barrierColor: const Color(0x2616120F),
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 390,
          height: 844,
          child: Stack(
            children: [
              Positioned(
                left: 36,
                top: 270,
                width: 318,
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/auth/warning-triangle.svg',
                          width: 56,
                          height: 49,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.tr('unlock.restore.title'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.darkTextHi,
                            fontFamily: AppTheme.displayFont,
                            fontSize: 24,
                            height: 31 / 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.tr('unlock.restore.body'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.darkTextLo,
                            fontSize: 13,
                            height: 16 / 13,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 46,
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.darkTextHi,
                                      backgroundColor: AppColors.darkSurface,
                                      side: const BorderSide(
                                        color: AppColors.darkBorder,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        height: 17 / 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    child: Text(context.tr('common.cancel')),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SizedBox(
                                  height: 46,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.gold,
                                      foregroundColor: AppColors.darkBg,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        height: 17 / 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      context.tr('common.continueBtn'),
                                    ),
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
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
