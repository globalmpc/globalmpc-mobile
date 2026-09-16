import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/security/biometric_auth.dart';
import '../../core/security/secure_screen.dart';
import '../../core/security/wallet_key_service.dart';
import '../../core/security/wallet_lock_controller.dart';
import '../../core/security/wallet_session_store.dart';

import 'entry_shared_widgets.dart';
import 'entry_create_flow.dart';
import 'entry_import_steps.dart';
import 'entry_pin_entry.dart';
import 'entry_status_views.dart';
import 'entry_result_views.dart';

enum WalletEntryMode { create, import }

enum _ImportStep {
  safety,
  phrase,
  address,
  pin,
  confirmPin,
  biometrics,
  syncing,
  ready,
}

class WalletEntryFlowScreen extends StatefulWidget {
  const WalletEntryFlowScreen({
    super.key,
    required this.mode,
    this.isRestore = false,
  });

  final WalletEntryMode mode;
  final bool isRestore;

  @override
  State<WalletEntryFlowScreen> createState() => _WalletEntryFlowScreenState();
}

class _WalletEntryFlowScreenState extends State<WalletEntryFlowScreen> {
  static const _keys = WalletKeyService();

  String _derivedAddress = '';
  _ImportStep _step = _ImportStep.safety;
  final _phraseController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _biometrics = true;
  BiometricAvailability? _biometricAvailability;
  bool _saving = false;
  bool _securityFailed = false;
  bool _isRestore = false;
  String? _error;
  Timer? _syncTimer;

  bool get _isImport => widget.mode == WalletEntryMode.import;

  bool get _hideAppBar =>
      _step == _ImportStep.syncing ||
      (_step == _ImportStep.ready && !_isRestore);

  @override
  void initState() {
    super.initState();

    SecureScreen.enable();
    _loadBiometricAvailability();
    _isRestore = widget.isRestore;
  }

  Future<void> _loadBiometricAvailability() async {
    final avail = await BiometricAuth().availability();
    if (mounted) setState(() => _biometricAvailability = avail);
  }

  @override
  void dispose() {
    SecureScreen.disable();
    _syncTimer?.cancel();
    _phraseController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isImport) return const CreateWalletFlow();

    if (_securityFailed) {
      return SecurityFailedView(
        onRetry: () {
          setState(() => _securityFailed = false);
          _continue();
        },
        onReturnToWelcome: () => context.go('/onboarding'),
      );
    }

    final p = context.palette;
    final index = _ImportStep.values.indexOf(_step);

