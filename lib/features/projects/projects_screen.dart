import 'package:flutter/material.dart';
import 'package:mpc_mining_app/core/theme/app_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/mining_project.dart';
import 'projects_provider.dart';
import 'widgets/project_card.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectsProvider>();
    final state = provider.state;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('proj.title'))),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: provider.load,
          child: switch (state.status) {
            _ when state.isLoading => const Center(
              child: CircularProgressIndicator(),
            ),
            _ when state.isError => ListView(
              children: [
                const SizedBox(height: 120),
                StateMessage(
                  icon: AppIcons.cloud_off_outlined,
                  title: context.tr('proj.loadError'),
                  message: state.error,
                  onRetry: provider.load,
                ),
              ],
            ),
            _ => _ProjectList(projects: state.data ?? const []),
          },
        ),
      ),
    );
  }
}

class _ProjectList extends StatelessWidget {
  const _ProjectList({required this.projects});
  final List<MiningProject> projects;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          StateMessage(
            icon: AppIcons.inbox_outlined,
            title: context.tr('proj.none'),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final project = projects[i];
        return ProjectCard(
          project: project,
          onTap: () => context.push('/projects/${project.id}'),
        );
      },
    );
  }
}
