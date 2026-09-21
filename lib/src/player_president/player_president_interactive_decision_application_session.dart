import '../core/simulation_config.dart';
import '../crisis/crisis_decision_core.dart';
import '../crisis/facility_sponsor_crisis_runtime_composition.dart';
import '../election/player_president_tenure_control_gate.dart';
import '../election/president_tenure.dart';
import '../fan/fan_state.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import '../league/club.dart';
import '../league/fixture_generator.dart';
import '../manager/manager_opening_state_initializer.dart';
import '../player/player.dart';
import '../player/team_strength_calculator.dart';
import '../sponsor/sponsor_system.dart';
import '../world/world_league.dart';
import '../world/world_opening_state_initializer.dart';
import 'player_president_interactive_decision_new_game_bootstrap_snapshot.dart';
import 'player_president_prepared_season_dashboard_snapshot.dart';
import 'player_president_prepared_season_fixtures_snapshot.dart';
import 'player_president_prepared_squad_snapshot.dart';
import 'player_president_interactive_decision_persistence_bundle.dart';
import 'player_president_interactive_decision_session.dart';
import 'player_president_interactive_decision_transcript_snapshot.dart';

enum PlayerPresidentInteractiveDecisionApplicationSessionOrigin {
  newGame,
  checkpoint,
}

/// Application-facing lifecycle owner for one interactive player-president
/// session.
///
/// M76 introduced the checkpoint-backed lifecycle. M79 added deterministic
/// new-game start ownership. M80 adds replay-only pre-checkpoint bootstrap
/// persistence without persisting partial game state: M65 remains the only
/// game-state authority, M74 remains accepted-answer replay metadata, and M75
/// remains the checkpoint-backed atomic persistence bundle.
class PlayerPresidentInteractiveDecisionApplicationSession {
  PlayerPresidentInteractiveDecisionApplicationSession._({
    required this.origin,
    required PlayerPresidentTicketPricingRuntimeCheckpoint? checkpoint,
    required this.resumeConfig,
    required this.newGameElectionInterval,
    required PlayerPresidentPreparedSeasonDashboardSnapshot
        preparedSeasonDashboard,
    required PlayerPresidentPreparedSquadSnapshot preparedSquad,
    required PlayerPresidentPreparedSeasonFixturesSnapshot
        preparedSeasonFixtures,
    required SimulationConfig? newGameConfig,
    required String? newGameControlledClubId,
    required String? newGameWorldFingerprint,
    required PlayerPresidentInteractiveDecisionTranscriptSession session,
    required this.bundleCodec,
    required this.bootstrapCodec,
  })  : _checkpoint = checkpoint,
        _preparedSeasonDashboard = preparedSeasonDashboard,
        _preparedSquad = preparedSquad,
        _preparedSeasonFixtures = preparedSeasonFixtures,
        _newGameConfig = newGameConfig,
        _newGameControlledClubId = newGameControlledClubId,
        _newGameWorldFingerprint = newGameWorldFingerprint,
        _session = session;

