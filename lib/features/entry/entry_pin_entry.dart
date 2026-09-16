import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';

import 'entry_shared_widgets.dart';

class PinEntry extends StatefulWidget {
  const PinEntry({
    super.key,
    required this.title,
    required this.body,
    required this.controller,
    required this.error,
    required this.onChanged,
    this.showWalletSafeAlert = false,
  });

  final String title;
  final String body;
  final TextEditingController controller;
  final String? error;
  final ValueChanged<String> onChanged;

  final bool showWalletSafeAlert;

  @override
  State<PinEntry> createState() => _PinEntryState();
}

class _PinEntryState extends State<PinEntry> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final digits = widget.controller.text;
    final hasError = widget.error != null;

    return ListView(
      children: [
        Text(
          widget.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(widget.body, style: TextStyle(color: p.textLo, height: 1.45)),
        const SizedBox(height: 28),
        Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0,
              child: SizedBox(
                width: 1,
                height: 1,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  onChanged: widget.onChanged,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  decoration: const InputDecoration(counterText: ''),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _focusNode.requestFocus,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 6; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    PinBox(
                      char: i < digits.length ? digits[i] : null,
                      active:
                          !hasError &&
                          _focusNode.hasFocus &&
                          i == digits.length,
                      error: hasError,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          widget.error ?? context.tr('wallet.create.pin.hint'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: hasError ? AppColors.danger : p.textLo,
            fontSize: 12,
          ),
        ),
        if (widget.showWalletSafeAlert && hasError) ...[
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.alertFill,
              border: Border.all(color: AppColors.alertBorder),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: AuthSvg('information_sign', size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('wallet.create.pin.safeTitle'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.tr('wallet.create.pin.safeBody'),
                        style: TextStyle(
                          color: p.textLo,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
