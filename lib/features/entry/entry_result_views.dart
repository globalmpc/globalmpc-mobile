import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';

import 'entry_shared_widgets.dart';

class SecurityFailedView extends StatelessWidget {
  const SecurityFailedView({
    super.key,
    required this.onRetry,
    required this.onReturnToWelcome,
  });

  final VoidCallback onRetry;
  final VoidCallback onReturnToWelcome;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorFill = isDark
        ? AppColors.darkErrorFill
        : const Color(0xFFFFF0ED);
    final errorBorder = isDark
        ? AppColors.darkErrorBorder
        : const Color(0xFFF3C0B9);

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          context.tr('wallet.import.secure'),
          style: TextStyle(
            color: p.textHi,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: Material(
              color: p.surface,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onReturnToWelcome,
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: p.textHi,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/icons/auth/wallet-shield.svg',
                width: 62,
                height: 64,
              ),
              const SizedBox(height: 17),
              Text(
                context.tr('wallet.secure.failed.title'),
                style: TextStyle(
                  color: p.textHi,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.24,
                ),
              ),
              const SizedBox(height: 17),
              Text(
                context.tr('wallet.secure.failed.body'),
                style: TextStyle(color: p.textLo, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: errorFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: errorBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AuthSvg(
                      'info-circle',
                      size: 20,
                      tint: Color(0xFFC9543C),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('wallet.secure.failed.deviceTitle'),
                            style: TextStyle(
                              color: p.textHi,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('wallet.secure.failed.deviceBody'),
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
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: const Color(0xFF241703),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onRetry,
                  child: Text(context.tr('wallet.secure.failed.retry')),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: onReturnToWelcome,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: p.surface,
                    foregroundColor: p.textHi,
                    side: BorderSide(color: p.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.tr('wallet.secure.failed.returnToWelcome'),
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

class Ready extends StatelessWidget {
  const Ready({super.key, required this.onOpen, this.isRestore = false});

  final VoidCallback onOpen;
  final bool isRestore;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final successFill = isDark
        ? AppColors.darkSuccessFill
        : const Color(0xFFEDF7F1);
    final successBorder = isDark
        ? AppColors.darkSuccessBorder
        : const Color(0xFFB7DDC6);

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRestore)
                  Container(
                    width: 78,
                    height: 78,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2AA66A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  )
                else
                  SvgPicture.asset(
                    'assets/icons/wallet/success_badge.svg',
                    width: 88,
                    height: 88,
                  ),
                const SizedBox(height: 24),
                Text(
                  context.tr(
                    isRestore
                        ? 'wallet.secure.done.title'
                        : 'wallet.import.ready.title',
                  ),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: isRestore ? FontWeight.w600 : FontWeight.w700,
                    color: isRestore
                        ? const Color(0xFF201A16)
                        : const Color(0xFF181310),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr(
                    isRestore
                        ? 'wallet.secure.done.body'
                        : 'wallet.import.ready.body',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isRestore
                        ? const Color(0xFF81766E)
                        : const Color(0xFF746B64),
                  ),
                ),
                if (isRestore) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: successFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: successBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF2AA66A),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr(
                                  'wallet.import.ready.securityComplete',
                                ),
                                style: TextStyle(
                                  color: p.textHi,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.tr('wallet.import.ready.securityBody'),
                                style: TextStyle(
                                  color: p.textLo,
                                  fontSize: 12,
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
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: onOpen,
            child: Text(context.tr('wallet.import.ready.open')),
          ),
        ),
      ],
    );
  }
}