  factory PlayerPresidentInteractiveDecisionApplicationSession.start({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    required String controlledClubId,
    int seasonCount = 20,
    int electionInterval = 4,
    bool hasFutureSeasonAfterReport = false,
    int crisisActivationThreshold = 55,
    int candidateLimit = 5,
    PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec bundleCodec =
        const PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec(),
    PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec
        bootstrapCodec =
        const PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec(),
  }) {
    final resumeConfig = PlayerPresidentInteractiveDecisionResumeConfig(
      seasonCount: seasonCount,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
      crisisActivationThreshold: crisisActivationThreshold,
      candidateLimit: candidateLimit,
    );
    resumeConfig.validate();
    if (electionInterval <= 0) {
      throw ArgumentError.value(electionInterval, 'electionInterval');
    }

    final base = PlayerPresidentInteractiveDecisionSession.start(
      clubs: clubs,
      leagues: leagues,
      config: config,
      controlledClubId: controlledClubId,
      seasonCount: seasonCount,
      electionInterval: electionInterval,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
      aiCrisisEngine: CrisisDecisionEngine(
        activationThreshold: crisisActivationThreshold,
      ),
      candidateLimit: candidateLimit,
    );
    final opening = const WorldOpeningStateInitializer().prepare(
      clubs: clubs,
      leagues: leagues,
      config: config,
    );
    final preparedSeasonDashboard = _preparedDashboardForNewGame(
      clubs: clubs,
      leagues: leagues,
      config: config,
      controlledClubId: controlledClubId,
      opening: opening,
    );
    final preparedSquad = _preparedSquadFromPlayers(
      clubs: clubs,
      players: opening.players,
      controlledClubId: controlledClubId,
      seasonIndex: config.seasonIndex,
    );
    final preparedSeasonFixtures = _preparedSeasonFixturesForNewGame(
      opening: opening,
      controlledClubId: controlledClubId,
      seasonIndex: config.seasonIndex,
    );
    return PlayerPresidentInteractiveDecisionApplicationSession._(
      origin: PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame,
      checkpoint: null,
      resumeConfig: resumeConfig,
      newGameElectionInterval: electionInterval,
      preparedSeasonDashboard: preparedSeasonDashboard,
      preparedSquad: preparedSquad,
      preparedSeasonFixtures: preparedSeasonFixtures,
      newGameConfig: config,
      newGameControlledClubId: controlledClubId,
      newGameWorldFingerprint:
          PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshot
              .worldFingerprintFor(clubs: clubs, leagues: leagues),
      session: PlayerPresidentInteractiveDecisionTranscriptSession(base),
      bundleCodec: bundleCodec,
      bootstrapCodec: bootstrapCodec,
    );
  }

  factory PlayerPresidentInteractiveDecisionApplicationSession
      .restoreNewGameBootstrap({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshot
        snapshot,
    PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec bundleCodec =
        const PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec(),
    PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec
        bootstrapCodec =
        const PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec(),
  }) {
    snapshot.validateWorld(clubs: clubs, leagues: leagues);

    final base = PlayerPresidentInteractiveDecisionSession.start(
      clubs: clubs,
      leagues: leagues,
      config: snapshot.config,
      controlledClubId: snapshot.controlledClubId,
      seasonCount: snapshot.resumeConfig.seasonCount,
      electionInterval: snapshot.electionInterval,
      hasFutureSeasonAfterReport:
          snapshot.resumeConfig.hasFutureSeasonAfterReport,
      aiCrisisEngine: CrisisDecisionEngine(
        activationThreshold:
            snapshot.resumeConfig.crisisActivationThreshold,
      ),
      candidateLimit: snapshot.resumeConfig.candidateLimit,
    );
    final opening = const WorldOpeningStateInitializer().prepare(
      clubs: clubs,
      leagues: leagues,
      config: snapshot.config,
    );
    final preparedSeasonDashboard = _preparedDashboardForNewGame(
      clubs: clubs,
      leagues: leagues,
      config: snapshot.config,
      controlledClubId: snapshot.controlledClubId,
      opening: opening,
    );
    final preparedSquad = _preparedSquadFromPlayers(
      clubs: clubs,
      players: opening.players,
      controlledClubId: snapshot.controlledClubId,
      seasonIndex: snapshot.config.seasonIndex,
    );
    final preparedSeasonFixtures = _preparedSeasonFixturesForNewGame(
      opening: opening,
      controlledClubId: snapshot.controlledClubId,
      seasonIndex: snapshot.config.seasonIndex,
    );

    return PlayerPresidentInteractiveDecisionApplicationSession._(
      origin: PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame,
      checkpoint: null,
      resumeConfig: snapshot.resumeConfig,
      newGameElectionInterval: snapshot.electionInterval,
      preparedSeasonDashboard: preparedSeasonDashboard,
      preparedSquad: preparedSquad,
      preparedSeasonFixtures: preparedSeasonFixtures,
      newGameConfig: snapshot.config,
      newGameControlledClubId: snapshot.controlledClubId,
      newGameWorldFingerprint: snapshot.worldFingerprint,
      session: PlayerPresidentInteractiveDecisionTranscriptSession.restore(
        session: base,
        snapshot: snapshot.transcript,
      ),
      bundleCodec: bundleCodec,
      bootstrapCodec: bootstrapCodec,
    );
  }

