import 'package:flutter/material.dart';

import '../../core/constants/mpc_facts.dart';
import '../../core/widgets/mining_hero_art.dart';

/// A verification method plus the status it is actually in.
///
/// The status is not decoration. Whitepaper Appendix D requires that
/// Verification B (CCTV/AI) is *always* accompanied by "design stage", and
/// forbids presenting JORC/CP work as complete while it is still to be
/// commissioned (Q3, Appendix C). Pairing every method with a
/// [CommissionStatus] makes that rule structural rather than editorial.
@immutable
class VerificationMethod {
  const VerificationMethod(this.labelKey, this.status);

  /// Localization key for the method name.
  final String labelKey;
  final CommissionStatus status;
}

/// Lifecycle stage of a mining asset. Values mirror the status words used on
/// globalmpc.tech ("Secured", "To be secured / in discussion").
enum ProjectStage {
  /// Whitepaper Section 3 / Section 14 status for the first reference case. Kept distinct
  /// from [secured] because no independent CP report backs "secured" yet.
  inDiscussion('In discussion'),
  secured('Secured'),
  toBeSecured('To be secured'),
  comingSoon('Coming soon');

  const ProjectStage(this.label);
  final String label;

  /// Localization key, e.g. 'stage.secured'.
  String get key => 'stage.$name';
}

/// Status of one of MPC's four infrastructure layers for a given asset.
/// Grounded in the site's language, not invented percentages.
enum LayerStatus {
  secured('Secured'),
  inProgress('In progress'),
  inDiscussion('In discussion'),
  planned('Planned');

  const LayerStatus(this.label);
  final String label;

  /// Localization key, e.g. 'status.inProgress'.
  String get key => 'status.$name';
}

/// A tokenizable real-world mining asset. Everything here is sourced from
/// globalmpc.tech; there are deliberately no fabricated figures (no APY, no
/// allocated-supply number, no production series).
///
/// User-facing strings ([nameKey], [summaryKey], [description],
/// [verificationMethods]) are localization keys resolved via `context.tr`.
@immutable
class MiningProject {
  const MiningProject({
    required this.id,
    required this.nameKey,
    required this.location,
    required this.commodities,
    required this.stage,
    required this.summaryKey,
    required this.description,
    required this.pipeline,
    required this.verificationMethods,
    this.featured = false,
    this.heroKind,
  });

  final String id;

  /// Localization key for the display name.
  final String nameKey;
  final String location;
  final List<String> commodities;
  final ProjectStage stage;

  /// Localization key for the short summary.
  final String summaryKey;

  /// Localization key for the long description.
  final String description;

  /// Status of each of the four infrastructure layers, in the same order as
  /// [MpcFacts.infraStack] (Resource, Structuring, Tokenization, Capital markets).
  final List<LayerStatus> pipeline;

  /// Verification methods, each with its real commissioning status.
  final List<VerificationMethod> verificationMethods;
  final bool featured;

  /// Illustrative hero theme — never treated as a photograph of the site.
  /// Nullable so hot-reload of older in-memory instances cannot crash the UI.
  final MiningHeroKind? heroKind;

  /// Safe art theme for widgets (survives hot-reload of pre-field instances).
  MiningHeroKind get artKind => heroKind ?? MiningHeroKind.strategicMinerals;

  bool get isSecured => stage == ProjectStage.secured;
  bool get isComingSoon => stage == ProjectStage.comingSoon;

  /// Count of layers that are fully secured — a factual summary, not a percentage.
  int get securedLayers =>
      pipeline.where((s) => s == LayerStatus.secured).length;
}
