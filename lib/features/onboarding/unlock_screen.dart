import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/notifications/notification_center.dart';
import '../../core/security/biometric_auth.dart';
import '../../core/security/wallet_lock_controller.dart';
import '../../core/security/wallet_session_store.dart';
import 'unlock_restore_pages.dart';
import 'unlock_restore_confirm.dart';
import 'widgets/unlock_pin_panel.dart';
import 'widgets/unlock_dialogs.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key, @visibleForTesting this.biometrics});

  /// Test seam; production always uses the platform implementation.
  final BiometricAuth? biometrics;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  /// Delay between the first frame and the automatic prompt, so the route
  /// transition has finished and the window is fully in front before the
  /// system UI is asked for.
  static const _autoPromptDelay = Duration(milliseconds: 350);

  final _pin = TextEditingController();
  late final BiometricAuth _biometrics = widget.biometrics ?? BiometricAuth();
  bool _busy = false;
  bool _promptShowing = false;
  int _promptSequence = 0;
  bool _biometricSheetOpen = false;
  bool _restoreSheetOpen = false;
  String? _error;
  Duration? _lockout;
  Duration? _lockoutTotal;
  Timer? _lockoutTimer;
  Timer? _autoPromptTimer;
  AppLifecycleListener? _resumeListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final lockout = await WalletSessionStore.instance.pinLockoutRemaining();
      if (!mounted) return;
      if (lockout != null) {
        _enterLockout(lockout);
      } else {
        _scheduleAutoPrompt();
      }
    });
  }

  @override
  void dispose() {
    _pin.dispose();
    _lockoutTimer?.cancel();
    _autoPromptTimer?.cancel();
    _resumeListener?.dispose();
    super.dispose();
  }

  /// The platform only presents a biometric prompt for an app in the
  /// foreground. At a cold start this screen can be built while the app is
  /// still becoming active, so the prompt waits for resume and then for the
  /// transition to settle.
  void _scheduleAutoPrompt() {
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == null || state == AppLifecycleState.resumed) {
      _autoPromptTimer?.cancel();
      _autoPromptTimer = Timer(_autoPromptDelay, () {
        if (mounted) _offerBiometrics();
      });
      return;
    }
    _resumeListener?.dispose();
    _resumeListener = AppLifecycleListener(
      onResume: () {
        _resumeListener?.dispose();
        _resumeListener = null;
        if (mounted) _scheduleAutoPrompt();
      },
    );
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
    if (_promptShowing) {
      if (!userInitiated) return;
      // A prompt the system cancelled stays pending on the platform side
      // until the app resumes. The user asking again must win over it.
      await _biometrics.cancel();
      if (!mounted) return;
    }
    if (!await WalletSessionStore.instance.biometricsEnabled()) {
      if (mounted && userInitiated) _notice(context.tr('unlock.bio.notSetUp'));
      return;
    }
    final availability = await _biometrics.availability();
    if (!mounted) return;
    if (availability == BiometricAvailability.unsupported) {
      if (userInitiated) _notice(context.tr('settings.bio.unsupported'));
      return;
    }
    // notEnrolled is attempted anyway: on iOS it also covers access having
    // been refused, and only the prompt's own error says which one it is.

    final sequence = ++_promptSequence;
    _promptShowing = true;
    final result = await WalletLockController.instance.runSystemPrompt(
      () => _biometrics.authenticate(reason: context.tr('unlock.bio.reason')),
    );
    if (!mounted || sequence != _promptSequence) return;
    _promptShowing = false;
    switch (result) {
      case BiometricResult.success:
        await WalletSessionStore.instance.clearPinFailures();
        if (!mounted) return;
        WalletLockController.instance.markUnlocked();
        context.go('/');
      case BiometricResult.cancelled:
        break;
      case BiometricResult.unavailable:
        if (userInitiated) _notice(context.tr(biometricMessageKey(result)!));
      case BiometricResult.lockedOut:
      case BiometricResult.notEnrolled:
      case BiometricResult.disabledForApp:
        _notice(context.tr(biometricMessageKey(result)!));
    }
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showBiometricPrompt() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!await WalletSessionStore.instance.biometricsEnabled()) {
      if (mounted) _notice(context.tr('unlock.bio.notSetUp'));
      return;
    }
    if (!mounted) return;
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
      _error = switch (attemptsLeft) {
        1 => context.tr('unlock.pin.oneAttemptLeft'),
        2 => context
            .tr('unlock.pin.attemptsLeft')
            .replaceFirst('{count}', '$attemptsLeft'),
        _ => context.tr('common.pin.incorrect'),
      };
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
