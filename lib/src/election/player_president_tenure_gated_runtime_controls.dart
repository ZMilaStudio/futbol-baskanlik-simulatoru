import 'dart:convert';

import '../core/simulation_config.dart';
import '../crisis/crisis_decision_core.dart';
import '../crisis/player_president_crisis_control.dart';
import '../crisis/player_president_facility_control.dart';
import '../facility/president_academy_investment_orchestrator.dart';
import '../facility/president_facility_portfolio_investment_orchestrator.dart';
import '../league/club.dart';
import '../manager/manager_fit_model.dart';
import '../manager/player_president_manager_control.dart';
import '../save/president_runtime_checkpoint.dart';
import '../save/save_checksum.dart';
import '../save/save_load_exception.dart';
import '../sponsor/player_president_sponsor_control.dart';
import '../sponsor/sponsor_system.dart';
import '../world/world_league.dart';
import 'player_president_tenure_control_gate.dart';
import 'president_tenure.dart';

class PlayerPresidentTenureGatedRuntimeCheckpoint {
  PlayerPresidentTenureGatedRuntimeCheckpoint({
    required this.control,
    required this.tenureControl,
  }) {
    validate();
  }

  final PlayerPresidentManagerControlCheckpoint control;
  final PlayerPresidentTenureControlState tenureControl;

  int get nextSeasonIndex => control.nextSeasonIndex;
  int get completedSeasons => control.completedSeasons;
  String get controlledClubId => control.controlledClubId;
  bool get playerControlActive => tenureControl.active;

  void validate() {
    control.validate();
    tenureControl.validate();
    if (control.controlledClubId != tenureControl.controlledClubId) {
      throw ArgumentError(
        'Runtime control club and tenure-control club must match.',
      );
    }
  }

  String get signature =>
      'tenure=${tenureControl.signature}:control=${control.signature}';
}

class PlayerPresidentTenureGatedRuntimeSaveCodec {
  const PlayerPresidentTenureGatedRuntimeSaveCodec({
    this.controlCodec = const PlayerPresidentManagerControlSaveCodec(),
    this.tenureCodec = const PlayerPresidentTenureControlSaveCodec(),
  });

  static const String format = 'zmila-fbs-player-president-tenure-gated-runtime';
  static const int currentSaveVersion = 1;

  final PlayerPresidentManagerControlSaveCodec controlCodec;
  final PlayerPresidentTenureControlSaveCodec tenureCodec;

  String encode(PlayerPresidentTenureGatedRuntimeCheckpoint checkpoint) {
    checkpoint.validate();
    final payload = <String, Object?>{
      'controlSave': controlCodec.encode(checkpoint.control),
      'tenureControlSave': tenureCodec.encode(checkpoint.tenureControl),
    };
    return SaveChecksum.canonicalJson({
      'format': format,
      'saveVersion': currentSaveVersion,
      'payload': payload,
      'checksum': SaveChecksum.forPayload(
        saveVersion: currentSaveVersion,
        payload: payload,
      ),
    });
  }

  PlayerPresidentTenureGatedRuntimeCheckpoint decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'Player-president tenure-gated runtime save is not valid JSON: ${error.message}',
      );
    }
    if (decoded is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Player-president tenure-gated runtime save envelope must be a map.',
      );
    }
    final envelope = Map<String, Object?>.from(decoded);
    if (envelope['format'] != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unknown player-president tenure-gated runtime save format.',
      );
    }
    final version = envelope['saveVersion'];
    if (version is! int || version < 0 || version > currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Unsupported player-president tenure-gated runtime save version $version.',
      );
    }
    final payloadObject = envelope['payload'];
    final checksum = envelope['checksum'];
    if (checksum is! String ||
        checksum != SaveChecksum.forPayload(
          saveVersion: version,
          payload: payloadObject,
        )) {
      throw const SaveLoadException(
        SaveLoadFailure.checksumMismatch,
        'Player-president tenure-gated runtime save checksum mismatch.',
      );
    }
    if (version != 1 || payloadObject is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Player-president tenure-gated runtime payload is invalid.',
      );
    }
    final payload = Map<String, Object?>.from(payloadObject);
    final controlSave = payload['controlSave'];
    final tenureControlSave = payload['tenureControlSave'];
    if (controlSave is! String || tenureControlSave is! String) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Player-president tenure-gated runtime payload fields are invalid.',
      );
    }
    try {
      return PlayerPresidentTenureGatedRuntimeCheckpoint(
        control: controlCodec.decode(controlSave),
        tenureControl: tenureCodec.decode(tenureControlSave),
      );
    } on SaveLoadException {
      rethrow;
    } catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Invalid player-president tenure-gated runtime payload: $error',
      );
    }
  }
}

