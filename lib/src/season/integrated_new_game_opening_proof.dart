import '../contract/player_contract.dart';
import '../contract/player_contract_controller.dart';
import '../election/president_domain_memory_opening_initializer.dart';
import '../election/president_opening_state_initializer.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../player_president/player_president_interactive_decision_application_session.dart';
import '../world/world_league.dart';
import '../world/world_opening_state_initializer.dart';
import 'season_opening_proof.dart';

/// Read-only composition proof for the four existing pristine new-game
/// contracts: P1, X1, X2-A and X2-B.
///
/// This is deliberately neither a career-state owner nor a save/checkpoint
/// schema. It joins observations made from one independently supplied M79/M80
/// source and fails before publishing a partial proof.
class IntegratedNewGameOpeningProof {
  IntegratedNewGameOpeningProof._({
    required this.seasonOpening,
    required this.initialContracts,
    required this.presidentOpening,
    required this.presidentDomainMemory,
  });

  final SeasonOpeningProof seasonOpening;
  final InitialContractOpeningState initialContracts;
  final PresidentOpeningWorldState presidentOpening;
  final PresidentOpeningDomainMemoryState presidentDomainMemory;

  int get seasonIndex => seasonOpening.seasonIndex;
  String get controlledClubId => seasonOpening.controlledClubId;

  factory IntegratedNewGameOpeningProof.fromNewGame({
    required PlayerPresidentInteractiveDecisionApplicationSession application,
    required List<Club> sourceClubs,
    required List<WorldLeague> sourceLeagues,
    required int expectedSeasonIndex,
    required String expectedControlledClubId,
    int rawHistorySeasons = 2,
    String expectedRulesetId = SeasonOpeningProof.rulesetId,
  }) {
    final p1 = SeasonOpeningProof.fromNewGame(
      application: application,
      sourceClubs: sourceClubs,
      sourceLeagues: sourceLeagues,
      expectedSeasonIndex: expectedSeasonIndex,
      expectedControlledClubId: expectedControlledClubId,
      expectedRulesetId: expectedRulesetId,
    );
    final bootstrap = application.newGameBootstrapSnapshot;
    final opening = const WorldOpeningStateInitializer().prepare(
      clubs: sourceClubs,
      leagues: sourceLeagues,
      config: bootstrap.config,
    );
    p1.assertOpeningProjectionMatches(opening);

    final x1 = const InitialContractOpeningGenerator().generate(
      careerSeed: p1.config.careerSeed,
      simulationVersion: p1.config.simulationVersion,
      seasonIndex: p1.seasonIndex,
      players: opening.players,
      leagues: opening.leagues,
    );
    if (!x1.matchesSource(
      careerSeed: p1.config.careerSeed,
      simulationVersion: p1.config.simulationVersion,
      seasonIndex: p1.seasonIndex,
      players: opening.players,
      leagues: opening.leagues,
    )) {
      throw StateError('X1 contract opening does not match P1 world source.');
    }

    final x2a = const PresidentOpeningStateInitializer().prepareWorld(
      clubs: opening.baseClubs,
      leagues: opening.leagues,
      config: p1.config,
      controlledClubId: p1.controlledClubId,
      electionInterval: bootstrap.electionInterval,
    );
    final x2b = const PresidentDomainMemoryOpeningInitializer().prepare(
      opening: x2a,
      rawHistorySeasons: rawHistorySeasons,
    );
    _validate(
      proof: p1,
      application: application,
      opening: opening,
      contracts: x1,
      presidents: x2a,
      memory: x2b,
    );
    return IntegratedNewGameOpeningProof._(
      seasonOpening: p1,
      initialContracts: x1,
      presidentOpening: x2a,
      presidentDomainMemory: x2b,
    );
  }

