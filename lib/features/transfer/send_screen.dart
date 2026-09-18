import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart' show EthereumAddress;

import '../../core/localization/locale_controller.dart';
import '../../core/security/wallet_key_service.dart';
import '../../core/security/wallet_session_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/thousands_amount_formatter.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/wallet_models.dart';
import '../../data/services/bsc_chain_service.dart';
import '../wallet/wallet_provider.dart';
import 'send_result_step.dart';
import 'send_review_step.dart';
import 'widgets/send_details_form.dart';
import 'widgets/send_gas_sheet.dart';
import 'widgets/send_pin_confirmation.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

enum _SendStep { details, review, pin, processing, success, failure }

/// Why a send did not happen. Each reason gets its own explanation because
/// the fixes differ: restore the wallet, top up BNB, or simply retry.
enum _FailureReason { keyUnavailable, gas, network }

class _SendScreenState extends State<SendScreen> {
  static const _previewLowGas = bool.fromEnvironment('MPC_PREVIEW_LOW_GAS');
  static const _previewReviewOnly = bool.fromEnvironment(
    'MPC_PREVIEW_REVIEW_ONLY',
  );
  final _address = TextEditingController();
  final _amount = TextEditingController();
  final _pin = TextEditingController();
  final _pinFocusNode = FocusNode();
  _SendStep _step = _SendStep.details;
  String? _addressError;
  String? _amountError;
  String? _pinError;
  bool _previewScheduled = false;

  FeeEstimate? _fee;
  bool _feeUnavailable = false;
  int _estimateSequence = 0;

  String? _txHash;
  TxStatus _txStatus = TxStatus.submitted;
  _FailureReason? _failure;

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

  BscChainService get _chain => context.read<BscChainService>();

  double get _amountValue =>
      double.tryParse(_amount.text.trim().replaceAll(',', '')) ?? 0;

  @override
  void dispose() {
    _address.dispose();
    _amount.dispose();
    _pin.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<WalletProvider>();
    _scheduleLowGasPreview();
    final networkLabel = _chain.config.networkLabel;
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
        appBar: _step == _SendStep.processing
            ? null
            : AppBar(
                centerTitle: true,
                leading: switch (_step) {
                  _SendStep.details => _circleBackButton(
                    onTap: () => Navigator.maybePop(context),
                  ),
                  _SendStep.review => _circleBackButton(
                    onTap: () => setState(() => _step = _SendStep.details),
                  ),
                  _SendStep.pin => _circleBackButton(
                    onTap: () => setState(() => _step = _SendStep.review),
                  ),
                  _SendStep.failure => _circleBackButton(
                    onTap: () => setState(() => _step = _SendStep.review),
                  ),
                  _SendStep.success => _circleBackButton(
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                  ),
                  _ => null,
                },
                title: Text(switch (_step) {
                  _SendStep.details => context.tr('send.title'),
                  _SendStep.review => context.tr('send.reviewShort'),
                  _SendStep.pin => context.tr('send.pin.title'),
                  _SendStep.failure => context.tr('send.failure.title'),
                  _SendStep.success => context.tr('send.success.title'),
                  _ => context.tr('send.title'),
                }),
              ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: switch (_step) {
              _SendStep.details => _details(networkLabel),
              _SendStep.review => SendReviewStep(
                amount: _amountValue,
                recipientAddress: _address.text,
                bnbBalance: _wallet!.bnbBalance,
                networkFee: _fee?.feeBnb,
                feeUnavailable: _feeUnavailable,
                networkLabel: networkLabel,
                onRetryFee: _estimateFee,
                onConfirm: _continueFromReview,
                onEdit: () => setState(() => _step = _SendStep.details),
              ),
              _SendStep.pin => _pinConfirmation(),
              _SendStep.processing => _processing(),
              _SendStep.success => SendResultStep(
                success: true,
                amount: _amountValue,
                recipientAddress: _address.text,
                networkLabel: networkLabel,
                txHash: _txHash,
                txStatus: _txStatus,
                explorerUrl: _txHash == null
                    ? null
                    : _chain.config.explorerTxUrl(_txHash!),
              ),
              _SendStep.failure => SendResultStep(
                success: false,
                amount: _amountValue,
                recipientAddress: _address.text,
                networkLabel: networkLabel,
                failureMessage: context.tr(switch (_failure) {
                  _FailureReason.keyUnavailable =>
                    'send.failure.keyUnavailable',
                  _FailureReason.gas => 'send.failure.gas',
                  _ => 'send.failure.body',
                }),
                onRetry: _failure == _FailureReason.keyUnavailable
                    ? null
                    : () => setState(() => _step = _SendStep.review),
              ),
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
      unawaited(_estimateFee());
      if (_previewReviewOnly) return;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (mounted) await _continueFromReview();
    });
  }

