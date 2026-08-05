import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/security/secure_screen.dart';
import '../../core/security/wallet_key_service.dart';
import '../../core/security/wallet_lock_controller.dart';
import '../../core/security/wallet_session_store.dart';
import 'wallet_provider.dart';

/// Renders one of the Figma auth icon assets (`assets/icons/auth/<name>.svg`).
/// Feature icons carry their own brand colors; pass [tint] only for the
/// monochrome glyphs (arrow, download, copy) so they follow the theme.
class _AuthSvg extends StatelessWidget {
  const _AuthSvg(this.name, {this.size = 22, this.tint});

  final String name;
  final double size;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/auth/$name.svg',
      width: size,
      height: size,
      colorFilter: tint == null
          ? null
          : ColorFilter.mode(tint!, BlendMode.srcIn),
    );
  }
}

/// Rounded outlined text-field styling from the Figma auth flow (white fill,
/// 12px radius, gold focus ring).
InputDecoration _outlinedFieldDecoration(
  BuildContext context, {
  String? hintText,
  String? errorText,
}) {
  final p = context.palette;
  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hintText,
    errorText: errorText,
    filled: true,
    fillColor: p.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    enabledBorder: border(p.border),
    focusedBorder: border(AppColors.gold, 1.5),
    errorBorder: border(AppColors.danger),
    focusedErrorBorder: border(AppColors.danger, 1.5),
  );
}

class _FlowBackButton extends StatelessWidget {
  const _FlowBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onPressed,
      icon: _AuthSvg('line-arrow-left', size: 20, tint: context.palette.textHi),
    );
  }
}

