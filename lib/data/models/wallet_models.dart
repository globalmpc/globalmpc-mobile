import 'package:flutter/material.dart';

enum TxDirection { incoming, outgoing }

enum TxStatus { submitted, pending, confirmed, failed }

enum TxKind {
  receive('Received'),
  send('Sent'),
  allocation('Project allocation'),
  issuance('Issuance');

  const TxKind(this.label);
  final String label;

  /// Localization key, e.g. 'tx.receive'.
  String get key => 'tx.$name';
}

@immutable
class WalletTransaction {
  const WalletTransaction({
    required this.hash,
    required this.kind,
    required this.direction,
    required this.amount,
    required this.timestamp,
    this.counterparty,
    this.counterpartyKey,
    this.projectNameKey,
    this.status = TxStatus.confirmed,
    this.networkFeeBnb = 0.00012,
    this.blockConfirmations,
  }) : assert(counterparty != null || counterpartyKey != null);

  final String hash;
  final TxKind kind;
  final TxDirection direction;
  final double amount; // MPC
  /// Raw counterparty when it is an address or proper noun (not translated).
  final String? counterparty;

  /// Localization key when the counterparty label should be translated.
  final String? counterpartyKey;
  final DateTime timestamp;

  /// Localization key for the related project name, if any.
  final String? projectNameKey;
  final TxStatus status;
  final double networkFeeBnb;
  final int? blockConfirmations;

  bool get isIncoming => direction == TxDirection.incoming;
}

/// A demo, non-custodial BSC account. This is a prototype wallet: no real keys
/// are generated or stored. Kept explicit so nothing here is mistaken for a
/// production custody surface.
@immutable
class WalletAccount {
  const WalletAccount({
    required this.address,
    required this.mpcBalance,
    required this.network,
    required this.transactions,
    required this.allocations,
    this.bnbBalance = 0.0128,
    this.isDemo = false,
  });

  final String address;

  /// True only for the mock fallback account. Real on-device wallets render
  /// the network label (e.g. Testnet) instead of the Demo badge.
  final bool isDemo;
  final double mpcBalance;
  final String network;
  final List<WalletTransaction> transactions;

  /// projectId -> MPC allocated to that project by this holder.
  final Map<String, double> allocations;
  final double bnbBalance;

  double get allocatedTotal =>
      allocations.values.fold(0.0, (sum, v) => sum + v);
}

/// Maps a known project id to its display-name localization key.
String projectNameKeyForId(String id) => switch (id) {
  'tsagaan-tolgoi' => 'proj.tsagaan.name',
  'additional-strategic-resources' => 'proj.additional.name',
  _ => id,
};