  factory PlayerPresidentInteractiveDecisionApplicationSession
      .restoreEncodedNewGameBootstrap({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required String encodedBootstrap,
    PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec bundleCodec =
        const PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec(),
    PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec
        bootstrapCodec =
        const PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec(),
  }) =>
          PlayerPresidentInteractiveDecisionApplicationSession
              .restoreNewGameBootstrap(
            clubs: clubs,
            leagues: leagues,
            snapshot: bootstrapCodec.decode(encodedBootstrap),
            bundleCodec: bundleCodec,
            bootstrapCodec: bootstrapCodec,
          );

  factory PlayerPresidentInteractiveDecisionApplicationSession.resume({
    required PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
    required PlayerPresidentInteractiveDecisionResumeConfig resumeConfig,
    PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec bundleCodec =
        const PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec(),
    PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec
        bootstrapCodec =
        const PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec(),
  }) {
    checkpoint.validate();
    resumeConfig.validate();
    final base = PlayerPresidentInteractiveDecisionSession.resume(
      checkpoint: checkpoint,
      seasonCount: resumeConfig.seasonCount,
      hasFutureSeasonAfterReport: resumeConfig.hasFutureSeasonAfterReport,
      aiCrisisEngine: CrisisDecisionEngine(
        activationThreshold: resumeConfig.crisisActivationThreshold,
      ),
      candidateLimit: resumeConfig.candidateLimit,
    );
    final preparedSeasonDashboard =
        _preparedDashboardForCheckpoint(checkpoint);
    final preparedSquad = _preparedSquadForCheckpoint(checkpoint);
    final preparedSeasonFixtures =
        _preparedSeasonFixturesForCheckpoint(checkpoint);
    return PlayerPresidentInteractiveDecisionApplicationSession._(
      origin: PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint,
      checkpoint: checkpoint,
      resumeConfig: resumeConfig,
      newGameElectionInterval: null,
      preparedSeasonDashboard: preparedSeasonDashboard,
      preparedSquad: preparedSquad,
      preparedSeasonFixtures: preparedSeasonFixtures,
      newGameConfig: null,
      newGameControlledClubId: null,
      newGameWorldFingerprint: null,
      session: PlayerPresidentInteractiveDecisionTranscriptSession(base),
      bundleCodec: bundleCodec,
      bootstrapCodec: bootstrapCodec,
    );
  }

  factory PlayerPresidentInteractiveDecisionApplicationSession.restore({
    required PlayerPresidentInteractiveDecisionPersistenceBundle bundle,
    PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec bundleCodec =
        const PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec(),
    PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec
        bootstrapCodec =
        const PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec(),
  }) {
    bundle.validate();
    final preparedSeasonDashboard =
        _preparedDashboardForCheckpoint(bundle.checkpoint);
    final preparedSquad = _preparedSquadForCheckpoint(bundle.checkpoint);
    final preparedSeasonFixtures =
        _preparedSeasonFixturesForCheckpoint(bundle.checkpoint);
    final restoredSession = bundle.restoreSession();
    return PlayerPresidentInteractiveDecisionApplicationSession._(
      origin: PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint,
      checkpoint: bundle.checkpoint,
      resumeConfig: bundle.resumeConfig,
      newGameElectionInterval: null,
      preparedSeasonDashboard: preparedSeasonDashboard,
      preparedSquad: preparedSquad,
      preparedSeasonFixtures: preparedSeasonFixtures,
      newGameConfig: null,
      newGameControlledClubId: null,
      newGameWorldFingerprint: null,
      session: restoredSession,
      bundleCodec: bundleCodec,
      bootstrapCodec: bootstrapCodec,
    );
  }

  factory PlayerPresidentInteractiveDecisionApplicationSession.restoreEncoded({
    required String encodedBundle,
    PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec bundleCodec =
        const PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec(),
    PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec
        bootstrapCodec =
        const PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec(),
  }) {
    final bundle = bundleCodec.decode(encodedBundle);
    return PlayerPresidentInteractiveDecisionApplicationSession.restore(
      bundle: bundle,
      bundleCodec: bundleCodec,
      bootstrapCodec: bootstrapCodec,
    );
  }

