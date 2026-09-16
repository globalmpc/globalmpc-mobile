import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';

class SendInsufficientGasSheet extends StatelessWidget {
  const SendInsufficientGasSheet({
    super.key,
    required this.networkFee,
    required this.bnbBalance,
  });

  final double networkFee;
  final double bnbBalance;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shortfall = (networkFee - bnbBalance).clamp(0, double.infinity);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.warning,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('send.gas.title'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              context
                  .tr('send.gas.body')
                  .replaceFirst('{fee}', networkFee.toStringAsFixed(5))
                  .replaceFirst('{bnb}', bnbBalance.toStringAsFixed(5)),
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textLo, height: 1.45),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: .28),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Text(context.tr('send.gas.needed')),
                  const Spacer(),
                  Text(
                    '${shortfall.toStringAsFixed(5)} BNB',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              context.tr('send.gas.note'),
              style: TextStyle(color: p.textLo, fontSize: 12.5),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/wallet/add-bnb');
                },
                icon: const Icon(AppIcons.south_west, size: 18),
                label: Text(context.tr('send.gas.receive')),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.tr('common.cancel')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