/// Refreshes the wallet screen with the just-created/imported account, then
/// opens it. The provider is absent when the flow is pumped standalone in
/// tests; the app shell always provides it.
void _openWallet(BuildContext context) {
  try {
    context.read<WalletProvider>().load();
  } on ProviderNotFoundException {
    // Standalone flow: nothing to refresh.
  }
  context.go('/wallet');
}

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
  const WalletEntryFlowScreen({super.key, required this.mode});

  final WalletEntryMode mode;

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
  bool _saving = false;
  String? _error;
  Timer? _syncTimer;

  bool get _isImport => widget.mode == WalletEntryMode.import;

  @override
  void initState() {
    super.initState();
    // The recovery phrase is typed on this screen (spec S2).
    SecureScreen.enable();
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
    if (!_isImport) return const _CreateWalletFlow();

    final p = context.palette;
    final index = _ImportStep.values.indexOf(_step);

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _step == _ImportStep.syncing || _step == _ImportStep.ready
          ? null
          : AppBar(
              centerTitle: true,
              title: const Text('Import wallet'),
              leading: _FlowBackButton(onPressed: _back),
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index < 6) ...[
                _Progress(current: index, total: 6),
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
                    child: Text(_primaryLabel),
                  ),
                ),
                if (_step == _ImportStep.phrase) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _AuthSvg('information_sign', size: 12),
                      const SizedBox(width: 6),
                      Text(
                        'MPC support will never ask for your recovery phrase.',
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

  String get _primaryLabel {
    switch (_step) {
      case _ImportStep.safety:
        return 'I understand';
      case _ImportStep.phrase:
        return 'Review wallet';
      case _ImportStep.address:
        return 'This is my wallet';
      case _ImportStep.pin:
        return 'Continue';
      case _ImportStep.confirmPin:
        return _error != null ? 'Re-enter PIN' : 'Confirm PIN';
      case _ImportStep.biometrics:
        return _saving ? 'Securing wallet…' : 'Finish import';
      default:
        return 'Continue';
    }
  }

  Widget _content(BuildContext context) {
    switch (_step) {
      case _ImportStep.safety:
        return const _ImportSafety(key: ValueKey('safety'));
      case _ImportStep.phrase:
        return _PhraseEntry(
          key: const ValueKey('phrase'),
          controller: _phraseController,
          wordCount: _wordCount,
          error: _error,
          onChanged: (_) => setState(() => _error = null),
        );
      case _ImportStep.address:
        return _AddressReview(
          key: const ValueKey('address'),
          address: _derivedAddress,
        );
      case _ImportStep.pin:
        return _PinEntry(
          key: const ValueKey('pin'),
          title: 'Create an app PIN',
          body: 'Use this PIN to unlock MPC on this device.',
          controller: _pinController,
          error: null,
          onChanged: (_) => setState(() {}),
        );
      case _ImportStep.confirmPin:
        return _PinEntry(
          key: const ValueKey('confirm'),
          title: 'Confirm your PIN',
          body: 'Enter the same 6-digit PIN again.',
          controller: _confirmPinController,
          error: _error,
          showWalletSafeAlert: true,
          onChanged: (_) => setState(() => _error = null),
        );
      case _ImportStep.biometrics:
        return _BiometricChoice(
          key: const ValueKey('biometrics'),
          enabled: _biometrics,
          onChanged: (value) => setState(() => _biometrics = value),
        );
      case _ImportStep.syncing:
        return const _Syncing(key: ValueKey('syncing'));
      case _ImportStep.ready:
        return _Ready(
          key: const ValueKey('ready'),
          onOpen: () => _openWallet(context),
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
          setState(() => _error = 'Add your recovery phrase to continue.');
          return;
        }
        if (!_keys.validateMnemonic(phrase)) {
          setState(
            () => _error =
                'That recovery phrase is not valid. Check the words and their order.',
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
          // "Re-enter PIN": clear the failed attempt for a fresh one.
          setState(() {
            _confirmPinController.clear();
            _error = null;
          });
        } else if (_pinController.text != _confirmPinController.text) {
          setState(() => _error = 'PINs do not match. Try again.');
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
            biometrics: _biometrics,
          );
          // Same as the create flow: an imported wallet starts unlocked.
          WalletLockController.instance.markWalletCreated();
        } catch (_) {
          if (mounted) {
            setState(() {
              _saving = false;
              _error =
                  'MPC could not secure this wallet on the device. Try again.';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Could not secure wallet access. Please try again.',
                ),
              ),
            );
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
      // Reached via push from onboarding, but via go() from the forgot-PIN
      // reset (stack replaced on purpose) — fall back to the welcome screen.
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

class _Progress extends StatelessWidget {
  const _Progress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: List.generate(
        total,
        (index) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 4,
            margin: EdgeInsets.only(right: index == total - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: index <= current ? AppColors.gold : p.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImportSafety extends StatelessWidget {
  const _ImportSafety({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      children: [
        Text(
          'Restore your existing wallet',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          'Before entering your recovery phrase:',
          style: TextStyle(color: p.textLo, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 28),
        const _SafetyRow(
          asset: 'private-circle',
          iconSize: 16,
          title: 'Keep it private',
          body: 'Make sure nobody can see your screen.',
        ),
        const SizedBox(height: 18),
        const _SafetyRow(
          asset: 'arrow-down',
          iconSize: 16,
          title: 'Entered only here',
          body: 'Never send your phrase to support.',
        ),
        const SizedBox(height: 18),
        const _SafetyRow(
          asset: 'secure-square',
          iconSize: 16,
          title: 'Stored securely',
          body: 'MPC protects access with your device and PIN.',
        ),
      ],
    );
  }
}

class _SafetyRow extends StatelessWidget {
  const _SafetyRow({
    this.icon,
    this.asset,
    this.iconSize = 22,
    required this.title,
    required this.body,
  }) : assert(icon != null || asset != null);

  final IconData? icon;

  /// Name of a brand-colored auth SVG; takes precedence over [icon].
  final String? asset;

  /// Rendered glyph size; the import-flow glyphs are natively small.
  final double iconSize;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.copper.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: asset != null
              ? _AuthSvg(asset!, size: iconSize)
              : Icon(icon, color: AppColors.gold, size: iconSize),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(body, style: TextStyle(color: p.textLo, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhraseEntry extends StatelessWidget {
  const _PhraseEntry({
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
    return ListView(
      children: [
        Text(
          'Enter recovery phrase',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          'Paste or type your recovery words in the correct order.',
          style: TextStyle(color: p.textLo),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Recovery phrase',
                    style: TextStyle(color: p.textLo, fontSize: 12),
                  ),
                  const Spacer(),
                  _GoldPill('PASTE', onTap: _paste),
                ],
              ),
              TextField(
                controller: controller,
                onChanged: onChanged,
                maxLines: 4,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(fontSize: 15, height: 1.5),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  hintText: 'Paste or type your recovery words',
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 4),
                Text(
                  error!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: p.border.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$wordCount words',
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

/// Small rounded gold chip used for the PASTE action and the BNB CHAIN tag.
class _GoldPill extends StatelessWidget {
  const _GoldPill(this.label, {this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.copper,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
    if (onTap == null) return pill;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: pill,
    );
  }
}

class _AddressReview extends StatelessWidget {
  const _AddressReview({super.key, required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      children: [
        Text(
          'Review wallet',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          'Confirm the wallet address before continuing.',
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
                'WALLET ADDRESS',
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
              const _GoldPill('BNB CHAIN'),
            ],
          ),
        ),
      ],
    );
  }
}

class _PinEntry extends StatefulWidget {
  const _PinEntry({
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

  /// Confirm-step mismatch shows the "Your wallet is still safe" card (03E).
  final bool showWalletSafeAlert;

  @override
  State<_PinEntry> createState() => _PinEntryState();
}

class _PinEntryState extends State<_PinEntry> {
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
            // The real input. Visually hidden but present in the tree so the
            // soft keyboard, backspace and widget tests keep working; the
            // boxes below only render its text.
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
                    _PinBox(
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
          widget.error ?? 'Your PIN protects this device only.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: hasError ? AppColors.danger : p.textLo,
            fontSize: 12,
          ),
        ),
        if (widget.showWalletSafeAlert && hasError) ...[
          const SizedBox(height: 28),
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
                  child: _AuthSvg('information_sign', size: 15),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your wallet is still safe',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Nothing has been saved or changed. Re-enter the PIN '
                        'to continue.',
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

class _PinBox extends StatelessWidget {
  const _PinBox({this.char, required this.active, required this.error});

  final String? char;
  final bool active;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final borderColor = error
        ? AppColors.danger
        : active
        ? AppColors.gold
        : p.border;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 44,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(
          color: borderColor,
          width: active || error ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        char ?? '',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: error ? AppColors.danger : p.textHi,
        ),
      ),
    );
  }
}

class _BiometricChoice extends StatelessWidget {
  const _BiometricChoice({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      children: [
        Text(
          'Use biometrics?',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          'Unlock faster while keeping your wallet protected.',
          style: TextStyle(color: p.textLo, height: 1.45),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Face ID / Touch ID',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Recommended',
                      style: TextStyle(
                        color: AppColors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.positive,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Syncing extends StatelessWidget {
  const _Syncing({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 24),
          const Text(
            'Importing your wallet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            'Securing this device and syncing wallet data…',
            style: TextStyle(color: p.textLo),
          ),
        ],
      ),
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({super.key, required this.onOpen});

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
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.positive,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Wallet imported',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your existing wallet is ready on this device.',
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
            child: const Text('Open wallet'),
          ),
        ),
      ],
    );
  }
}

class _CreateWalletFlow extends StatefulWidget {
  const _CreateWalletFlow();

  @override
  State<_CreateWalletFlow> createState() => _CreateWalletFlowState();
}

class _CreateWalletFlowState extends State<_CreateWalletFlow> {
  static const _keys = WalletKeyService();

  /// Generated once per flow instance; leaving the flow discards it.
  final String _mnemonic = _keys.generateMnemonic();
  late final List<String> _words = _mnemonic.split(' ');

  /// Random word positions the user must re-type (typed, never selected:
  /// selection can be tapped through without a real backup). Re-picked per
  /// flow instance so no two runs ask the same positions.
  late final List<int> _verifyIndices = (List<int>.generate(
    _words.length,
    (i) => i,
  )..shuffle(Random.secure())).take(3).toList()..sort();
  late final List<TextEditingController> _verifyControllers = List.generate(
    _verifyIndices.length,
    (_) => TextEditingController(),
  );

  int _step = 0;
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  Set<int> _verifyMismatches = const {};
  bool _biometrics = true;
  bool _saving = false;
  String? _error;
  Timer? _clipboardClearTimer;

  @override
  void initState() {
    super.initState();
    // The recovery phrase renders on this screen (spec S2).
    SecureScreen.enable();
  }

  @override
  void dispose() {
    SecureScreen.disable();
    _clipboardClearTimer?.cancel();
    for (final controller in _verifyControllers) {
      controller.dispose();
    }
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: _step == 6
          ? null
          : AppBar(
              centerTitle: true,
              title: const Text('Create wallet'),
              leading: _FlowBackButton(onPressed: _back),
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_step < 6) ...[
                _Progress(current: _step, total: 6),
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
                    child: Text(_createPrimaryLabel),
                  ),
                ),
              ],
            ],
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

  String get _createPrimaryLabel {
    switch (_step) {
      case 0:
        return 'Create new wallet';
      case 1:
        return 'I saved these words';
      case 2:
        return 'Verify backup';
      case 3:
        return 'Continue';
      case 4:
        return _error != null ? 'Re-enter PIN' : 'Confirm PIN';
      case 5:
        return _saving ? 'Securing wallet…' : 'Finish setup';
      default:
        return 'Continue';
    }
  }

  Widget _createContent(BuildContext context) {
    final p = context.palette;
    switch (_step) {
      case 0:
        return ListView(
          key: const ValueKey('create-intro'),
          children: [
            Text(
              'A wallet only you control',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'MPC creates your wallet on this device. Your recovery phrase is '
              'the only way to restore access if this device is lost.',
              style: TextStyle(color: p.textLo, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 28),
            const _SafetyRow(
              asset: 'eye-slash',
              title: 'You hold the keys',
              body: 'MPC cannot recover or reset your phrase.',
            ),
            const SizedBox(height: 18),
            const _SafetyRow(
              asset: 'document-text',
              title: 'Back it up offline',
              body: 'Write the words down and keep them private.',
            ),
            const SizedBox(height: 18),
            const _SafetyRow(
              asset: 'unlock',
              title: 'Protect this device',
              body: 'Set a PIN and optionally use biometrics.',
            ),
          ],
        );
      case 1:
        return ListView(
          key: const ValueKey('create-phrase'),
          children: [
            Text(
              'Back up your recovery phrase',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Write these 12 words down in order.',
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
                itemCount: _words.length,
                itemBuilder: (_, index) => Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: p.border.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}.  ${_words[index]}',
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
                    onPressed: _downloadPhrase,
                    icon: _AuthSvg('download', size: 16, tint: p.textHi),
                    label: const Text('Download'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyPhrase,
                    icon: _AuthSvg('copy', size: 16, tint: p.textHi),
                    label: const Text('Copy codes'),
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
                  child: _AuthSvg('information_sign', size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Never share these words with anyone. MPC support will '
                    'never ask for your recovery phrase.',
                    style: TextStyle(
                      color: p.textLo,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      case 2:
        return ListView(
          key: const ValueKey('create-verify'),
          children: [
            Text(
              'Verify your backup',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Select the requested words to confirm your backup.',
              style: TextStyle(color: p.textLo),
            ),
            const SizedBox(height: 24),
            for (var i = 0; i < _verifyIndices.length; i++) ...[
              Text(
                'Word #${_verifyIndices[i] + 1}',
                style: TextStyle(
                  color: p.textLo,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: ValueKey('verify-word-${_verifyIndices[i] + 1}'),
                controller: _verifyControllers[i],
                onChanged: (_) => setState(() => _verifyMismatches = const {}),
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.none,
                decoration: _outlinedFieldDecoration(
                  context,
                  hintText: 'Enter word #${_verifyIndices[i] + 1}',
                  errorText: _verifyMismatches.contains(i)
                      ? 'This word does not match your recovery phrase.'
                      : null,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        );
      case 3:
        return _PinEntry(
          key: const ValueKey('create-pin'),
          title: 'Create an app PIN',
          body: 'Use this PIN to unlock MPC on this device.',
          controller: _pinController,
          error: null,
          onChanged: (_) => setState(() {}),
        );
      case 4:
        return _PinEntry(
          key: const ValueKey('create-confirm'),
          title: 'Confirm your PIN',
          body: 'Enter the same 6-digit PIN again.',
          controller: _confirmController,
          error: _error,
          showWalletSafeAlert: true,
          onChanged: (_) => setState(() => _error = null),
        );
      case 5:
        return _BiometricChoice(
          key: const ValueKey('create-biometric'),
          enabled: _biometrics,
          onChanged: (value) => setState(() => _biometrics = value),
        );
      default:
        return _WalletCreated(
          key: const ValueKey('created'),
          onOpen: () => _openWallet(context),
        );
    }
  }

  Future<void> _continueCreate() async {
    FocusScope.of(context).unfocus();
    if (_step == 2) {
      final wrong = <int>{
        for (var i = 0; i < _verifyIndices.length; i++)
          if (_verifyControllers[i].text.trim().toLowerCase() !=
              _words[_verifyIndices[i]])
            i,
      };
      if (wrong.isNotEmpty) {
        setState(() => _verifyMismatches = wrong);
        return;
      }
    }
    if (_step == 4 && _error != null) {
      // "Re-enter PIN": clear the failed attempt for a fresh one.
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
      setState(() => _saving = true);
      try {
        await WalletSessionStore.instance.saveWalletSecrets(
          mnemonic: _mnemonic,
          address: _keys.deriveAddress(_mnemonic),
        );
        await WalletSessionStore.instance.configure(
          pin: _pinController.text,
          biometrics: _biometrics,
        );
        // The user authenticated as part of this flow, so the new wallet
        // starts unlocked rather than bouncing them to the unlock screen.
        WalletLockController.instance.markWalletCreated();
      } catch (_) {
        if (mounted) {
          setState(() {
            _saving = false;
            _error =
                'MPC could not secure this wallet on the device. Try again.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not finish setup. Please try again.'),
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      setState(() => _saving = false);
    }
    if (_step < 6) setState(() => _step += 1);
  }

  /// S3: the phrase may not sit on the clipboard indefinitely. Clears it
  /// after 30 seconds unless the user has since copied something else.
  Future<void> _copyPhrase() async {
    await Clipboard.setData(ClipboardData(text: _mnemonic));
    _clipboardClearTimer?.cancel();
    _clipboardClearTimer = Timer(const Duration(seconds: 30), () async {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == _mnemonic) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Recovery phrase copied. Clipboard clears in 30s.'),
        ),
      );
  }

  Future<void> _downloadPhrase() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save digitally?'),
        content: const Text(
          'Any app or cloud service you save this to can read your recovery '
          'phrase. Writing the words down offline is safer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (proceed != true) return;
    await SharePlus.instance.share(ShareParams(text: _mnemonic));
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
        _verifyMismatches = const {};
        _step -= 1;
      });
    }
  }
}

class _WalletCreated extends StatelessWidget {
  const _WalletCreated({super.key, required this.onOpen});

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
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.positive,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Wallet created',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your wallet is protected and ready to use.',
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
            child: const Text('Open wallet'),
          ),
        ),
      ],
    );
  }
}
