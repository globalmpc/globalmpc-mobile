/// MPC facts. Single source: the UI never hardcodes a claim we cannot back up.
/// User-facing copy lives in [AppStrings] under the keys referenced here.
///
/// The app describes the BNB Smart Chain token shown on the official site.
/// Chain and contract are pinned by a test tripwire, so changing either is a
/// deliberate edit rather than a drive-by one.
class MpcFacts {
  const MpcFacts._();

  static const String tokenName = 'MPC';
  static const String tokenSymbol = 'MPC';
  static const String issuer = 'Bolor Geo MPC Corp.';
  static const String network = 'BNB Smart Chain';
  static const String networkShort = 'BSC';
  static const int totalSupply = 10000000000; // 10,000,000,000
  static const String contractAddress =
      '0x9135709be5eB0f7d6B777b8d53a27B07e7d6107F';

  /// ERC-3643 is the whitepaper's PLANNED issuance standard, never a claim
  /// about the live token. Render it only via 'facts.plannedStandard'.
  static const String tokenStandard = 'ERC-3643';
  static const String explorerBase = 'https://bscscan.com';

  /// Localization key for the site tagline.
  static const String taglineKey = 'facts.tagline';

  /// Localization key for the honesty / trust line.
  static const String trustLineKey = 'app.trust';

  /// Localization key for quarterly disclosure copy.
  static const String disclosureKey = 'facts.disclosure';

  static String get explorerTokenUrl => '$explorerBase/token/$contractAddress';

  /// MPC's stated risk framework (applies to every issued asset).
  static const List<RiskLayerFact> riskLayers = [
    RiskLayerFact('risk.resource.title', 'risk.resource.detail'),
    RiskLayerFact('risk.operational.title', 'risk.operational.detail'),
    RiskLayerFact('risk.market.title', 'risk.market.detail'),
    RiskLayerFact('risk.regulatory.title', 'risk.regulatory.detail'),
  ];

  /// The orchestration network (whitepaper Section 6): firms MPC commissions on demand
  /// rather than holds. Status per firm is taken from whitepaper Q3 (six-pillar
  /// verification table) and Section 11 (readiness), so the UI can never imply an
  /// engaged partnership that does not exist yet. [name] stays a proper noun.
  static const List<PartnerFact> partners = [
    PartnerFact('SGS', 'partner.audit', CommissionStatus.afterOperations),
    PartnerFact('BV', 'partner.audit', CommissionStatus.afterOperations),
    PartnerFact('Tokeny', 'partner.tokenization', CommissionStatus.provisional),
    PartnerFact('UMA', 'partner.oracle', CommissionStatus.provisional),
  ];

  /// The four-layer infrastructure stack, top (off-chain) to bottom (markets).
  static const List<InfraLayerFact> infraStack = [
    InfraLayerFact(
      index: 1,
      titleKey: 'layer.resource.title',
      scopeKey: 'scope.offChain',
      detailKey: 'layer.resource.detail',
    ),
    InfraLayerFact(
      index: 2,
      titleKey: 'layer.structuring.title',
      scopeKey: 'scope.offChain',
      detailKey: 'layer.structuring.detail',
    ),
    InfraLayerFact(
      index: 3,
      titleKey: 'layer.tokenization.title',
      scopeKey: 'scope.onChain',
      detailKey: 'layer.tokenization.detail',
    ),
    InfraLayerFact(
      index: 4,
      titleKey: 'layer.capital.title',
      scopeKey: 'scope.onChain',
      detailKey: 'layer.capital.detail',
    ),
  ];
}

class InfraLayerFact {
  const InfraLayerFact({
    required this.index,
    required this.titleKey,
    required this.scopeKey,
    required this.detailKey,
  });

  final int index;
  final String titleKey;
  final String scopeKey;
  final String detailKey;

  bool get isOnChain => scopeKey == 'scope.onChain';
}

class RiskLayerFact {
  const RiskLayerFact(this.titleKey, this.detailKey);
  final String titleKey;
  final String detailKey;
}

/// Commissioning status vocabulary, taken verbatim in meaning from whitepaper
/// Q3 (six-pillar verification table), Q4 (held vs to-be-built) and Section 11
/// (readiness). MPC is an orchestrator (Section 6): it commissions verification on
/// demand, so nothing here may render as "done" until a signed artifact exists.
///
/// Appendix D forbids presenting an incomplete process as complete, which is
/// why there is deliberately no `complete` value. One gets added only when a
/// real signed report or a third-party-reviewed PoC exists to back it.
enum CommissionStatus {
  /// Commissioned at deal issuance (Q3, resource verification).
  atIssuance('status.atIssuance'),

  /// To be commissioned (Q3, title and legal verification).
  toBeCommissioned('status.toBeCommissioned'),

  /// Design stage (Q3, financial / data-integrity / operational verification).
  designStage('status.designStage'),

  /// Design stage, commissioned after operations begin (Q3, operational).
  afterOperations('status.afterOperations'),

  /// Provisionally selected, final freeze pending (Section 11, technology stack).
  provisional('status.provisional');

  const CommissionStatus(this.key);

  /// Localization key for the status label.
  final String key;
}

class PartnerFact {
  const PartnerFact(this.name, this.roleKey, this.status);
  final String name;
  final String roleKey;
  final CommissionStatus status;
}
