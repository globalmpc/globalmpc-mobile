import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/security/wallet_lock_controller.dart';
import '../../core/security/wallet_session_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/mpc_logo.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _pin = TextEditingController();
  final _auth = LocalAuthentication();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerBiometrics());
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _offerBiometrics() async {
    if (!await WalletSessionStore.instance.biometricsEnabled()) return;
    try {
      if (await _auth.canCheckBiometrics && mounted) {
        // The OS dialog backgrounds the app. Bracketing it stops that pause
        // being read as the user leaving, which would re-lock on resume and
        // bounce a successful unlock straight back to this screen.
        final authenticated = await WalletLockController.instance
            .runSystemPrompt(
              () => _auth.authenticate(
                localizedReason: 'Unlock your MPC wallet',
                biometricOnly: true,
                persistAcrossBackgrounding: true,
              ),
            );
        if (authenticated && mounted) {
          WalletLockController.instance.markUnlocked();
          if (mounted) context.go('/');
        }
      }
    } catch (_) {
      // PIN is always available as the reliable fallback.
    }
  }

  Future<void> _unlock() async {
    if (_pin.text.length != 6 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final store = WalletSessionStore.instance;
    final valid = await store.verifyPin(_pin.text);
    if (!mounted) return;
    if (valid) {
      // Must precede navigation: the router guard reads this, and would
      // otherwise redirect straight back here.
      WalletLockController.instance.markUnlocked();
      context.go('/');
      return;
    }
    // Distinguish "wrong PIN" from "locked out", otherwise a user who is
    // simply rate-limited keeps retrying and extends their own lockout.
    final lockout = await store.pinLockoutRemaining();
    if (!mounted) return;
    final attemptsLeft =
        WalletSessionStore.maxPinAttempts - await store.pinFailureCount();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _pin.clear();
      if (lockout != null) {
        _error = 'Too many attempts. Try again in ${_formatWait(lockout)}.';
      } else if (attemptsLeft > 0 && attemptsLeft <= 2) {
        _error =
            'Incorrect PIN. $attemptsLeft attempt'
            '${attemptsLeft == 1 ? '' : 's'} left.';
      } else {
        _error = 'Incorrect PIN. Try again.';
      }
    });
  }

  static String _formatWait(Duration d) {
    if (d.inMinutes < 1) return '${d.inSeconds + 1}s';
    if (d.inHours < 1) return '${d.inMinutes + 1} min';
    return '${d.inHours} hr';
  }

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore wallet?'),
        content: const Text(
          'Your device PIN cannot recover your wallet. Continue only if you '
          'have your recovery phrase.',
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
    if (confirmed != true) return;
    await WalletSessionStore.instance.clear();
    WalletLockController.instance.markWalletCleared();
    if (mounted) context.go('/wallet/import');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/brand/hero_terrain.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x440C0A09),
                  Color(0xE80C0A09),
                  AppColors.darkBg,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                children: [
                  const Row(
                    children: [
                      MpcLogo(size: 30, tint: AppColors.gold),
                      SizedBox(width: 10),
                      Text(
                        'MPC',
                        style: TextStyle(
                          color: AppColors.darkTextHi,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      color: AppColors.darkTextHi,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Enter your device PIN to unlock your wallet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.darkTextLo, fontSize: 15),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _pin,
                    autofocus: true,
                    obscureText: true,
                    obscuringCharacter: '●',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.darkTextHi,
                      fontSize: 26,
                      letterSpacing: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••••',
                      errorText: _error,
                      filled: true,
                      fillColor: AppColors.darkSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.darkBorder,
                        ),
                      ),
                    ),
                    onChanged: (_) {
                      setState(() => _error = null);
                      if (_pin.text.length == 6) _unlock();
                    },
                    onSubmitted: (_) => _unlock(),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _pin.text.length == 6 && !_busy
                          ? _unlock
                          : null,
                      child: Text(_busy ? 'Unlocking…' : 'Unlock wallet'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _offerBiometrics,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text('Use biometrics'),
                  ),
                  TextButton(
                    onPressed: _restore,
                    child: const Text('Forgot PIN? Restore wallet'),
                  ),
                  const Spacer(),
                  const Text(
                    'Your PIN never leaves this device.',
                    style: TextStyle(color: AppColors.darkTextLo, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
