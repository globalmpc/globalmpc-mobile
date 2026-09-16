import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/notifications/notification_center.dart';
import '../../core/security/biometric_auth.dart';
import '../../core/security/wallet_lock_controller.dart';
import '../../core/security/wallet_session_store.dart';
import 'unlock_restore_pages.dart';
import 'unlock_restore_confirm.dart';
import 'widgets/unlock_pin_panel.dart';
import 'widgets/unlock_dialogs.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _pin = TextEditingController();
  final _biometrics = BiometricAuth();
  bool _busy = false;
  bool _promptShowing = false;
  bool _biometricSheetOpen = false;
  bool _restoreSheetOpen = false;
  String? _error;
  Duration? _lockout;
  Duration? _lockoutTotal;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final lockout = await WalletSessionStore.instance.pinLockoutRemaining();
      if (lockout != null && mounted) {
        _enterLockout(lockout);
      } else {
        _offerBiometrics();
      }
    });
  }

  @override
  void dispose() {
    _pin.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _enterLockout(Duration remaining) {
    _lockoutTimer?.cancel();
    setState(() {
      _lockout = remaining;
      _lockoutTotal = remaining;
    });
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = _lockout! - const Duration(seconds: 1);
      if (next <= Duration.zero) {
        timer.cancel();
        setState(() {
          _lockout = null;
          _lockoutTotal = null;
        });
      } else {
        setState(() => _lockout = next);
      }
    });
  }

  Future<void> _offerBiometrics({bool userInitiated = false}) async {
    if (_promptShowing) return;
    final unavailableReason = await _biometricsUnavailableReason();
    if (!mounted) return;
    if (unavailableReason != null) {
      if (userInitiated) _notice(unavailableReason);
      return;
    }
    _promptShowing = true;
    final result = await WalletLockController.instance.runSystemPrompt(
      () => _biometrics.authenticate(reason: 'Unlock your MPC wallet'),
    );
    _promptShowing = false;
    if (!mounted) return;
    switch (result) {
      case BiometricResult.success:
        await WalletSessionStore.instance.clearPinFailures();
        if (!mounted) return;
        WalletLockController.instance.markUnlocked();
        context.go('/');
      case BiometricResult.cancelled:
        break;
      case BiometricResult.lockedOut:
        _notice(
          'Biometrics are temporarily locked by the device. Use your PIN.',
        );
      case BiometricResult.notEnrolled:
        _notice(_availabilityMessage(BiometricAvailability.notEnrolled));
      case BiometricResult.unavailable:
        if (userInitiated) {
          _notice('Biometric unlock is not available right now. Use your PIN.');
        }
    }
  }

  static String _availabilityMessage(BiometricAvailability availability) =>
      switch (availability) {
        BiometricAvailability.notEnrolled =>
          'No fingerprint or face is enrolled on this device yet. Add one in '
              'your device settings, then try again.',
        _ => 'Biometric unlock is not available on this device.',
      };

  void _notice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _biometricsUnavailableReason() async {
    if (!await WalletSessionStore.instance.biometricsEnabled()) {
      return 'Biometric unlock is not set up on this device. Use your PIN.';
    }
    final availability = await _biometrics.availability();
    if (availability == BiometricAvailability.ready) return null;
    return _availabilityMessage(availability);
  }

  Future<void> _showBiometricPrompt() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final unavailableReason = await _biometricsUnavailableReason();
    if (!mounted) return;
    if (unavailableReason != null) {
      _notice(unavailableReason);
      return;
    }
    setState(() => _biometricSheetOpen = true);
    final choice = await showBiometricChoiceDialog(context);
    if (mounted) setState(() => _biometricSheetOpen = false);
    if (choice != 'biometrics' || !mounted) return;
    await _offerBiometrics(userInitiated: true);
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
      WalletLockController.instance.markUnlocked();
      context.go('/');
      return;
    }

    final lockout = await store.pinLockoutRemaining();
    if (!mounted) return;
    final attemptsLeft =
        WalletSessionStore.maxPinAttempts - await store.pinFailureCount();
    if (!mounted) return;
    if (lockout != null) {
      setState(() {
        _busy = false;
        _pin.clear();
      });
      _enterLockout(lockout);
      await NotificationCenter.instance.notifySecurity(
        'notif.sec.lockout.title',
        'notif.sec.lockout.body',
      );
      return;
    }
    setState(() {
      _busy = false;
      _pin.clear();
      if (attemptsLeft > 0 && attemptsLeft <= 2) {
        _error =
            'Incorrect PIN. $attemptsLeft attempt'
            '${attemptsLeft == 1 ? '' : 's'} remaining.';
      } else {
        _error = 'Incorrect PIN. Try again.';
      }
    });
  }

  Future<void> _restore() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _restoreSheetOpen = true);
    final confirmed = await showRestoreConfirmDialog(context);
    if (mounted) setState(() => _restoreSheetOpen = false);
    if (confirmed != true || !mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RestoreConfirmPage()));
  }

  @override
  Widget build(BuildContext context) {
    if (_lockout != null) {
      return LockoutView(
        remaining: _lockout!,
        total: _lockoutTotal!,
        onUseBiometrics: _showBiometricPrompt,
        onRestore: _restore,
      );
    }
    return UnlockPinPanel(
      pinController: _pin,
      busy: _busy,
      error: _error,
      onPinChanged: () => setState(() => _error = null),
      onUnlock: _unlock,
      onRestore: _restore,
      onShowBiometrics: _showBiometricPrompt,
      onCreateWallet: () => context.push('/wallet/create'),
      showLanguageSelector: !_biometricSheetOpen && !_restoreSheetOpen,
    );
  }
}
