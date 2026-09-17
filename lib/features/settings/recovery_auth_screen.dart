import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/notifications/notification_center.dart';
import '../../core/security/secure_screen.dart';
import '../../core/security/sensitive_clipboard.dart';
import '../../core/security/wallet_session_store.dart';
import '../../core/theme/app_colors.dart';
import '../entry/entry_shared_widgets.dart';
import 'settings_widgets.dart';

enum _RevealStep { attention, pin, revealed }

class RecoveryAuthScreen extends StatefulWidget {
  const RecoveryAuthScreen({super.key});

  @override
  State<RecoveryAuthScreen> createState() => _RecoveryAuthScreenState();
}

class _RecoveryAuthScreenState extends State<RecoveryAuthScreen> {
  _RevealStep _step = _RevealStep.attention;
  final _pin = TextEditingController();
  final _pinFocus = FocusNode();
  String? _pinError;

  List<String>? _phraseWords;

  @override
  void initState() {
    super.initState();
    SecureScreen.enable();
  }

  @override
  void dispose() {
    SecureScreen.disable();
    _clipboard.dispose();
    _pin.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: SettingsAppBar(
        title: _step == _RevealStep.revealed
            ? context.tr('settings.recovery.title')
            : context.tr('settings.reveal.appBarTitle'),
        fallbackRoute: '/settings/recovery',
      ),
      body: SafeArea(
        child: switch (_step) {
          _RevealStep.attention => _attentionContent(context),
          _RevealStep.pin => _pinContent(context),
          _RevealStep.revealed => _revealedContent(context),
        },
      ),
    );
  }

  Widget _attentionContent(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFCEAE6),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              'assets/icons/auth/warning-badge.svg',
              width: 40,
              height: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('settings.reveal.attentionTitle'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: p.textHi,
            ),
          ),
          const SizedBox(height: 17),
          Text(
            context.tr('settings.reveal.attentionBody'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: p.textLo, height: 1.3),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                _AttentionRow(
                  asset: 'unlock',
                  title: context.tr('settings.reveal.fullAccessTitle'),
                  body: context.tr('settings.reveal.fullAccessBody'),
                ),
                const SizedBox(height: 32),
                _AttentionRow(
                  asset: 'eye-slash',
                  title: context.tr('settings.reveal.keepToYourselfTitle'),
                  body: context.tr('settings.reveal.keepToYourselfBody'),
                ),
                const SizedBox(height: 32),
                _AttentionRow(
                  asset: 'document-text',
                  title: context.tr('settings.reveal.storedSecurelyTitle'),
                  body: context.tr('settings.reveal.storedSecurelyBody'),
                ),
              ],
            ),
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
              onPressed: () {
                setState(() => _step = _RevealStep.pin);
                _pinFocus.requestFocus();
              },
              child: Text(
                context.tr('settings.reveal.continueWithPin'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: p.textHi,
                side: BorderSide(color: p.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.maybePop(context),
              child: Text(
                context.tr('common.cancel'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pinContent(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('settings.reveal.pinTitle'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: p.textHi,
            ),
          ),
          const SizedBox(height: 96),
          Center(
            child: SixBoxPinInput(
              controller: _pin,
              focusNode: _pinFocus,
              error: _pinError,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('settings.reveal.pinHelper'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: p.textLo),
          ),
          const Spacer(),
          ListenableBuilder(
            listenable: _pin,
            builder: (_, __) {
              final ready = _pin.text.length == 6;
              return SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ready
                        ? AppColors.gold
                        : const Color(0xFFE8E0D8),
                    foregroundColor: ready ? AppColors.lightTextHi : p.textLo,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: ready ? _verify : null,
                  child: Text(
                    context.tr('settings.reveal.verifyPin'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _revealedContent(BuildContext context) {
    final p = context.palette;
    final words = _phraseWords;
    if (words == null || words.isEmpty) {
      return Center(
        child: Text(
          context.tr('settings.reveal.unavailable'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('settings.reveal.phraseBody'),
            style: TextStyle(fontSize: 13, color: p.textLo),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF9),
                      border: Border.all(color: const Color(0xFFE7E0D9)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 152 / 40,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: words.length,
                          itemBuilder: (_, index) => Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3EEE8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${index + 1}. ${words[index]}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF181310),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF181310),
                                  side: const BorderSide(
                                    color: Color(0xFFE7E0D9),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => _downloadPhrase(words),
                                icon: AuthSvg(
                                  'download',
                                  size: 16,
                                  tint: p.textHi,
                                ),
                                label: Text(
                                  context.tr('wallet.create.step1.download'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: p.textHi,
                                  side: const BorderSide(
                                    color: Color(0xFFE7E0D9),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => _copyPhrase(words),
                                icon: AuthSvg('copy', size: 16, tint: p.textHi),
                                label: Text(
                                  context.tr('wallet.create.step1.copy'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    context.tr('settings.reveal.noScreenshot'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFC95E3C),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.lightTextHi,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go('/settings/recovery'),
              child: Text(
                context.tr('settings.reveal.writtenDown'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verify() async {
    if (_pin.text.length != 6) {
      setState(() => _pinError = context.tr('common.pin.incomplete'));
      return;
    }
    final valid = await WalletSessionStore.instance.verifyPin(_pin.text);
    if (!mounted) return;
    if (!valid) {
      setState(() => _pinError = context.tr('common.pin.incorrect'));
      _pin.clear();
      return;
    }
    final mnemonic = await WalletSessionStore.instance.readMnemonic();
    if (mnemonic != null) {
      await NotificationCenter.instance.notifySecurity(
        'notif.sec.phraseViewed.title',
        'notif.sec.phraseViewed.body',
      );
    }
    if (!mounted) return;
    setState(() {
      _step = _RevealStep.revealed;
      _phraseWords = mnemonic?.trim().split(RegExp(r'\s+'));
    });
  }

  final _clipboard = SensitiveClipboard();

  Future<void> _copyPhrase(List<String> words) async {
    await _clipboard.copy(words.join(' '));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.tr('wallet.create.step1.copied'))),
      );
  }

  Future<void> _downloadPhrase(List<String> words) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('wallet.create.step1.saveDigital')),
        content: Text(context.tr('wallet.create.step1.saveDigitalBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('wallet.create.step1.saveCancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('wallet.create.step1.saveContinue')),
          ),
        ],
      ),
    );
    if (proceed != true) return;
    await SharePlus.instance.share(ShareParams(text: words.join(' ')));
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.asset,
    required this.title,
    required this.body,
  });

  final String asset;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF3EEE8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: AuthSvg(asset, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF181310),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                body,
                style: TextStyle(fontSize: 12, color: p.textLo, height: 1.25),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
