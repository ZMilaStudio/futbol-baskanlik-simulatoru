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
  /// Source digests are content identities only; this method is the authority
  /// check and never treats a proof's own values as authentication.
  void verifyNewGame({
    required PlayerPresidentInteractiveDecisionApplicationSession application,
    required List<Club> sourceClubs,
    required List<WorldLeague> sourceLeagues,
    String expectedRulesetId = SeasonOpeningProof.rulesetId,
  }) {
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
        initialContracts.sourceDigest != fresh.initialContracts.sourceDigest ||
        presidentDomainMemory.signature !=
            fresh.presidentDomainMemory.signature) {
      throw StateError(
        'Integrated opening differs from supplied M79 authority.',
      );
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
