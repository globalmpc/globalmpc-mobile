import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/config/app_environment.dart';
import 'core/localization/app_strings.dart';
import 'core/localization/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/security/wallet_lock_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'data/repositories/chain_mpc_repository.dart';
import 'data/repositories/mock_mpc_repository.dart';
import 'data/repositories/mpc_repository.dart';
import 'data/services/bsc_chain_service.dart';
import 'data/services/registry_anchor_service.dart';
import 'features/projects/projects_provider.dart';
import 'features/registry/registry_provider.dart';
import 'features/wallet/wallet_provider.dart';

class MpcApp extends StatefulWidget {
  const MpcApp({
    super.key,
    required this.localeController,
    required this.themeController,
  });

  final LocaleController localeController;
  final ThemeController themeController;

  @override
  State<MpcApp> createState() => _MpcAppState();
}

class _MpcAppState extends State<MpcApp> {
  // The network, token and registry come from the build environment. Wallet
  // data is live on that network once an on-device wallet exists; projects
  // and content stay on the mock until the content service exists.
  static final AppEnvironment _environment = AppEnvironment.current;
  static final BscChainService _chainService = BscChainService(
    _environment.chain,
  );
  static final RegistryAnchorService? _registryService =
      _environment.hasRegistry
      ? RegistryAnchorService(
          config: _environment.chain,
          anchorAddress: _environment.registryAnchorAddress!,
        )
      : null;
  static final MpcRepository _repository = ChainMpcRepository(
    _chainService,
    const MockMpcRepository(),
  );

  final WalletLockController _lock = WalletLockController.instance;
  late final GoRouter _router = AppRouter.create(lock: _lock);

  @override
  void initState() {
    super.initState();
    // Binds the lifecycle observer and resolves whether a wallet exists.
    // Until it completes the guard stays open, which is why launch runs
    // through the splash screen.
    _lock.start();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<BscChainService>.value(value: _chainService),
        Provider<MpcRepository>.value(value: _repository),
        ChangeNotifierProvider<ThemeController>.value(
          value: widget.themeController,
        ),
        ChangeNotifierProvider(
          create: (_) => ProjectsProvider(_repository)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => WalletProvider(_repository)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => RegistryProvider(_registryService)..load(),
        ),
      ],
      child: LocaleControllerScope.provide(
        controller: widget.localeController,
        child: ListenableBuilder(
          listenable: Listenable.merge([
            widget.localeController,
            widget.themeController,
          ]),
          builder: (context, _) => MaterialApp.router(
            title: 'MPC',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: widget.themeController.mode,
            locale: widget.localeController.locale,
            supportedLocales: AppStrings.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
