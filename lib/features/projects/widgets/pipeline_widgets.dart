import 'package:flutter/material.dart';

import '../../../core/constants/mpc_facts.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/mining_project.dart';

/// Colour for a layer status. Grounded, qualitative — never a percentage.
Color layerStatusColor(BuildContext context, LayerStatus status) {
  final p = context.palette;
  return switch (status) {
    LayerStatus.secured => AppColors.positive,
    LayerStatus.inProgress => AppColors.info,
    LayerStatus.inDiscussion => p.accent,
    LayerStatus.planned => p.textLo,
  };
}

/// Compact 4-dot indicator of the four-layer pipeline (Resource → Capital
/// markets), coloured by status. Used on project cards.
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

/// Full pipeline breakdown: each infrastructure layer with its status pill.
/// Layer names come from [MpcFacts.infraStack]; statuses from the project.
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
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: layerStatusColor(
                    context,
                    pipeline[i],
                  ).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${layers[i].index}',
                  style: TextStyle(
                    color: layerStatusColor(context, pipeline[i]),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr(layers[i].titleKey),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Pill(
                context.tr(pipeline[i].key),
                color: layerStatusColor(context, pipeline[i]),
              ),
            ],
          ),
          if (i != count - 1) Divider(color: p.border, height: 20),
        ],
      ],
    );
  }
}
