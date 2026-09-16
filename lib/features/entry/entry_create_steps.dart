import 'package:flutter/material.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';

import 'entry_shared_widgets.dart';

class CreateIntroStep extends StatelessWidget {
  const CreateIntroStep({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      key: const ValueKey('create-intro'),
      children: [
        Text(
          context.tr('wallet.create.step0.header'),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('wallet.create.step0.body'),
          style: TextStyle(color: p.textLo, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 28),
        SafetyRow(
          asset: 'eye-slash',
          title: context.tr('wallet.create.step0.holdKeys'),
          body: context.tr('wallet.create.step0.holdKeysBody'),
        ),
        const SizedBox(height: 18),
        SafetyRow(
          asset: 'document-text',
          title: context.tr('wallet.create.step0.backupOffline'),
          body: context.tr('wallet.create.step0.backupOfflineBody'),
        ),
        const SizedBox(height: 18),
        SafetyRow(
          asset: 'unlock',
          title: context.tr('wallet.create.step0.protectDevice'),
          body: context.tr('wallet.create.step0.protectDeviceBody'),
        ),
      ],
    );
  }
}

class CreatePhraseStep extends StatelessWidget {
  const CreatePhraseStep({
    super.key,
    required this.words,
    required this.onDownload,
    required this.onCopy,
  });

  final List<String> words;
  final VoidCallback onDownload;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      key: const ValueKey('create-phrase'),
      children: [
        Text(
          context.tr('wallet.create.step1.header'),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          context.tr('wallet.create.step1.body'),
          style: TextStyle(color: p.textLo),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.15,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: words.length,
            itemBuilder: (_, index) => Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: p.border.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${index + 1}.  ${words[index]}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDownload,
                icon: AuthSvg('download', size: 16, tint: p.textHi),
                label: Text(context.tr('wallet.create.step1.download')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCopy,
                icon: AuthSvg('copy', size: 16, tint: p.textHi),
                label: Text(context.tr('wallet.create.step1.copy')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: AuthSvg('information_sign', size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr('wallet.create.step1.warning'),
                style: TextStyle(color: p.textLo, fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CreateVerifyStep extends StatelessWidget {
  const CreateVerifyStep({
    super.key,
    required this.verifyIndices,
    required this.verifyControllers,
    required this.verifyFailed,
    required this.onWordChanged,
  });

  final List<int> verifyIndices;
  final List<TextEditingController> verifyControllers;
  final bool verifyFailed;
  final VoidCallback onWordChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      key: const ValueKey('create-verify'),
      children: [
        Text(
          context.tr('wallet.create.step2.header'),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          context.tr('wallet.create.step2.body'),
          style: TextStyle(color: p.textLo),
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < verifyIndices.length; i++) ...[
          Text(
            context
                .tr('wallet.create.step2.wordLabel')
                .replaceFirst('{n}', '${verifyIndices[i] + 1}'),
            style: TextStyle(
              color: p.textLo,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: ValueKey('verify-word-${verifyIndices[i] + 1}'),
            controller: verifyControllers[i],
            onChanged: (_) => onWordChanged(),
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            decoration: outlinedFieldDecoration(
              context,
              hintText: context
                  .tr('wallet.create.step2.wordHint')
                  .replaceFirst('{n}', '${verifyIndices[i] + 1}'),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (verifyFailed)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.danger,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('wallet.create.step2.mismatchTitle'),
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.tr('wallet.create.step2.mismatchBody'),
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
    );
  }
}

class WalletCreated extends StatelessWidget {
  const WalletCreated({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SuccessCheck(),
                const SizedBox(height: 24),
                Text(
                  context.tr('wallet.create.done.title'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr('wallet.create.done.body'),
                  style: TextStyle(color: p.textLo),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: onOpen,
            child: Text(context.tr('wallet.create.done.open')),
          ),
        ),
      ],
    );
  }
}
