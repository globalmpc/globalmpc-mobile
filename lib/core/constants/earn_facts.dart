/// Planned "Earn" capabilities for MPC: staking and farming via smart
/// contract. MPC issuance is designed on the permissioned **ERC-3643**
/// standard and is **pre-listing**, so no reward rate is published anywhere.
/// These are therefore declared as *planned, listing-gated* capabilities and
/// the UI must never show an invented APY / pool size. Keeping the structure
/// here (and the copy in the localization tables) keeps that honesty rule in
/// one place.
class EarnFacts {
  const EarnFacts._();

  /// The two planned capabilities, in display order.
  /// [id] resolves copy via the `earn.<id>.*` localization keys.
  static const List<EarnProgramFact> programs = [
    EarnProgramFact(id: 'staking'),
    EarnProgramFact(id: 'farming'),
  ];

  /// Why Earn is not live yet. [id] resolves copy via `earn.gate.<id>.*`.
  static const List<EarnGateFact> gates = [
    EarnGateFact(id: 'kyc'),
    EarnGateFact(id: 'listing'),
  ];
}

/// A single planned earn capability. Intentionally carries no rate field — MPC
/// is pre-listing and no yield exists to quote.
class EarnProgramFact {
  const EarnProgramFact({required this.id});
  final String id;
}

/// A precondition that gates Earn from going live.
class EarnGateFact {
  const EarnGateFact({required this.id});
  final String id;
}
