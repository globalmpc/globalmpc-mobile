import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/notifications/notification_center.dart';
import '../../core/state/view_state.dart';
import '../../data/models/wallet_models.dart';
import '../../data/repositories/mpc_repository.dart';

class WalletProvider extends ChangeNotifier {
  WalletProvider(this._repo);

  final MpcRepository _repo;

  ViewState<WalletAccount> _state = const ViewState.idle();
  ViewState<WalletAccount> get state => _state;

  Future<void> load() async {
    _state = const ViewState.loading();
    notifyListeners();
    try {
      final wallet = await _repo.fetchWallet();
      _state = ViewState.success(wallet);
      unawaited(NotificationCenter.instance.reviewTransactions(wallet));
    } catch (e) {
      _state = ViewState.error('Could not load wallet. $e');
    }
    notifyListeners();
  }
}
