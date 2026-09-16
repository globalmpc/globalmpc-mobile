import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

class MpcLogo extends StatelessWidget {
  const MpcLogo({super.key, this.size = 40, this.tint});

  final double size;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/brand/logo.svg',
      width: size,
      height: size,
      colorFilter: tint == null
          ? null
          : ColorFilter.mode(tint!, BlendMode.srcIn),
    );
  }
}

class MpcLogoTile extends StatelessWidget {
  const MpcLogoTile({super.key, this.size = 44, this.radius = 13});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.terracotta, AppColors.gold, AppColors.goldSoft],
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: MpcLogo(size: size * 0.62, tint: const Color(0xFF241703)),
    );
  }
}