  Widget _circleBackButton({required VoidCallback onTap}) => Padding(
    padding: const EdgeInsets.only(left: 8),
    child: Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: context.palette.circleButtonBg,
            shape: BoxShape.circle,
          ),
          child: SvgPicture.asset(
            'assets/icons/wallet/back-arrow.svg',
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(
              context.palette.textHi,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _details(String networkLabel) {
    final wallet = _wallet;
    if (wallet == null) {
      return StateMessage(
        icon: AppIcons.cloud_off_outlined,
        title: context.tr('dash.addressUnavailable'),
        message: context.tr('send.unavailableBody'),
        onRetry: context.read<WalletProvider>().load,
      );
    }
    if (!_chain.config.hasToken) {
      return StateMessage(
        icon: AppIcons.info_outline,
        title: context.tr('send.tokenNotConfigured.title'),
        message: context
            .tr('send.tokenNotConfigured.body')
            .replaceFirst('{network}', networkLabel),
      );
    }
    final available = (wallet.mpcBalance - wallet.allocatedTotal)
        .clamp(0, double.infinity)
        .toDouble();
    return SendDetailsForm(
      available: available,
      networkLabel: networkLabel,
      addressController: _address,
      amountController: _amount,
      addressError: _addressError,
      amountError: _amountError,
      onSubmit: _validateDetails,
      onPasteAddress: _pasteAddress,
      onAddressChanged: () => setState(() => _addressError = null),
      onAmountChanged: () => setState(() => _amountError = null),
      onUseMax: () {
        _amount.text = ThousandsAmountFormatter.group(
          available.toStringAsFixed(0),
        );
        setState(() => _amountError = null);
      },
    );
  }

  /// Prices the transfer for the review step. Sequenced so a stale answer
  /// from an earlier recipient or amount can never overwrite a newer one.
  Future<void> _estimateFee() async {
    final wallet = _wallet;
    if (wallet == null) return;
    final sequence = ++_estimateSequence;
    final chain = _chain;
    setState(() {
      _fee = null;
      _feeUnavailable = false;
    });
    try {
      final fee = await chain.estimateTransferFee(
        from: wallet.address,
        to: _address.text.trim(),
        amountMpc: _amountValue,
      );
      if (!mounted || sequence != _estimateSequence) return;
      setState(() => _fee = fee);
    } catch (_) {
      if (!mounted || sequence != _estimateSequence) return;
      setState(() => _feeUnavailable = true);
    }
  }

  Future<void> _continueFromReview() async {
    final fee = _fee;
    if (fee == null) return;
    if (_wallet!.bnbBalance >= fee.feeBnb) {
      setState(() => _step = _SendStep.pin);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SendInsufficientGasSheet(
        networkFee: fee.feeBnb,
        bnbBalance: _wallet!.bnbBalance,
      ),
    );
  }

  Widget _pinConfirmation() {
    return SendPinConfirmation(
      pinController: _pin,
      pinFocusNode: _pinFocusNode,
      amountValue: _amountValue,
      pinError: _pinError,
      onPinChanged: () => setState(() => _pinError = null),
      onConfirm: _confirmPin,
    );
  }

  Widget _processing() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SpinningLoader(),
        const SizedBox(height: 24),
        Text(
          context.tr('send.processing.title'),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: context.palette.textHi,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          context.tr('send.processing.body'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: context.palette.textLo),
        ),
      ],
    ),
  );

  /// A mixed-case address carries its own checksum. Accepting one that fails
  /// it would send funds to whatever the typo resolves to, so it is rejected
  /// here rather than left to the chain.
  static bool _checksumValid(String address) {
    final body = address.substring(2);
    final mixedCase =
        body.contains(RegExp('[a-f]')) && body.contains(RegExp('[A-F]'));
    if (!mixedCase) return true;
    try {
      EthereumAddress.fromHex(address, enforceEip55: true);
      return true;
    } on ArgumentError {
      return false;
    }
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
      addressError = context.tr('send.error.address');
    } else if (address.toLowerCase() == _wallet!.address.toLowerCase()) {
      addressError = context.tr('send.error.self');
    } else if (!_checksumValid(address)) {
      addressError = context.tr('send.error.checksum');
    }
    if (_amountValue <= 0) {
      amountError = context.tr('send.error.zero');
    } else if (_amountValue > available) {
      amountError = context
          .tr('send.error.balance')
          .replaceFirst('{amount}', Fmt.compact(available));
    }
    setState(() {
      _addressError = addressError;
      _amountError = amountError;
      if (addressError == null && amountError == null) {
        _step = _SendStep.review;
      }
    });
    if (addressError == null && amountError == null) {
      unawaited(_estimateFee());
    }
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
      setState(() => _pinError = context.tr('common.pin.incomplete'));
      return;
    }
    final valid = await WalletSessionStore.instance.verifyPin(_pin.text);
    if (!mounted) return;
    if (!valid) {
      setState(() {
        _pin.clear();
        _pinError = context.tr('common.pin.incorrect');
      });
      return;
    }
    setState(() => _step = _SendStep.processing);

    final mnemonic = await WalletSessionStore.instance.readMnemonic();
    if (!mounted) return;
    if (mnemonic == null) {
      // A PIN without a stored key means the vault is incomplete on this
      // device. Nothing can be signed, so nothing is presented as sent.
      setState(() {
        _failure = _FailureReason.keyUnavailable;
        _step = _SendStep.failure;
      });
      return;
    }

    final chain = _chain;
    try {
      final hash = await chain.sendMpc(
        credentials: const WalletKeyService().deriveKey(mnemonic),
        to: _address.text.trim(),
        amountMpc: _amountValue,
      );
      if (!mounted) return;
      context.read<WalletProvider>().load();
      setState(() {
        _txHash = hash;
        _txStatus = TxStatus.submitted;
        _step = _SendStep.success;
      });
      unawaited(_trackReceipt(chain, hash));
    } on InsufficientGasException {
      if (!mounted) return;
      setState(() {
        _failure = _FailureReason.gas;
        _step = _SendStep.failure;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failure = _FailureReason.network;
        _step = _SendStep.failure;
      });
    }
  }

  Future<void> _trackReceipt(BscChainService chain, String hash) async {
    final status = await chain.waitForReceipt(hash);
    if (!mounted || _txHash != hash) return;
    setState(() => _txStatus = status);
    if (status != TxStatus.pending) {
      context.read<WalletProvider>().load();
    }
  }
}

class _SpinningLoader extends StatefulWidget {
  const _SpinningLoader();

  @override
  State<_SpinningLoader> createState() => _SpinningLoaderState();
}

class _SpinningLoaderState extends State<_SpinningLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: _ctrl,
    child: SvgPicture.asset(
      'assets/icons/wallet/spinner_dots.svg',
      width: 52,
      height: 52,
    ),
  );
}
