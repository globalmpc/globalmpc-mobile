import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/mpc_facts.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/security/wallet_lock_controller.dart';
import '../../core/security/wallet_session_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';
import '../wallet/wallet_provider.dart';
import '../web/web_view_screen.dart';
import 'language_sheet.dart';
import 'theme_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final wallet = context.watch<WalletProvider>().state.data;

    return Scaffold(
      appBar: AppBar(
        leading: const MpcBackButton(fallbackRoute: '/'),
        title: Text(context.tr('settings.title')),
        actions: [
          IconButton(
            tooltip: 'Help & support',
            onPressed: () => context.push('/settings/support'),
            icon: const Icon(Icons.help_outline_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            if (wallet != null) ...[
              GlassCard(
                onTap: () => context.push('/profile'),
                accent: AppColors.gold,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: p.primary.withValues(alpha: 0.16),
                      child: Icon(
                        AppIcons.account_balance_wallet_outlined,
                        color: p.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Fmt.shortAddress(wallet.address, lead: 8, tail: 6),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${wallet.network} · This device',
                            style: TextStyle(color: p.textLo, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    Icon(AppIcons.chevron_right, color: p.textLo),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            const _SettingsLabel('Preferences'),
            _SettingsGroup(
              children: [
                _SettingRow(
                  icon: AppIcons.language,
                  label: context.tr('settings.language'),
                  value: LocaleControllerScope.of(context).language.nativeName,
                  onTap: () => LanguageSheet.show(context),
                ),
                _SettingRow(
                  icon: Icons.brightness_6_outlined,
                  label: context.tr('settings.appearance'),
                  value: context.tr(context.watch<ThemeController>().labelKey),
                  onTap: () => ThemeSheet.show(context),
                ),
                _SettingRow(
                  icon: AppIcons.notify,
                  label: 'Notifications',
                  value: 'Manage',
                  onTap: () => context.push('/settings/notifications'),
                ),
                _SettingRow(
                  icon: Icons.visibility_outlined,
                  label: 'Privacy',
                  value: 'Balances & previews',
                  onTap: () => context.push('/settings/privacy'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SettingsLabel('Wallet & security'),
            _SettingsGroup(
              children: [
                _SettingRow(
                  icon: Icons.shield_outlined,
                  label: 'Security',
                  value: 'PIN & biometrics',
                  onTap: () => context.push('/settings/security'),
                ),
                _SettingRow(
                  icon: Icons.hub_outlined,
                  label: 'Network',
                  value: MpcFacts.networkShort,
                  onTap: () => context.push('/settings/network'),
                ),
                _SettingRow(
                  icon: Icons.key_outlined,
                  label: 'Backup & recovery',
                  value: 'Verify backup',
                  onTap: () => context.push('/settings/recovery'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SettingsLabel('Support & legal'),
            _SettingsGroup(
              children: [
                _SettingRow(
                  icon: Icons.fact_check_outlined,
                  label: 'Security & audit status',
                  value: 'Review',
                  onTap: () => context.push('/settings/audit-status'),
                ),
                _SettingRow(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy & open-source notices',
                  onTap: () => context.push('/settings/legal'),
                ),
                _SettingRow(
                  icon: Icons.info_outline_rounded,
                  label: 'About MPC',
                  value: 'v0.1.0',
                  onTap: () => context.push('/settings/about'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(
                  color: AppColors.danger.withValues(alpha: 0.45),
                ),
              ),
              onPressed: () => _confirmRemoveWallet(context),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Remove wallet from this device'),
            ),
            const SizedBox(height: 12),
            Text(
              'MPC does not use Google or Apple accounts and does not store your recovery phrase.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textLo, fontSize: 11.5, height: 1.4),
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

/// Owns its confirmation controller so it is disposed when the dialog route
/// actually leaves the tree.
///
/// Disposing right after `showDialog` returns is a defect: the pop resolves
/// the future immediately while the dismiss animation keeps rebuilding this
/// subtree, so the still-mounted [TextField] would touch a disposed
/// controller.
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
      title: const Text('Remove wallet?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This removes wallet access and the PIN from this device. You will need your recovery phrase to restore the wallet.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Type REMOVE to continue.',
            style: TextStyle(fontWeight: FontWeight.w700),
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
          child: const Text('Keep wallet'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: _confirmation.text.trim() == 'REMOVE'
              ? () => Navigator.pop(context, true)
              : null,
          child: const Text('Remove from device'),
        ),
      ],
    );
  }
}

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool? _biometrics;
  String autoLock = 'After 1 minute';

  @override
  void initState() {
    super.initState();
    WalletSessionStore.instance.biometricsEnabled().then((value) {
      if (mounted) setState(() => _biometrics = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        leading: const MpcBackButton(fallbackRoute: '/settings'),
        title: const Text('Security'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const _SecurityHero(),
          const SizedBox(height: 24),
          const _SettingsLabel('App access'),
          _SettingsGroup(
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                secondary: const Icon(Icons.fingerprint_rounded),
                title: const Text('Unlock with biometrics'),
                subtitle: const Text('PIN remains available as a fallback'),
                value: _biometrics ?? false,
                onChanged: _biometrics == null
                    ? null
                    : (value) async {
                        await WalletSessionStore.instance.setBiometricsEnabled(
                          value,
                        );
                        if (mounted) setState(() => _biometrics = value);
                      },
              ),
              _SettingRow(
                icon: Icons.password_rounded,
                label: 'Change app PIN',
                value: '6 digits',
                onTap: () => context.push('/settings/change-pin'),
              ),
              _SettingRow(
                icon: Icons.timer_outlined,
                label: 'Auto-lock',
                value: autoLock,
                onTap: _chooseAutoLock,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.phonelink_lock_outlined,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'MPC asks for your PIN or biometrics before sensitive actions. Your recovery phrase is the only way to restore the wallet on another device.',
                    style: TextStyle(color: p.textLo, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseAutoLock() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Auto-lock',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Require verification after inactivity'),
            ),
            for (final option in const [
              'Immediately',
              'After 1 minute',
              'After 5 minutes',
              'After 15 minutes',
            ])
              ListTile(
                title: Text(option),
                trailing: option == autoLock
                    ? const Icon(Icons.check_rounded, color: AppColors.gold)
                    : null,
                onTap: () => Navigator.pop(context, option),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (choice != null && mounted) setState(() => autoLock = choice);
  }
}

class NetworkSettingsScreen extends StatelessWidget {
  const NetworkSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimpleSettingsPage(
      title: 'Network',
      children: [
        const GlassCard(
          accent: AppColors.gold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Pill('Active network', color: AppColors.positive),
              SizedBox(height: 14),
              Text(
                MpcFacts.network,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6),
              Text('Chain ID 56 · MPC transfers use BNB for network fees.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsGroup(
          children: [
            _SettingRow(
              icon: Icons.token_outlined,
              label: 'MPC contract',
              // Derived, never transcribed: a hand-copied address that drifts
              // from [MpcFacts] would point a user at the wrong contract.
              value: Fmt.shortAddress(MpcFacts.contractAddress),
              onTap: () => context.push(
                '/webview',
                extra: WebViewArgs(
                  url: MpcFacts.explorerTokenUrl,
                  title: 'MPC on BscScan',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool transactions = true;
  bool projects = true;
  bool security = true;

  @override
  Widget build(BuildContext context) {
    return _SimpleSettingsPage(
      title: 'Notifications',
      children: [
        _SettingsGroup(
          children: [
            _NotificationToggle(
              title: 'Wallet activity',
              subtitle: 'Sent, received, pending, and failed transactions',
              value: transactions,
              onChanged: (value) => setState(() => transactions = value),
            ),
            _NotificationToggle(
              title: 'Project updates',
              subtitle: 'Milestones and material project changes',
              value: projects,
              onChanged: (value) => setState(() => projects = value),
            ),
            _NotificationToggle(
              title: 'Security alerts',
              subtitle: 'Important wallet and device access events',
              value: security,
              onChanged: (value) => setState(() => security = value),
            ),
          ],
        ),
      ],
    );
  }
}

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool hideBalances = false;
  bool hidePreviews = true;

  @override
  Widget build(BuildContext context) => _SimpleSettingsPage(
    title: 'Privacy',
    children: [
      _SettingsGroup(
        children: [
          _NotificationToggle(
            title: 'Hide wallet balances',
            subtitle: 'Mask amounts until you tap to reveal them',
            value: hideBalances,
            onChanged: (value) => setState(() => hideBalances = value),
          ),
          _NotificationToggle(
            title: 'Hide notification previews',
            subtitle: 'Keep amounts and addresses off the lock screen',
            value: hidePreviews,
            onChanged: (value) => setState(() => hidePreviews = value),
          ),
        ],
      ),
      const SizedBox(height: 18),
      const GlassCard(
        child: Text(
          'MPC uses your public wallet address as identity. It does not require Google or Apple login.',
          style: TextStyle(height: 1.45),
        ),
      ),
    ],
  );
}

class SupportSettingsScreen extends StatelessWidget {
  const SupportSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => _SimpleSettingsPage(
    title: 'Help & support',
    children: [
      _SettingsGroup(
        children: [
          _SettingRow(
            icon: Icons.menu_book_outlined,
            label: 'Help centre',
            onTap: () =>
                _open(context, 'https://www.globalmpc.tech/', 'MPC Help'),
          ),
          _SettingRow(
            icon: Icons.bug_report_outlined,
            label: 'Report a problem',
            value: 'Include app version',
            onTap: () => _open(
              context,
              'https://www.globalmpc.tech/',
              'Report a problem',
            ),
          ),
          _SettingRow(
            icon: Icons.shield_outlined,
            label: 'Report a security issue',
            onTap: () =>
                _open(context, 'https://www.globalmpc.tech/', 'Security'),
          ),
        ],
      ),
      const SizedBox(height: 18),
      const GlassCard(
        accent: AppColors.warning,
        child: Text(
          'MPC support will never ask for your PIN or recovery phrase.',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );

  void _open(BuildContext context, String url, String title) {
    context.push(
      '/webview',
      extra: WebViewArgs(url: url, title: title),
    );
  }
}

class AuditStatusScreen extends StatelessWidget {
  const AuditStatusScreen({super.key});

  @override
  Widget build(BuildContext context) => const _SimpleSettingsPage(
    title: 'Security & audit status',
    children: [
      GlassCard(
        accent: AppColors.warning,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Pill('In progress', color: AppColors.warning),
            SizedBox(height: 14),
            Text(
              'Production security review',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 7),
            Text(
              'Internal and independent reviews are planned before production release. No completed audit is claimed yet.',
              style: TextStyle(height: 1.45),
            ),
          ],
        ),
      ),
      SizedBox(height: 16),
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What will be published',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 12),
            Text('• Critical component review status'),
            SizedBox(height: 7),
            Text('• Open-source license notices'),
            SizedBox(height: 7),
            Text('• Known limitations and resolved findings'),
            SizedBox(height: 7),
            Text('• Public repository and release evidence'),
          ],
        ),
      ),
    ],
  );
}

class RecoverySettingsScreen extends StatelessWidget {
  const RecoverySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimpleSettingsPage(
      title: 'Recovery phrase',
      children: [
        const GlassCard(
          accent: AppColors.warning,
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: AppColors.warning),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup not verified',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 3),
                    Text('Verify that you stored the phrase correctly.'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const GlassCard(
          accent: AppColors.warning,
          child: Column(
            children: [
              Icon(Icons.visibility_off_outlined, size: 42),
              SizedBox(height: 16),
              Text(
                'Your recovery phrase controls your wallet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text(
                'Never share it. MPC support will never ask for it.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.push('/settings/recovery/auth'),
          child: const Text('View recovery phrase'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => context.push('/settings/recovery/verify'),
          child: const Text('Verify my backup'),
        ),
      ],
    );
  }
}

class VerifyBackupScreen extends StatefulWidget {
  const VerifyBackupScreen({super.key});

  @override
  State<VerifyBackupScreen> createState() => _VerifyBackupScreenState();
}

class _VerifyBackupScreenState extends State<VerifyBackupScreen> {
  String? word4;
  String? word9;
  bool checked = false;

  @override
  Widget build(BuildContext context) {
    final valid = word4 == 'ledger' && word9 == 'secure' && checked;
    return _SimpleSettingsPage(
      title: 'Verify backup',
      children: [
        const Text(
          'Confirm two words from your recovery phrase.',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'This check stays on your device.',
          style: TextStyle(color: context.palette.textLo),
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          initialValue: word4,
          decoration: const InputDecoration(labelText: 'Word 4'),
          items: const ['copper', 'ledger', 'proof', 'terrain']
              .map((word) => DropdownMenuItem(value: word, child: Text(word)))
              .toList(),
          onChanged: (value) => setState(() => word4 = value),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: word9,
          decoration: const InputDecoration(labelText: 'Word 9'),
          items: const ['forest', 'orbit', 'secure', 'verify']
              .map((word) => DropdownMenuItem(value: word, child: Text(word)))
              .toList(),
          onChanged: (value) => setState(() => word9 = value),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: checked,
          onChanged: (value) => setState(() => checked = value ?? false),
          title: const Text(
            'I stored the phrase somewhere private and offline.',
          ),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: valid
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup verified')),
                  );
                  context.pop();
                }
              : null,
          child: const Text('Mark backup as verified'),
        ),
      ],
    );
  }
}

class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimpleSettingsPage(
      title: 'About MPC',
      children: [
        GlassCard(
          child: Column(
            children: [
              Icon(
                AppIcons.account_balance_wallet_rounded,
                color: AppColors.gold,
                size: 46,
              ),
              SizedBox(height: 14),
              Text(
                'Global MPC',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6),
              Text(
                'A mobile DApp with an embedded non-custodial wallet for transparent RWA infrastructure.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Pill('Version 0.1.0 (3)', color: AppColors.info),
            ],
          ),
        ),
      ],
    );
  }
}

class LegalSettingsScreen extends StatelessWidget {
  const LegalSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimpleSettingsPage(
      title: 'Privacy & notices',
      children: [
        GlassCard(
          child: Text(
            'MPC uses the wallet address as identity. No Google or Apple login is used. Recovery phrases are not stored by MPC. Open-source dependencies and audit references will be published with the production repository.',
            style: TextStyle(height: 1.55),
          ),
        ),
      ],
    );
  }
}

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();
  String? error;
  bool saving = false;

  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const MpcBackButton(fallbackRoute: '/settings/security'),
      title: const Text('Change app PIN'),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        const Text(
          'Use a PIN you do not use elsewhere.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'The PIN protects wallet access on this device. It cannot restore your wallet.',
          style: TextStyle(color: context.palette.textLo, height: 1.4),
        ),
        const SizedBox(height: 24),
        _PinField(controller: current, label: 'Current PIN'),
        const SizedBox(height: 16),
        _PinField(controller: next, label: 'New PIN'),
        const SizedBox(height: 16),
        _PinField(controller: confirm, label: 'Confirm new PIN'),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: const TextStyle(color: AppColors.danger)),
        ],
        const SizedBox(height: 28),
        FilledButton(
          onPressed: saving ? null : _save,
          child: Text(saving ? 'Updating…' : 'Update PIN'),
        ),
      ],
    ),
  );

  Future<void> _save() async {
    if (current.text.length != 6 ||
        next.text.length != 6 ||
        confirm.text.length != 6) {
      setState(() => error = 'Enter all 6 digits in each field.');
      return;
    }
    if (next.text != confirm.text) {
      setState(() => error = 'The new PINs do not match.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final valid = await WalletSessionStore.instance.verifyPin(current.text);
    if (!mounted) return;
    if (!valid) {
      setState(() {
        saving = false;
        error = 'Current PIN is incorrect.';
      });
      return;
    }
    await WalletSessionStore.instance.updatePin(next.text);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('App PIN updated')));
    context.pop();
  }
}

class RecoveryAuthScreen extends StatefulWidget {
  const RecoveryAuthScreen({super.key});

  @override
  State<RecoveryAuthScreen> createState() => _RecoveryAuthScreenState();
}

class _RecoveryAuthScreenState extends State<RecoveryAuthScreen> {
  final pin = TextEditingController();
  String? error;
  bool revealed = false;

  @override
  void dispose() {
    pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const MpcBackButton(fallbackRoute: '/settings/recovery'),
      title: Text(revealed ? 'Recovery phrase' : 'Confirm it’s you'),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: revealed ? _revealedContent(context) : _authContent(context),
    ),
  );

  List<Widget> _authContent(BuildContext context) => [
    const Icon(Icons.lock_outline_rounded, size: 48),
    const SizedBox(height: 18),
    const Text(
      'Enter your app PIN',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 8),
    Text(
      'Make sure no one can see your screen.',
      textAlign: TextAlign.center,
      style: TextStyle(color: context.palette.textLo),
    ),
    const SizedBox(height: 28),
    _PinField(controller: pin, label: 'App PIN', error: error),
    const SizedBox(height: 24),
    FilledButton(onPressed: _verify, child: const Text('Reveal phrase')),
  ];

  List<Widget> _revealedContent(BuildContext context) => [
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: const Text(
        'Never copy this into a message, website, or support chat.',
        textAlign: TextAlign.center,
      ),
    ),
    const SizedBox(height: 18),
    GlassCard(
      accent: AppColors.gold,
      child: Wrap(
        spacing: 8,
        runSpacing: 10,
        children: [
          for (var i = 0; i < _recoveryWords.length; i++)
            Container(
              width: 142,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: context.palette.surfaceHi,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.palette.border),
              ),
              child: Text('${i + 1}. ${_recoveryWords[i]}'),
            ),
        ],
      ),
    ),
    const SizedBox(height: 22),
    FilledButton(
      onPressed: () => context.go('/wallet'),
      child: const Text('I have stored it safely'),
    ),
  ];

  Future<void> _verify() async {
    if (pin.text.length != 6) {
      setState(() => error = 'Enter all 6 digits.');
      return;
    }
    final valid = await WalletSessionStore.instance.verifyPin(pin.text);
    if (!mounted) return;
    setState(() {
      error = valid ? null : 'Incorrect PIN. Try again.';
      revealed = valid;
    });
  }

  static const _recoveryWords = [
    'audit',
    'copper',
    'forest',
    'ledger',
    'mineral',
    'orbit',
    'proof',
    'quartz',
    'secure',
    'terrain',
    'verify',
    'wallet',
  ];
}

class _PinField extends StatelessWidget {
  const _PinField({required this.controller, required this.label, this.error});

  final TextEditingController controller;
  final String label;
  final String? error;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: true,
    maxLength: 6,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(
      labelText: label,
      counterText: '',
      errorText: error,
    ),
  );
}

class _SimpleSettingsPage extends StatelessWidget {
  const _SimpleSettingsPage({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const MpcBackButton(fallbackRoute: '/settings'),
      title: Text(title),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: children,
    ),
  );
}

class _SettingsLabel extends StatelessWidget {
  const _SettingsLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 9),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        color: context.palette.textLo,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    ),
  );
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Material(color: Colors.transparent, child: children[i]),
          if (i < children.length - 1) const SizedBox(height: 2),
        ],
      ],
    ),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 58,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
    leading: Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.palette.bg,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: context.palette.textLo, size: 20),
    ),
    title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (value != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              value!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.palette.textLo, fontSize: 12.5),
            ),
          ),
        const SizedBox(width: 4),
        Icon(AppIcons.chevron_right, color: context.palette.textLo, size: 20),
      ],
    ),
    onTap: onTap,
  );
}

class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(subtitle),
    value: value,
    onChanged: onChanged,
  );
}

class _SecurityHero extends StatelessWidget {
  const _SecurityHero();

  @override
  Widget build(BuildContext context) => const GlassCard(
    accent: AppColors.positive,
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: Color(0x1850986B),
          child: Icon(Icons.verified_user_outlined, color: AppColors.positive),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wallet protection is active',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text('Sensitive actions require device verification.'),
            ],
          ),
        ),
      ],
    ),
  );
}
