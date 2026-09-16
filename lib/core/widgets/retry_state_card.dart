import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

class RetryStateCard extends StatelessWidget {
  const RetryStateCard({
    super.key,
    required this.iconAsset,
    required this.iconSize,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onRetry,
  });

  final String iconAsset;
  final double iconSize;
  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SvgPicture.asset(iconAsset, width: iconSize, height: iconSize),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: p.textHi,
              height: 22 / 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: p.textLo, height: 16 / 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 49,
            child: FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.lightTextHi,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 17 / 14,
                  color: AppColors.lightTextHi,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
