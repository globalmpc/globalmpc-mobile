import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_info.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../web/web_view_screen.dart';
import 'settings_widgets.dart';

const _lightPageBg = Color(0xFFF8F5F1);
const _headerCardBorder = Color(0xFFFCFAF7);
const _rowBorder = Color(0xFFE8E0D8);
const _rowArrow = Color(0xFFE8E0D8);

class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final pageBg = isLight ? _lightPageBg : p.bg;
    return Scaffold(
      backgroundColor: pageBg,
      appBar: SettingsAppBar(
        title: context.tr('settings.about.title'),
        backgroundColor: pageBg,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: p.surface,
              border: Border.all(
                color: settingsCardBorder(context, _headerCardBorder),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'globalMPC',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 24 / 20,
                    color: p.textHi,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.tr('settings.about.tagline'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 16 / 13,
                    color: p.textLo,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context
                      .tr('settings.about.version')
                      .replaceFirst('{v}', appVersion),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 13 / 11,
                    color: p.textLo,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _AboutLinkRow(
            label: context.tr('settings.about.terms'),
            onTap: () => context.push(
              '/webview',
              extra: WebViewArgs(
                url: 'https://www.globalmpc.tech/',
                title: context.tr('settings.about.terms'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _AboutLinkRow(
            label: context.tr('settings.about.privacy'),
            onTap: () => context.push(
              '/webview',
              extra: WebViewArgs(
                url: 'https://www.globalmpc.tech/',
                title: context.tr('settings.about.privacy'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _AboutLinkRow(
            label: context.tr('settings.about.licences'),
            onTap: () => showLicensePage(context: context),
          ),
          const SizedBox(height: 16),
          _AboutLinkRow(
            label: context.tr('settings.about.website'),
            value: 'globalmpc.tech',
            onTap: () => context.push(
              '/webview',
              extra: WebViewArgs(
                url: 'https://www.globalmpc.tech/',
                title: 'globalMPC',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutLinkRow extends StatelessWidget {
  const _AboutLinkRow({required this.label, required this.onTap, this.value});

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border.all(color: settingsCardBorder(context, _rowBorder)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 16 / 13,
                  color: p.textHi,
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (value != null)
              Text(
                value!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 15 / 12,
                  color: p.textLo,
                ),
              )
            else
              SvgPicture.asset(
                'assets/icons/wallet/arrow-right.svg',
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(_rowArrow, BlendMode.srcIn),
              ),
          ],
        ),
      ),
    );
  }
}

class LegalSettingsScreen extends StatelessWidget {
  const LegalSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: SettingsAppBar(title: context.tr('settings.legal.title')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          SettingsLabel(context.tr('settings.privacy.label')),
          SettingsGroup(
            borderColor: const Color(0xFFE8E0D8),
            children: [
              SettingRow(
                label: context.tr('settings.about.privacy'),
                onTap: () => context.push(
                  '/webview',
                  extra: WebViewArgs(
                    url: 'https://www.globalmpc.tech/',
                    title: context.tr('settings.about.privacy'),
                  ),
                ),
              ),
              SettingRow(
                label: context.tr('settings.legal.identity'),
                value: context.tr('settings.legal.identityValue'),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsLabel(context.tr('settings.legal.openSource')),
          SettingsGroup(
            borderColor: const Color(0xFFE8E0D8),
            children: [
              SettingRow(
                label: context.tr('settings.about.licences'),
                value: context.tr('settings.legal.review'),
                onTap: () => showLicensePage(context: context),
              ),
              SettingRow(label: context.tr('settings.legal.ack'), onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}
