import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/security/wallet_key_service.dart';
import '../../core/security/wallet_session_store.dart';
import '../../core/constants/mpc_facts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/wallet_models.dart';
import '../../data/services/bsc_chain_service.dart';
import 'wallet_provider.dart';
import '../web/web_view_screen.dart';

class ReceiveScreen extends StatelessWidget {
  const ReceiveScreen({super.key, this.assetSymbol = 'MPC'});

  final String assetSymbol;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WalletProvider>().state;
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text('Receive $assetSymbol')),
      body: SafeArea(
        top: false,
        child: switch (state.status) {
          _ when state.isLoading => const Center(
            child: CircularProgressIndicator(),
          ),
          _ when state.isError => StateMessage(
            icon: AppIcons.cloud_off_outlined,
            title: 'Wallet address unavailable',
            message: state.error,
            onRetry: context.read<WalletProvider>().load,
          ),
          _ when state.isSuccess => ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                'Only send $assetSymbol and supported BNB Smart Chain assets to this address.',
                style: TextStyle(color: p.textLo, height: 1.4),
              ),
              const SizedBox(height: 20),
              GlassCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    _AddressCode(value: state.data!.address),
                    const SizedBox(height: 20),
                    const Pill('BNB Smart Chain', color: AppColors.info),
                    const SizedBox(height: 14),
                    SelectableText(
                      state.data!.address,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () =>
                                _copy(context, state.data!.address),
                            icon: const Icon(AppIcons.copy_rounded, size: 18),
                            label: const Text('Copy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => SharePlus.instance.share(
                              ShareParams(
                                text:
                                    'My $assetSymbol wallet address on BNB Smart Chain:\n${state.data!.address}',
                              ),
                            ),
                            icon: const Icon(Icons.ios_share_rounded, size: 18),
                            label: const Text('Share'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SafetyNote(
                icon: AppIcons.info_outline,
                message:
                    'Assets sent on another network may be permanently lost.',
              ),
            ],
          ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  Future<void> _copy(BuildContext context, String address) async {
    await Clipboard.setData(ClipboardData(text: address));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Wallet address copied')));
  }
}

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

enum _SendStep { details, review, pin, processing, success, failure }

class _SendScreenState extends State<SendScreen> {
  static const _networkFee = 0.00012;
  static const _previewLowGas = bool.fromEnvironment('MPC_PREVIEW_LOW_GAS');
  static const _previewReviewOnly = bool.fromEnvironment(
    'MPC_PREVIEW_REVIEW_ONLY',
  );
  final _address = TextEditingController();
  final _amount = TextEditingController();
  final _pin = TextEditingController();
  _SendStep _step = _SendStep.details;
  String? _addressError;
  String? _amountError;
  String? _pinError;
  Timer? _timer;
  bool _previewScheduled = false;

  @override
  void initState() {
    super.initState();
    if (_previewLowGas) {
      _address.text = '0x1111111111111111111111111111111111111111';
      _amount.text = '1250';
    }
  }

  WalletAccount? get _wallet => context.read<WalletProvider>().state.isSuccess
      ? context.read<WalletProvider>().state.data
      : null;

  double get _amountValue => double.tryParse(_amount.text.trim()) ?? 0;

  @override
  void dispose() {
    _timer?.cancel();
    _address.dispose();
    _amount.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Send can be opened as a root route, so it must listen for the wallet's
    // asynchronous load instead of relying on the dashboard to rebuild it.
    context.watch<WalletProvider>();
    _scheduleLowGasPreview();
    return PopScope(
      canPop: _step == _SendStep.details || _step == _SendStep.success,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step != _SendStep.processing) {
          setState(() {
            _step = switch (_step) {
              _SendStep.review => _SendStep.details,
              _SendStep.pin => _SendStep.review,
              _SendStep.failure => _SendStep.review,
              _ => _step,
            };
          });
        }
      },
      child: Scaffold(
        appBar: _step == _SendStep.processing || _step == _SendStep.success
            ? null
            : AppBar(
                centerTitle: _step == _SendStep.review,
                leading: _step == _SendStep.review
                    ? IconButton(
                        tooltip: 'Edit transaction',
                        onPressed: () =>
                            setState(() => _step = _SendStep.details),
                        icon: const Icon(AppIcons.back),
                      )
                    : null,
                title: Text(switch (_step) {
                  _SendStep.details => 'Send MPC',
                  _SendStep.review => 'Send',
                  _SendStep.pin => 'Confirm with PIN',
                  _SendStep.failure => 'Transaction not sent',
                  _ => 'Send MPC',
                }),
              ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: switch (_step) {
              _SendStep.details => _details(),
              _SendStep.review => _review(),
              _SendStep.pin => _pinConfirmation(),
              _SendStep.processing => _processing(),
              _SendStep.success => _result(success: true),
              _SendStep.failure => _result(success: false),
            },
          ),
        ),
      ),
    );
  }

  void _scheduleLowGasPreview() {
    if (!_previewLowGas || _previewScheduled || _wallet == null) return;
    _previewScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() => _step = _SendStep.review);
      if (_previewReviewOnly) return;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (mounted) await _continueFromReview();
    });
  }

  Widget _details() {
    final p = context.palette;
    final wallet = _wallet;
    if (wallet == null) {
      return StateMessage(
        icon: AppIcons.cloud_off_outlined,
        title: 'Wallet unavailable',
        message: 'Reload your wallet before sending.',
        onRetry: context.read<WalletProvider>().load,
      );
    }
    final available = (wallet.mpcBalance - wallet.allocatedTotal).clamp(
      0,
      double.infinity,
    );
    return ListView(
      children: [
        GlassCard(
          child: Row(
            children: [
              const Icon(AppIcons.token_outlined, color: AppColors.copper),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MPC', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('BNB Smart Chain', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Text(
                '${Fmt.token(available)} available',
                style: TextStyle(color: p.textLo, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.local_gas_station_outlined, size: 16, color: p.textLo),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${wallet.bnbBalance.toStringAsFixed(4)} BNB available for network fees',
                style: TextStyle(color: p.textLo, fontSize: 12.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _address,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Recipient address',
            hintText: '0x…',
            errorText: _addressError,
            suffixIcon: IconButton(
              tooltip: 'Paste address',
              icon: const Icon(AppIcons.copy_rounded),
              onPressed: _pasteAddress,
            ),
          ),
          onChanged: (_) => setState(() => _addressError = null),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,6}')),
          ],
          decoration: InputDecoration(
            labelText: 'Amount',
            hintText: '0',
            suffixText: 'MPC',
            errorText: _amountError,
          ),
          onChanged: (_) => setState(() => _amountError = null),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              _amount.text = available.toStringAsFixed(0);
              setState(() => _amountError = null);
            },
            child: const Text('Use maximum'),
          ),
        ),
        const SizedBox(height: 12),
        const _SafetyNote(
          icon: AppIcons.info_outline,
          message:
              'Confirm the recipient and network carefully. Blockchain transactions cannot be reversed.',
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _validateDetails,
            child: const Text('Review transaction'),
          ),
        ),
      ],
    );
  }

  Widget _review() {
    final p = context.palette;
    final hasEnoughBnb = _wallet!.bnbBalance >= _networkFee;

    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        Center(
          child: Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              'assets/brand/logo.svg',
              width: 27,
              height: 27,
              colorFilter: const ColorFilter.mode(
                AppColors.lightTextHi,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          "You're sending",
          textAlign: TextAlign.center,
          style: TextStyle(color: p.textLo, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Text(
          '${Fmt.token(_amountValue)} MPC',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        const Center(child: Pill('BNB Smart Chain', color: AppColors.info)),
        const SizedBox(height: 28),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  children: [
                    Text('To', style: TextStyle(color: p.textLo, fontSize: 14)),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        Fmt.shortAddress(_address.text, lead: 8, tail: 6),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Copy recipient address',
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          Clipboard.setData(ClipboardData(text: _address.text)),
                      icon: const Icon(AppIcons.copy_rounded, size: 18),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: p.border),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Network fee',
                        style: TextStyle(color: p.textLo, fontSize: 14),
                      ),
                    ),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            '~0.00012 BNB',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!hasEnoughBnb) ...[
                            const SizedBox(height: 3),
                            const Text(
                              'Not enough BNB',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, color: p.textLo, size: 18),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Check the address carefully. Blockchain transfers cannot be reversed.',
                style: TextStyle(color: p.textLo, fontSize: 12.5, height: 1.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: _continueFromReview,
          child: const Text('Confirm and continue'),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => setState(() => _step = _SendStep.details),
          child: const Text('Edit details'),
        ),
      ],
    );
  }

  Future<void> _continueFromReview() async {
    if (_wallet!.bnbBalance >= _networkFee) {
      setState(() => _step = _SendStep.pin);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final p = sheetContext.palette;
        final shortfall = (_networkFee - _wallet!.bnbBalance).clamp(
          0,
          double.infinity,
        );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.warning,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'BNB needed for network fee',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'This transfer needs about ${_networkFee.toStringAsFixed(5)} BNB. '
                  'Your wallet has ${_wallet!.bnbBalance.toStringAsFixed(5)} BNB.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textLo, height: 1.45),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: .28),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.warning,
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      const Text('Needed'),
                      const Spacer(),
                      Text(
                        '${shortfall.toStringAsFixed(5)} BNB',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Your MPC balance will not be used for this fee.',
                  style: TextStyle(color: p.textLo, fontSize: 12.5),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      context.push('/wallet/add-bnb');
                    },
                    icon: const Icon(AppIcons.south_west, size: 18),
                    label: const Text('Receive BNB'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pinConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your 6-digit app PIN',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'This confirms that it is you sending ${Fmt.token(_amountValue)} MPC.',
          style: TextStyle(color: context.palette.textLo, height: 1.4),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _pin,
          autofocus: true,
          obscureText: true,
          maxLength: 6,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'App PIN',
            errorText: _pinError,
            counterText: '',
          ),
          onChanged: (_) => setState(() => _pinError = null),
          onSubmitted: (_) => _confirmPin(),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _pin.text.length == 6 ? _confirmPin : null,
            child: const Text('Send MPC'),
          ),
        ),
      ],
    );
  }

  Widget _processing() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 22),
        Text(
          'Submitting securely',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8),
        Text('Keep MPC open until the network accepts the transaction.'),
      ],
    ),
  );

  Widget _result({required bool success}) {
    final p = context.palette;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          success ? AppIcons.check_circle : AppIcons.cloud_off_outlined,
          size: 68,
          color: success ? AppColors.positive : AppColors.danger,
        ),
        const SizedBox(height: 22),
        Text(
          success ? 'Transaction submitted' : 'Transaction not sent',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          success
              ? '${Fmt.token(_amountValue)} MPC is pending network confirmation. You can safely leave this screen.'
              : 'Your balance has not changed. Check your connection and try again.',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.textLo, height: 1.4),
        ),
        const SizedBox(height: 28),
        if (success) ...[
          const Pill('Pending confirmation', color: AppColors.warning),
          const SizedBox(height: 24),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: success
                ? () => context.go('/wallet')
                : () => setState(() => _step = _SendStep.review),
            child: Text(success ? 'Back to wallet' : 'Try again'),
          ),
        ),
        if (!success) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.go('/wallet'),
            child: const Text('Cancel transfer'),
          ),
        ],
      ],
    );
  }

  void _validateDetails() {
    final address = _address.text.trim();
    final available = (_wallet!.mpcBalance - _wallet!.allocatedTotal).clamp(
      0,
      double.infinity,
    );
    String? addressError;
    String? amountError;
    if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(address)) {
      addressError = 'Enter a valid BNB Smart Chain address.';
    } else if (address.toLowerCase() == _wallet!.address.toLowerCase()) {
      addressError = 'Use a different recipient address.';
    }
    if (_amountValue <= 0) {
      amountError = 'Enter an amount greater than zero.';
    } else if (_amountValue > available) {
      amountError = 'You do not have enough unallocated MPC.';
    }
    setState(() {
      _addressError = addressError;
      _amountError = amountError;
      if (addressError == null && amountError == null) {
        _step = _SendStep.review;
      }
    });
  }

  Future<void> _pasteAddress() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted || data?.text == null) return;
    setState(() {
      _address.text = data!.text!.trim();
      _addressError = null;
    });
  }

  Future<void> _confirmPin() async {
    if (_pin.text.length != 6) {
      setState(() => _pinError = 'Enter all 6 digits.');
      return;
    }
    final valid = await WalletSessionStore.instance.verifyPin(_pin.text);
    if (!mounted) return;
    if (!valid) {
      setState(() {
        _pin.clear();
        _pinError = 'Incorrect PIN. Try again.';
      });
      return;
    }
    setState(() => _step = _SendStep.processing);

    // Real path: sign on device and broadcast. The mnemonic never leaves
    // secure storage scope and is not retained on this screen.
    final mnemonic = await WalletSessionStore.instance.readMnemonic();
    if (!mounted) return;
    if (mnemonic == null) {
      // Demo wallet (desktop/tests): keep the design-flow simulation.
      _timer = Timer(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() => _step = _SendStep.success);
      });
      return;
    }

    try {
      final chain = context.read<BscChainService>();
      await chain.sendMpc(
        credentials: const WalletKeyService().deriveKey(mnemonic),
        to: _address.text.trim(),
        amountMpc: _amountValue,
      );
      if (!mounted) return;
      context.read<WalletProvider>().load();
      setState(() => _step = _SendStep.success);
    } catch (_) {
      if (!mounted) return;
      setState(() => _step = _SendStep.failure);
    }
  }
}

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.transaction});

  final WalletTransaction transaction;

  /// Real transfers live on the configured chain (testnet today); only the
  /// demo account's placeholder hashes point at mainnet BscScan.
  String _explorerTxUrl(BuildContext context) {
    try {
      final wallet = context.read<WalletProvider>().state.data;
      if (wallet != null && !wallet.isDemo) {
        return context.read<BscChainService>().config.explorerTxUrl(
          transaction.hash,
        );
      }
    } on ProviderNotFoundException {
      // Standalone (tests): fall through to the default explorer.
    }
    return '${MpcFacts.explorerBase}/tx/${transaction.hash}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final incoming = transaction.isIncoming;
    final statusLabel = switch (transaction.status) {
      TxStatus.submitted => 'Submitted',
      TxStatus.pending => 'Pending',
      TxStatus.confirmed => 'Confirmed',
      TxStatus.failed => 'Failed',
    };
    final statusColor = switch (transaction.status) {
      TxStatus.submitted || TxStatus.pending => AppColors.warning,
      TxStatus.confirmed => AppColors.positive,
      TxStatus.failed => AppColors.danger,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  incoming ? AppIcons.south_west : AppIcons.north_east,
                  size: 34,
                  color: incoming ? AppColors.positive : p.textHi,
                ),
                const SizedBox(height: 12),
                Text(
                  '${incoming ? '+' : '−'}${Fmt.token(transaction.amount)} MPC',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Pill(statusLabel, color: statusColor),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              children: [
                _ReviewRow(label: 'Status', value: statusLabel),
                _ReviewRow(
                  label: incoming ? 'From' : 'To',
                  value: transaction.counterparty ?? 'Project vault',
                ),
                _ReviewRow(
                  label: 'Date',
                  value: Fmt.date(transaction.timestamp),
                ),
                _ReviewRow(label: 'Network', value: 'BNB Smart Chain'),
                _ReviewRow(
                  label: 'Network fee',
                  value: '${transaction.networkFeeBnb.toStringAsFixed(5)} BNB',
                ),
                if (transaction.blockConfirmations != null)
                  _ReviewRow(
                    label: 'Confirmations',
                    value: '${transaction.blockConfirmations}',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Transaction hash'),
                  subtitle: Text(
                    Fmt.shortAddress(transaction.hash, lead: 10, tail: 8),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  trailing: IconButton(
                    tooltip: 'Copy transaction hash',
                    onPressed: () => _copyHash(context),
                    icon: const Icon(AppIcons.copy_rounded),
                  ),
                ),
                Divider(color: p.border, height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('View on BscScan'),
                  trailing: const Icon(AppIcons.open_in_new),
                  onTap: () => context.push(
                    '/webview',
                    extra: WebViewArgs(
                      url: _explorerTxUrl(context),
                      title: 'BscScan',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyHash(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: transaction.hash));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Transaction hash copied')));
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: context.palette.textLo)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.warning.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppColors.warning),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: context.palette.textLo,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

class _AddressCode extends StatelessWidget {
  const _AddressCode({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 196,
      height: 196,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border),
      ),
      child: QrImageView(
        data: value,
        version: QrVersions.auto,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: AppColors.darkBg,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: AppColors.darkBg,
        ),
      ),
    );
  }
}
