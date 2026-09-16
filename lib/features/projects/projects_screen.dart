import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/retry_state_card.dart';
import '../../data/models/mining_project.dart';
import 'projects_provider.dart';
import 'widgets/project_card.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectsProvider>();
    final state = provider.state;
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.gold,
          onRefresh: provider.load,
          child: switch (state) {
            _ when state.isLoading => _LoadingBody(),
            _ when state.isError => _ErrorBody(onRetry: provider.load),
            _ when (state.data?.isEmpty ?? false) => _EmptyBody(
              onRetry: provider.load,
            ),
            _ => _LoadedBody(
              projects: state.data ?? const [],
              onTap: (p) => context.push('/projects/${p.id}'),
            ),
          },
        ),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({this.showSubtitle = true});
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('proj.title'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: p.textHi,
            height: 29 / 24,
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 16),
          Text(
            context.tr('proj.subtitle'),
            style: TextStyle(fontSize: 13, color: p.textLo, height: 16 / 13),
          ),
        ],
      ],
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.projects, required this.onTap});
  final List<MiningProject> projects;
  final ValueChanged<MiningProject> onTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        const _ScreenHeader(),
        const SizedBox(height: 16),
        for (int i = 0; i < projects.length; i++) ...[
          ProjectCard(project: projects[i], onTap: () => onTap(projects[i])),
          if (i < projects.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _LoadingBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        const _ScreenHeader(),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('proj.loadingTitle'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: p.textHi,
                  height: 22 / 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('proj.loadingBody'),
                style: TextStyle(
                  fontSize: 13,
                  color: p.textLo,
                  height: 16 / 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          height: 180,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        const _ScreenHeader(showSubtitle: false),
        const SizedBox(height: 40),
        RetryStateCard(
          iconAsset: 'assets/icons/notifications/cloud_off.svg',
          iconSize: 36,
          title: context.tr('proj.loadError'),
          body: context.tr('proj.loadErrorBody'),
          onRetry: onRetry,
          buttonLabel: context.tr('proj.tryAgain'),
        ),
      ],
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        const _ScreenHeader(showSubtitle: false),
        const SizedBox(height: 40),
        RetryStateCard(
          iconAsset: 'assets/icons/notifications/inbox.svg',
          iconSize: 40,
          title: context.tr('proj.none'),
          body: context.tr('proj.noneBody'),
          onRetry: onRetry,
          buttonLabel: context.tr('proj.tryAgain'),
        ),
      ],
    );
  }
}
