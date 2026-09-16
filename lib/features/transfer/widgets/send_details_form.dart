import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/mpc_facts.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/thousands_amount_formatter.dart';
import '../transfer_shared.dart';

class SendDetailsForm extends StatelessWidget {
  const SendDetailsForm({
    super.key,
    required this.available,
    required this.addressController,
    required this.amountController,
    required this.addressError,
    required this.amountError,
    required this.onSubmit,
    required this.onPasteAddress,
    required this.onAddressChanged,
    required this.onAmountChanged,
    required this.onUseMax,
  });

  final double available;
  final TextEditingController addressController;
  final TextEditingController amountController;
  final String? addressError;
  final String? amountError;
  final VoidCallback onSubmit;
  final VoidCallback onPasteAddress;
  final VoidCallback onAddressChanged;
  final VoidCallback onAmountChanged;
  final VoidCallback onUseMax;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: context.palette.textLo,
    );
    BoxDecoration fieldDeco(bool hasError) => BoxDecoration(
      color: context.palette.surface,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      border: Border.fromBorderSide(
        BorderSide(
          color: hasError
              ? context.palette.inputErrorBorder
              : context.palette.border,
        ),
      ),
    );
    const bareField = InputDecoration(
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      isDense: true,
    );
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              Container(
                height: 62,
                decoration: BoxDecoration(
                  color: context.palette.surface,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  border: Border.fromBorderSide(
                    BorderSide(color: context.palette.border),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.palette.tokenChipBg,
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        'assets/brand/mpc-token.svg',
                        width: 20,
                        height: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            MpcFacts.tokenName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.palette.textHi,
                            ),
                          ),
                          Text(
                            'BNB Smart Chain',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.palette.textLo,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 124),
                      child: Text(
                        context
                            .tr('send.available')
                            .replaceFirst('{amount}', Fmt.token(available)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.palette.textLo,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('send.recipient'), style: labelStyle),
                  const SizedBox(height: 8),
                  Container(
                    height: 64,
                    decoration: fieldDeco(addressError != null),
                    padding: const EdgeInsets.fromLTRB(14, 0, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: addressController,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(
                              fontSize: 14,
                              color: addressError != null
                                  ? const Color(0xFFC9543C)
                                  : context.palette.textHi,
                            ),
                            decoration: bareField.copyWith(
                              hintText: context.tr('send.recipientHint'),
                              hintStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: context.palette.textLo,
                              ),
                            ),
                            onChanged: (_) => onAddressChanged(),
                          ),
                        ),
                        GestureDetector(
                          onTap: onPasteAddress,
                          child: Container(
                            width: 56,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: context.palette.pasteBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              context.tr('send.paste'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.actionOrange,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (addressError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      addressError!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFC9543C),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('send.amount'), style: labelStyle),
                  const SizedBox(height: 8),
                  Container(
                    height: 64,
                    decoration: fieldDeco(amountError != null),
                    padding: const EdgeInsets.fromLTRB(14, 0, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: const [ThousandsAmountFormatter()],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: amountError != null
                                  ? const Color(0xFFC9543C)
                                  : context.palette.textHi,
                            ),
                            decoration: bareField.copyWith(
                              hintText: '0',
                              hintStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: context.palette.textLo,
                              ),
                            ),
                            onChanged: (_) => onAmountChanged(),
                          ),
                        ),
                        Text(
                          MpcFacts.tokenName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.palette.textLo,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (amountError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      amountError!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFC95E3C),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: onUseMax,
                      child: Text(
                        context.tr('send.useMax'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.copper,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SafetyNote(
                iconWidget: SvgPicture.asset(
                  'assets/icons/auth/info-circle-filled.svg',
                  width: 28,
                  height: 28,
                ),
                message: context.tr('send.safety'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onSubmit,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            foregroundColor: context.palette.textHi,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(context.tr('send.review.cta')),
        ),
      ],
    );
  }
}
