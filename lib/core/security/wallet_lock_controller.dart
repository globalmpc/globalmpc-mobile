import 'package:flutter/widgets.dart';

import 'wallet_session_store.dart';

/// Session lock state: whether the configured wallet is currently unlocked,
/// and when time away from the app should take that away again (spec S9).
///
/// Unlocking is a session fact, not a stored one — a wallet is unlocked for as
/// long as the user is actually using the app. Without this, one PIN entry
/// unlocked the wallet until the process died, so a phone handed over or
/// picked up hours later was still a live wallet.
///
/// Two lifecycle traps this deliberately avoids:
/// - Only [AppLifecycleState.paused] counts as leaving. `inactive` and
///   `hidden` fire for the app switcher, Control Center, the notification
///   shade and incoming-call banners; locking on those would fire constantly
///   while the user is still holding the phone.
/// - System auth dialogs background the app themselves. Locking on that pause
///   and redirecting on resume produces the classic unlock loop: prompt →
///   lock → unlock screen → prompt. [runSystemPrompt] brackets those calls so
///   the pause they cause is not counted as leaving, and the timeout below is
///   a second line of defence for any prompt that is not bracketed.
class WalletLockController extends ChangeNotifier with WidgetsBindingObserver {
  WalletLockController._({
    WalletSessionStore? store,
    DateTime Function()? clock,
    Duration? lockTimeout,
  }) : _store = store ?? WalletSessionStore.instance,
       _now = clock ?? DateTime.now,
       _lockTimeout = lockTimeout ?? defaultLockTimeout;

  static final WalletLockController instance = WalletLockController._();

  @visibleForTesting
  static WalletLockController forTesting({
    WalletSessionStore? store,
    DateTime Function()? clock,
    Duration? lockTimeout,
  }) => WalletLockController._(
    store: store,
    clock: clock,
    lockTimeout: lockTimeout,
  );

  /// Grace period before backgrounding locks the wallet.
  ///
  /// This is the product knob: shorter is safer, longer is less annoying.
  /// Two minutes covers answering a message or copying an address out of
  /// another app without re-authenticating, while still locking a phone that
  /// was put down or taken.
  static const Duration defaultLockTimeout = Duration(minutes: 2);

  final WalletSessionStore _store;
  final DateTime Function() _now;
  final Duration _lockTimeout;

  bool _ready = false;
  bool _hasWallet = false;
  bool _unlocked = false;
  int _systemPromptDepth = 0;
  DateTime? _backgroundedAt;
  bool _observing = false;

  bool get isReady => _ready;
  bool get hasWallet => _hasWallet;
  bool get isUnlocked => _unlocked;

  /// Whether navigation should be diverted to the unlock screen.
  ///
  /// False until [start] has resolved, so the router never redirects on
  /// half-initialised state during launch, and false when no wallet exists,
  /// so onboarding is untouched.
  bool get requiresUnlock => _ready && _hasWallet && !_unlocked;

  /// Binds to the lifecycle and loads whether a wallet exists. Safe to call
  /// more than once.
  Future<void> start() async {
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    _hasWallet = await _store.hasWallet();
    _ready = true;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    super.dispose();
  }

  /// Records a successful PIN or biometric check.
  void markUnlocked() {
    _backgroundedAt = null;
    if (_unlocked && _hasWallet) return;
    _hasWallet = true;
    _unlocked = true;
    notifyListeners();
  }

  /// A wallet was just created or imported; it starts unlocked because the
  /// user authenticated as part of that flow.
  void markWalletCreated() => markUnlocked();

  /// The wallet was removed or reset, so there is nothing left to guard.
  void markWalletCleared() {
    _backgroundedAt = null;
    if (!_hasWallet && !_unlocked) return;
    _hasWallet = false;
    _unlocked = false;
    notifyListeners();
  }

  void lockNow() {
    _backgroundedAt = null;
    if (!_unlocked) return;
    _unlocked = false;
    notifyListeners();
  }

  /// Runs [action] without its own backgrounding counting as leaving the app.
  /// Wrap platform dialogs that take over the screen, such as biometric auth.
  Future<T> runSystemPrompt<T>(Future<T> Function() action) async {
    _systemPromptDepth++;
    try {
      return await action();
    } finally {
      _systemPromptDepth--;
      // The pause this prompt caused is not the user leaving, so drop it
      // rather than measuring it on resume.
      if (_systemPromptDepth == 0) _backgroundedAt = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        if (_systemPromptDepth == 0 && _backgroundedAt == null) {
          _backgroundedAt = _now();
        }
      case AppLifecycleState.resumed:
        final leftAt = _backgroundedAt;
        _backgroundedAt = null;
        if (leftAt == null || _systemPromptDepth > 0) return;
        if (_now().difference(leftAt) >= _lockTimeout) lockNow();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }
}
