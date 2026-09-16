import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/wallet_models.dart';
import '../transaction_filters.dart';

class TransactionSearchField extends StatelessWidget {
  const TransactionSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.active,
    required this.onChanged,
    required this.onFocusChange,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool active;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onFocusChange;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: onFocusChange,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: AppColors.lightTextHi),
        decoration: InputDecoration(
          hintText: 'Search address, transaction ID or project',
          hintStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.lightTextLo,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: active ? AppColors.copper : const Color(0xFFCFC3B8),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 44),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: onClear,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '×',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppColors.lightTextLo,
                      ),
                    ),
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 40),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 17),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFC96B28)),
          ),
        ),
      ),
    );
  }
}

class TransactionTypeChipRow extends StatelessWidget {
  const TransactionTypeChipRow({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final TypeFilter selected;
  final ValueChanged<TypeFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    const chips = [
      (TypeFilter.all, 'All'),
      (TypeFilter.receive, 'Received'),
      (TypeFilter.send, 'Sent'),
      (TypeFilter.allocation, 'Allocation'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((c) {
          final active = selected == c.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(c.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFFFF3D7) : Colors.white,
                  border: Border.all(
                    color: active
                        ? const Color(0xFFF2D79A)
                        : AppColors.lightBorder,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  c.$2,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: active
                        ? const Color(0xFFC96B28)
                        : AppColors.lightTextLo,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class TransactionRow extends StatelessWidget {
  const TransactionRow({super.key, required this.tx});
  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    final incoming = tx.isIncoming;
    final pending =
        tx.status == TxStatus.pending || tx.status == TxStatus.submitted;
    final failed = tx.status == TxStatus.failed;

    final amountColor = failed
        ? const Color(0xFFC33E2B)
        : pending
        ? AppColors.copper
        : incoming
        ? AppColors.txPositive
        : AppColors.lightTextHi;

    final counterparty = tx.counterpartyKey != null
        ? context.tr(tx.counterpartyKey!)
        : (tx.counterparty ?? '');
    final projectName = tx.projectNameKey != null
        ? context.tr(tx.projectNameKey!)
        : null;
    final title = projectName != null
        ? '${context.tr(tx.kind.key)} $projectName'
        : '${context.tr(tx.kind.key)} '
              '${context.tr(incoming ? 'tx.from' : 'tx.to')} '
              '$counterparty';

    final statusLabel = failed
        ? 'Failed'
        : pending
        ? 'Pending'
        : 'Completed';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/wallet/transaction', extra: tx),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.lightBg),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: incoming
                    ? AppColors.receiveIconBg
                    : AppColors.lightSurfaceHi,
                borderRadius: BorderRadius.circular(19),
              ),
              child: SvgPicture.asset(
                incoming
                    ? 'assets/icons/wallet/tx-receive.svg'
                    : 'assets/icons/wallet/tx-send.svg',
                width: 16,
                height: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.lightTextHi,
                      height: 17 / 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Fmt.dateTime(tx.timestamp),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.lightTextLo,
                      height: 13 / 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${incoming ? '+' : '−'}${Fmt.compact(tx.amount)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: amountColor,
                    height: 16 / 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  statusLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.lightTextLo,
                    height: 13 / 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionEmptyState extends StatelessWidget {
  const TransactionEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No transactions found',
        style: TextStyle(fontSize: 13, color: AppColors.lightTextLo),
      ),
    );
  }
}

class TransactionSearchLoading extends StatelessWidget {
  const TransactionSearchLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Searching across addresses and transaction IDs',
            style: TextStyle(fontSize: 11, color: AppColors.lightTextLo),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < 2; i++) ...[
            Container(
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFEEE9E4),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
