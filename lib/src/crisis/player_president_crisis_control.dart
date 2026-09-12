import 'dart:convert';

import '../core/simulation_config.dart';
import '../election/president_management_profile.dart';
import '../fan/fan_state.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../media/media_state.dart';
import '../save/save_checksum.dart';
import '../save/save_load_exception.dart';
import '../sponsor/player_president_sponsor_control.dart';
import '../sponsor/sponsor_system.dart';
import '../world/world_league.dart';
import 'crisis_decision_core.dart';
import 'crisis_runtime_integration.dart';
import 'player_president_facility_control.dart';

class PlayerCrisisActionChoice {
  const PlayerCrisisActionChoice({required this.action});

  final CrisisAction action;

  String get signature => action.name;
}

class PlayerCrisisDecisionContext {
  PlayerCrisisDecisionContext({
    required this.crisis,
    required this.scenario,
    required Iterable<CrisisDecision> availableDecisions,
    required this.aiDecision,
  }) : availableDecisions = List.unmodifiable(availableDecisions);

  final CrisisContext crisis;
  final CrisisScenario scenario;
  final List<CrisisDecision> availableDecisions;
  final CrisisDecision aiDecision;

  int get seasonIndex => crisis.seasonIndex;
  String get clubId => crisis.clubId;
  String get presidentId => crisis.president.presidentId;
  PresidentManagementProfile get managementProfile => crisis.president;
  ClubFinanceState get finance => crisis.finance;
  FanState get fan => crisis.fan;
  MediaState get media => crisis.media;

  String get signature =>
      '${crisis.signature}:scenario=${scenario.signature}:'
      'ai=${aiDecision.signature}:options='
      '${availableDecisions.map((item) => item.signature).join('|')}';
}

abstract class PlayerCrisisDecisionProvider {
  const PlayerCrisisDecisionProvider();

  PlayerCrisisActionChoice choose(PlayerCrisisDecisionContext context);
}

class PlayerPresidentCrisisRuntimeDecision {
  const PlayerPresidentCrisisRuntimeDecision({
    required this.context,
    required this.choice,
    required this.selectedDecision,
    required this.resolution,
  });

  final PlayerCrisisDecisionContext context;
  final PlayerCrisisActionChoice choice;
  final CrisisDecision selectedDecision;
  final CrisisResolution resolution;

  int get seasonIndex => context.seasonIndex;
  String get clubId => context.clubId;
  String get presidentId => context.presidentId;
  CrisisDecision get aiDecision => context.aiDecision;
  bool get changedFromAi => selectedDecision.action != aiDecision.action;

  String get signature =>
      '${context.signature}:choice=${choice.signature}:'
      'selected=${selectedDecision.signature}:applied=${resolution.signature}';
}

class PlayerPresidentCrisisControlCheckpoint {
  PlayerPresidentCrisisControlCheckpoint({required this.control}) {
    validate();
  }

  final PlayerPresidentSponsorControlCheckpoint control;

  int get nextSeasonIndex => control.nextSeasonIndex;
  int get completedSeasons => control.completedSeasons;
  String get controlledClubId => control.controlledClubId;

  void validate() => control.validate();

  String get signature => 'crisis-control:${control.signature}';
}

class PlayerPresidentCrisisControlSaveCodec {
  const PlayerPresidentCrisisControlSaveCodec({
    this.controlCodec = const PlayerPresidentSponsorControlSaveCodec(),
  });

  static const String format = 'zmila-fbs-player-president-crisis-control';
  static const int currentSaveVersion = 1;

  final PlayerPresidentSponsorControlSaveCodec controlCodec;

  String encode(PlayerPresidentCrisisControlCheckpoint checkpoint) {
    checkpoint.validate();
    final payload = <String, Object?>{
      'controlSave': controlCodec.encode(checkpoint.control),
    };
    final checksum = SaveChecksum.forPayload(
      saveVersion: currentSaveVersion,
      payload: payload,
    );
    return SaveChecksum.canonicalJson({
      'format': format,
      'saveVersion': currentSaveVersion,
      'payload': payload,
      'checksum': checksum,
    });
  }

