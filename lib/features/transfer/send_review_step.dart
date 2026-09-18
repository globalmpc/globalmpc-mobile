import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';
import 'transfer_shared.dart';

class SendReviewStep extends StatelessWidget {
  const SendReviewStep({
    super.key,
    required this.amount,
    required this.recipientAddress,
    required this.bnbBalance,
    required this.networkFee,
    required this.feeUnavailable,
    required this.networkLabel,
    required this.onRetryFee,
    required this.onConfirm,
    required this.onEdit,
  });

  final double amount;
  final String recipientAddress;
  final double bnbBalance;

  /// Estimated fee in BNB, or null while the estimate is still loading.
  final double? networkFee;

  /// True when the node could not price the transfer; the user can retry.
  final bool feeUnavailable;
  final String networkLabel;
  final VoidCallback onRetryFee;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fee = networkFee;
    final hasEnoughBnb = fee == null || bnbBalance >= fee;

    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        Center(
          child: Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              'assets/brand/logo.svg',
              width: 27,
              height: 27,
              colorFilter: ColorFilter.mode(
                context.palette.textHi,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          context.tr('send.review.sending'),
          textAlign: TextAlign.center,
          style: TextStyle(color: p.textLo, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Text(
          context
              .tr('send.amountMpc')
              .replaceFirst('{amount}', Fmt.token(amount)),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Pill(networkLabel, color: AppColors.info)),
        const SizedBox(height: 28),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        context.tr('send.review.to'),
                        style: TextStyle(color: p.textLo, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        Fmt.shortAddress(recipientAddress, lead: 8, tail: 6),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: context.tr('send.review.copyRecipient'),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Clipboard.setData(
                        ClipboardData(text: recipientAddress),
                      ),
                      icon: const Icon(AppIcons.copy_rounded, size: 18),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: p.border),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showGasFeeInfo(context),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                context.tr('send.review.fee'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: p.textLo, fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SvgPicture.asset(
                              'assets/icons/auth/info-circle.svg',
                              width: 16,
                              height: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Flexible(child: _feeValue(context, fee, hasEnoughBnb)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SafetyNote(
          iconWidget: SvgPicture.asset(
            'assets/icons/auth/info-circle.svg',
            width: 28,
            height: 28,
          ),
          message: context.tr('send.review.note'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: fee == null ? null : onConfirm,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            foregroundColor: context.palette.textHi,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(context.tr('send.review.confirm')),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onEdit,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: context.palette.surface,
            side: BorderSide(color: p.border),
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
          child: Text(context.tr('send.review.edit')),
        ),
      ],
    );
  }

  Widget _feeValue(BuildContext context, double? fee, bool hasEnoughBnb) {
    final p = context.palette;
    if (feeUnavailable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            context.tr('send.review.feeUnavailable'),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextButton(
            onPressed: onRetryFee,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.copper,
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(context.tr('send.review.feeRetry')),
          ),
        ],
      );
    }
    if (fee == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: p.textLo),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              context.tr('send.review.estimating'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.textLo, fontSize: 14),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          context
              .tr('send.review.feeValue')
              .replaceFirst('{fee}', fee.toStringAsFixed(5)),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        if (!hasEnoughBnb) ...[
          const SizedBox(height: 3),
          Text(
            context.tr('send.review.notEnoughBnb'),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  void _showGasFeeInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/auth/info-circle.svg',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('send.gasInfo.title'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.palette.textHi,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, size: 20),
                    color: context.palette.textLo,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('send.gasInfo.body'),
                style: TextStyle(
                  fontSize: 14,
                  color: context.palette.textLo,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  foregroundColor: context.palette.textHi,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(context.tr('common.gotIt')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
