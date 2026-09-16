import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/mpc_facts.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/mining_project.dart';

Color layerStatusColor(BuildContext context, LayerStatus status) {
  return switch (status) {
    LayerStatus.secured => AppColors.progressGreen,
    LayerStatus.inProgress => AppColors.info,
    LayerStatus.inDiscussion => AppColors.copper,
    LayerStatus.planned => context.palette.dotMuted,
  };
}

Color? layerStatusBg(LayerStatus status) {
  return switch (status) {
    LayerStatus.secured => AppColors.receiveIconBg,
    LayerStatus.inProgress => AppColors.receiveIconBg,
    LayerStatus.inDiscussion => AppColors.goldSoft,
    LayerStatus.planned => AppColors.goldSoft,
  };
}

class PipelineDots extends StatelessWidget {
  const PipelineDots({super.key, required this.pipeline});
  final List<LayerStatus> pipeline;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final status in pipeline)
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(left: 5),
            decoration: BoxDecoration(
              color: layerStatusColor(context, status),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class PipelineList extends StatelessWidget {
  const PipelineList({super.key, required this.pipeline});
  final List<LayerStatus> pipeline;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final layers = MpcFacts.infraStack;
    final count = pipeline.length < layers.length
        ? pipeline.length
        : layers.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(layers[i].iconAsset, width: 18, height: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(layers[i].titleKey),
                        style: TextStyle(
                          color: p.textHi,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 16 / 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr(layers[i].briefKey),
                        style: TextStyle(
                          color: p.textLo,
                          fontSize: 12,
                          height: 17 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Pill(
                  context.tr(pipeline[i].key),
                  color: layerStatusColor(context, pipeline[i]),
                  backgroundColor: layerStatusBg(pipeline[i]),
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  fontSize: 10,
                ),
              ],
            ),
          ),
          if (i != count - 1)
            Container(
              height: 1,
              color: isDark ? p.border : AppColors.layerDivider,
            ),
        ],
      ],
    );
  }
}
