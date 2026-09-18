import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/security/biometric_auth.dart';

import 'entry_shared_widgets.dart';

class BiometricChoice extends StatelessWidget {
  const BiometricChoice({
    super.key,
    required this.enabled,
    required this.onChanged,
    this.availability,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;
  final BiometricAvailability? availability;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ready = availability == BiometricAvailability.ready;
    final note = switch (availability) {
      null => null,
      BiometricAvailability.ready => null,
      BiometricAvailability.notEnrolled => context.tr(
        'wallet.create.biometric.noteNotEnrolled',
      ),
      BiometricAvailability.unsupported => context.tr(
        'wallet.create.biometric.noteUnsupported',
      ),
    };
    return ListView(
      children: [
        Text(
          context.tr('wallet.create.biometric.title'),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          context.tr('wallet.create.biometric.body'),
          style: TextStyle(color: p.textLo, height: 1.45),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              AuthSvg('face-id', size: 24, tint: p.textHi),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('wallet.create.biometric.faceId'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.tr('wallet.create.biometric.recommended'),
                      style: const TextStyle(
                        color: AppColors.positive,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled && ready,
                onChanged: ready ? onChanged : null,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF2AA66A),
              ),
            ],
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 12),
          Text(note, style: TextStyle(color: p.textLo, height: 1.45)),
        ],
      ],
    );
  }
}

class Syncing extends StatefulWidget {
  const Syncing({
    super.key,
    this.title = 'Securing your wallet',
    this.body = 'Encrypting device access and checking secure storage…',
    this.showKeepOpenBanner = true,
  });

  final String title;
  final String body;
  final bool showKeepOpenBanner;

  @override
  State<Syncing> createState() => _SyncingState();
}

class _SyncingState extends State<Syncing> with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warningFill = isDark
        ? AppColors.darkWarningFill
        : const Color(0xFFFFF6E7);
    final warningBorder = isDark
        ? AppColors.darkWarningBorder
        : const Color(0xFFF2D79A);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: _spinCtrl,
            child: SvgPicture.asset(
              'assets/icons/wallet/spinner_dots.svg',
              width: 32,
              height: 32,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w600,
              color: Color(0xFF201A16),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 300,
            child: Text(
              widget.body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF81766E),
                fontSize: 13,
                height: 1.23,
              ),
            ),
          ),
          if (widget.showKeepOpenBanner) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: warningFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: warningBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AuthSvg('info-circle', size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('wallet.create.securing.keepOpen'),
                          style: TextStyle(
                            color: p.textHi,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('wallet.create.securing.keepOpenBody'),
                          style: TextStyle(
                            color: p.textLo,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
