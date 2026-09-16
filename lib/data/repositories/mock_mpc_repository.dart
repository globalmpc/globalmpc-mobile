import '../../core/constants/mpc_facts.dart';
import '../../core/widgets/mining_hero_art.dart';
import '../models/mining_project.dart';
import '../models/wallet_models.dart';
import 'mpc_repository.dart';

/// In-memory data source. Project facts (Tsagaan Tolgoi, commodities,
/// verification design) are grounded in globalmpc.tech; the second entry is
/// the site's explicit "coming soon" asset. Wallet figures are clearly a demo.
///
/// Small artificial delays simulate network latency so loading states are real.
class MockMpcRepository implements MpcRepository {
  const MockMpcRepository();

  static const _latency = Duration(milliseconds: 550);
  static const _previewLowGas = bool.fromEnvironment('MPC_PREVIEW_LOW_GAS');

  static final List<MiningProject> _projects = [
    const MiningProject(
      id: 'tsagaan-tolgoi',
      nameKey: 'proj.tsagaan.name',
      location: 'geo.mongolia',
      commodities: [
        'commodity.silicon',
        'commodity.lithium',
        'commodity.rareEarth',
      ],
      stage: ProjectStage.inDiscussion,
      summaryKey: 'proj.tsagaan.summary',
      description: 'proj.tsagaan.desc',
      // Order matches MpcFacts.infraStack: Resource, Structuring, Tokenization,
      // Capital markets. Grounded in the site's status language.
      pipeline: [
        // Whitepaper Section 3/Section 14: the asset itself is "In discussion". No layer may
        // read "Secured" until an independent CP signed report exists (Section 2.1).
        LayerStatus.inDiscussion, // Resource: dev/production/supply leadership
        LayerStatus
            .inProgress, // Structuring: offtake + ops audit in negotiation
        LayerStatus
            .planned, // Tokenization: stack provisionally selected (Section 11)
        LayerStatus.planned, // Capital markets: listing/liquidity pending
      ],
      // Statuses per whitepaper Q3 (six-pillar table) and Appendix C. None of
      // these is complete: the CP report is commissioned at issuance, and
      // Verification B is a 30-day PoC that has not run.
      verificationMethods: [
        VerificationMethod('verify.jorc', CommissionStatus.atIssuance),
        VerificationMethod('verify.cctv', CommissionStatus.designStage),
        VerificationMethod('verify.cp', CommissionStatus.atIssuance),
      ],
      featured: true,
      heroKind: MiningHeroKind.strategicMinerals,
    ),
    const MiningProject(
      id: 'additional-strategic-resources',
      nameKey: 'proj.additional.name',
      location: 'geo.mongolia',
      commodities: ['commodity.tba'],
      stage: ProjectStage.comingSoon,
      summaryKey: 'proj.additional.summary',
      description: 'proj.additional.desc',
      pipeline: [
        LayerStatus.inDiscussion, // Resource
        LayerStatus.planned,
        LayerStatus.planned,
        LayerStatus.planned,
      ],
      verificationMethods: [
        VerificationMethod('verify.jorc', CommissionStatus.toBeCommissioned),
      ],
      heroKind: MiningHeroKind.forthcoming,
    ),
  ];

  static final WalletAccount _wallet = WalletAccount(
    address: '0x7A1f4C9d2E5b8A3f0C6d9E2b1A4f7C0d8E3b6A21',
    isDemo: true,
    mpcBalance: 128450.0,
    bnbBalance: _previewLowGas ? 0.00003 : 0.0128,
    network: MpcFacts.network,
    allocations: {'tsagaan-tolgoi': 96000.0},
    transactions: [
      WalletTransaction(
        hash: '0x9f2a…c41d',
        kind: TxKind.issuance,
        direction: TxDirection.incoming,
        amount: 50000,
        counterparty: MpcFacts.issuer,
        timestamp: DateTime(2026, 7, 12, 9, 14),
        projectNameKey: 'proj.tsagaan.name',
      ),
      WalletTransaction(
        hash: '0x3b71…08ac',
        kind: TxKind.allocation,
        direction: TxDirection.outgoing,
        amount: 96000,
        counterpartyKey: 'wallet.tx.vault',
        timestamp: DateTime(2026, 7, 10, 16, 2),
        projectNameKey: 'proj.tsagaan.name',
      ),
      WalletTransaction(
        hash: '0x5c88…7f10',
        kind: TxKind.receive,
        direction: TxDirection.incoming,
        amount: 174450,
        // Deliberately not a real address, so demo data can never be read as
        // an on-chain fact.
        counterparty: '0xDEMO…0000',
        timestamp: DateTime(2026, 7, 3, 11, 47),
      ),
    ],
  );

  @override
  Future<List<MiningProject>> fetchProjects() async {
    await Future.delayed(_latency);
    return List.unmodifiable(_projects);
  }

  @override
  Future<MiningProject?> fetchProject(String id) async {
    await Future.delayed(_latency);
    for (final p in _projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<WalletAccount> fetchWallet() async {
    await Future.delayed(_latency);
    return _wallet;
  }
}
