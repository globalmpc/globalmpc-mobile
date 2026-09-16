import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/earn_facts.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';

class EarnScreen extends StatelessWidget {
  const EarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          children: [
            const SizedBox(height: 16),
            Text(
              context.tr('earn.title'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 29 / 24,
                color: context.palette.textHi,
              ),
            ),
            const SizedBox(height: 16),
            const _GatedBanner(),
            const SizedBox(height: 16),
            for (final program in EarnFacts.programs) ...[
              _ProgramCard(program: program),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 8),
            Text(
              context.tr('earn.whyGated'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 19 / 16,
                color: context.palette.textHi,
              ),
            ),
            const SizedBox(height: 16),
            const _GatesCard(),
          ],
        ),
      ),
    );
  }
}

class _GatedBanner extends StatelessWidget {
  const _GatedBanner();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFFDFEFF) : context.palette.surface,
        border: Border.all(color: const Color(0xFF6E93C9)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 22,
            child: Icon(
              Icons.info_outline_rounded,
              size: 22,
              color: Color(0xFF4F75AE),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('earn.gatedBanner'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 15 / 12,
                color: context.palette.textHi,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramCard extends StatefulWidget {
  const _ProgramCard({required this.program});
  final EarnProgramFact program;

  @override
  State<_ProgramCard> createState() => _ProgramCardState();
}

class _ProgramCardState extends State<_ProgramCard> {
  void _notify() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF50986B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          content: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFF1EBE5),
                        width: 1.5,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: Color(0xFFF1EBE5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  context.tr('earn.notifyToast'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 16 / 13,
                    color: Color(0xFFF7F3EE),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  String get _iconAsset => switch (widget.program.id) {
    'staking' => 'assets/icons/earn/staking.svg',
    'farming' => 'assets/icons/earn/farming.svg',
    _ => 'assets/icons/bottom-nav/trend-up.svg',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border.all(color: context.palette.border),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(_iconAsset, width: 24, height: 24),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  context.tr('earn.${widget.program.id}.title'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 19 / 16,
                    color: context.palette.textHi,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: context.palette.pillAmberBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  context.tr('earn.status.planned'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 13 / 11,
                    color: AppColors.copper,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            context.tr('earn.${widget.program.id}.body'),
            style: TextStyle(
              fontSize: 12,
              height: 15 / 12,
              color: context.palette.textLo,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${context.tr('earn.rateLabel')} • ${context.tr('earn.ratePending')}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 15 / 12,
              color: context.palette.textHi,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _notify,
              icon: SvgPicture.asset(
                'assets/icons/earn/notification.svg',
                width: 16,
                height: 16,
              ),
              label: Text(context.tr('earn.notify')),
              style: OutlinedButton.styleFrom(
                backgroundColor: context.palette.bg,
                foregroundColor: context.palette.textHi,
                side: const BorderSide(color: AppColors.gold),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 17 / 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GatesCard extends StatelessWidget {
  const _GatesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border.all(color: context.palette.border),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < EarnFacts.gates.length; i++) ...[
            if (i > 0) const SizedBox(height: 20),
            _GateRow(gate: EarnFacts.gates[i]),
          ],
        ],
      ),
    );
  }
}

class _GateRow extends StatelessWidget {
  const _GateRow({required this.gate});
  final EarnGateFact gate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('earn.gate.${gate.id}.title'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 17 / 14,
            color: context.palette.textHi,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('earn.gate.${gate.id}.body'),
          style: TextStyle(
            fontSize: 12,
            height: 15 / 12,
            color: context.palette.textLo,
          ),
        ),
      ],
    );
  }
}
