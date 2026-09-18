import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/platform/external_link.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../web/web_view_screen.dart';

/// Entry point to the presale website. The app shows no sale terms itself:
/// the website decides what a visitor may see, so the card only hands the
/// user over to it, in their own browser.
class PresaleCard extends StatelessWidget {
  const PresaleCard({super.key, required this.url});

  final String url;

  Future<void> _open(BuildContext context) async {
    if (await ExternalLink.open(url)) return;
    if (!context.mounted) return;
    context.push(
      '/webview',
      extra: WebViewArgs(url: url, title: context.tr('presale.title')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      borderColor: p.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F0C0A),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  'assets/brand/mpc-token.svg',
                  width: 26,
                  height: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr('presale.title'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 17 / 14,
                    color: p.textHi,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('presale.body'),
            style: TextStyle(fontSize: 12, height: 16 / 12, color: p.textLo),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed: () => _open(context),
              icon: SvgPicture.asset(
                'assets/icons/dashboard/external-link.svg',
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(p.onPrimary, BlendMode.srcIn),
              ),
              label: Text(
                context.tr('presale.open'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: FilledButton.styleFrom(
                minimumSize: Size.zero,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('presale.external'),
            style: TextStyle(
              fontSize: 11,
              height: 13 / 11,
              color: AppColors.balanceLabelText,
            ),
          ),
        ],
      ),
    );
  }
}
