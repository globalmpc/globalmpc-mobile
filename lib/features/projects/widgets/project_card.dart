import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/mining_project.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project, required this.onTap});

  final MiningProject project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final featured = project.featured;
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          border: Border.all(color: p.border),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: double.infinity,
                height: 110,
                child: featured
                    ? Container(
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFF7BA52), Color(0xFFC74F1F)],
                          ),
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/projects/mountain.svg',
                          width: 44,
                        ),
                      )
                    : Container(
                        alignment: Alignment.center,
                        color: isDark
                            ? AppColors.darkSurfaceHi
                            : const Color(0xFFF4F0EB),
                        child: SvgPicture.asset(
                          'assets/icons/projects/mountain.svg',
                          width: 44,
                          colorFilter: const ColorFilter.mode(
                            AppColors.gold,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              context.tr(project.nameKey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: p.textHi,
                height: 21 / 17,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                _Pill(
                  label: context.tr(project.location),
                  bg: isDark ? AppColors.darkBorder : const Color(0xFFF4F0EB),
                  textColor: p.textLo,
                ),
                const SizedBox(width: 8),
                _Pill(
                  label: context.tr(project.stage.key),
                  bg: isDark
                      ? AppColors.darkWarningFill
                      : const Color(0xFFFFEDC1),
                  textColor: AppColors.copper,
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              project.commodities.map((k) => context.tr(k)).join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: p.textLo, height: 15 / 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.textColor});

  final String label;
  final Color bg;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 13 / 11,
        ),
      ),
    );
  }
}