class PlayerPresidentTenureGatedRuntimeResult {
  PlayerPresidentTenureGatedRuntimeResult({
    required this.checkpoint,
    required Iterable<PlayerPresidentManagerControlCareerResult> segments,
  }) : segments = List.unmodifiable(segments);

  final PlayerPresidentTenureGatedRuntimeCheckpoint checkpoint;
  final List<PlayerPresidentManagerControlCareerResult> segments;

  List<PlayerPresidentManagerRuntimeDecision> get managerDecisions =>
      List.unmodifiable(segments.expand((item) => item.managerDecisions));

  List<PlayerPresidentCrisisRuntimeDecision> get crisisDecisions =>
      List.unmodifiable(segments.expand((item) => item.crisisDecisions));

  List<PlayerPresidentSponsorRuntimeDecision> get sponsorDecisions =>
      List.unmodifiable(segments.expand((item) => item.sponsorDecisions));

  List<PlayerPresidentFacilityControlSeasonBoundary> get boundaries =>
      List.unmodifiable(segments.expand((item) => item.boundaries));

  String get signature =>
      '${segments.map((item) => item.signature).join('||')}:'
      'final=${checkpoint.signature}';
}

/// M59 applies M58's incumbent-president ownership gate to the nested M49-M52
/// player decision stack.
///
/// The external player providers are consulted only while the captured player
/// president remains the real incumbent. If a real election installs another
/// president, the same in-flight season immediately falls back to each
/// subsystem's canonical AI choice and later seasons use the untouched AI path.
/// The gate is refreshed and persisted after every season, while providers
/// remain runtime-only.
class PlayerPresidentTenureGatedRuntimeCareerEngine {
  const PlayerPresidentTenureGatedRuntimeCareerEngine({
    this.managerProvider,
    this.crisisProvider,
    this.sponsorProvider,
    this.facilityProvider,
    this.offerEngine = const SponsorOfferEngine(),
    this.aiSponsorPolicy = const PresidentSponsorDecisionPolicy(),
    this.aiCrisisEngine = const CrisisDecisionEngine(activationThreshold: 55),
    this.fitModel = const ManagerFitModel(),
    this.candidateLimit = 5,
    this.tenureGate = const PlayerPresidentTenureControlGate(),
  }) : assert(candidateLimit > 0);

  final PlayerManagerDecisionProvider? managerProvider;
  final PlayerCrisisDecisionProvider? crisisProvider;
  final PlayerSponsorDecisionProvider? sponsorProvider;
  final PlayerFacilityInvestmentDecisionProvider? facilityProvider;
  final SponsorOfferEngine offerEngine;
  final PresidentSponsorDecisionPolicy aiSponsorPolicy;
  final CrisisDecisionEngine aiCrisisEngine;
  final ManagerFitModel fitModel;
  final int candidateLimit;
  final PlayerPresidentTenureControlGate tenureGate;

  PlayerPresidentTenureGatedRuntimeResult simulateWithCheckpoint({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    required String controlledClubId,
    int seasonCount = 20,
    int electionInterval = 4,
    bool hasFutureSeasonAfterReport = false,
  }) {
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }
    if (!clubs.any((club) => club.id == controlledClubId)) {
      throw ArgumentError('Unknown controlled club $controlledClubId.');
    }

