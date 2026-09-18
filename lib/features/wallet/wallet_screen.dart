import 'package:flutter/material.dart';
import 'package:mpc_mining_app/core/theme/app_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/wallet_error_state.dart';
import '../../data/models/wallet_models.dart';
import 'wallet_provider.dart';
import '../../core/widgets/glass_card.dart';
import 'widgets/wallet_balance_card.dart';
import 'widgets/wallet_activity.dart';

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
            icon: SvgPicture.asset(
              'assets/icons/dashboard/setting-2.svg',
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: switch (state.status) {
          _ when state.isLoading => _WalletLoadingBody(onRetry: provider.load),
          _ when state.isError => _WalletErrorBody(onRetry: provider.load),
          _ when state.isSuccess => _WalletBody(account: state.data!),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _WalletErrorBody extends StatelessWidget {
  const _WalletErrorBody({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return WalletErrorState(
      title: context.tr('wallet.unavailable'),
      message: context.tr('wallet.unavailableBody'),
      retryLabel: context.tr('wallet.tryAgain'),
      onRetry: onRetry,
    );
  }
}

class _WalletLoadingBody extends StatelessWidget {
  const _WalletLoadingBody({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFFF5B942),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('wallet.loading.title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: context.palette.textHi,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.tr('wallet.loading.body'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: p.textLo),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: context.palette.textHi,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(context.tr('wallet.tryAgain')),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SectionHeader(context.tr('wallet.activity')),
        const SizedBox(height: 12),
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: 66,
            decoration: BoxDecoration(
              color: context.palette.pillNeutralBg,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _WalletBody extends StatelessWidget {
  const _WalletBody({required this.account});
  final WalletAccount account;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const SizedBox(height: 12),
        WalletBalanceCard(account: account),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              SectionHeader(context.tr('wallet.allocations')),
              const SizedBox(height: 12),
              WalletAllocationCard(account: account),
              const SizedBox(height: 22),
              SectionHeader(
                context.tr('wallet.activity'),
                action: account.transactions.isNotEmpty
                    ? GestureDetector(
                        onTap: () => context.push('/wallet/transactions'),
                        child: const Text(
                          'See all',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.copper,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              if (account.historyUnavailable)
                GlassCard(
                  child: StateMessage(
                    icon: AppIcons.cloud_off_outlined,
                    title: context.tr('wallet.historyUnavailable'),
                    message: context.tr('wallet.historyUnavailableBody'),
                    onRetry: context.read<WalletProvider>().load,
                    contentWidth: 250,
                  ),
                )
              else if (account.transactions.isEmpty)
                GlassCard(
                  child: StateMessage(
                    icon: AppIcons.inbox_outlined,
                    iconWidget: SvgPicture.asset(
                      'assets/icons/wallet/empty-transactions.svg',
                      width: 58,
                      height: 77,
                    ),
                    title: context.tr('wallet.noTransactions'),
                    message: context.tr('wallet.noTransactionsBody'),
                    contentWidth: 250,
                  ),
                )
              else
                for (final tx in account.transactions) ...[
                  WalletTxTile(tx: tx),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ],
    );
  }
}
