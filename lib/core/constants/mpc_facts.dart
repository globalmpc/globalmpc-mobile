class MpcFacts {
  const MpcFacts._();

  static const String tokenName = 'MPC';
  static const String tokenSymbol = 'MPC';
  static const String issuer = 'Bolor Geo MPC Corp.';
  static const String network = 'BNB Smart Chain';
  static const String networkShort = 'BSC';
  static const int totalSupply = 10000000000;
  static const String contractAddress =
      '0x9135709be5eB0f7d6B777b8d53a27B07e7d6107F';

  static const String tokenStandard = 'ERC-3643';
  static const String explorerBase = 'https://bscscan.com';

  static const String taglineKey = 'facts.tagline';

  static const String trustLineKey = 'app.trust';

  static const String disclosureKey = 'facts.disclosure';

  static String get explorerTokenUrl => '$explorerBase/token/$contractAddress';

  static const List<RiskLayerFact> riskLayers = [
    RiskLayerFact('risk.resource.title', 'risk.resource.detail'),
    RiskLayerFact('risk.operational.title', 'risk.operational.detail'),
    RiskLayerFact('risk.market.title', 'risk.market.detail'),
    RiskLayerFact('risk.regulatory.title', 'risk.regulatory.detail'),
  ];

  static const List<PartnerFact> partners = [
    PartnerFact(
      'partner.audit',
      'partner.audit.detail',
      CommissionStatus.toBeCommissioned,
    ),
    PartnerFact(
      'partner.tokenization',
      'partner.tokenization.detail',
      CommissionStatus.planned,
    ),
    PartnerFact(
      'partner.oracle',
      'partner.oracle.detail',
      CommissionStatus.planned,
    ),
  ];

  static const List<InfraLayerFact> infraStack = [
    InfraLayerFact(
      index: 1,
      titleKey: 'layer.resource.title',
      scopeKey: 'scope.offChain',
      detailKey: 'layer.resource.detail',
      briefKey: 'layer.resource.brief',
      iconAsset: 'assets/icons/infra/resource-layer.svg',
    ),
    InfraLayerFact(
      index: 2,
      titleKey: 'layer.structuring.title',
      scopeKey: 'scope.offChain',
      detailKey: 'layer.structuring.detail',
      briefKey: 'layer.structuring.brief',
      iconAsset: 'assets/icons/infra/structuring-layer.svg',
    ),
    InfraLayerFact(
      index: 3,
      titleKey: 'layer.tokenization.title',
      scopeKey: 'scope.onChain',
      detailKey: 'layer.tokenization.detail',
      briefKey: 'layer.tokenization.brief',
      iconAsset: 'assets/icons/infra/tokenization-layer.svg',
    ),
    InfraLayerFact(
      index: 4,
      titleKey: 'layer.capital.title',
      scopeKey: 'scope.onChain',
      detailKey: 'layer.capital.detail',
      briefKey: 'layer.capital.brief',
      iconAsset: 'assets/icons/infra/capital-layer.svg',
    ),
  ];
}

class InfraLayerFact {
  const InfraLayerFact({
    required this.index,
    required this.titleKey,
    required this.scopeKey,
    required this.detailKey,
    required this.briefKey,
    required this.iconAsset,
  });

  final int index;
  final String titleKey;
  final String scopeKey;
  final String detailKey;

  final String briefKey;
  final String iconAsset;

  bool get isOnChain => scopeKey == 'scope.onChain';
}

class RiskLayerFact {
  const RiskLayerFact(this.titleKey, this.detailKey);
  final String titleKey;
  final String detailKey;
}

enum CommissionStatus {
  atIssuance('status.atIssuance'),

  toBeCommissioned('status.toBeCommissioned'),

  designStage('status.designStage'),

  afterOperations('status.afterOperations'),

  provisional('status.provisional'),

  planned('status.planned');

  const CommissionStatus(this.key);

  final String key;
}

class PartnerFact {
  const PartnerFact(this.roleKey, this.detailKey, this.status);
  final String roleKey;
  final String detailKey;
  final CommissionStatus status;
}