    final initialPresident = const PresidentProfileGenerator().generateInitial(
      clubId: controlledClubId,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );
    var tenure = PlayerPresidentTenureControlState(
      controlledClubId: controlledClubId,
      playerPresidentId: initialPresident.id,
      status: PlayerPresidentTenureControlStatus.active,
    );
    final segments = <PlayerPresidentManagerControlCareerResult>[];
    PlayerPresidentManagerControlCheckpoint? current;

    for (var offset = 0; offset < seasonCount; offset++) {
      final hasFuture = offset < seasonCount - 1 || hasFutureSeasonAfterReport;
      final session = _TenureDecisionSession(tenure);
      final engine = _engineFor(session);
      final PlayerPresidentManagerControlCareerResult segment;
      if (current == null) {
        segment = engine.simulateWithCheckpoint(
          clubs: clubs,
          leagues: leagues,
          config: config,
          controlledClubId: controlledClubId,
          seasonCount: 1,
          electionInterval: electionInterval,
          hasFutureSeasonAfterReport: hasFuture,
        );
      } else {
        segment = engine.resume(
          checkpoint: current,
          seasonCount: 1,
          hasFutureSeasonAfterReport: hasFuture,
        );
      }
      segments.add(segment);
      current = segment.checkpoint;
      tenure = tenureGate.refresh(
        state: tenure,
        presidentRuntime: _presidentRuntime(current),
      );
    }

    return PlayerPresidentTenureGatedRuntimeResult(
      checkpoint: PlayerPresidentTenureGatedRuntimeCheckpoint(
        control: current!,
        tenureControl: tenure,
      ),
      segments: segments,
    );
  }

  PlayerPresidentTenureGatedRuntimeResult resume({
    required PlayerPresidentTenureGatedRuntimeCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
  }) {
    checkpoint.validate();
    if (seasonCount <= 0) {
      throw ArgumentError.value(seasonCount, 'seasonCount');
    }

    var current = checkpoint.control;
    var tenure = checkpoint.tenureControl;
    final segments = <PlayerPresidentManagerControlCareerResult>[];
    for (var offset = 0; offset < seasonCount; offset++) {
      final hasFuture = offset < seasonCount - 1 || hasFutureSeasonAfterReport;
      final session = _TenureDecisionSession(tenure);
      final segment = _engineFor(session).resume(
        checkpoint: current,
        seasonCount: 1,
        hasFutureSeasonAfterReport: hasFuture,
      );
      segments.add(segment);
      current = segment.checkpoint;
      tenure = tenureGate.refresh(
        state: tenure,
        presidentRuntime: _presidentRuntime(current),
      );
    }

    return PlayerPresidentTenureGatedRuntimeResult(
      checkpoint: PlayerPresidentTenureGatedRuntimeCheckpoint(
        control: current,
        tenureControl: tenure,
      ),
      segments: segments,
    );
  }

  PlayerPresidentManagerControlCareerEngine _engineFor(
    _TenureDecisionSession session,
  ) {
    if (session.state.lost) {
      return PlayerPresidentManagerControlCareerEngine(
        offerEngine: offerEngine,
        aiSponsorPolicy: aiSponsorPolicy,
        aiCrisisEngine: aiCrisisEngine,
        fitModel: fitModel,
        candidateLimit: candidateLimit,
      );
    }
    return PlayerPresidentManagerControlCareerEngine(
      managerProvider: managerProvider == null
          ? null
          : _TenureGatedManagerProvider(
              delegate: managerProvider!,
              session: session,
            ),
      crisisProvider: crisisProvider == null
          ? null
          : _TenureGatedCrisisProvider(
              delegate: crisisProvider!,
              session: session,
            ),
      sponsorProvider: sponsorProvider == null
          ? null
          : _TenureGatedSponsorProvider(
              delegate: sponsorProvider!,
              session: session,
            ),
      facilityProvider: facilityProvider == null
          ? null
          : _TenureGatedFacilityProvider(
              delegate: facilityProvider!,
              session: session,
            ),
      offerEngine: offerEngine,
      aiSponsorPolicy: aiSponsorPolicy,
      aiCrisisEngine: aiCrisisEngine,
      fitModel: fitModel,
      candidateLimit: candidateLimit,
    );
  }

  PresidentRuntimeCheckpoint _presidentRuntime(
    PlayerPresidentManagerControlCheckpoint checkpoint,
  ) =>
      checkpoint.control.control.control.runtime.runtime.domain.presidentRuntime;
}

