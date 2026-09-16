import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/notifications/notification_center.dart';
import '../../core/security/biometric_auth.dart';
import '../../core/security/wallet_lock_controller.dart';
import '../../core/security/wallet_session_store.dart';
import '../../core/theme/app_colors.dart';
import 'settings_widgets.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool? _biometrics;

  @override
  void initState() {
    super.initState();
    WalletSessionStore.instance.biometricsEnabled().then((v) {
      if (mounted) setState(() => _biometrics = v);
    });
  }

  Future<void> _setBiometrics(bool enable) async {
    final store = WalletSessionStore.instance;
    if (!enable) {
      await store.setBiometricsEnabled(false);
      await NotificationCenter.instance.notifySecurity(
        'notif.sec.biometricsOff.title',
        'notif.sec.biometricsOff.body',
      );
      if (mounted) setState(() => _biometrics = false);
      return;
    }
    final auth = BiometricAuth();
    final availability = await auth.availability();
    if (!mounted) return;
    if (availability != BiometricAvailability.ready) {
      _notice(switch (availability) {
        BiometricAvailability.notEnrolled => context.tr('settings.bio.enrol'),
        _ => context.tr('settings.bio.unsupported'),
      });
      return;
    }
    final result = await WalletLockController.instance.runSystemPrompt(
      () => auth.authenticate(reason: context.tr('settings.bio.authReason')),
    );
    if (!mounted) return;
    switch (result) {
      case BiometricResult.success:
        await store.setBiometricsEnabled(true);
        await NotificationCenter.instance.notifySecurity(
          'notif.sec.biometricsOn.title',
          'notif.sec.biometricsOn.body',
        );
        if (mounted) setState(() => _biometrics = true);
      case BiometricResult.cancelled:
        break;
      case BiometricResult.lockedOut:
        _notice(context.tr('settings.bio.locked'));
      case BiometricResult.notEnrolled:
        _notice(context.tr('settings.bio.enrol'));
      case BiometricResult.unavailable:
        _notice(context.tr('settings.bio.unavailable'));
    }
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: SettingsAppBar(title: context.tr('settings.security.title')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          SettingsLabel(context.tr('settings.security.access')),
          SettingsGroup(
            children: [
              SettingRow(
                label: context.tr('settings.security.changePin'),
                value: context.tr('settings.security.pinDigits'),
                onTap: () => context.push('/settings/change-pin'),
              ),
              SettingRow(
                label: context.tr('settings.security.biometrics'),
                value: context.tr(
                  _biometrics == true ? 'common.on' : 'common.off',
                ),
                onTap: () async {
                  if (_biometrics == null) return;
                  await _setBiometrics(!_biometrics!);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsLabel(context.tr('settings.security.devices')),
          SettingsGroup(
            children: [
              SettingRow(
                label: context.tr('settings.security.connectedDevices'),
                value: context.tr('common.thisDevice'),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
