import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/wallet_models.dart';
import '../web/web_view_screen.dart';

class SendResultStep extends StatelessWidget {
  const SendResultStep({
    super.key,
    required this.success,
    required this.amount,
    required this.recipientAddress,
    required this.networkLabel,
    this.txHash,
    this.txStatus = TxStatus.submitted,
    this.explorerUrl,
    this.failureMessage,
    this.onRetry,
  });

  final bool success;
  final double amount;
  final String recipientAddress;
  final String networkLabel;

  /// Hash returned by the node. Present on every success: a send that has no
  /// hash was never broadcast and is not shown as a success.
  final String? txHash;

  /// Latest known chain status of [txHash], updated while this step is open.
  final TxStatus txStatus;
  final String? explorerUrl;

  /// Explanation shown on failure. Falls back to the generic copy.
  final String? failureMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 52),
      foregroundColor: context.palette.textHi,
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );
    final secondaryStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 52),
      backgroundColor: context.palette.surface,
      side: BorderSide(color: context.palette.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(16),
      foregroundColor: context.palette.textHi,
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );

    if (success) {
      return Column(
        children: [
          Expanded(child: _SuccessBody(step: this)),
          if (explorerUrl != null) ...[
            FilledButton(
              onPressed: () => context.push(
                '/webview',
                extra: WebViewArgs(
                  url: explorerUrl!,
                  title: context.tr('send.success.explorer'),
                ),
              ),
              style: buttonStyle,
              child: Text(context.tr('send.success.explorer')),
            ),
            const SizedBox(height: 16),
          ],
          OutlinedButton(
            onPressed: () => context.go('/wallet'),
            style: secondaryStyle,
            child: Text(context.tr('send.success.back')),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          // Centred while the explanation is short, scrollable once it is
          // not; a long reason must never push the buttons off screen.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/wallet/error_badge.svg',
                        width: 40,
                        height: 40,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        context.tr('send.failure.title'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: context.palette.textHi,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 17),
                      Text(
                        failureMessage ?? context.tr('send.failure.body'),
                        style: TextStyle(
                          fontSize: 13,
                          color: context.palette.textLo,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (onRetry != null) ...[
          FilledButton(
            onPressed: onRetry,
            style: buttonStyle,
            child: Text(context.tr('send.failure.retry')),
          ),
          const SizedBox(height: 16),
        ],
        OutlinedButton(
          onPressed: () => context.go('/wallet'),
          style: secondaryStyle,
          child: Text(context.tr('send.failure.cancel')),
        ),
      ],
    );
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({required this.step});

  final SendResultStep step;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final labelStyle = TextStyle(fontSize: 12, color: p.textLo);
    final valueStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: p.textHi,
    );
    final divider = Divider(color: p.cardDivider, height: 1, thickness: 1);
    final statusKey = switch (step.txStatus) {
      TxStatus.confirmed => 'send.success.confirmed',
      TxStatus.failed => 'send.success.failedOnChain',
      TxStatus.pending => 'send.success.stillPending',
      TxStatus.submitted => 'send.success.pending',
    };
    final statusColor = switch (step.txStatus) {
      TxStatus.confirmed => AppColors.positive,
      TxStatus.failed => AppColors.danger,
      _ => p.textHi,
    };

    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(flex: 2, child: Text(label, style: labelStyle)),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: value),
        ],
      ),
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFF0F0C0A),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/brand/mpc-token.svg',
                width: 40,
                height: 40,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.tr('send.success.headline'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: p.textHi,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          context
              .tr('send.success.body')
              .replaceFirst('{amount}', Fmt.token(step.amount))
              .replaceFirst(
                '{address}',
                Fmt.shortAddress(step.recipientAddress),
              ),
          style: TextStyle(fontSize: 13, color: p.textLo),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.fromBorderSide(BorderSide(color: p.border)),
            borderRadius: const BorderRadius.all(Radius.circular(16)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
          child: Column(
            children: [
              row(
                context.tr('send.success.status'),
                Text(
                  context.tr(statusKey),
                  textAlign: TextAlign.right,
                  style: valueStyle.copyWith(color: statusColor),
                ),
              ),
              divider,
              row(
                context.tr('send.amount'),
                Text(
                  '${Fmt.token(step.amount)} MPC',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: valueStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              divider,
              row(
                context.tr('dash.network'),
                Text(
                  step.networkLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: valueStyle,
                ),
              ),
              if (step.txHash != null) ...[
                divider,
                row(
                  context.tr('send.success.hash'),
                  _HashValue(hash: step.txHash!, style: valueStyle),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _HashValue extends StatelessWidget {
  const _HashValue({required this.hash, required this.style});

  final String hash;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            Fmt.shortAddress(hash, lead: 10, tail: 6),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: style.copyWith(fontFamily: AppTheme.monoFont),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: hash));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(context.tr('registry.copied'))),
              );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(
              AppIcons.copy_rounded,
              size: 16,
              color: context.palette.textLo,
            ),
          ),
        ),
      ],
    );
  }
}
