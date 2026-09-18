import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/security/biometric_auth.dart';
import '../../core/security/phrase_check.dart';
import '../../core/security/secure_screen.dart';
import '../../core/security/sensitive_clipboard.dart';
import '../../core/security/wallet_key_service.dart';
import '../../core/security/wallet_lock_controller.dart';
import '../../core/security/wallet_session_store.dart';

import 'entry_shared_widgets.dart';
import 'entry_status_views.dart';
import 'entry_result_views.dart';
import 'entry_create_steps.dart';
import 'entry_pin_entry.dart';

class CreateWalletFlow extends StatefulWidget {
  const CreateWalletFlow({super.key});

  @override
  State<CreateWalletFlow> createState() => _CreateWalletFlowState();
}

class _CreateWalletFlowState extends State<CreateWalletFlow> {
  static const _keys = WalletKeyService();

  final String _mnemonic = _keys.generateMnemonic();
  late final List<String> _words = _mnemonic.split(' ');

  static const _verifyCount = 3;

  late List<int> _verifyIndices = pickPhraseCheckIndices(
    _words.length,
    _verifyCount,
  );
  final List<TextEditingController> _verifyControllers = List.generate(
    _verifyCount,
    (_) => TextEditingController(),
  );

  int _step = 0;
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _verifyFailed = false;
  bool _biometrics = true;
  BiometricAvailability? _biometricAvailability;
  bool _saving = false;
  bool _securityFailed = false;
  String? _error;
  final _clipboard = SensitiveClipboard();
  Timer? _creatingTimer;

  @override
  void initState() {
    super.initState();

    SecureScreen.enable();
    _loadBiometricAvailability();
  }

  Future<void> _loadBiometricAvailability() async {
    final avail = await BiometricAuth().availability();
    if (mounted) setState(() => _biometricAvailability = avail);
  }

  @override
  void dispose() {
    SecureScreen.disable();
    _clipboard.dispose();
    _creatingTimer?.cancel();
    for (final controller in _verifyControllers) {
      controller.dispose();
    }
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_securityFailed) {
      return SecurityFailedView(
        onRetry: () {
          setState(() => _securityFailed = false);
          _continueCreate();
        },
        onReturnToWelcome: () => context.go('/onboarding'),
      );
    }

