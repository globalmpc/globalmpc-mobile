import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class CustomDateSheet extends StatefulWidget {
  const CustomDateSheet({super.key, this.initialStart, this.initialEnd});
  final DateTime? initialStart;
  final DateTime? initialEnd;

  @override
  State<CustomDateSheet> createState() => _CustomDateSheetState();
}

class _CustomDateSheetState extends State<CustomDateSheet> {
  late DateTime? _start;
  late DateTime? _end;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  String _fmtDate(DateTime? d) => d != null ? Fmt.date(d) : '—';

  bool get _valid => _start != null && _end != null && !_end!.isBefore(_start!);

  Future<void> _pickDate(bool isStart) async {
    final initial = (isStart ? _start : _end) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
      _hasError = _start != null && _end != null && _end!.isBefore(_start!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 22,
                        color: AppColors.lightTextHi,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Custom date range',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightTextHi,
                        ),
                      ),
                    ),
                    const SizedBox(width: 22),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Start date',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.lightTextLo,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _DateField(
                            label: _fmtDate(_start),
                            hasError: _hasError,
                            onTap: () => _pickDate(true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'End date',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.lightTextLo,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _DateField(
                            label: _fmtDate(_end),
                            hasError: _hasError,
                            onTap: () => _pickDate(false),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_hasError)
                  const Text(
                    'End date must be after the start date.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFC95E3C)),
                  )
                else
                  const Text(
                    'Maximum range: 12 months',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.lightTextLo,
                    ),
                  ),

                const SizedBox(height: 200),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _valid
                        ? () => Navigator.pop(context, (_start!, _end!))
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _valid
                          ? AppColors.gold
                          : AppColors.lightTextLo,
                      foregroundColor: _valid
                          ? AppColors.lightTextHi
                          : AppColors.lightTextLo,
                      disabledBackgroundColor: AppColors.lightTextLo,
                      disabledForegroundColor: AppColors.lightTextLo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply date range',
                      style: TextStyle(
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.hasError,
    required this.onTap,
  });
  final String label;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: hasError ? const Color(0xFFC33E2B) : AppColors.lightBorder,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.lightTextHi,
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.lightTextLo,
            ),
          ],
        ),
      ),
    );
  }
}