    return Theme(
      data: Theme.of(context),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: p.bg,
          appBar: _hideAppBar
              ? null
              : AppBar(
                  centerTitle: true,
                  title: Text(
                    context.tr(
                      _step == _ImportStep.ready
                          ? 'wallet.import.secure'
                          : 'wallet.import.title',
                    ),
                  ),
                  leading: FlowBackButton(onPressed: _back),
                ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index < 6) ...[
                    Progress(current: index, total: 6),
                    const SizedBox(height: 28),
                  ],
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _content(context),
                    ),
                  ),
                  if (_showPrimaryButton) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _primaryEnabled ? _continue : null,
                        child: Text(_primaryLabel(context)),
                      ),
                    ),
                    if (_step == _ImportStep.phrase) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AuthSvg('information_sign', size: 12),
                          const SizedBox(width: 6),
                          Text(
                            context.tr('wallet.import.phrase.support'),
                            style: TextStyle(color: p.textLo, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _showPrimaryButton =>
      _step != _ImportStep.syncing && _step != _ImportStep.ready;

  bool get _primaryEnabled {
    if (_saving) return false;
    switch (_step) {
      case _ImportStep.pin:
        return _pinController.text.length == 6;
      case _ImportStep.confirmPin:
        return _confirmPinController.text.length == 6;
      default:
        return true;
    }
  }

  int get _wordCount {
    final value = _phraseController.text.trim();
    return value.isEmpty ? 0 : value.split(RegExp(r'\s+')).length;
  }

  String _primaryLabel(BuildContext context) {
    switch (_step) {
      case _ImportStep.safety:
        return context.tr('wallet.import.step0.understand');
      case _ImportStep.phrase:
        return context.tr('wallet.import.phrase.review');
      case _ImportStep.address:
        return context.tr('wallet.import.address.confirm');
      case _ImportStep.pin:
        return context.tr('wallet.create.pin.continue');
      case _ImportStep.confirmPin:
        return _error != null
            ? context.tr('wallet.create.pin.reEnter')
            : context.tr('wallet.create.pin.confirm');
      case _ImportStep.biometrics:
        return _saving
            ? context.tr('wallet.create.securing.inProgress')
            : context.tr('wallet.import.biometric.finish');
      default:
        return context.tr('wallet.create.pin.continue');
    }
  }

  Widget _content(BuildContext context) {
    switch (_step) {
      case _ImportStep.safety:
        return const ImportSafety(key: ValueKey('safety'));
      case _ImportStep.phrase:
        return PhraseEntry(
          key: const ValueKey('phrase'),
          controller: _phraseController,
          wordCount: _wordCount,
          error: _error,
          onChanged: (_) => setState(() => _error = null),
        );
      case _ImportStep.address:
        return AddressReview(
          key: const ValueKey('address'),
          address: _derivedAddress,
        );
      case _ImportStep.pin:
        return PinEntry(
          key: const ValueKey('pin'),
          title: context.tr('wallet.create.pin.createTitle'),
          body: context.tr('wallet.create.pin.createBody'),
          controller: _pinController,
          error: null,
          onChanged: (_) => setState(() {}),
        );
      case _ImportStep.confirmPin:
        return PinEntry(
          key: const ValueKey('confirm'),
          title: context.tr('wallet.create.pin.confirmTitle'),
          body: context.tr('wallet.create.pin.confirmBody'),
          controller: _confirmPinController,
          error: _error,
          showWalletSafeAlert: true,
          onChanged: (_) => setState(() => _error = null),
        );
      case _ImportStep.biometrics:
        return BiometricChoice(
          key: const ValueKey('biometrics'),
          enabled: _biometrics,
          onChanged: (value) => setState(() => _biometrics = value),
          availability: _biometricAvailability,
        );
      case _ImportStep.syncing:
        return _isRestore
            ? const Syncing(key: ValueKey('syncing'))
            : Syncing(
                key: const ValueKey('syncing'),
                title: context.tr('wallet.import.syncing.title'),
                body: context.tr('wallet.import.syncing.body'),
                showKeepOpenBanner: false,
              );
      case _ImportStep.ready:
        return Ready(
          key: const ValueKey('ready'),
          onOpen: () => openWallet(context),
          isRestore: _isRestore,
        );
    }
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    switch (_step) {
      case _ImportStep.safety:
        setState(() => _step = _ImportStep.phrase);
      case _ImportStep.phrase:
        final phrase = _phraseController.text;
        if (phrase.trim().isEmpty) {
          setState(
            () => _error = context.tr('wallet.import.phrase.errorEmpty'),
          );
          return;
        }
        if (!_keys.validateMnemonic(phrase)) {
          setState(
            () => _error = context.tr('wallet.import.phrase.errorInvalid'),
          );
          return;
        }
        setState(() {
          _derivedAddress = _keys.deriveAddress(phrase);
          _step = _ImportStep.address;
        });
      case _ImportStep.address:
        setState(() => _step = _ImportStep.pin);
      case _ImportStep.pin:
        setState(() => _step = _ImportStep.confirmPin);
      case _ImportStep.confirmPin:
        if (_error != null) {
          setState(() {
            _confirmPinController.clear();
            _error = null;
          });
        } else if (_pinController.text != _confirmPinController.text) {
          setState(() => _error = context.tr('wallet.create.pin.mismatch'));
        } else {
          setState(() => _step = _ImportStep.biometrics);
        }
      case _ImportStep.biometrics:
        setState(() => _saving = true);
        try {
          await WalletSessionStore.instance.saveWalletSecrets(
            mnemonic: _phraseController.text.trim(),
            address: _derivedAddress,
          );
          await WalletSessionStore.instance.configure(
            pin: _pinController.text,
            biometrics:
                _biometrics &&
                _biometricAvailability == BiometricAvailability.ready,
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
        setState(() => _step = _ImportStep.syncing);
        _syncTimer = Timer(const Duration(milliseconds: 1300), () {
          if (mounted) setState(() => _step = _ImportStep.ready);
        });
      case _ImportStep.syncing:
      case _ImportStep.ready:
        break;
    }
  }

  void _back() {
    if (_step == _ImportStep.safety) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/onboarding');
      }
      return;
    }
    final index = _ImportStep.values.indexOf(_step);
    setState(() {
      _error = null;
      _step = _ImportStep.values[index - 1];
    });
  }
}