  /// Rebuilds every observation from a separately supplied M79/M80 source.
  /// P1 validates its complete private canonical identity and M1 fixture plan
  /// against that independent source; selected exposed digests are NOT enough.
  /// Content digests are not authentication, monotonic revisions or CAS keys.
  void verifyNewGame({
    required PlayerPresidentInteractiveDecisionApplicationSession application,
    required List<Club> sourceClubs,
    required List<WorldLeague> sourceLeagues,
    String expectedRulesetId = SeasonOpeningProof.rulesetId,
  }) {
    // Keep the existing P1 authority gate, including its private canonical
    // identity and ordered fixture-plan comparison, rather than reducing it
    // to selected visible digest fields.
    seasonOpening.verifyNewGame(
      application: application,
      sourceClubs: sourceClubs,
      sourceLeagues: sourceLeagues,
      expectedRulesetId: expectedRulesetId,
    );
    final fresh = IntegratedNewGameOpeningProof.fromNewGame(
      application: application,
      sourceClubs: sourceClubs,
      sourceLeagues: sourceLeagues,
      expectedSeasonIndex: seasonIndex,
      expectedControlledClubId: controlledClubId,
      rawHistorySeasons: presidentDomainMemory.rawHistorySeasons,
      expectedRulesetId: expectedRulesetId,
    );
    if (seasonOpening.originSourceDigest !=
            fresh.seasonOpening.originSourceDigest ||
        seasonOpening.openingCareerStateDigest !=
            fresh.seasonOpening.openingCareerStateDigest ||
        presidentDomainMemory.signature !=
            fresh.presidentDomainMemory.signature) {
      throw StateError(
        'Integrated opening differs from supplied M79 authority.',
      );
    }

    // X1 source identity alone does not verify the generated contracts or
    // events. Compare independently regenerated ordered outputs as well as
    // source metadata and per-player contract/event coverage.
    final x1 = initialContracts;
    final independentX1 = fresh.initialContracts;
    if (x1.careerSeed != independentX1.careerSeed ||
        x1.simulationVersion != independentX1.simulationVersion ||
        x1.seasonIndex != independentX1.seasonIndex ||
        x1.sourceDigest != independentX1.sourceDigest ||
        x1.sourcePlayerCount != independentX1.sourcePlayerCount ||
        x1.sourceLeagueCount != independentX1.sourceLeagueCount ||
        x1.activeContracts.length != independentX1.activeContracts.length ||
        x1.initialEvents.length != independentX1.initialEvents.length) {
      throw StateError('X1 opening source or output count mismatch.');
    }
    for (var i = 0; i < x1.activeContracts.length; i++) {
      final original = x1.activeContracts[i];
      final independent = independentX1.activeContracts[i];
      if (original.playerId != independent.playerId ||
          original.signature != independent.signature) {
        throw StateError('X1 ordered initial contract mismatch at $i.');
      }
    }
    for (var i = 0; i < x1.initialEvents.length; i++) {
      final original = x1.initialEvents[i];
      final independent = independentX1.initialEvents[i];
      if (original.playerId != independent.playerId ||
          original.signature != independent.signature) {
        throw StateError('X1 ordered initial event mismatch at $i.');
      }
    }
  }

  static void _validate({
    required SeasonOpeningProof proof,
    required PlayerPresidentInteractiveDecisionApplicationSession application,
    required WorldOpeningState opening,
    required InitialContractOpeningState contracts,
    required PresidentOpeningWorldState presidents,
    required PresidentOpeningDomainMemoryState memory,
  }) {
    final bootstrap = application.newGameBootstrapSnapshot;
    if (!application.isNewGame ||
        application.answeredDecisionCount != 0 ||
        application.completed != null ||
        application.checkpointOrNull != null ||
        bootstrap.config.careerSeed != proof.config.careerSeed ||
        bootstrap.config.simulationVersion != proof.config.simulationVersion ||
        bootstrap.config.seasonIndex != 0 ||
        proof.seasonIndex != 0 ||
        bootstrap.controlledClubId != proof.controlledClubId ||
        bootstrap.electionInterval != presidents.electionInterval) {
      throw StateError('Integrated proof requires one pristine M79 source.');
    }
    if (opening.baseClubs.length != 48 ||
        opening.leagues.length != 3 ||
        opening.leagues.any((league) => league.clubIds.length != 16) ||
        opening.players.length != 864 ||
        opening.financeStates.length != 48 ||
        proof.fixtureSnapshot.fixtures.length != 720 ||
        proof.fixtureSnapshot.completedMatchCount != 0 ||
        proof.fixtureSnapshot.nextRound != 1 ||
        proof.fixtureSnapshot.fixtures.any((fixture) => fixture.isPlayed)) {
      throw StateError(
        'Integrated proof does not describe the canonical opening.',
      );
    }
    _validateContracts(contracts, opening.players);
    if (presidents.clubs.length != 48 ||
        presidents.controlledClubId != proof.controlledClubId ||
        presidents.controlledPresidentId == null ||
        presidents.firstElectionSeasonIndex != bootstrap.electionInterval - 1 ||
        !identical(memory.opening, presidents) ||
        memory.completedSeasons != 0 ||
        memory.completedElectionTerms != 0 ||
        memory.seasonsIntoCurrentTerm != 0 ||
        memory.recentFan.isNotEmpty ||
        memory.recentMedia.isNotEmpty ||
        memory.resolvedCurrentTermPromises.isNotEmpty ||
        memory.summary.totalPromises != 0) {
      throw StateError(
        'Integrated president opening provenance is inconsistent.',
      );
    }
  }

  static void _validateContracts(
    InitialContractOpeningState contracts,
    List<Player> players,
  ) {
    final playerIds = players.map((player) => player.id).toSet();
    final contractIds = contracts.activeContracts
        .map((PlayerContract contract) => contract.playerId)
        .toSet();
    final eventIds = contracts.initialEvents
        .map((event) => event.playerId)
        .toSet();
    if (contracts.activeContracts.length != players.length ||
        contracts.initialEvents.length != players.length ||
        contractIds.length != players.length ||
        eventIds.length != players.length ||
        !contractIds.containsAll(playerIds) ||
        !eventIds.containsAll(playerIds)) {
      throw StateError('X1 contract identity does not cover the P1 roster.');
    }
  }
}