  final PlayerPresidentInteractiveDecisionApplicationSessionOrigin origin;
  final PlayerPresidentTicketPricingRuntimeCheckpoint? _checkpoint;
  final PlayerPresidentPreparedSeasonDashboardSnapshot
      _preparedSeasonDashboard;
  final PlayerPresidentPreparedSquadSnapshot _preparedSquad;
  final PlayerPresidentPreparedSeasonFixturesSnapshot _preparedSeasonFixtures;
  final PlayerPresidentInteractiveDecisionResumeConfig resumeConfig;
  final int? newGameElectionInterval;
  final SimulationConfig? _newGameConfig;
  final String? _newGameControlledClubId;
  final String? _newGameWorldFingerprint;
  final PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec
      bundleCodec;
  final PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec
      bootstrapCodec;
  final PlayerPresidentInteractiveDecisionTranscriptSession _session;

  bool get isNewGame =>
      origin == PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame;

  PlayerPresidentPreparedSeasonDashboardSnapshot
      get preparedSeasonDashboard => _preparedSeasonDashboard;

  PlayerPresidentPreparedSquadSnapshot get preparedSquad => _preparedSquad;

  PlayerPresidentPreparedSeasonFixturesSnapshot get preparedSeasonFixtures =>
      _preparedSeasonFixtures;

  bool get canPersist => _checkpoint != null;

  bool get canPersistBootstrap =>
      isNewGame &&
      _newGameConfig != null &&
      _newGameControlledClubId != null &&
      _newGameWorldFingerprint != null;

  PlayerPresidentTicketPricingRuntimeCheckpoint? get checkpointOrNull =>
      _checkpoint;

  PlayerPresidentTicketPricingRuntimeCheckpoint get checkpoint {
    final checkpoint = _checkpoint;
    if (checkpoint == null) {
      throw StateError(
        'New-game application sessions do not have an M65 checkpoint and '
        'cannot be persisted by M75 before checkpoint handoff.',
      );
    }
    return checkpoint;
  }

  int get answeredDecisionCount => _session.answeredDecisionCount;
  PlayerPresidentInteractiveDecisionRequest? get pendingDecision =>
      _session.pendingDecision;
  PlayerPresidentInteractiveSessionCompleted? get completed =>
      _session.completed;

  PlayerPresidentTenureControlState? get completedTenureControl =>
      _session.completed?.result.checkpoint.tenureControl;

  PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshot
      get newGameBootstrapSnapshot {
    final config = _newGameConfig;
    final controlledClubId = _newGameControlledClubId;
    final worldFingerprint = _newGameWorldFingerprint;
    final electionInterval = newGameElectionInterval;
    if (!isNewGame ||
        config == null ||
        controlledClubId == null ||
        worldFingerprint == null ||
        electionInterval == null) {
      throw StateError(
        'Checkpoint-backed application sessions do not have an M80 '
        'new-game bootstrap snapshot.',
      );
    }
    return PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshot(
      worldFingerprint: worldFingerprint,
      config: config,
      controlledClubId: controlledClubId,
      electionInterval: electionInterval,
      resumeConfig: resumeConfig,
      transcript: _session.snapshot,
    );
  }

  String encodeNewGameBootstrapSnapshot() =>
      bootstrapCodec.encode(newGameBootstrapSnapshot);

  PlayerPresidentInteractiveDecisionPersistenceBundle get persistenceBundle {
    final checkpoint = _checkpoint;
    if (checkpoint == null) {
      throw StateError(
        'Pre-checkpoint new-game sessions cannot be encoded as an M75 bundle.',
      );
    }
    return PlayerPresidentInteractiveDecisionPersistenceBundle(
      checkpoint: checkpoint,
      transcript: _session.snapshot,
      resumeConfig: resumeConfig,
    );
  }

  String encodePersistenceBundle() => bundleCodec.encode(persistenceBundle);

  PlayerPresidentInteractiveDecisionApplicationSession
      continuePlayerCareerToNextSeason() {
    final completed = _session.completed;
    if (completed == null) {
      throw StateError(
        'Player career can continue only after the interactive session completes.',
      );
    }
    if (completed.result.checkpoint.tenureControl.lost) {
      throw StateError(
        'Player career cannot continue after presidency control is lost.',
      );
    }
    return PlayerPresidentInteractiveDecisionApplicationSession.resume(
      checkpoint: completed.result.checkpoint,
      resumeConfig: resumeConfig,
      bundleCodec: bundleCodec,
      bootstrapCodec: bootstrapCodec,
    );
  }

  PlayerPresidentInteractiveSessionStep advance() => _session.advance();

