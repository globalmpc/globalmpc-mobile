import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_environment.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/widgets/wallet_error_state.dart';
import '../wallet/wallet_provider.dart';
import 'transfer_shared.dart';

class ReceiveScreen extends StatelessWidget {
  const ReceiveScreen({super.key, this.assetSymbol = 'MPC'});

  final String assetSymbol;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WalletProvider>().state;
    final p = context.palette;
    final networkLabel = AppEnvironment.current.chain.networkLabel;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 48,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.maybePop(context),
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
        ),
        title: Text(
          context.tr('receive.title').replaceFirst('{asset}', assetSymbol),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 22 / 18,
            color: p.textHi,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: switch (state.status) {
          _ when state.isLoading => const Center(
            child: CircularProgressIndicator(),
          ),
          _ when state.isError => WalletErrorState(
            title: context.tr('receive.unavailable'),
            message: context.tr('wallet.unavailableBody'),
            retryLabel: context.tr('wallet.tryAgain'),
            onRetry: context.read<WalletProvider>().load,
          ),
          _ when state.isSuccess => ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                context
                    .tr('receive.warning')
                    .replaceFirst('{asset}', assetSymbol)
                    .replaceFirst('{network}', networkLabel),
                style: TextStyle(fontSize: 13, color: p.textLo),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: context.palette.surface,
                  border: Border.all(color: context.palette.cardBorder),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _AddressCode(value: state.data!.address),
                    const SizedBox(height: 34),
                    Column(
                      children: [
                        Text(
                          networkLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          state.data!.address,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.palette.textHi,
                            height: 15 / 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 34),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CopyAddressButton(address: state.data!.address),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () => SharePlus.instance.share(
                              ShareParams(
                                text: context
                                    .tr('receive.shareTemplate')
                                    .replaceFirst('{asset}', assetSymbol)
                                    .replaceFirst('{network}', networkLabel)
                                    .replaceFirst(
                                      '{address}',
                                      state.data!.address,
                                    ),
                              ),
                            ),
                            icon: SvgPicture.asset(
                              'assets/icons/wallet/share-address.svg',
                              width: 16,
                              height: 16,
                              colorFilter: const ColorFilter.mode(
                                AppColors.lightTextHi,
                                BlendMode.srcIn,
                              ),
                            ),
                            label: Text(context.tr('receive.share')),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.lightBg,
                              foregroundColor: AppColors.lightTextHi,
                              side: BorderSide(color: context.palette.border),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SafetyNote(
                icon: AppIcons.error_outline,
                message: context.tr('receive.wrongNetwork'),
              ),
            ],
          ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _CopyAddressButton extends StatefulWidget {
  const _CopyAddressButton({required this.address});
  final String address;

  @override
  State<_CopyAddressButton> createState() => _CopyAddressButtonState();
}

class _CopyAddressButtonState extends State<_CopyAddressButton> {
  bool _copied = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.address));
    if (!mounted) return;
    setState(() => _copied = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 50,
      child: FilledButton.icon(
        onPressed: _copy,
        icon: SvgPicture.asset(
          _copied
              ? 'assets/icons/wallet/check.svg'
              : 'assets/icons/wallet/copy-address.svg',
          width: 16,
          height: 16,
          colorFilter: ColorFilter.mode(p.onPrimary, BlendMode.srcIn),
        ),
        label: Text(
          context.tr(_copied ? 'wallet.addressCopied' : 'receive.copy'),
        ),
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
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
