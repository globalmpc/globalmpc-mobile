import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/security/phrase_check.dart';
import '../../core/security/secure_screen.dart';
import '../../core/security/wallet_session_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../entry/entry_shared_widgets.dart';
import 'settings_widgets.dart';

class RecoverySettingsScreen extends StatelessWidget {
  const RecoverySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleSettingsPage(
      title: context.tr('settings.recovery.title'),
      children: [
        FutureBuilder<bool>(
          future: WalletSessionStore.instance.isBackupVerified(),
          builder: (context, snapshot) {
            final verified = snapshot.data ?? false;
            return GlassCard(
              accent: verified ? AppColors.positive : AppColors.warning,
              child: Row(
                children: [
                  Icon(
                    verified
                        ? Icons.check_circle_outline_rounded
                        : Icons.error_outline_rounded,
                    color: verified ? AppColors.positive : AppColors.warning,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            verified
                                ? 'settings.recovery.verifiedTitle'
                                : 'settings.recovery.notVerified',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (!verified) ...[
                          const SizedBox(height: 3),
                          Text(context.tr('settings.recovery.notVerifiedBody')),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        GlassCard(
          accent: AppColors.warning,
          child: Column(
            children: [
              const Icon(Icons.visibility_off_outlined, size: 42),
              const SizedBox(height: 16),
              Text(
                context.tr('settings.recovery.controls'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('settings.recovery.neverShare'),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.push('/settings/recovery/auth'),
          child: Text(context.tr('settings.recovery.view')),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => context.push('/settings/recovery/verify'),
          child: Text(context.tr('settings.recovery.verify')),
        ),
      ],
    );
  }
}

class VerifyBackupScreen extends StatefulWidget {
  const VerifyBackupScreen({super.key});

  @override
  State<VerifyBackupScreen> createState() => _VerifyBackupScreenState();
}

class _VerifyBackupScreenState extends State<VerifyBackupScreen> {
  static const _checkCount = 3;

  final _pin = TextEditingController();
  final List<TextEditingController> _checkControllers = List.generate(
    _checkCount,
    (_) => TextEditingController(),
  );
  String? _pinError;
  bool _authorized = false;

  List<String>? _words;

  List<int>? _checkIndices;
  bool _checked = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    SecureScreen.enable();
  }

  @override
  void dispose() {
    SecureScreen.disable();
    _pin.dispose();
    for (final controller in _checkControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_pin.text.length != 6) {
      setState(() => _pinError = context.tr('common.pin.incomplete'));
      return;
    }
    final valid = await WalletSessionStore.instance.verifyPin(_pin.text);
    if (!mounted) return;
    if (!valid) {
      setState(() => _pinError = context.tr('common.pin.incorrect'));
      return;
    }
    final mnemonic = await WalletSessionStore.instance.readMnemonic();
    if (!mounted) return;
    final words = mnemonic?.trim().split(RegExp(r'\s+'));
    setState(() {
      _authorized = true;
      _words = words;
      _checkIndices = words == null
          ? null
          : pickPhraseCheckIndices(words.length, _checkCount);
    });
  }

  List<Widget> _authContent(BuildContext context) => [
    const Icon(Icons.lock_outline_rounded, size: 48),
    const SizedBox(height: 18),
    Text(
      context.tr('settings.reveal.subtitle'),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 28),
    PinField(
      controller: _pin,
      label: context.tr('settings.reveal.pinLabel'),
      error: _pinError,
    ),
    const SizedBox(height: 24),
    FilledButton(
      onPressed: _unlock,
      child: Text(context.tr('settings.reveal.cta')),
    ),
  ];

  bool get _allWordsEntered =>
      _checkControllers.every((c) => c.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final words = _words;
    final indices = _checkIndices;
    final ready =
        _authorized && words != null && indices != null && words.length >= 12;
    return SimpleSettingsPage(
      title: context.tr('settings.verify.title'),
      children: [
        if (!_authorized)
          ..._authContent(context)
        else if (!ready)
          Text(
            context.tr('settings.verify.unavailable'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          )
        else ...[
          Text(
            context.tr('settings.verify.body'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('settings.verify.local'),
            style: TextStyle(color: context.palette.textLo),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < indices.length; i++) ...[
            Text(
              context
                  .tr('settings.verify.word')
                  .replaceFirst('{n}', '${indices[i] + 1}'),
              style: TextStyle(
                color: context.palette.textLo,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: ValueKey('verify-word-${indices[i] + 1}'),
              controller: _checkControllers[i],
              onChanged: (_) => setState(() => _error = null),
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              decoration: outlinedFieldDecoration(
                context,
                hintText: context
                    .tr('settings.verify.hint')
                    .replaceFirst('{n}', '${indices[i] + 1}'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _checked,
            onChanged: (v) => setState(() => _checked = v ?? false),
            title: Text(context.tr('settings.verify.stored')),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _allWordsEntered && _checked ? _confirm : null,
            child: Text(context.tr('settings.verify.mark')),
          ),
        ],
      ],
    );
  }

  Future<void> _confirm() async {
    final words = _words!;
    final matches = phraseCheckMatches(
      words: words,
      indices: _checkIndices!,
      answers: [for (final c in _checkControllers) c.text],
    );
    if (!matches) {
      setState(() {
        _error = context.tr('settings.verify.wrong');
        _checkIndices = pickPhraseCheckIndices(words.length, _checkCount);
        for (final controller in _checkControllers) {
          controller.clear();
        }
      });
      return;
    }
    await WalletSessionStore.instance.setBackupVerified(true);
    if (!mounted) return;
    context.push('/settings/recovery/verified');
  }
}

class BackupVerifiedScreen extends StatelessWidget {
  const BackupVerifiedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: SettingsAppBar(
        title: context.tr('settings.recovery.verifiedTitle'),
        fallbackRoute: '/settings/recovery',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFF2AA66A).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(44),
                ),
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2AA66A),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.tr('settings.verified.headline'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: p.textHi,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('settings.verified.body'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: p.textLo, height: 1.45),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.lightTextHi,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => context.go('/settings'),
                  child: Text(
                    context.tr('common.done'),
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
