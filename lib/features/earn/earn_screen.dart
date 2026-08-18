import 'package:flutter/material.dart';
import 'package:mpc_mining_app/core/theme/app_icons.dart';

import '../../core/constants/earn_facts.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/glass_card.dart';

/// Earn — MPC's planned staking + farming surface.
///
/// MPC is permissioned (ERC-3643) and pre-listing, so nothing here quotes a
/// rate. Every capability is clearly labelled "Planned" and the reward figure
/// reads "Announced at listing".
class EarnScreen extends StatelessWidget {
  const EarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('earn.title'))),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const _GatedBanner(),
            const SizedBox(height: 20),
            for (final program in EarnFacts.programs) ...[
              _ProgramCard(program: program),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 10),
            SectionHeader(context.tr('earn.whyGated')),
            const SizedBox(height: 12),
            const _GatesCard(),
            const SizedBox(height: 20),
            Center(
              child: Text(
                context.tr('app.trust'),
                style: TextStyle(
                  color: context.palette.textLo,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ),
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
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(AppIcons.info_outline, size: 18, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr('earn.gatedBanner'),
              style: TextStyle(color: p.textHi, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.program});
  final EarnProgramFact program;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      padding: const EdgeInsets.all(18),
      accent: p.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(_iconFor(program.id), size: 20, color: p.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr('earn.${program.id}.title'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Pill(context.tr('earn.status.planned'), color: AppColors.warning),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('earn.${program.id}.body'),
            style: TextStyle(color: p.textLo, fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: p.bg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  context.tr('earn.rateLabel'),
                  style: TextStyle(color: p.textLo, fontSize: 12.5),
                ),
                const Spacer(),
                Text(
                  context.tr('earn.ratePending'),
                  style: TextStyle(
                    color: p.textHi,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _notify(context),
              icon: const Icon(AppIcons.notify, size: 18),
              label: Text(context.tr('earn.notify')),
            ),
          ),
        ],
      ),
    );
  }

  void _notify(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.tr('earn.notifyToast'))));
  }

  IconData _iconFor(String id) => switch (id) {
    'staking' => AppIcons.staking,
    'farming' => AppIcons.farming,
    _ => AppIcons.earn_outlined,
  };
}

class _GatesCard extends StatelessWidget {
  const _GatesCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassCard(
      child: Column(
        children: [
          for (var i = 0; i < EarnFacts.gates.length; i++) ...[
            _GateRow(gate: EarnFacts.gates[i]),
            if (i != EarnFacts.gates.length - 1)
              Divider(color: p.border, height: 22),
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
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: p.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(_iconFor(gate.id), size: 17, color: p.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('earn.gate.${gate.id}.title'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                context.tr('earn.gate.${gate.id}.body'),
                style: TextStyle(color: p.textLo, fontSize: 12.5, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _iconFor(String id) => switch (id) {
    'kyc' => AppIcons.kyc,
    'listing' => AppIcons.listing,
    _ => AppIcons.info_outline,
  };
}
