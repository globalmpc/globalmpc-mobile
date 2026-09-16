import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/mining_project.dart';
import 'pipeline_widgets.dart';

class HomeProjectCard extends StatelessWidget {
  const HomeProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  final MiningProject project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.palette.surface,
          border: Border.all(color: context.palette.cardBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  'assets/icons/projects/mining-badge.svg',
                  width: 44,
                  height: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(project.nameKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.palette.textHi,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/projects/location.svg',
                            width: 12,
                            height: 12,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              context.tr(project.location),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: context.palette.textLo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: context.palette.pillAmberBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    context.tr(project.stage.key),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.copper,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final k in project.commodities)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.palette.pillAmberBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '◇ ${context.tr(k)}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.copper,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  context.tr('proj.pipeline'),
                  style: TextStyle(fontSize: 12, color: context.palette.textLo),
                ),
                const Spacer(),
                PipelineDots(pipeline: project.pipeline),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