  PlayerPresidentCrisisControlCheckpoint decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'Player-president crisis save is not valid JSON: ${error.message}',
      );
    }
    if (decoded is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Player-president crisis save envelope must be a map.',
      );
    }
    final envelope = Map<String, Object?>.from(decoded);
    if (envelope['format'] != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unknown player-president crisis save format.',
      );
    }
    final version = envelope['saveVersion'];
    if (version is! int || version < 0 || version > currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Unsupported player-president crisis save version $version.',
      );
    }
    final payload = envelope['payload'];
    final checksum = envelope['checksum'];
    if (checksum is! String ||
        checksum != SaveChecksum.forPayload(saveVersion: version, payload: payload)) {
      throw const SaveLoadException(
        SaveLoadFailure.checksumMismatch,
        'Player-president crisis save checksum mismatch.',
      );
    }
    if (version != 1 || payload is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Player-president crisis save payload is invalid.',
      );
    }
    final map = Map<String, Object?>.from(payload);
    final controlSave = map['controlSave'];
    if (controlSave is! String) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Player-president crisis control payload is invalid.',
      );
    }
    try {
      return PlayerPresidentCrisisControlCheckpoint(
        control: controlCodec.decode(controlSave),
      );
    } on SaveLoadException {
      rethrow;
    } catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Invalid player-president crisis payload: $error',
      );
    }
  }
}

class PlayerPresidentCrisisControlCareerResult {
  PlayerPresidentCrisisControlCareerResult({
    required this.checkpoint,
    required this.source,
    required Iterable<PlayerPresidentCrisisRuntimeDecision> crisisDecisions,
  }) : crisisDecisions = List.unmodifiable(crisisDecisions);

  final PlayerPresidentCrisisControlCheckpoint checkpoint;
  final PlayerPresidentSponsorControlCareerResult source;
  final List<PlayerPresidentCrisisRuntimeDecision> crisisDecisions;

  List<PlayerPresidentFacilityControlSeasonBoundary> get boundaries =>
      source.boundaries;

  String get signature =>
      'crisis=${crisisDecisions.map((item) => item.signature).join('||')}:'
      'source=${source.signature}:final=${checkpoint.signature}';
}

/// M51 gives the player-controlled president the final say on an actual crisis
/// response while preserving the M50 sponsor and M49 facility controls.
///
/// The provider is consulted only when the controlled club has a detected
/// crisis. It may select only one of M43's canonical actions for that crisis
/// type. Other clubs stay on the exact AI path, and no provider is serialized.
class PlayerPresidentCrisisControlCareerEngine {
  const PlayerPresidentCrisisControlCareerEngine({
    this.crisisProvider,
    this.sponsorProvider,
    this.facilityProvider,
    this.offerEngine = const SponsorOfferEngine(),
    this.aiSponsorPolicy = const PresidentSponsorDecisionPolicy(),
    this.aiCrisisEngine = const CrisisDecisionEngine(activationThreshold: 55),
  });

  final PlayerCrisisDecisionProvider? crisisProvider;
  final PlayerSponsorDecisionProvider? sponsorProvider;
  final PlayerFacilityInvestmentDecisionProvider? facilityProvider;
  final SponsorOfferEngine offerEngine;
  final PresidentSponsorDecisionPolicy aiSponsorPolicy;
  final CrisisDecisionEngine aiCrisisEngine;

