import 'package:flutter/foundation.dart';

import '../../core/state/view_state.dart';
import '../../data/models/mining_project.dart';
import '../../data/repositories/mpc_repository.dart';

class ProjectsProvider extends ChangeNotifier {
  ProjectsProvider(this._repo);

  final MpcRepository _repo;

  ViewState<List<MiningProject>> _state = const ViewState.idle();
  ViewState<List<MiningProject>> get state => _state;

  Future<void> load() async {
    _state = const ViewState.loading();
    notifyListeners();
    try {
      final projects = await _repo.fetchProjects();
      _state = ViewState.success(projects);
    } catch (e) {
      _state = ViewState.error('Could not load projects. $e');
    }
    notifyListeners();
  }

  MiningProject? byId(String id) {
    final data = _state.data;
    if (data == null) return null;
    for (final p in data) {
      if (p.id == id) return p;
    }
    return null;
  }

  MiningProject? get featured {
    final data = _state.data;
    if (data == null || data.isEmpty) return null;
    return data.firstWhere((p) => p.featured, orElse: () => data.first);
  }
}