  PlayerPresidentInteractiveSessionStep submit({
    required PlayerPresidentInteractiveDecisionRequest request,
    required Object choice,
  }) =>
      submitWithResolution(request: request, choice: choice).nextStep;

  PlayerPresidentInteractiveDecisionSubmissionResult submitWithResolution({
    required PlayerPresidentInteractiveDecisionRequest request,
    required Object choice,
  }) =>
      _session.submitWithResolution(request: request, choice: choice);
}


PlayerPresidentPreparedSeasonDashboardSnapshot _preparedDashboardForNewGame({
  required List<Club> clubs,
  required List<WorldLeague> leagues,
  required SimulationConfig config,
  required String controlledClubId,
  required WorldOpeningState opening,
}) {
  final controlledClub = _singlePreparedWhere(
    clubs,
    (club) => club.id == controlledClubId,
    'controlled club',
  );
  final inputLeague = _singlePreparedWhere(
    leagues,
    (league) => league.clubIds.contains(controlledClubId),
    'controlled-club opening league',
  );
  if (inputLeague.clubIds
          .where((clubId) => clubId == controlledClubId)
          .length !=
      1) {
    throw StateError(
      'Prepared new-game source requires exactly one controlled-club '
      'membership in the opening league.',
    );
  }

  final preparedLeague = _singlePreparedWhere(
    opening.leagues,
    (league) => league.clubIds.contains(controlledClubId),
    'controlled-club prepared league',
  );
  final finance = _singlePreparedWhere(
    opening.financeStates,
    (state) => state.clubId == controlledClubId,
    'controlled-club opening finance',
  );
  final fan = FanState.initial(controlledClubId);

  final president = const PresidentProfileGenerator().generateInitial(
    clubId: controlledClub.id,
    careerSeed: config.careerSeed,
    simulationVersion: config.simulationVersion,
  );
  final tenure = PresidentTenureState.initial(
    clubId: controlledClub.id,
    president: president,
    startedSeasonIndex: config.seasonIndex,
  );
  final playerControl = PlayerPresidentTenureControlState.initial(
    controlledClubId: controlledClub.id,
    playerPresidentId: president.id,
  );

  final squadClubs = const TeamStrengthCalculator().deriveClubs(
    baseClubs: opening.baseClubs,
    players: opening.players,
  );
  final managerOpening = const ManagerOpeningStateInitializer().prepare(
    careerSeed: config.careerSeed,
    simulationVersion: config.simulationVersion,
    initialSeasonIndex: config.seasonIndex,
    clubs: squadClubs,
    players: opening.players,
    leagues: opening.leagues,
    financeStates: opening.financeStates,
  );
  final managerAssignment = _singlePreparedWhere(
    managerOpening.assignments,
    (assignment) => assignment.clubId == controlledClubId,
    'controlled-club opening manager assignment',
  );
  final manager = _singlePreparedWhere(
    managerOpening.managers,
    (item) => item.id == managerAssignment.managerId,
    'controlled-club opening manager',
  );

  final facilities = FacilityPortfolioRuntimeState.forClubs(
    clubs: opening.baseClubs,
  );
  final academy = _singlePreparedWhere(
    facilities.academyFacilities,
    (state) => state.clubId == controlledClubId,
    'controlled-club opening academy',
  );
  final stadium = _singlePreparedWhere(
    facilities.stadiumFacilities,
    (state) => state.clubId == controlledClubId,
    'controlled-club opening stadium',
  );
  final trainingGround = _singlePreparedWhere(
    facilities.trainingGroundFacilities,
    (state) => state.clubId == controlledClubId,
    'controlled-club opening training ground',
  );

  final openingSponsor = SponsorRuntimeCheckpoint.initial(
    seasonIndex: config.seasonIndex,
  );
  final activeSponsor = _activePreparedSponsor(
    openingSponsor.activeContracts,
    controlledClubId: controlledClubId,
    seasonIndex: config.seasonIndex,
  );

  return PlayerPresidentPreparedSeasonDashboardSnapshot(
    controlledClubId: controlledClubId,
    seasonIndex: config.seasonIndex,
    league: preparedLeague,
    finance: finance,
    fanOverallTrust: fan.overallTrust,
    presidentTenure: tenure,
    playerControl: playerControl,
    manager: manager,
    managerAssignment: managerAssignment,
    academyFacility: academy,
    stadiumFacility: stadium,
    trainingGroundFacility: trainingGround,
    activeSponsor: activeSponsor,
  );
}

