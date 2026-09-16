import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/chain_config.dart';
import '../../core/constants/mpc_facts.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';
import '../web/web_view_screen.dart';
import 'settings_widgets.dart';

class NetworkSettingsScreen extends StatelessWidget {
  const NetworkSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleSettingsPage(
      title: context.tr('dash.network'),
      children: [
        GlassCard(
          accent: AppColors.gold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Pill(
                context.tr('settings.security.activeNetwork'),
                color: AppColors.positive,
              ),
              const SizedBox(height: 14),
              Text(
                MpcFacts.network,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context
                    .tr('settings.security.chainNote')
                    .replaceFirst(
                      '{chainId}',
                      '${ChainConfig.bscTestnet.chainId}',
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsGroup(
          children: [
            SettingRow(
              label: context.tr('settings.security.contract'),
              value: Fmt.shortAddress(MpcFacts.contractAddress),
              onTap: () => context.push(
                '/webview',
                extra: WebViewArgs(
                  url: MpcFacts.explorerTokenUrl,
                  title: context.tr('settings.security.contract'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
