import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/security/wallet_key_service.dart';

import 'entry_shared_widgets.dart';

class ImportSafety extends StatelessWidget {
  const ImportSafety({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      children: [
        Text(
          context.tr('wallet.import.step0.header'),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('wallet.import.step0.body'),
          style: TextStyle(color: p.textLo, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 28),
        SafetyRow(
          asset: 'unlock',
          title: context.tr('wallet.import.step0.keepPrivate'),
          body: context.tr('wallet.import.step0.keepPrivateBody'),
        ),
        const SizedBox(height: 18),
        SafetyRow(
          asset: 'eye-slash',
          title: context.tr('wallet.import.step0.enterOnly'),
          body: context.tr('wallet.import.step0.enterOnlyBody'),
        ),
        const SizedBox(height: 18),
        SafetyRow(
          asset: 'document-text',
          title: context.tr('wallet.import.step0.stored'),
          body: context.tr('wallet.import.step0.storedBody'),
        ),
      ],
    );
  }
}

class PhraseEntry extends StatelessWidget {
  const PhraseEntry({
    super.key,
    required this.controller,
    required this.wordCount,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int wordCount;
  final String? error;
  final ValueChanged<String> onChanged;

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text case final text?) {
      controller.text = text;
      onChanged(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      children: [
        Text(
          context.tr('wallet.import.phrase.header'),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          context.tr('wallet.import.phrase.body'),
          style: TextStyle(color: p.textLo),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: isDark ? p.bg : p.surface,
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.tr('wallet.import.phrase.label'),
                    style: TextStyle(color: p.textLo, fontSize: 12),
                  ),
                  const Spacer(),
                  GoldPill(
                    'PASTE',
                    onTap: _paste,
                    textColor: AppColors.actionOrange,
                    backgroundColor: isDark ? p.surfaceHi : AppColors.pasteFill,
                  ),
                ],
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 15,
                      height: 1.0,
                    ),
                  ),
                ),
              TextField(
                controller: controller,
                onChanged: onChanged,
                maxLines: 4,
                autocorrect: false,
                enableSuggestions: false,
                cursorColor: p.textHi,
                style: TextStyle(fontSize: 15, height: 1.5, color: p.textHi),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  hintText: error == null
                      ? context.tr('wallet.import.phrase.hint')
                      : null,
                  hintStyle: TextStyle(color: p.textLo),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? p.surfaceHi
                      : p.border.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  context
                      .tr('wallet.phrase.words')
                      .replaceFirst('{count}', '$wordCount'),
                  style: TextStyle(
                    color: WalletKeyService.validWordCounts.contains(wordCount)
                        ? AppColors.positive
                        : p.textLo,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AddressReview extends StatelessWidget {
  const AddressReview({super.key, required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      children: [
        Text(
          context.tr('wallet.import.address.header'),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          context.tr('wallet.import.address.body'),
          style: TextStyle(color: p.textLo),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('wallet.import.address.label'),
                style: TextStyle(
                  color: p.textLo,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                address,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const GoldPill('BNB CHAIN', textColor: AppColors.rust),
            ],
          ),
        ),
      ],
    );
  }
}
