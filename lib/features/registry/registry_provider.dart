import 'package:flutter/foundation.dart';

import '../../core/state/view_state.dart';
import '../../data/services/registry_anchor_service.dart';

/// Holds the registry feed for the dashboard card and the registry screen.
/// A build without an anchor address has no service, and the UI shows that
/// as "not connected" rather than as an empty registry.
class RegistryProvider extends ChangeNotifier {
  RegistryProvider(this._service);

  final RegistryAnchorService? _service;

  ViewState<RegistryFeed> _state = const ViewState.idle();
  ViewState<RegistryFeed> get state => _state;

  bool get isConnected => _service != null;

  String? get explorerUrl => _service?.explorerUrl;

  Future<void> load() async {
    final service = _service;
    if (service == null) return;
    _state = const ViewState.loading();
    notifyListeners();
    try {
      _state = ViewState.success(await service.fetchLatest());
    } catch (e) {
      _state = ViewState.error('Could not read the registry anchor. $e');
    }
    notifyListeners();
  }
}
