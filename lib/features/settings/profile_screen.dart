import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_environment.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';
import '../wallet/wallet_provider.dart';
import '../web/web_view_screen.dart';
import 'settings_widgets.dart';

/// Wallet identity. There are no user accounts and no personal data, by
/// explicit product decision: the wallet address IS the identity. Today this shows
/// the labelled demo wallet; the create / import flow replaces it when the
/// non-custodial wallet ships.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final wallet = context.watch<WalletProvider>().state.data;

    return Scaffold(
      appBar: AppBar(
        leading: const MpcBackButton(
          fallbackRoute: '/settings',
          iconAsset: 'assets/icons/wallet/back-arrow-circle.svg',
          iconSize: 28,
        ),
        title: Text(context.tr('profile.title')),
      ),
      body: SafeArea(
        top: false,
        child: wallet == null
            ? StateMessage(
                icon: AppIcons.account_balance_wallet_outlined,
                title: context.tr('wallet.unavailable'),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _WalletIdentityCard(
                    address: wallet.address,
                    network: wallet.network,
                    isDemo: wallet.isDemo,
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(context.tr('profile.details')),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    borderColor: settingsCardBorder(context, p.border),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: AppIcons.account_balance_wallet_outlined,
                          label: context.tr('dash.network'),
                          value: wallet.network,
                        ),
                        Divider(color: p.border, height: 1),
                        _InfoRow(
                          icon: AppIcons.tag,
                          label: context.tr('profile.walletAddress'),
                          value: Fmt.shortAddress(wallet.address),
                          onCopy: () => _copy(context, wallet.address),
                          onOpen: () => _openExplorer(
                            context,
                            wallet.address,
                            isDemo: wallet.isDemo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.tr('wallet.addressCopied'))),
        );
    }
  }

  void _openExplorer(
    BuildContext context,
    String address, {
    required bool isDemo,
  }) {
    // The explorer must match the chain the wallet actually lives on, or the
    // address page comes up empty.
    final chain = AppEnvironment.current.chain;
    context.push(
      '/webview',
      extra: WebViewArgs(
        url: chain.explorerAddressUrl(address),
        title: chain.networkShort,
      ),
    );
  }
}

class _WalletIdentityCard extends StatelessWidget {
  const _WalletIdentityCard({
    required this.address,
    required this.network,
    required this.isDemo,
  });

  final String address;
  final String network;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      padding: const EdgeInsets.all(20),
      accent: p.accent,
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: p.primary.withValues(alpha: 0.18),
            child: Icon(
              AppIcons.account_balance_wallet_outlined,
              color: p.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            Fmt.shortAddress(address),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: [
              Pill(
                network,
                color: p.primary,
                icon: AppIcons.account_balance_wallet_outlined,
              ),
              if (isDemo)
                Pill(
                  context.tr('dash.demo'),
                  color: AppColors.warning,
                  icon: AppIcons.info_outline,
                )
              else if (!AppEnvironment.current.chain.isMainnet)
                Pill(
                  context.tr('dash.testnet'),
                  color: AppColors.warning,
                  icon: AppIcons.info_outline,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
    this.onOpen,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: p.textLo),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(color: p.textLo)),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (onOpen != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onOpen,
              icon: Icon(AppIcons.open_in_new, size: 16, color: p.primary),
            ),
          if (onCopy != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onCopy,
              icon: Icon(AppIcons.copy_rounded, size: 16, color: p.textLo),
            ),
        ],
      ),
    );
  }
}
