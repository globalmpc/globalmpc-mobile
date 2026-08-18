import 'package:flutter/material.dart';
import 'package:mpc_mining_app/core/theme/app_icons.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/mining_hero_art.dart';
import '../../../data/models/mining_project.dart';
import 'pipeline_widgets.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project, required this.onTap});

  final MiningProject project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final stageColor = _stageColor(context, project.stage);

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Glyph(project: project),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(project.nameKey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          AppIcons.place_outlined,
                          size: 13,
                          color: p.textLo,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            context.tr(project.location),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: p.textLo, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Pill(context.tr(project.stage.key), color: stageColor),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in project.commodities)
                Pill(
                  context.tr(c),
                  color: p.accent,
                  icon: AppIcons.diamond_outlined,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                context.tr('proj.pipeline'),
                style: TextStyle(color: p.textLo, fontSize: 12.5),
              ),
              const Spacer(),
              PipelineDots(pipeline: project.pipeline),
            ],
          ),
        ],
      ),
    );
  }

  Color _stageColor(BuildContext context, ProjectStage stage) {
    final p = context.palette;
    return switch (stage) {
      ProjectStage.inDiscussion => p.accent,
      ProjectStage.secured => AppColors.positive,
      ProjectStage.toBeSecured => p.accent,
      ProjectStage.comingSoon => p.textLo,
    };
  }
}

class _Glyph extends StatelessWidget {
  const _Glyph({required this.project});
  final MiningProject project;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 46,
        height: 46,
        child: MiningHeroArt(compact: true, kind: project.artKind),
      ),
    );
  }
}