    final p = context.palette;
    return Theme(
      data: Theme.of(context),

      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: p.bg,
          appBar: _step >= 6
              ? null
              : AppBar(
                  centerTitle: true,
                  title: Text(context.tr('wallet.create.title')),
                  leading: FlowBackButton(onPressed: _back),
                ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_step < 6) ...[
                    Progress(current: _step, total: 6),
                    const SizedBox(height: 28),
                  ],
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _createContent(context),
                    ),
                  ),
                  if (_step < 6) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _createCanContinue ? _continueCreate : null,
                        child: Text(_createPrimaryLabel(context)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _createCanContinue {
    if (_saving) return false;
    if (_step == 2) {
      return _verifyControllers.every((c) => c.text.trim().isNotEmpty);
    }
    if (_step == 3) return _pinController.text.length == 6;
    if (_step == 4) return _confirmController.text.length == 6;
    return true;
  }

  String _createPrimaryLabel(BuildContext context) {
    switch (_step) {
      case 0:
        return context.tr('wallet.create.step0.button');
      case 1:
        return context.tr('wallet.create.step1.saved');
      case 2:
        return context.tr('wallet.create.step2.button');
      case 3:
        return context.tr('wallet.create.pin.continue');
      case 4:
        return _error != null
            ? context.tr('wallet.create.pin.reEnter')
            : context.tr('wallet.create.pin.confirm');
      case 5:
        return _saving
            ? context.tr('wallet.create.securing.inProgress')
            : context.tr('wallet.create.biometric.finish');
      default:
        return context.tr('wallet.create.pin.continue');
    }
  }

  Widget _createContent(BuildContext context) {
    switch (_step) {
      case 0:
        return const CreateIntroStep();
      case 1:
        return CreatePhraseStep(
          words: _words,
          onDownload: _downloadPhrase,
          onCopy: _copyPhrase,
        );
      case 2:
        return CreateVerifyStep(
          verifyIndices: _verifyIndices,
          verifyControllers: _verifyControllers,
          verifyFailed: _verifyFailed,
          onWordChanged: () => setState(() => _verifyFailed = false),
        );
      case 3:
        return PinEntry(
          key: const ValueKey('create-pin'),
          title: context.tr('wallet.create.pin.createTitle'),
          body: context.tr('wallet.create.pin.createBody'),
          controller: _pinController,
          error: null,
          onChanged: (_) => setState(() {}),
        );
      case 4:
        return PinEntry(
          key: const ValueKey('create-confirm'),
          title: context.tr('wallet.create.pin.confirmTitle'),
          body: context.tr('wallet.create.pin.confirmBody'),
          controller: _confirmController,
          error: _error,
          showWalletSafeAlert: true,
          onChanged: (_) => setState(() => _error = null),
        );
      case 5:
        return BiometricChoice(
          key: const ValueKey('create-biometric'),
          enabled: _biometrics,
          onChanged: (value) => setState(() => _biometrics = value),
          availability: _biometricAvailability,
        );
      case 6:
        return Syncing(
          key: const ValueKey('creating'),
          title: context.tr('wallet.create.securing.title'),
          body: context.tr('wallet.create.securing.body'),
          showKeepOpenBanner: false,
        );
      default:
        return WalletCreated(
          key: const ValueKey('created'),
          onOpen: () => openWallet(context),
        );
    }
  }

  Future<void> _continueCreate() async {
    FocusScope.of(context).unfocus();
    if (_step == 2) {
      final allCorrect = phraseCheckMatches(
        words: _words,
        indices: _verifyIndices,
        answers: [for (final c in _verifyControllers) c.text],
      );
      if (!allCorrect) {
        setState(() {
          _verifyFailed = true;
          _verifyIndices = pickPhraseCheckIndices(_words.length, _verifyCount);
          for (final controller in _verifyControllers) {
            controller.clear();
          }
        });
        return;
      }
    }
    if (_step == 4 && _error != null) {
      setState(() {
        _confirmController.clear();
        _error = null;
      });
      return;
    }
    if (_step == 4 && _pinController.text != _confirmController.text) {
      setState(() => _error = 'PINs do not match. Try again.');
      return;
    }
    if (_step == 5) {
      final biometrics = await _proveBiometrics();
      if (!mounted) return;
      setState(() => _saving = true);
      try {
        await WalletSessionStore.instance.saveWalletSecrets(
          mnemonic: _mnemonic,
          address: _keys.deriveAddress(_mnemonic),
        );
        await WalletSessionStore.instance.configure(
          pin: _pinController.text,
          biometrics: biometrics,
        );

        WalletLockController.instance.markWalletCreated();
      } catch (_) {
        if (mounted) {
          setState(() {
            _saving = false;
            _securityFailed = true;
          });
        }
        return;
      }
      if (!mounted) return;
      setState(() => _saving = false);
      setState(() => _step = 6);
      _creatingTimer = Timer(const Duration(milliseconds: 1300), () {
        if (mounted) setState(() => _step = 7);
      });
      return;
    }
    if (_step < 6) setState(() => _step += 1);
  }

  Future<void> _copyPhrase() async {
    await _clipboard.copy(_mnemonic);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.tr('wallet.create.step1.copied'))),
      );
  }

  Future<void> _downloadPhrase() async {
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
    await SharePlus.instance.share(ShareParams(text: _mnemonic));
  }

  /// Biometric unlock is only stored as on after one successful prompt, so
  /// the system permission is asked for here, where the user just chose it,
  /// rather than at the first unlock. Anything short of success leaves it
  /// off and says so; the wallet is still created.
  Future<bool> _proveBiometrics() async {
    if (!_biometrics ||
        _biometricAvailability != BiometricAvailability.ready) {
      return false;
    }
    final result = await WalletLockController.instance.runSystemPrompt(
      () => BiometricAuth().authenticate(
        reason: context.tr('settings.bio.authReason'),
      ),
    );
    if (!mounted) return false;
    if (result == BiometricResult.success) return true;
    final messageKey = biometricMessageKey(result);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            context.tr(messageKey ?? 'wallet.create.biometric.skipped'),
          ),
        ),
      );
    return false;
  }

  void _back() {
    if (_step == 0) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/onboarding');
      }
    } else {
      setState(() {
        _error = null;
        _verifyFailed = false;
        _step -= 1;
      });
    }
  }
}
