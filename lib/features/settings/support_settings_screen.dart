import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../web/web_view_screen.dart';
import 'settings_widgets.dart';

class SupportSettingsScreen extends StatelessWidget {
  const SupportSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: SettingsAppBar(title: context.tr('settings.support.title')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          SettingsLabel(context.tr('settings.support.getHelp')),
          SettingsGroup(
            borderColor: const Color(0xFFE8E0D8),
            children: [
              SettingRow(
                label: context.tr('settings.faq.recovery'),
                trailing: const _SupportChevron(),
                onTap: () => _open(
                  context,
                  'https://www.globalmpc.tech/',
                  context.tr('settings.faq.recovery'),
                ),
              ),
              SettingRow(
                label: context.tr('settings.faq.sending'),
                trailing: const _SupportChevron(),
                onTap: () => _open(
                  context,
                  'https://www.globalmpc.tech/',
                  context.tr('settings.faq.sendingTitle'),
                ),
              ),
              SettingRow(
                label: context.tr('settings.faq.fees'),
                trailing: const _SupportChevron(),
                onTap: () => _open(
                  context,
                  'https://www.globalmpc.tech/',
                  context.tr('settings.faq.fees'),
                ),
              ),
              SettingRow(
                label: context.tr('settings.faq.security'),
                trailing: const _SupportChevron(),
                onTap: () => _open(
                  context,
                  'https://www.globalmpc.tech/',
                  context.tr('settings.faq.security'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsLabel(context.tr('settings.support.contact')),
          SettingsGroup(
            borderColor: const Color(0xFFE8E0D8),
            children: [
              SettingRow(
                label: context.tr('settings.support.contactSupport'),
                trailing: const _SupportChevron(),
                onTap: () => _open(
                  context,
                  'https://www.globalmpc.tech/',
                  context.tr('settings.support.contactSupport'),
                ),
              ),
              SettingRow(
                label: context.tr('settings.support.report'),
                trailing: const _SupportChevron(),
                onTap: () => _open(
                  context,
                  'https://www.globalmpc.tech/',
                  context.tr('settings.support.report'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, String url, String title) {
    context.push(
      '/webview',
      extra: WebViewArgs(url: url, title: title),
    );
  }
}

class _SupportChevron extends StatelessWidget {
  const _SupportChevron();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/wallet/chevron-right.svg',
      width: 5,
      height: 10,
    );
  }
}
