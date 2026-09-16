import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/wallet_lock_controller.dart';
import '../../core/security/wallet_session_store.dart';
import '../../core/theme/app_colors.dart';

class RestoreConfirmPage extends StatelessWidget {
  const RestoreConfirmPage({super.key});

  void _continue(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RestorePhraseRequiredPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Restore wallet',
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
                onTap: () => Navigator.pop(context),
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
              Text(
                'Restore access to your wallet?',
                style: TextStyle(
                  color: p.textHi,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You will need the recovery phrase for this wallet. '
                'Restoring removes the current PIN from this device and '
                'starts the secure import flow.',
                style: TextStyle(color: p.textLo, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 50),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkWarningFill
                      : const Color(0xFFFFF6E7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkWarningBorder
                        : const Color(0xFFF2D79A),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFC2773F),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Before you continue',
                            style: TextStyle(
                              color: p.textHi,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Make sure you have the correct recovery phrase '
                            'and nobody can see your screen.',
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
                  onPressed: () => _continue(context),
                  child: const Text('Continue to restore'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: p.surface,
                    foregroundColor: p.textHi,
                    side: BorderSide(color: p.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RestorePhraseRequiredPage extends StatelessWidget {
  const RestorePhraseRequiredPage({super.key});

  Future<void> _continue(BuildContext context) async {
    await WalletSessionStore.instance.clear();
    WalletLockController.instance.markWalletCleared();
    if (context.mounted) {
      context.go('/wallet/import', extra: const {'isRestore': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Restore wallet',
          style: TextStyle(
            color: p.textHi,
            fontSize: 18,
            height: 22 / 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: Material(
              color: AppColors.lightSurfaceHi,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: SvgPicture.asset(
                    'assets/icons/auth/line-arrow-left.svg',
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your recovery phrase is required',
                style: TextStyle(
                  color: p.textHi,
                  fontSize: 24,
                  height: 29 / 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'MPC cannot recover or reset your PIN without it.',
                style: const TextStyle(
                  color: AppColors.restoreSubtitle,
                  fontSize: 14,
                  height: 17 / 14,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                decoration: BoxDecoration(
                  color: AppColors.restoreInfoBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What happens next',
                      style: TextStyle(
                        color: p.textHi,
                        fontSize: 13,
                        height: 16 / 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Enter your recovery phrase\n'
                      '2. Review the wallet address\n'
                      '3. Create a new device PIN\n'
                      '4. Secure the wallet again',
                      style: TextStyle(
                        color: AppColors.restoreSubtitle,
                        fontSize: 14,
                        height: 17 / 14,
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
                  onPressed: () => _continue(context),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 14,
                      height: 17 / 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: p.surface,
                    foregroundColor: p.textHi,
                    side: BorderSide(color: p.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 14,
                      height: 17 / 14,
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
