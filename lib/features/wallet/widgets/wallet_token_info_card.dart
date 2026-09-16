import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/mpc_facts.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../web/web_view_screen.dart';
import 'wallet_balance_card.dart';

class WalletTokenInfoCard extends StatelessWidget {
  const WalletTokenInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: context.palette.surface,
          border: Border.all(color: context.palette.cardBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                WalletInfoPill(
                  label: '◇ ${context.tr('dash.utilityToken')}',
                  bg: context.palette.pillNeutralBg,
                  fg: context.palette.textLo,
                ),
                WalletInfoPill(
                  label: MpcFacts.networkShort,
                  bg: context.palette.pillInfoBg,
                  fg: AppColors.info,
                ),
                WalletInfoPill(
                  label: context.tr('facts.plannedStandard'),
                  bg: context.palette.pillAmberBg,
                  fg: AppColors.copper,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              context.tr(MpcFacts.taglineKey),
              style: TextStyle(
                fontSize: 12,
                height: 1.42,
                color: context.palette.textLo,
              ),
            ),
            const SizedBox(height: 16),

            IntrinsicHeight(
              child: Row(
                children: [
                  WalletStatCol(
                    value: Fmt.compact(MpcFacts.totalSupply),
                    label: context.tr('dash.totalSupply'),
                    hasDivider: true,
                  ),
                  WalletStatCol(
                    value: MpcFacts.networkShort,
                    label: context.tr('dash.network'),
                    hasDivider: true,
                  ),
                  WalletStatCol(
                    value: context.tr('common.pending'),
                    label: context.tr('dash.listing'),
                    hasDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: context.palette.insetBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tag_rounded,
                        size: 12,
                        color: context.palette.textLo,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        context.tr('dash.contract'),
                        style: TextStyle(
                          fontSize: 11,
                          color: context.palette.textLo,
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          Fmt.shortAddress(
                            MpcFacts.contractAddress,
                            lead: 6,
                            tail: 4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.palette.textHi,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      GestureDetector(
                        onTap: () async {
                          await Clipboard.setData(
                            const ClipboardData(text: MpcFacts.contractAddress),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.tr('wallet.addressCopied'),
                                  ),
                                ),
                              );
                          }
                        },
                        child: SvgPicture.asset(
                          'assets/icons/auth/copy.svg',
                          width: 16,
                          height: 16,
                        ),
                      ),
                      const SizedBox(width: 7),
                      GestureDetector(
                        onTap: () => context.push(
                          '/webview',
                          extra: WebViewArgs(
                            url: MpcFacts.explorerTokenUrl,
                            title: MpcFacts.networkShort,
                          ),
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/dashboard/external-link.svg',
                          width: 14,
                          height: 14,
                          colorFilter: const ColorFilter.mode(
                            AppColors.copper,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Divider(height: 1, color: context.palette.insetDivider),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 14,
                        color: context.palette.textLo,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        context.tr('dash.issuer'),
                        style: TextStyle(
                          fontSize: 11,
                          color: context.palette.textLo,
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          MpcFacts.issuer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.palette.textHi,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: () => context.push(
                  '/webview',
                  extra: WebViewArgs(
                    url: MpcFacts.explorerTokenUrl,
                    title: MpcFacts.networkShort,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.palette.textHi,
                  side: const BorderSide(color: AppColors.amber),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/dashboard/external-link.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        AppColors.copper,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('dash.explorer'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 15 / 12,
                        color: context.palette.textHi,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