  PlayerPresidentCrisisControlCareerResult simulateWithCheckpoint({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    required String controlledClubId,
    int seasonCount = 20,
    int electionInterval = 4,
    bool hasFutureSeasonAfterReport = false,
  }) {
    final decisions = <PlayerPresidentCrisisRuntimeDecision>[];
    final engine = _sourceEngine(
      controlledClubId: controlledClubId,
      decisions: decisions,
    );
    final source = engine.simulateWithCheckpoint(
      clubs: clubs,
      leagues: leagues,
      config: config,
      controlledClubId: controlledClubId,
      seasonCount: seasonCount,
      electionInterval: electionInterval,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
    );
    return PlayerPresidentCrisisControlCareerResult(
      checkpoint: PlayerPresidentCrisisControlCheckpoint(
        control: source.checkpoint,
      ),
      source: source,
      crisisDecisions: decisions,
    );
  }

  PlayerPresidentCrisisControlCareerResult resume({
    required PlayerPresidentCrisisControlCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
  }) {
    checkpoint.validate();
    final decisions = <PlayerPresidentCrisisRuntimeDecision>[];
    final engine = _sourceEngine(
      controlledClubId: checkpoint.controlledClubId,
      decisions: decisions,
    );
    final source = engine.resume(
      checkpoint: checkpoint.control,
      seasonCount: seasonCount,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
    );
    return PlayerPresidentCrisisControlCareerResult(
      checkpoint: PlayerPresidentCrisisControlCheckpoint(
        control: source.checkpoint,
      ),
      source: source,
      crisisDecisions: decisions,
    );
  }

  PlayerPresidentSponsorControlCareerEngine _sourceEngine({
    required String controlledClubId,
    required List<PlayerPresidentCrisisRuntimeDecision> decisions,
  }) {
    final CrisisDecisionEngine decisionEngine;
    if (crisisProvider == null) {
      decisionEngine = aiCrisisEngine;
    } else {
      decisionEngine = _PlayerPresidentCrisisDecisionEngine(
        controlledClubId: controlledClubId,
        provider: crisisProvider!,
        decisions: decisions,
        aiEngine: aiCrisisEngine,
      );
    }
    return PlayerPresidentSponsorControlCareerEngine(
      sponsorProvider: sponsorProvider,
      facilityProvider: facilityProvider,
      offerEngine: offerEngine,
      aiSponsorPolicy: aiSponsorPolicy,
      crisisIntegration: CrisisRuntimeIntegrationEngine(
        decisionEngine: decisionEngine,
      ),
    );
  }
}

class _PlayerPresidentCrisisDecisionEngine extends CrisisDecisionEngine {
  _PlayerPresidentCrisisDecisionEngine({
    required this.controlledClubId,
    required this.provider,
    required this.decisions,
    required this.aiEngine,
  }) : super(activationThreshold: aiEngine.activationThreshold);

  final String controlledClubId;
  final PlayerCrisisDecisionProvider provider;
  final List<PlayerPresidentCrisisRuntimeDecision> decisions;
  final CrisisDecisionEngine aiEngine;

  @override
  CrisisResolution? evaluate(CrisisContext context) {
    if (context.clubId != controlledClubId) {
      return aiEngine.evaluate(context);
    }

    final scenario = aiEngine.detect(context);
    if (scenario == null) {
      return null;
    }
    final aiDecision = aiEngine.choose(
      scenario: scenario,
      president: context.president,
    );
    final available = aiEngine.availableDecisions(scenario);
    final playerContext = PlayerCrisisDecisionContext(
      crisis: context,
      scenario: scenario,
      availableDecisions: available,
      aiDecision: aiDecision,
    );
    final choice = provider.choose(playerContext);
    final matches = available
        .where((decision) => decision.action == choice.action)
        .toList(growable: false);
    if (matches.length != 1) {
      throw ArgumentError.value(
        choice.action,
        'action',
        'Player crisis choice must select one action for ${scenario.type.name}.',
      );
    }
    final selected = matches.single;
    final resolution = aiEngine.resolveAction(
      context: context,
      scenario: scenario,
      action: selected.action,
    );
    decisions.add(
      PlayerPresidentCrisisRuntimeDecision(
        context: playerContext,
        choice: choice,
        selectedDecision: selected,
        resolution: resolution,
      ),
    );
    return resolution;
  }
}