PlayerPresidentPreparedSeasonDashboardSnapshot _preparedDashboardForCheckpoint(
  PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
) {
  checkpoint.validate();
  final facilityRuntime = checkpoint.runtime;
  final sponsorPresidentRuntime = facilityRuntime.runtime;
  final presidentRuntime = sponsorPresidentRuntime.domain.presidentRuntime;
  final advanced = presidentRuntime.runtime.runtime;
  final world = advanced.world;
  final seasonIndex = checkpoint.nextSeasonIndex;

  if (facilityRuntime.nextSeasonIndex != seasonIndex ||
      sponsorPresidentRuntime.nextSeasonIndex != seasonIndex ||
      sponsorPresidentRuntime.sponsor.nextSeasonIndex != seasonIndex ||
      presidentRuntime.nextSeasonIndex != seasonIndex ||
      advanced.nextSeasonIndex != seasonIndex ||
      world.nextSeasonIndex != seasonIndex) {
    throw StateError(
      'Prepared checkpoint source has inconsistent season cursors.',
    );
  }

  _singlePreparedWhere(
    world.baseClubs,
    (club) => club.id == checkpoint.controlledClubId,
    'controlled checkpoint club',
  );
  final league = _singlePreparedWhere(
    world.nextSeasonLeagues,
    (item) => item.clubIds.contains(checkpoint.controlledClubId),
    'controlled-club prepared checkpoint league',
  );
  if (league.clubIds
          .where((clubId) => clubId == checkpoint.controlledClubId)
          .length !=
      1) {
    throw StateError(
      'Prepared checkpoint league contains duplicate controlled-club '
      'membership.',
    );
  }
  final finance = _singlePreparedWhere(
    world.nextSeasonFinanceStates,
    (state) => state.clubId == checkpoint.controlledClubId,
    'controlled-club prepared checkpoint finance',
  );

  final presidentState = _singlePreparedWhere(
    presidentRuntime.clubs,
    (state) => state.clubId == checkpoint.controlledClubId,
    'controlled-club president runtime state',
  );

  final managerAssignment = _singlePreparedWhere(
    advanced.manager.assignments,
    (assignment) => assignment.clubId == checkpoint.controlledClubId,
    'controlled-club prepared manager assignment',
  );
  final manager = _singlePreparedWhere(
    advanced.manager.managers,
    (item) => item.id == managerAssignment.managerId,
    'controlled-club prepared manager',
  );

  final facilities = facilityRuntime.facilities;
  final academy = _singlePreparedWhere(
    facilities.academyFacilities,
    (state) => state.clubId == checkpoint.controlledClubId,
    'controlled-club prepared academy',
  );
  final stadium = _singlePreparedWhere(
    facilities.stadiumFacilities,
    (state) => state.clubId == checkpoint.controlledClubId,
    'controlled-club prepared stadium',
  );
  final trainingGround = _singlePreparedWhere(
    facilities.trainingGroundFacilities,
    (state) => state.clubId == checkpoint.controlledClubId,
    'controlled-club prepared training ground',
  );

  final activeSponsor = _activePreparedSponsor(
    sponsorPresidentRuntime.sponsor.activeContracts,
    controlledClubId: checkpoint.controlledClubId,
    seasonIndex: seasonIndex,
  );

  return PlayerPresidentPreparedSeasonDashboardSnapshot(
    controlledClubId: checkpoint.controlledClubId,
    seasonIndex: seasonIndex,
    league: league,
    finance: finance,
    fanOverallTrust: presidentState.fanReputation.overallTrust,
    presidentTenure: presidentState.tenure,
    playerControl: checkpoint.tenureControl,
    manager: manager,
    managerAssignment: managerAssignment,
    academyFacility: academy,
    stadiumFacility: stadium,
    trainingGroundFacility: trainingGround,
    activeSponsor: activeSponsor,
  );
}


