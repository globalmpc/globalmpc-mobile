import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../security/wallet_lock_controller.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/earn/earn_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/onboarding/unlock_screen.dart';
import '../../features/projects/project_detail_screen.dart';
import '../../features/projects/projects_screen.dart';
import '../../features/settings/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/home_shell.dart';
import '../../features/wallet/wallet_entry_flow_screen.dart';
import '../../features/wallet/wallet_transfer_screens.dart';
import '../../features/wallet/wallet_screen.dart';
import '../../features/web/web_view_screen.dart';
import '../../data/models/wallet_models.dart';

/// Central route table.
///
/// There is no account system: the app keeps no personal data and identity is
/// the wallet address. The one gate is the wallet lock — once a wallet exists,
/// every surface that can see balances, history or the recovery phrase sits
/// behind [WalletLockController], so backgrounding the app for longer than the
/// lock timeout sends the user back to `/unlock`.
class AppRouter {
  const AppRouter._();

  static final _rootKey = GlobalKey<NavigatorState>();
  static const _initialLocation = String.fromEnvironment(
    'MPC_PREVIEW_ROUTE',
    defaultValue: '/splash',
  );

  /// Routes reachable while a wallet is locked.
  ///
  /// `/unlock` is the destination itself; `/splash` runs before the lock state
  /// is known; the onboarding and create/import flows are how a user with no
  /// wallet — or one restoring from their phrase after forgetting the PIN —
  /// gets in at all. Importing cannot expose the existing wallet: it replaces
  /// it, and only with a phrase the user already holds.
  static const Set<String> unlockExemptRoutes = {
    '/splash',
    '/unlock',
    '/onboarding',
    '/wallet/create',
    '/wallet/import',
  };

  /// Resolves where a navigation should actually land given [lock].
  ///
  /// Split out from [create] so the guard is testable without pumping a
  /// widget tree.
  static String? redirectFor(WalletLockController lock, String location) {
    if (!lock.requiresUnlock) return null;
    if (unlockExemptRoutes.contains(location)) return null;
    return '/unlock';
  }

  /// [lock] is optional: without it the router has no guard at all, which is
  /// what widget tests that drive a single screen directly rely on.
  static GoRouter create({
    String? initialLocation,
    WalletLockController? lock,
  }) {
    return GoRouter(
      navigatorKey: _rootKey,
      initialLocation: initialLocation ?? _initialLocation,
      refreshListenable: lock,
      redirect: lock == null
          ? null
          : (context, state) => redirectFor(lock, state.matchedLocation),
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/unlock', builder: (_, __) => const UnlockScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/wallet/create',
          parentNavigatorKey: _rootKey,
          builder: (_, __) =>
              const WalletEntryFlowScreen(mode: WalletEntryMode.create),
        ),
        GoRoute(
          path: '/wallet/import',
          parentNavigatorKey: _rootKey,
          builder: (_, __) =>
              const WalletEntryFlowScreen(mode: WalletEntryMode.import),
        ),
        GoRoute(
          path: '/wallet/receive',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const ReceiveScreen(),
        ),
        GoRoute(
          path: '/wallet/add-bnb',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const ReceiveScreen(assetSymbol: 'BNB'),
        ),
        GoRoute(
          path: '/wallet/send',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const SendScreen(),
        ),
        GoRoute(
          path: '/wallet/transaction',
          parentNavigatorKey: _rootKey,
          builder: (_, state) => TransactionDetailScreen(
            transaction: state.extra as WalletTransaction,
          ),
        ),
        GoRoute(
          path: '/notifications',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/settings',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/settings/security',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const SecuritySettingsScreen(),
        ),
        GoRoute(
          path: '/settings/notifications',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const NotificationSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/privacy',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const PrivacySettingsScreen(),
        ),
        GoRoute(
          path: '/settings/support',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const SupportSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/audit-status',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const AuditStatusScreen(),
        ),
        GoRoute(
          path: '/settings/network',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const NetworkSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/recovery',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const RecoverySettingsScreen(),
        ),
        GoRoute(
          path: '/settings/recovery/auth',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const RecoveryAuthScreen(),
        ),
        GoRoute(
          path: '/settings/recovery/verify',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const VerifyBackupScreen(),
        ),
        GoRoute(
          path: '/settings/change-pin',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const ChangePinScreen(),
        ),
        GoRoute(
          path: '/settings/legal',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const LegalSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/about',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const AboutSettingsScreen(),
        ),
        GoRoute(
          path: '/profile',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/webview',
          parentNavigatorKey: _rootKey,
          builder: (_, state) =>
              WebViewScreen(args: state.extra as WebViewArgs),
        ),
        GoRoute(
          path: '/projects/:id',
          parentNavigatorKey: _rootKey,
          builder: (_, state) =>
              ProjectDetailScreen(projectId: state.pathParameters['id']!),
        ),
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => HomeShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/projects',
                  builder: (_, __) => const ProjectsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/earn', builder: (_, __) => const EarnScreen()),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/wallet',
                  builder: (_, __) => const WalletScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
