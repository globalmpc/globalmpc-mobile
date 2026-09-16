import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../data/models/wallet_models.dart';
import '../wallet/wallet_provider.dart';
import 'widgets/transaction_list_widgets.dart';
import 'transaction_filters.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchActive = false;

  TypeFilter _type = TypeFilter.all;
  StatusFilter _status = StatusFilter.all;
  DateFilter _date = DateFilter.allTime;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<WalletTransaction> _applyFilters(List<WalletTransaction> all) {
    final query = _searchCtrl.text.trim().toLowerCase();
    return all.where((tx) {
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

      final now = DateTime.now();
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

      if (query.isNotEmpty) {
        final haystack = [
          tx.hash.toLowerCase(),
          (tx.counterparty ?? '').toLowerCase(),
        ].join(' ');
        if (!haystack.contains(query)) return false;
      }

      return true;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _type = TypeFilter.all;
      _status = StatusFilter.all;
      _date = DateFilter.allTime;
      _customStart = null;
      _customEnd = null;
    });
  }

  void _showFilterSheet(List<WalletTransaction> allTx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(
        allTx: allTx,
        type: _type,
        status: _status,
        date: _date,
        customStart: _customStart,
        customEnd: _customEnd,
        onApply: (type, status, date, start, end) {
          setState(() {
            _type = type;
            _status = status;
            _date = date;
            _customStart = start;
            _customEnd = end;
          });
        },
        onReset: _resetFilters,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = context.watch<WalletProvider>();
    final allTx = walletState.state.data?.transactions ?? [];
    final filtered = _applyFilters(allTx);
    final isSearching = _searchActive;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final todayTx = filtered.where((tx) {
      final d = DateTime(
        tx.timestamp.year,
        tx.timestamp.month,
        tx.timestamp.day,
      );
      return d == todayDate;
    }).toList();
    final earlierTx = filtered.where((tx) {
      final d = DateTime(
        tx.timestamp.year,
        tx.timestamp.month,
        tx.timestamp.day,
      );
      return d != todayDate;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.lightSurfaceHi,
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.back, size: 16),
              ),
            ),
          ),
        ),
        title: const Text(
          'Transactions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF181310),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showFilterSheet(allTx),
              child: Container(
                width: 44,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.lightBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/icons/wallet/sort-lines.svg',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TransactionSearchField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  active: isSearching,
                  onChanged: (v) => setState(() {}),
                  onFocusChange: (f) => setState(() => _searchActive = f),
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() {});
                    _searchFocus.requestFocus();
                  },
                ),
                const SizedBox(height: 12),

                TransactionTypeChipRow(
                  selected: _type,
                  onSelect: (t) => setState(() => _type = t),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: isSearching && _searchCtrl.text.trim().isEmpty
                ? const TransactionSearchLoading()
                : filtered.isEmpty
                ? const TransactionEmptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    children: [
                      if (isSearching && _searchCtrl.text.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.lightTextLo,
                            ),
                          ),
                        ),
                      if (!isSearching || _searchCtrl.text.trim().isEmpty) ...[
                        if (todayTx.isNotEmpty) ...[
                          const Text(
                            'Today',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightTextLo,
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (final tx in todayTx) ...[
                            TransactionRow(tx: tx),
                            const SizedBox(height: 8),
                          ],
                          if (earlierTx.isNotEmpty) const SizedBox(height: 16),
                        ],
                        if (earlierTx.isNotEmpty) ...[
                          const Text(
                            'Earlier',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightTextLo,
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (final tx in earlierTx) ...[
                            TransactionRow(tx: tx),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ] else ...[
                        for (final tx in filtered) ...[
                          TransactionRow(tx: tx),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            'Search matches the recipient address and transaction ID.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.lightTextLo,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
