import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';

(int, String) _lockoutDisplay(Duration d) {
  final seconds = d.inSeconds;
  if (seconds < 60) return (seconds, seconds == 1 ? 'second' : 'seconds');
  final minutes = (seconds / 60).ceil();
  if (minutes < 60) return (minutes, minutes == 1 ? 'minute' : 'minutes');
  final hours = (seconds / 3600).ceil();
  return (hours, hours == 1 ? 'hour' : 'hours');
}

class LockoutView extends StatelessWidget {
  const LockoutView({
    super.key,
    required this.remaining,
    required this.total,
    required this.onUseBiometrics,
    required this.onRestore,
  });

  final Duration remaining;
  final Duration total;
  final VoidCallback onUseBiometrics;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final (value, unit) = _lockoutDisplay(remaining);
    final progress = total.inMilliseconds == 0
        ? 0.0
        : 1 - (remaining.inMilliseconds / total.inMilliseconds);

    return Scaffold(
      backgroundColor: AppColors.lockoutBg,
      appBar: AppBar(
        backgroundColor: AppColors.lockoutBg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Unlock wallet',
          style: TextStyle(
            color: AppColors.lightTextHi,
            fontSize: 18,
            height: 22 / 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/icons/auth/lock-clock.svg',
                width: 56,
                height: 56,
              ),
              const SizedBox(height: 24),
              Text(
                'Try again in $value $unit',
                style: const TextStyle(
                  color: AppColors.lightTextHi,
                  fontSize: 24,
                  height: 29 / 24,
                  letterSpacing: -0.24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Too many incorrect PIN attempts. This delay protects your '
                'wallet.',
                style: TextStyle(
                  color: AppColors.restoreSubtitle,
                  fontSize: 14,
                  height: 17 / 14,
                ),
              ),
              const SizedBox(height: 53),
              Center(
                child: SizedBox(
                  width: 132,
                  height: 132,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 132,
                        height: 132,
                        decoration: const BoxDecoration(
                          color: AppColors.lightSurface,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(
                        width: 132,
                        height: 132,
                        child: CircularProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          strokeWidth: 6,
                          backgroundColor: AppColors.lightSurfaceHi,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.lockoutRing,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$value',
                            style: const TextStyle(
                              color: AppColors.lightTextHi,
                              fontSize: 40,
                              height: 48 / 40,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            unit,
                            style: const TextStyle(
                              color: AppColors.restoreSubtitle,
                              fontSize: 12,
                              height: 15 / 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: onUseBiometrics,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.lockoutBiometricBg,
                    foregroundColor: AppColors.lightTextHi,
                    side: const BorderSide(color: AppColors.lightBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Use biometrics',
                    style: TextStyle(
                      fontSize: 14,
                      height: 17 / 14,
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
                  onPressed: onRestore,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.lightSurface,
                    foregroundColor: AppColors.lockoutRestoreText,
                    side: const BorderSide(color: AppColors.lightBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Forgot PIN? Restore wallet',
                    style: TextStyle(
                      fontSize: 13,
                      height: 16 / 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
