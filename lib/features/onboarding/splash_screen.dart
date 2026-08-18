import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/security/wallet_session_store.dart';
import '../../core/widgets/mpc_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationTimer = Timer(const Duration(milliseconds: 2800), () async {
        final returning = await WalletSessionStore.instance.hasWallet();
        if (mounted) context.go(returning ? '/unlock' : '/onboarding');
      });
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final fade = CurvedAnimation(
      parent: _controller,
      curve: reduceMotion ? Curves.linear : Curves.easeOutCubic,
    );
    final settle = Tween<double>(
      begin: .82,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _navigationTimer?.cancel();
          _routeAfterSplash();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFD077),
                      Color(0xFFF28A3C),
                      Color(0xFF8F2F1D),
                      Color(0xFF1A090B),
                      Color(0xFF0C0A09),
                    ],
                    stops: [0, .16, .36, .68, 1],
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: FadeTransition(
                opacity: fade,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(.25, -.55),
                      radius: .72,
                      colors: [
                        Color(0x99FFEDC1),
                        Color(0x44F28A3C),
                        Color(0x001A090B),
                      ],
                      stops: [0, .38, 1],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final progress = Curves.easeOutCubic.transform(
                    _controller.value,
                  );
                  return Transform.scale(
                    scale: settle.value,
                    child: Opacity(
                      opacity: fade.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 88,
                            height: 94,
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                Transform.translate(
                                  offset: Offset(0, 18 * (1 - progress)),
                                  child: Opacity(
                                    opacity: .12 * (1 - progress),
                                    child: const MpcLogo(
                                      size: 72,
                                      tint: AppColors.terracotta,
                                    ),
                                  ),
                                ),
                                Transform.translate(
                                  offset: Offset(0, 9 * (1 - progress)),
                                  child: Opacity(
                                    opacity: .28 * (1 - progress),
                                    child: const MpcLogo(
                                      size: 72,
                                      tint: AppColors.copper,
                                    ),
                                  ),
                                ),
                                const MpcLogo(size: 72, tint: AppColors.gold),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'MPC',
                            style: TextStyle(
                              color: AppColors.darkTextHi,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'RWA INFRASTRUCTURE',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _routeAfterSplash() async {
    final returning = await WalletSessionStore.instance.hasWallet();
    if (mounted) context.go(returning ? '/unlock' : '/onboarding');
  }
}
