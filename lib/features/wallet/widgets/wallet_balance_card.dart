import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/wallet_models.dart';

class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({super.key, required this.account});
  final WalletAccount account;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF201A16),
          border: Border.all(color: context.palette.border),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'TOTAL BALANCE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textLo,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3028),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    account.network,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.copper,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${Fmt.token(account.mpcBalance)} MPC',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.64,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: account.address));
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(context.tr('wallet.addressCopied')),
                      ),
                    );
                }
              },
              child: Row(
                children: [
                  Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: context.palette.textLo,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      Fmt.shortAddress(account.address, lead: 6, tail: 5),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textLo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/wallet/receive'),
                      icon: SvgPicture.asset(
                        'assets/icons/wallet/line-arrow-down.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          AppColors.lightTextHi,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: Text(context.tr('wallet.receive')),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.darkPrimaryButtonContent,
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
                ),
                const SizedBox(width: 21),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/wallet/send'),
                      icon: SvgPicture.asset(
                        'assets/icons/wallet/line-arrow-up.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          AppColors.lightTextHi,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: Text(context.tr('wallet.send')),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.lightBg,
                        foregroundColor: AppColors.lightTextHi,
                        side: const BorderSide(color: AppColors.darkBorder),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WalletInfoPill extends StatelessWidget {
  const WalletInfoPill({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
  });
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class WalletStatCol extends StatelessWidget {
  const WalletStatCol({
    super.key,
    required this.value,
    required this.label,
    required this.hasDivider,
  });
  final String value;
  final String label;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.only(right: 8),
        decoration: hasDivider
            ? BoxDecoration(
                border: Border(
                  right: BorderSide(color: context.palette.border),
                ),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.palette.textHi,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: context.palette.textLo),
            ),
          ],
        ),
      ),
    );
  }
}
