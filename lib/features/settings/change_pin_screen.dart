import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/notifications/notification_center.dart';
import '../../core/security/wallet_session_store.dart';
import '../../core/theme/app_colors.dart';
import 'settings_widgets.dart';

enum _PinStep { current, setNew }

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  _PinStep _step = _PinStep.current;

  final _currentCtrl = TextEditingController();
  final _currentFocus = FocusNode();
  String? _currentError;

  final _newCtrl = TextEditingController();
  final _newFocus = FocusNode();
  final _confirmCtrl = TextEditingController();
  final _confirmFocus = FocusNode();
  String? _confirmError;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _newCtrl.addListener(_onNewPinChanged);
  }

  void _onNewPinChanged() {
    if (_newCtrl.text.length == 6) _confirmFocus.requestFocus();
  }

  @override
  void dispose() {
    _newCtrl.removeListener(_onNewPinChanged);
    _currentCtrl.dispose();
    _currentFocus.dispose();
    _newCtrl.dispose();
    _newFocus.dispose();
    _confirmCtrl.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: SettingsAppBar(
        title: context.tr('settings.security.changePin'),
        fallbackRoute: '/settings/security',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('settings.pin.intro'),
                style: TextStyle(fontSize: 13, color: p.textLo, height: 1.4),
              ),
              const SizedBox(height: 44),
              if (_step == _PinStep.current) ...[
                Text(
                  context.tr('settings.pin.current'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: p.textLo,
                  ),
                ),
                const SizedBox(height: 8),
                SixBoxPinInput(
                  controller: _currentCtrl,
                  focusNode: _currentFocus,
                  error: _currentError,
                ),
                if (_currentError != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      _currentError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ] else ...[
                Text(
                  context.tr('settings.pin.new'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: p.textLo,
                  ),
                ),
                const SizedBox(height: 8),
                SixBoxPinInput(controller: _newCtrl, focusNode: _newFocus),
                const SizedBox(height: 24),
                Text(
                  context.tr('settings.pin.confirmLabel'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: p.textLo,
                  ),
                ),
                const SizedBox(height: 8),
                SixBoxPinInput(
                  controller: _confirmCtrl,
                  focusNode: _confirmFocus,
                  error: _confirmError,
                ),
                if (_confirmError != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      _confirmError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ],
              const Spacer(),
              ListenableBuilder(
                listenable: _step == _PinStep.current
                    ? _currentCtrl
                    : Listenable.merge([_newCtrl, _confirmCtrl]),
                builder: (_, __) {
                  final ready = _step == _PinStep.current
                      ? _currentCtrl.text.length == 6
                      : (_newCtrl.text.length == 6 &&
                            _confirmCtrl.text.length == 6);
                  return SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: ready
                            ? AppColors.gold
                            : (isDark ? p.border : const Color(0xFFE8E0D8)),
                        foregroundColor: ready
                            ? AppColors.lightTextHi
                            : p.textLo,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: (_saving || !ready) ? null : _advance,
                      child: Text(
                        _saving
                            ? context.tr('settings.pin.updating')
                            : (_step == _PinStep.current
                                  ? context.tr('common.continueBtn')
                                  : context.tr('settings.pin.updateCta')),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _advance() async {
    switch (_step) {
      case _PinStep.current:
        setState(() {
          _currentError = null;
          _saving = true;
        });
        final valid = await WalletSessionStore.instance.verifyPin(
          _currentCtrl.text,
        );
        if (!mounted) return;
        if (!valid) {
          setState(() {
            _currentError = context.tr('common.pin.incorrect');
            _saving = false;
          });
          _currentCtrl.clear();
          return;
        }
        setState(() {
          _step = _PinStep.setNew;
          _saving = false;
        });
        _newFocus.requestFocus();

      case _PinStep.setNew:
        if (_confirmCtrl.text != _newCtrl.text) {
          setState(() => _confirmError = context.tr('settings.pin.mismatch'));
          _confirmCtrl.clear();
          _confirmFocus.requestFocus();
          return;
        }
        setState(() {
          _confirmError = null;
          _saving = true;
        });
        await WalletSessionStore.instance.updatePin(_newCtrl.text);
        await NotificationCenter.instance.notifySecurity(
          'notif.sec.pinChanged.title',
          'notif.sec.pinChanged.body',
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('settings.pin.updated'))),
        );
        if (context.mounted) context.pop();
    }
  }
}
