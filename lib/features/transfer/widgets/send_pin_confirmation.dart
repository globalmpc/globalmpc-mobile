import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class SendPinConfirmation extends StatelessWidget {
  const SendPinConfirmation({
    super.key,
    required this.pinController,
    required this.pinFocusNode,
    required this.amountValue,
    required this.pinError,
    required this.onPinChanged,
    required this.onConfirm,
  });

  final TextEditingController pinController;
  final FocusNode pinFocusNode;
  final double amountValue;
  final String? pinError;
  final VoidCallback onPinChanged;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final hasError = pinError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('send.pin.prompt'),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: context.palette.textHi,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          context
              .tr('send.pin.confirm')
              .replaceFirst('{amount}', Fmt.token(amountValue)),
          style: TextStyle(fontSize: 13, color: context.palette.textLo),
        ),
        const SizedBox(height: 60),

        SizedBox(
          height: 50,
          child: Stack(
            children: [
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(6, (i) {
                    final filled = i < pinController.text.length;
                    final isActive =
                        i == pinController.text.length && !hasError;
                    return Container(
                      width: 42,
                      height: 50,
                      margin: EdgeInsets.only(right: i < 5 ? 13 : 0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.palette.pinBoxBg,
                        border: Border.all(
                          color: hasError
                              ? context.palette.inputErrorBorder
                              : isActive
                              ? AppColors.copper
                              : context.palette.border,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: filled
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: context.palette.textHi,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    );
                  }),
                ),
              ),

              Positioned.fill(
                child: TextField(
                  controller: pinController,
                  focusNode: pinFocusNode,
                  autofocus: true,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    color: Colors.transparent,
                    fontSize: 1,
                  ),
                  cursorColor: Colors.transparent,
                  cursorWidth: 0,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    counterText: '',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => onPinChanged(),
                  onSubmitted: (_) => onConfirm(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: Text(
            context.tr('send.pin.hint'),
            style: TextStyle(fontSize: 12, color: context.palette.textLo),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              pinError!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFC9543C)),
            ),
          ),
        ],
        const Spacer(),
        FilledButton(
          onPressed: pinController.text.length == 6 ? onConfirm : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            foregroundColor: context.palette.textHi,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(context.tr('send.title')),
        ),
      ],
    );
  }
}