class _TenureDecisionSession {
  _TenureDecisionSession(this.state) : _blocked = state.lost;

  final PlayerPresidentTenureControlState state;
  bool _blocked;

  bool allows(String presidentId) {
    if (_blocked) return false;
    if (presidentId == state.playerPresidentId) return true;
    _blocked = true;
    return false;
  }
}

class _TenureGatedFacilityProvider
    extends PlayerFacilityInvestmentDecisionProvider {
  const _TenureGatedFacilityProvider({
    required this.delegate,
    required this.session,
  });

  final PlayerFacilityInvestmentDecisionProvider delegate;
  final _TenureDecisionSession session;

  @override
  PlayerFacilityInvestmentChoice choose(PlayerFacilityInvestmentContext context) {
    if (session.allows(context.presidentId)) {
      return delegate.choose(context);
    }
    final academy = const PresidentAcademyInvestmentOrchestrator()
        .planFor(context.managementProfile);
    final portfolio = const PresidentFacilityPortfolioInvestmentOrchestrator()
        .planFor(context.managementProfile);
    return PlayerFacilityInvestmentChoice(
      academyUpgrades: _attempts(
        current: context.academyLevel,
        target: academy.targetLevel,
        maximum: academy.maxUpgradesThisWindow,
      ),
      trainingGroundUpgrades: _attempts(
        current: context.trainingGroundLevel,
        target: portfolio.trainingGroundTargetLevel,
        maximum: portfolio.maxTrainingGroundUpgradesThisWindow,
      ),
      stadiumUpgrades: _attempts(
        current: context.stadiumLevel,
        target: portfolio.stadiumTargetLevel,
        maximum: portfolio.maxStadiumUpgradesThisWindow,
      ),
    );
  }

  int _attempts({
    required int current,
    required int target,
    required int maximum,
  }) {
    final needed = target - current;
    if (needed <= 0 || maximum <= 0) return 0;
    return needed < maximum ? needed : maximum;
  }
}

class _TenureGatedSponsorProvider extends PlayerSponsorDecisionProvider {
  const _TenureGatedSponsorProvider({
    required this.delegate,
    required this.session,
  });

  final PlayerSponsorDecisionProvider delegate;
  final _TenureDecisionSession session;

  @override
  PlayerSponsorOfferChoice choose(PlayerSponsorDecisionContext context) {
    if (session.allows(context.presidentId)) {
      return delegate.choose(context);
    }
    return PlayerSponsorOfferChoice(offerId: context.aiChoice.id);
  }
}

class _TenureGatedCrisisProvider extends PlayerCrisisDecisionProvider {
  const _TenureGatedCrisisProvider({
    required this.delegate,
    required this.session,
  });

  final PlayerCrisisDecisionProvider delegate;
  final _TenureDecisionSession session;

  @override
  PlayerCrisisActionChoice choose(PlayerCrisisDecisionContext context) {
    if (session.allows(context.presidentId)) {
      return delegate.choose(context);
    }
    return PlayerCrisisActionChoice(action: context.aiDecision.action);
  }
}

class _TenureGatedManagerProvider extends PlayerManagerDecisionProvider {
  const _TenureGatedManagerProvider({
    required this.delegate,
    required this.session,
  });

  final PlayerManagerDecisionProvider delegate;
  final _TenureDecisionSession session;

  @override
  PlayerManagerReviewChoice review(PlayerManagerReviewContext context) {
    if (session.allows(context.presidentId)) {
      return delegate.review(context);
    }
    return context.aiWouldReplace
        ? PlayerManagerReviewChoice.replace
        : PlayerManagerReviewChoice.retain;
  }

  @override
  PlayerManagerReplacementChoice chooseReplacement(
    PlayerManagerReplacementContext context,
  ) {
    if (session.allows(context.presidentId)) {
      return delegate.chooseReplacement(context);
    }
    return PlayerManagerReplacementChoice(managerId: context.aiChoice.id);
  }
}
