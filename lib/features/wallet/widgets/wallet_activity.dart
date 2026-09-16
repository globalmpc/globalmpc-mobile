import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/models/wallet_models.dart';

class WalletAllocationCard extends StatelessWidget {
  const WalletAllocationCard({super.key, required this.account});
  final WalletAccount account;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (account.allocations.isEmpty) {
      return GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 34,
              height: 50,
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/wallet/pie-empty.svg',
                  width: 34,
                  height: 34,
                  colorFilter: const ColorFilter.mode(
                    AppColors.copper,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('wallet.noAllocations'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('wallet.noAllocationsBody'),
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
      );
    }
    final allocated = account.allocatedTotal;
    final free = (account.mpcBalance - allocated).clamp(0, double.infinity);
    return GlassCard(
      child: Column(
        children: [
          for (final entry in account.allocations.entries) ...[
            Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/wallet/allocation-triangle.svg',
                  width: 18,
                  height: 15,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr(projectNameKeyForId(entry.key)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${Fmt.token(entry.value)} MPC',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Divider(color: p.border, height: 20),
          ],
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/wallet/unallocated-square.svg',
                width: 15,
                height: 15,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('wallet.unallocated'),
                  style: TextStyle(color: p.textLo),
                ),
              ),
              Text(
                '${Fmt.token(free)} MPC',
                style: TextStyle(color: p.textLo, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WalletTxTile extends StatelessWidget {
  const WalletTxTile({super.key, required this.tx});
  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    final incoming = tx.isIncoming;
    final pending =
        tx.status == TxStatus.pending || tx.status == TxStatus.submitted;
    final failed = tx.status == TxStatus.failed;
    final amountColor = failed
        ? AppColors.danger
        : pending
        ? AppColors.copper
        : incoming
        ? AppColors.txPositive
        : context.palette.textHi;
    final counterpartyText = tx.projectNameKey != null
        ? context.tr(tx.projectNameKey!)
        : tx.counterpartyKey != null
        ? context.tr(tx.counterpartyKey!)
        : (tx.counterparty ?? '');
    final title =
        '${context.tr(tx.kind.key)} '
        '${context.tr(incoming ? 'tx.from' : 'tx.to')} '
        '$counterpartyText';
    final statusLabel = failed
        ? context.tr('tx.status.failed')
        : pending
        ? context.tr('common.pending')
        : context.tr('tx.status.completed');
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/wallet/transaction', extra: tx),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.palette.surface,
          border: Border.all(color: context.palette.bg),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: incoming
                    ? AppColors.receiveIconBg
                    : context.palette.surfaceHi,
                borderRadius: BorderRadius.circular(19),
              ),
              child: SvgPicture.asset(
                incoming
                    ? 'assets/icons/wallet/tx-receive.svg'
                    : 'assets/icons/wallet/tx-send.svg',
                width: 16,
                height: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.palette.textHi,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 17 / 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Fmt.dateTime(tx.timestamp),
                    style: const TextStyle(
                      color: AppColors.balanceLabelText,
                      fontSize: 11,
                      height: 13 / 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${incoming ? '+' : '−'}${Fmt.token(tx.amount)}',
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 16 / 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  statusLabel,
                  style: const TextStyle(
                    color: AppColors.balanceLabelText,
                    fontSize: 11,
                    height: 13 / 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
