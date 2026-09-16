import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/wallet_models.dart';
import 'widgets/custom_date_sheet.dart';

enum TypeFilter { all, receive, send, allocation }

enum StatusFilter { all, completed, pending, failed }

enum DateFilter { allTime, sevenDays, thirtyDays, custom }

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.allTx,
    required this.type,
    required this.status,
    required this.date,
    required this.customStart,
    required this.customEnd,
    required this.onApply,
    required this.onReset,
  });

  final List<WalletTransaction> allTx;
  final TypeFilter type;
  final StatusFilter status;
  final DateFilter date;
  final DateTime? customStart;
  final DateTime? customEnd;
  final void Function(
    TypeFilter,
    StatusFilter,
    DateFilter,
    DateTime?,
    DateTime?,
  )
  onApply;
  final VoidCallback onReset;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late TypeFilter _type;
  late StatusFilter _status;
  late DateFilter _date;
  late DateTime? _customStart;
  late DateTime? _customEnd;

  @override
  void initState() {
    super.initState();
    _type = widget.type;
    _status = widget.status;
    _date = widget.date;
    _customStart = widget.customStart;
    _customEnd = widget.customEnd;
  }

  int get _matchCount {
    final now = DateTime.now();
    return widget.allTx.where((tx) {
      if (_type != TypeFilter.all) {
        final match = switch (_type) {
          TypeFilter.receive => tx.kind == TxKind.receive,
          TypeFilter.send => tx.kind == TxKind.send,
          TypeFilter.allocation =>
            tx.kind == TxKind.allocation || tx.kind == TxKind.issuance,
          TypeFilter.all => true,
        };
        if (!match) return false;
      }
      if (_status != StatusFilter.all) {
        final match = switch (_status) {
          StatusFilter.completed => tx.status == TxStatus.confirmed,
          StatusFilter.pending =>
            tx.status == TxStatus.pending || tx.status == TxStatus.submitted,
          StatusFilter.failed => tx.status == TxStatus.failed,
          StatusFilter.all => true,
        };
        if (!match) return false;
      }
      if (_date == DateFilter.sevenDays) {
        if (tx.timestamp.isBefore(now.subtract(const Duration(days: 7)))) {
          return false;
        }
      } else if (_date == DateFilter.thirtyDays) {
        if (tx.timestamp.isBefore(now.subtract(const Duration(days: 30)))) {
          return false;
        }
      } else if (_date == DateFilter.custom &&
          _customStart != null &&
          _customEnd != null) {
        final start = DateTime(
          _customStart!.year,
          _customStart!.month,
          _customStart!.day,
        );
        final end = DateTime(
          _customEnd!.year,
          _customEnd!.month,
          _customEnd!.day,
          23,
          59,
          59,
        );
        if (tx.timestamp.isBefore(start) || tx.timestamp.isAfter(end)) {
          return false;
        }
      }
      return true;
    }).length;
  }

  Future<void> _openCustomDate() async {
    final result = await showModalBottomSheet<(DateTime, DateTime)?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          CustomDateSheet(initialStart: _customStart, initialEnd: _customEnd),
    );
    if (result != null) {
      setState(() {
        _date = DateFilter.custom;
        _customStart = result.$1;
        _customEnd = result.$2;
      });
    }
  }

  Widget _filterChip({
    required bool active,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFF3D7) : Colors.white,
          border: Border.all(
            color: active ? const Color(0xFFF2D79A) : AppColors.lightBorder,
          ),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: active ? const Color(0xFFC96B28) : AppColors.lightTextLo,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customLabel =
        (_date == DateFilter.custom &&
            _customStart != null &&
            _customEnd != null)
        ? '${Fmt.date(_customStart!)} - ${Fmt.date(_customEnd!)}'
        : 'Custom';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F5F1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 14),
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD7CEC6),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Filter transactions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightTextHi,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        widget.onReset();
                        setState(() {
                          _type = TypeFilter.all;
                          _status = StatusFilter.all;
                          _date = DateFilter.allTime;
                          _customStart = null;
                          _customEnd = null;
                        });
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFC96B28),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text(
                  'Transaction type',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextLo,
                  ),
                ),
                const SizedBox(height: 11),
                Wrap(
                  spacing: 8,
                  children: [
                    _filterChip(
                      active: _type == TypeFilter.all,
                      label: 'All',
                      onTap: () => setState(() => _type = TypeFilter.all),
                    ),
                    _filterChip(
                      active: _type == TypeFilter.receive,
                      label: 'Received',
                      onTap: () => setState(() => _type = TypeFilter.receive),
                    ),
                    _filterChip(
                      active: _type == TypeFilter.send,
                      label: 'Sent',
                      onTap: () => setState(() => _type = TypeFilter.send),
                    ),
                    _filterChip(
                      active: _type == TypeFilter.allocation,
                      label: 'Allocation',
                      onTap: () =>
                          setState(() => _type = TypeFilter.allocation),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextLo,
                  ),
                ),
                const SizedBox(height: 11),
                Wrap(
                  spacing: 8,
                  children: [
                    _filterChip(
                      active: _status == StatusFilter.all,
                      label: 'All',
                      onTap: () => setState(() => _status = StatusFilter.all),
                    ),
                    _filterChip(
                      active: _status == StatusFilter.completed,
                      label: 'Completed',
                      onTap: () =>
                          setState(() => _status = StatusFilter.completed),
                    ),
                    _filterChip(
                      active: _status == StatusFilter.pending,
                      label: 'Pending',
                      onTap: () =>
                          setState(() => _status = StatusFilter.pending),
                    ),
                    _filterChip(
                      active: _status == StatusFilter.failed,
                      label: 'Failed',
                      onTap: () =>
                          setState(() => _status = StatusFilter.failed),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  'Date',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextLo,
                  ),
                ),
                const SizedBox(height: 11),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterChip(
                      active: _date == DateFilter.allTime,
                      label: 'All time',
                      onTap: () => setState(() => _date = DateFilter.allTime),
                    ),
                    _filterChip(
                      active: _date == DateFilter.sevenDays,
                      label: '7 days',
                      onTap: () => setState(() => _date = DateFilter.sevenDays),
                    ),
                    _filterChip(
                      active: _date == DateFilter.thirtyDays,
                      label: '30 days',
                      onTap: () =>
                          setState(() => _date = DateFilter.thirtyDays),
                    ),
                    _filterChip(
                      active: _date == DateFilter.custom,
                      label: customLabel,
                      onTap: _openCustomDate,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      widget.onApply(
                        _type,
                        _status,
                        _date,
                        _customStart,
                        _customEnd,
                      );
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.lightTextHi,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Show $_matchCount transaction${_matchCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
