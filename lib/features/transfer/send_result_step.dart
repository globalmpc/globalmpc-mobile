import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/mpc_facts.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

class SendResultStep extends StatelessWidget {
  const SendResultStep({
    super.key,
    required this.success,
    required this.amount,
    required this.recipientAddress,
    this.onRetry,
  });

  final bool success;
  final double amount;
  final String recipientAddress;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 52),
      foregroundColor: context.palette.textHi,
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );

    final cardDeco = BoxDecoration(
      color: context.palette.surface,
      border: Border.fromBorderSide(BorderSide(color: context.palette.border)),
      borderRadius: BorderRadius.all(Radius.circular(16)),
    );
    final labelStyle = TextStyle(fontSize: 12, color: context.palette.textLo);
    final divider = Divider(
      color: context.palette.cardDivider,
      height: 1,
      thickness: 1,
    );

    if (success) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Container(
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
          const SizedBox(height: 16),
          Text(
            context.tr('send.success.headline'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: context.palette.textHi,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            context
                .tr('send.success.body')
                .replaceFirst('{amount}', Fmt.token(amount))
                .replaceFirst('{address}', Fmt.shortAddress(recipientAddress)),
            style: TextStyle(fontSize: 13, color: context.palette.textLo),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: cardDeco,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.tr('send.success.status'), style: labelStyle),
                    Flexible(
                      child: Text(
                        context.tr('send.success.pending'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.palette.textHi,
                        ),
                      ),
                    ),
                  ],
                ),
                divider,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.tr('send.amount'), style: labelStyle),
                    Flexible(
                      child: Text(
                        '${Fmt.token(amount)} MPC',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.palette.textHi,
                        ),
                      ),
                    ),
                  ],
                ),
                divider,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.tr('dash.network'), style: labelStyle),
                    Flexible(
                      child: Text(
                        MpcFacts.network,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.palette.textHi,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => context.pushReplacement('/wallet/transactions'),
            style: buttonStyle,
            child: Text(context.tr('send.success.view')),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.go('/wallet'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: context.palette.cardDivider,
              side: BorderSide(color: context.palette.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.fromLTRB(10, 16, 10, 18),
              foregroundColor: context.palette.textHi,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(context.tr('send.success.back')),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
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
                  context.tr('send.failure.body'),
                  style: TextStyle(fontSize: 13, color: context.palette.textLo),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        FilledButton(
          onPressed: onRetry,
          style: buttonStyle,
          child: Text(context.tr('send.failure.retry')),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => context.go('/wallet'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: context.palette.surface,
            side: BorderSide(color: context.palette.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            foregroundColor: context.palette.textHi,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(context.tr('send.failure.cancel')),
        ),
      ],
    );
  }
}
