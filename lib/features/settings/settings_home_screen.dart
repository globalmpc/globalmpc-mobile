import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_info.dart';
import '../../core/constants/mpc_facts.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/security/wallet_lock_controller.dart';
import '../../core/security/wallet_session_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/formatters.dart';
import '../wallet/wallet_provider.dart';
import 'language_sheet.dart';
import 'theme_sheet.dart';
import 'settings_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _storedAddress;

  @override
  void initState() {
    super.initState();
    WalletSessionStore.instance.walletAddress().then((addr) {
      if (mounted && addr != null) setState(() => _storedAddress = addr);
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletState = context.watch<WalletProvider>().state;
    final wallet = walletState.data;
    final displayAddress = wallet?.address ?? _storedAddress;
    final displayNetwork = wallet?.network ?? MpcFacts.network;
    final p = context.palette;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final pageBg = isLight ? const Color(0xFFF8F5F1) : p.bg;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: SettingsAppBar(
        title: context.tr('settings.title'),
        fallbackRoute: '/',
        backgroundColor: pageBg,
        actions: [
          GestureDetector(
            onTap: () => context.push('/settings/support'),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE8E0D8)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Builder(
                builder: (context) {
                  final label = context.tr('settings.needHelp');
                  final rest = label.substring(0, label.length - 1);
                  final mark = label.substring(label.length - 1);
                  return Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: rest,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.copper,
                          ),
                        ),
                        TextSpan(
                          text: mark,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFC96B28),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
          children: [
            if (displayAddress != null) ...[
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
                  decoration: BoxDecoration(
                    color: p.surface,
                    border: Border.all(
                      color: settingsCardBorder(
                        context,
                        const Color(0xFFE8E0D8),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F0C0A),
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/wallet/mpc-logo.svg',
                          width: 32,
                          height: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Fmt.shortAddress(
                                displayAddress,
                                lead: 10,
                                tail: 5,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: p.textHi,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$displayNetwork · This device',
                              style: TextStyle(color: p.textLo, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      SvgPicture.asset(
                        'assets/icons/wallet/arrow-right.svg',
                        width: 16,
                        height: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 27),
            ],
            SettingsLabel(context.tr('settings.section.preferences')),
            SettingsGroup(
              children: [
                SettingRow(
                  label: context.tr('settings.language'),
                  value: LocaleControllerScope.of(context).language.nativeName,
                  onTap: () => LanguageSheet.show(context),
                ),
                SettingRow(
                  label: context.tr('settings.appearance'),
                  value: context.tr(context.watch<ThemeController>().labelKey),
                  onTap: () => ThemeSheet.show(context),
                ),
                SettingRow(
                  label: context.tr('settings.notify.label'),
                  value: context.tr('settings.notify.manage'),
                  onTap: () => context.push('/settings/notifications'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsLabel(context.tr('settings.section.wallet')),
            SettingsGroup(
              children: [
                SettingRow(
                  label: context.tr('settings.security'),
                  value: context.tr('settings.pinBiometrics'),
                  onTap: () => context.push('/settings/security'),
                ),
                SettingRow(
                  label: context.tr('dash.network'),
                  value: MpcFacts.network,
                  onTap: () => context.push('/settings/network'),
                ),
                SettingRow(
                  label: context.tr('settings.backup'),
                  value: context.tr('settings.verifyBackup'),
                  onTap: () => context.push('/settings/recovery/auth'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsLabel(context.tr('settings.section.appInfo')),
            SettingsGroup(
              children: [
                SettingRow(
                  label: context.tr('settings.privacyNotices'),
                  onTap: () => context.push('/settings/legal'),
                ),
                SettingRow(
                  label: context.tr('settings.about'),
                  value: 'v$appVersion',
                  onTap: () => context.push('/settings/about'),
                ),
                SettingRow(
                  label: context.tr('settings.rateUs'),
                  value: context.tr('settings.review'),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 27),
            GestureDetector(
              onTap: () => _confirmRemoveWallet(context),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 16, 10, 18),
                decoration: BoxDecoration(
                  color: p.surface,
                  border: Border.all(color: const Color(0xFFC95E3C)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    context.tr('settings.removeWallet'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC95E3C),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 27),
            Text(
              'MPC app v$appVersion',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: p.textLo),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemoveWallet(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _RemoveWalletDialog(),
    );
    if (confirmed != true || !context.mounted) return;
    await WalletSessionStore.instance.clear();
    WalletLockController.instance.markWalletCleared();
    if (context.mounted) context.go('/onboarding');
  }
}

class _RemoveWalletDialog extends StatefulWidget {
  const _RemoveWalletDialog();

  @override
  State<_RemoveWalletDialog> createState() => _RemoveWalletDialogState();
}

class _RemoveWalletDialogState extends State<_RemoveWalletDialog> {
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
      title: Text(context.tr('settings.remove.title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('settings.remove.body')),
          const SizedBox(height: 16),
          Text(
            context.tr('settings.remove.type'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmation,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr('settings.remove.keep')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: _confirmation.text.trim() == 'REMOVE'
              ? () => Navigator.pop(context, true)
              : null,
          child: Text(context.tr('settings.remove.confirm')),
        ),
      ],
    );
  }
}
