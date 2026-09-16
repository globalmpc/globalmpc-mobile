import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/wallet_session_store.dart';
import 'splash/splash_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _navigationTimer;
  bool _unlockBackgroundRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_unlockBackgroundRequested) return;
    _unlockBackgroundRequested = true;
    precacheImage(
      const AssetImage('assets/brand/hero_terrain_portrait.png'),
      context,
    );
  }

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
      backgroundColor: kSplashBgTop,
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
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [kSplashBgTop, kSplashBgMid, kSplashBgBottom],
                    stops: [0, .42, 1],
                  ),
                ),
              ),
            ),

            const _EllipticalGlow(
              left: -0.6395,
              top: 0.1905,
              width: 1.1628,
              height: 2.381,
              colors: [
                kSplashGlowLeftStart,
                kSplashGlowLeftMid,
                Colors.transparent,
              ],
              stops: [0, .48, 1],
              opacities: [.221, .0748, 0],
            ),

            const _EllipticalGlow(
              left: 0.3143,
              top: -0.0862,
              width: 1.4286,
              height: 1.7241,
              colors: [
                kSplashGlowRightStart,
                kSplashGlowRightMid,
                Colors.transparent,
              ],
              stops: [0, .55, 1],
              opacities: [.121, .0264, 0],
            ),

            const _BlurredGlow(
              assetPath: 'assets/splash/beam1.svg',
              blurSigma: 90,
            ),
            const _BlurredGlow(
              assetPath: 'assets/splash/beam2.svg',
              blurSigma: 80,
            ),
            const _BlurredGlow(
              assetPath: 'assets/splash/beam3.svg',
              blurSigma: 67.5,
            ),

            IgnorePointer(
              child: FadeTransition(
                opacity: fade,
                child: Align(
                  alignment: const Alignment(0, -0.2326),
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            kSplashHaloStart.withValues(alpha: .06),
                            kSplashHaloMid.withValues(alpha: .02),
                            Colors.transparent,
                          ],
                          stops: const [0, .48, 1],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.2326),
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
                            width: 70,
                            height: 92,
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                Transform.translate(
                                  offset: Offset(0, 18 * (1 - progress)),
                                  child: Opacity(
                                    opacity: .12 * (1 - progress),
                                    child: const _LogoMark(
                                      tint: kSplashGlowLeftMid,
                                    ),
                                  ),
                                ),
                                Transform.translate(
                                  offset: Offset(0, 9 * (1 - progress)),
                                  child: Opacity(
                                    opacity: .28 * (1 - progress),
                                    child: const _LogoMark(
                                      tint: kSplashGlowRightStart,
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: const BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: kSplashShadowColor,
                                        offset: Offset(0, 6),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: const _LogoMark(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'MPC',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: kSplashTitleColor,
                              fontSize: 34,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 34 * .015,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'RWA INFRASTRUCTURE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: kSplashSubtitleColor,
                              fontSize: 10,
                              height: 1,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 10 * .14,
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

class _EllipticalGlow extends StatelessWidget {
  const _EllipticalGlow({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.colors,
    required this.stops,
    required this.opacities,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final List<Color> colors;
  final List<double> stops;
  final List<double> opacities;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width * width;
    final h = size.height * height;
    if (w <= 0 || h <= 0) return const SizedBox.shrink();
    return Positioned(
      left: size.width * left,
      top: size.height * top,
      width: w,
      height: h,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 0.5,
              stops: stops,
              colors: [
                for (var i = 0; i < colors.length; i++)
                  colors[i] == Colors.transparent
                      ? colors[i]
                      : colors[i].withValues(alpha: opacities[i]),
              ],
              transform: _EllipseStretch(h / w),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlurredGlow extends StatelessWidget {
  const _BlurredGlow({required this.assetPath, required this.blurSigma});

  static const _designWidth = 390.0;
  static const _designHeight = 844.0;

  final String assetPath;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Positioned.fill(
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: blurSigma * size.width / _designWidth,
            sigmaY: blurSigma * size.height / _designHeight,
          ),
          child: SvgPicture.asset(
            assetPath,
            fit: BoxFit.fill,
            width: size.width,
            height: size.height,
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({this.tint});

  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/splash/logo_mark.svg',
      width: 62,
      height: 75,
      colorFilter: tint == null
          ? null
          : ColorFilter.mode(tint!, BlendMode.srcIn),
    );
  }
}

class _EllipseStretch extends GradientTransform {
  const _EllipseStretch(this.scaleY);

  final double scaleY;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final cx = bounds.left + bounds.width / 2;
    final cy = bounds.top + bounds.height / 2;
    return Matrix4.identity()
      ..translateByDouble(cx, cy, 0, 1)
      ..scaleByDouble(1.0, scaleY, 1.0, 1.0)
      ..translateByDouble(-cx, -cy, 0, 1);
  }
}