PlayerPresidentPreparedSquadSnapshot _preparedSquadForCheckpoint(
  PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
) {
  checkpoint.validate();
  final world =
      checkpoint.runtime.runtime.domain.presidentRuntime.runtime.runtime.world;
  if (world.nextSeasonIndex != checkpoint.nextSeasonIndex) {
    throw StateError(
      'Prepared squad checkpoint source has inconsistent season cursors.',
    );
  }
  return _preparedSquadFromPlayers(
    clubs: world.baseClubs,
    players: world.nextSeasonPlayers,
    controlledClubId: checkpoint.controlledClubId,
    seasonIndex: checkpoint.nextSeasonIndex,
  );
}

PlayerPresidentPreparedSquadSnapshot _preparedSquadFromPlayers({
  required Iterable<Club> clubs,
  required Iterable<Player> players,
  required String controlledClubId,
  required int seasonIndex,
}) {
  _singlePreparedWhere(
    clubs,
    (club) => club.id == controlledClubId,
    'prepared squad controlled club',
  );

  final selected = players
      .where((player) => player.clubId == controlledClubId)
      .map(
        (player) => PlayerPresidentPreparedSquadPlayer(
          playerId: player.id,
          name: player.name,
          position: player.position,
          age: player.age,
          ability: player.ability,
          potential: player.potential,
          isAcademyGraduate: player.isAcademyGraduate,
        ),
      )
      .toList(growable: false);

  if (selected.isEmpty) {
    throw StateError(
      'Prepared squad requires at least one controlled-club player.',
    );
  }

  return PlayerPresidentPreparedSquadSnapshot(
    controlledClubId: controlledClubId,
    seasonIndex: seasonIndex,
    players: selected,
  );
}


PlayerPresidentPreparedSeasonFixturesSnapshot
    _preparedSeasonFixturesForNewGame({
  required WorldOpeningState opening,
  required String controlledClubId,
  required int seasonIndex,
}) {
  final league = _singlePreparedWhere(
    opening.leagues,
    (item) => item.clubIds.contains(controlledClubId),
    'controlled-club prepared fixture league',
  );
  return _preparedSeasonFixturesFromLeague(
    baseClubs: opening.baseClubs,
    league: league,
    controlledClubId: controlledClubId,
    seasonIndex: seasonIndex,
  );
}

PlayerPresidentPreparedSeasonFixturesSnapshot
    _preparedSeasonFixturesForCheckpoint(
  PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
) {
  checkpoint.validate();
  final world =
      checkpoint.runtime.runtime.domain.presidentRuntime.runtime.runtime.world;
  if (world.nextSeasonIndex != checkpoint.nextSeasonIndex) {
    throw StateError(
      'Prepared fixture checkpoint source has inconsistent season cursors.',
    );
  }
  final league = _singlePreparedWhere(
    world.nextSeasonLeagues,
    (item) => item.clubIds.contains(checkpoint.controlledClubId),
    'controlled-club prepared fixture checkpoint league',
  );
  return _preparedSeasonFixturesFromLeague(
    baseClubs: world.baseClubs,
    league: league,
    controlledClubId: checkpoint.controlledClubId,
    seasonIndex: checkpoint.nextSeasonIndex,
  );
}

