import 'package:flutter/material.dart';
import 'package:mpc_mining_app/core/theme/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/wallet_models.dart';
import 'wallet_provider.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final state = provider.state;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('wallet.title')),
        actions: [
          IconButton(
            tooltip: 'Wallet settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(AppIcons.settings_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: switch (state.status) {
          _ when state.isLoading => const Center(
            child: CircularProgressIndicator(),
          ),
          _ when state.isError => StateMessage(
            icon: AppIcons.cloud_off_outlined,
            title: context.tr('wallet.unavailable'),
            message: state.error,
            onRetry: provider.load,
          ),
          _ when state.isSuccess => _WalletBody(account: state.data!),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _WalletBody extends StatelessWidget {
  const _WalletBody({required this.account});
  final WalletAccount account;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        _BalanceCard(account: account),
        const SizedBox(height: 12),
        const SizedBox(height: 10),
        SectionHeader(context.tr('wallet.allocations')),
        const SizedBox(height: 12),
        _AllocationCard(account: account),
        const SizedBox(height: 22),
        SectionHeader(context.tr('wallet.activity')),
        const SizedBox(height: 12),
        if (account.transactions.isEmpty)
          GlassCard(
            child: StateMessage(
              icon: AppIcons.inbox_outlined,
              title: 'No transactions yet',
              message:
                  'Your received, sent, pending, and failed transactions will appear here.',
            ),
          )
        else
          for (final tx in account.transactions) ...[
            _TxTile(tx: tx),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.account});
  final WalletAccount account;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      padding: const EdgeInsets.all(20),
      accent: AppColors.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.tr('wallet.totalBalance'),
                style: TextStyle(color: p.textLo),
              ),
              const Spacer(),
              Pill(account.network, color: AppColors.info),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                Fmt.token(account.mpcBalance),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'MPC',
                  style: TextStyle(
                    color: p.textLo,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: account.address));
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text(context.tr('wallet.addressCopied'))),
                  );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(AppIcons.copy_rounded, size: 14, color: p.textLo),
                  const SizedBox(width: 6),
                  Text(
                    Fmt.shortAddress(account.address, lead: 8, tail: 6),
                    style: TextStyle(color: p.textLo, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.push('/wallet/receive'),
                  icon: const Icon(AppIcons.south_west, size: 18),
                  label: Text(context.tr('wallet.receive')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/wallet/send'),
                  icon: const Icon(AppIcons.north_east, size: 18),
                  label: Text(context.tr('wallet.send')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AllocationCard extends StatelessWidget {
  const _AllocationCard({required this.account});
  final WalletAccount account;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (account.allocations.isEmpty) {
      return GlassCard(
        child: StateMessage(
          icon: AppIcons.pie_chart_outline,
          title: context.tr('wallet.noAllocations'),
          message: context.tr('wallet.noAllocationsBody'),
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
                Icon(AppIcons.terrain_rounded, size: 18, color: p.accent),
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
              Icon(
                AppIcons.account_balance_wallet_outlined,
                size: 18,
                color: p.primary,
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

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx});
  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final incoming = tx.isIncoming;
    final pending =
        tx.status == TxStatus.pending || tx.status == TxStatus.submitted;
    final failed = tx.status == TxStatus.failed;
    final color = failed
        ? AppColors.danger
        : pending
        ? AppColors.warning
        : incoming
        ? AppColors.positive
        : p.textHi;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/wallet/transaction', extra: tx),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                incoming ? AppIcons.south_west : AppIcons.north_east,
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    failed
                        ? 'Failed'
                        : pending
                        ? 'Pending'
                        : context.tr(tx.kind.key),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tx.projectNameKey != null
                        ? context.tr(tx.projectNameKey!)
                        : tx.counterpartyKey != null
                        ? context.tr(tx.counterpartyKey!)
                        : (tx.counterparty ?? ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.textLo, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${incoming ? '+' : '−'}${Fmt.token(tx.amount)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  Fmt.date(tx.timestamp),
                  style: TextStyle(color: p.textLo, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
