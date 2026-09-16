import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/constants/mpc_facts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/wallet_models.dart';
import '../../data/services/bsc_chain_service.dart';
import '../wallet/wallet_provider.dart';
import '../web/web_view_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.transaction});

  final WalletTransaction transaction;

  String _explorerTxUrl(BuildContext context) {
    final wallet = context.read<WalletProvider?>()?.state.data;
    final chain = context.read<BscChainService?>();
    if (wallet != null && !wallet.isDemo && chain != null) {
      return chain.config.explorerTxUrl(transaction.hash);
    }
    return '${MpcFacts.explorerBase}/tx/${transaction.hash}';
  }

  @override
  Widget build(BuildContext context) {
    final incoming = transaction.isIncoming;
    final statusLabel = switch (transaction.status) {
      TxStatus.submitted => context.tr('tx.status.submitted'),
      TxStatus.pending => context.tr('tx.status.pending'),
      TxStatus.confirmed => context.tr('tx.status.confirmed'),
      TxStatus.failed => context.tr('tx.status.failed'),
    };
    final statusColor = switch (transaction.status) {
      TxStatus.submitted || TxStatus.pending => AppColors.warning,
      TxStatus.confirmed => AppColors.positive,
      TxStatus.failed => AppColors.danger,
    };

    final cardDeco = BoxDecoration(
      color: context.palette.surface,
      border: Border.fromBorderSide(BorderSide(color: context.palette.border)),
      borderRadius: BorderRadius.all(Radius.circular(16)),
    );
    final labelStyle = TextStyle(fontSize: 12, color: context.palette.textLo);
    final divider = Divider(
      color: context.palette.border,
      height: 17,
      thickness: 1,
    );

    Widget detailRow(
      String label,
      String value, {
      bool bold = false,
      bool tappable = false,
    }) => GestureDetector(
      onTap: tappable
          ? () => context.push(
              '/webview',
              extra: WebViewArgs(
                url: _explorerTxUrl(context),
                title: 'BscScan',
              ),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: bold ? 14 : 13,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
                color: tappable ? AppColors.copper : context.palette.textHi,
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(context.tr('tx.details.title')),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: context.palette.circleButtonBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.back,
                  size: 16,
                  color: context.palette.textHi,
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            decoration: cardDeco,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  incoming ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 24,
                  color: incoming ? AppColors.positive : context.palette.textHi,
                ),
                const SizedBox(height: 16),
                Text(
                  '${incoming ? '+' : '−'}${Fmt.token(transaction.amount)} MPC',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: incoming
                        ? AppColors.positive
                        : context.palette.textHi,
                  ),
                ),
                const SizedBox(height: 16),
                Pill(statusLabel, color: statusColor),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: cardDeco,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                detailRow(
                  context.tr('tx.details.status'),
                  statusLabel,
                  bold: true,
                ),
                divider,
                detailRow(
                  incoming
                      ? context.tr('tx.details.from')
                      : context.tr('tx.details.to'),
                  transaction.counterparty ?? context.tr('tx.details.vault'),
                ),
                divider,
                detailRow(
                  context.tr('tx.details.date'),
                  Fmt.date(transaction.timestamp),
                  bold: true,
                ),
                divider,
                detailRow(context.tr('dash.network'), MpcFacts.network),
                divider,
                detailRow(
                  context.tr('tx.details.hash'),
                  Fmt.shortAddress(transaction.hash, lead: 6, tail: 4),
                  tappable: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