PlayerPresidentPreparedSeasonFixturesSnapshot
    _preparedSeasonFixturesFromLeague({
  required List<Club> baseClubs,
  required WorldLeague league,
  required String controlledClubId,
  required int seasonIndex,
}) {
  if (controlledClubId.isEmpty) {
    throw StateError('Prepared fixtures controlled club cannot be empty.');
  }
  if (seasonIndex < 0) {
    throw StateError('Prepared fixtures season index cannot be negative.');
  }

  final leagueClubIds = <String>{};
  for (final clubId in league.clubIds) {
    if (clubId.isEmpty || !leagueClubIds.add(clubId)) {
      throw StateError('Prepared fixture league club IDs must be unique.');
    }
  }
  if (league.clubIds.where((id) => id == controlledClubId).length != 1) {
    throw StateError(
      'Prepared fixtures require exactly one controlled-club league membership.',
    );
  }

  final clubById = <String, Club>{};
  for (final club in baseClubs) {
    if (club.id.isEmpty || clubById.containsKey(club.id)) {
      throw StateError('Prepared fixture base club IDs must be unique.');
    }
    clubById[club.id] = club;
  }

  final orderedLeagueClubs = <Club>[];
  for (final clubId in league.clubIds) {
    final club = clubById[clubId];
    if (club == null) {
      throw StateError(
        'Prepared fixture league references unknown base club ${clubId}.',
      );
    }
    orderedLeagueClubs.add(club);
  }

  final clubCount = orderedLeagueClubs.length;
  if (clubCount < 2 || clubCount.isOdd) {
    throw StateError(
      'Prepared fixture league requires an even number of at least two clubs.',
    );
  }

  final generated = const FixtureGenerator().generateDoubleRoundRobin(
    clubs: orderedLeagueClubs,
    seasonIndex: seasonIndex,
  );
  final expectedTotal = clubCount * (clubCount - 1);
  final expectedControlled = 2 * (clubCount - 1);
  final expectedHomeAway = clubCount - 1;
  final expectedRoundMax = expectedControlled;

  if (generated.length != expectedTotal) {
    throw StateError(
      'Prepared fixture generator count mismatch: ${generated.length} != '
      '${expectedTotal}.',
    );
  }

  final generatedIds = <String>{};
  final selectedRounds = <int>{};
  final selected = <PlayerPresidentPreparedSeasonFixture>[];
  var homeCount = 0;
  var awayCount = 0;

  for (final fixture in generated) {
    if (fixture.id.isEmpty || !generatedIds.add(fixture.id)) {
      throw StateError('Prepared fixture IDs must be non-empty and unique.');
    }
    if (fixture.seasonIndex != seasonIndex) {
      throw StateError('Prepared fixture season index mismatch.');
    }
    if (fixture.homeClubId == fixture.awayClubId) {
      throw StateError('Prepared fixtures cannot contain self fixtures.');
    }
    if (!leagueClubIds.contains(fixture.homeClubId) ||
        !leagueClubIds.contains(fixture.awayClubId)) {
      throw StateError(
        'Prepared fixture generator produced a club outside the prepared league.',
      );
    }
    if (fixture.round < 1 || fixture.round > expectedRoundMax) {
      throw StateError('Prepared fixture round is outside the season range.');
    }

    final isHome = fixture.homeClubId == controlledClubId;
    final isAway = fixture.awayClubId == controlledClubId;
    if (!isHome && !isAway) continue;
    if (isHome == isAway) {
      throw StateError(
        'Prepared controlled fixture must contain the club exactly once.',
      );
    }

    final opponentClubId =
        isHome ? fixture.awayClubId : fixture.homeClubId;
    if (opponentClubId == controlledClubId ||
        !leagueClubIds.contains(opponentClubId)) {
      throw StateError('Prepared fixture opponent is invalid.');
    }
    if (!selectedRounds.add(fixture.round)) {
      throw StateError('Prepared fixture rounds must be unique per club.');
    }

    if (isHome) {
      homeCount++;
    } else {
      awayCount++;
    }
    selected.add(
      PlayerPresidentPreparedSeasonFixture(
        fixtureId: fixture.id,
        round: fixture.round,
        opponentClubId: opponentClubId,
        isHome: isHome,
      ),
    );
  }

  if (selected.length != expectedControlled ||
      homeCount != expectedHomeAway ||
      awayCount != expectedHomeAway ||
      selectedRounds.length != expectedControlled) {
    throw StateError(
      'Prepared controlled fixture balance/count contract failed.',
    );
  }

  return PlayerPresidentPreparedSeasonFixturesSnapshot(
    controlledClubId: controlledClubId,
    seasonIndex: seasonIndex,
    leagueTier: league.tier,
    fixtures: selected,
  );
}

SponsorContract? _activePreparedSponsor(
  Iterable<SponsorContract> contracts, {
  required String controlledClubId,
  required int seasonIndex,
}) {
  final matches = contracts
      .where(
        (contract) =>
            contract.offer.clubId == controlledClubId &&
            contract.isActiveAt(seasonIndex),
      )
      .toList(growable: false);
  if (matches.length > 1) {
    throw StateError(
      'Prepared dashboard found multiple active sponsor contracts for '
      '$controlledClubId.',
    );
  }
  return matches.isEmpty ? null : matches.single;
}

T _singlePreparedWhere<T>(
  Iterable<T> values,
  bool Function(T item) predicate,
  String label,
) {
  final matches = values.where(predicate).toList(growable: false);
  if (matches.length != 1) {
    throw StateError(
      'Prepared dashboard requires exactly one $label, got '
      '${matches.length}.',
    );
  }
  return matches.single;
}
