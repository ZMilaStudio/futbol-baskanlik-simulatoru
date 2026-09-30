import '../core/money.dart';
import '../contract/contract_event.dart';
import 'player_president_accepted_promise_closing_projection.dart';

enum PlayerPresidentB3AFinanceEquivalenceStatus {
  verifiedBasicX1,
  fullM65EquivalenceUnproven,
  sourceMismatch,
  sourceUnavailable,
}

/// Read-only classification of the finance authority already owned by B2.
/// This deliberately never runs an economy engine or replaces B2 records.
class PlayerPresidentB3AFinanceEquivalence {
  const PlayerPresidentB3AFinanceEquivalence();

  PlayerPresidentB3AFinanceEquivalenceResult inspect(
    PlayerPresidentAcceptedPromiseClosingCandidate source,
  ) {
    final state = source.sourceState;
    final boundary = state.boundary;
    final application = boundary.application;
    final opening = boundary.opening;
    final proof = boundary.proof;
    final config = proof.seasonOpening.config;
    final owned = application.isNewGame &&
        identical(application.acceptedPromiseClosingCandidate, source) &&
        identical(application.committedSeasonResultCandidate,
            source.sourceResultCandidate) &&
        identical(application.preseasonWeeklyState, state) &&
        identical(application.preseasonPromiseBoundary, boundary) &&
        identical(application.appliedPreseasonPromises, source.applied) &&
        identical(boundary.applied, source.applied) &&
        identical(source.activePromises, source.applied.activePromises) &&
        source.sourceIdentity == proof.seasonOpening.originSourceDigest &&
        state.completedMatchCount == 720 &&
        state.fixtureSnapshot.isComplete;
    final x1 = proof.initialContracts;
    final players = {for (final player in opening.players) player.id: player};
    final contracts = {
      for (final contract in x1.activeContracts) contract.playerId: contract
    };
    final wages = {
      for (final club in state.effectiveClubs) club.id: Money.zero
    };
    final x1Provenance = owned &&
        config.seasonIndex == 0 &&
        x1.matchesSource(
            careerSeed: config.careerSeed,
            simulationVersion: config.simulationVersion,
            seasonIndex: config.seasonIndex,
            players: opening.players,
            leagues: opening.leagues) &&
        players.length == 864 &&
        contracts.length == 864 &&
        x1.activeContracts.length == 864 &&
        x1.initialEvents.length == 864 &&
        x1.initialEvents.map((event) => event.playerId).toSet().length == 864 &&
        x1.activeContracts.every((contract) =>
            players[contract.playerId]?.clubId == contract.clubId &&
            wages.containsKey(contract.clubId) &&
            contract.isActiveDuring(0) &&
            !contract.annualWage.isNegative) &&
        x1.initialEvents.every((event) =>
            event.type == ContractEventType.initial &&
            event.seasonIndex == 0 &&
            event.toClubId == contracts[event.playerId]?.clubId &&
            event.annualWage == contracts[event.playerId]?.annualWage &&
            event.endSeasonIndex == contracts[event.playerId]?.endSeasonIndex);
    if (x1Provenance) {
      for (final contract in x1.activeContracts) {
        wages[contract.clubId] = wages[contract.clubId]! + contract.annualWage;
      }
    }
    final initial = {
      for (final item in opening.financeStates) item.clubId: item
    };
    final closing = {
      for (final item in source.closingFinanceStates) item.clubId: item
    };
    final uniqueFinance = source.finances.map((item) => item.clubId).toSet();
    final uniqueClosing =
        source.closingFinanceStates.map((item) => item.clubId).toSet();
    final basicX1 = owned &&
        x1Provenance &&
        wages.length == 48 &&
        initial.length == 48 &&
        source.finances.length == 48 &&
        uniqueFinance.length == 48 &&
        source.closingFinanceStates.length == 48 &&
        uniqueClosing.length == 48 &&
        source.finances.every(
          (item) =>
              item.openingCash == initial[item.clubId]?.cash &&
              item.openingDebt == initial[item.clubId]?.debt &&
              item.wageExpense == wages[item.clubId] &&
              item.transferInstallmentIncome == Money.zero &&
              item.transferInstallmentExpense == Money.zero &&
              item.closingCash == closing[item.clubId]?.cash &&
              item.closingDebt == closing[item.clubId]?.debt &&
              item.expectedClosingCash == item.closingCash &&
              item.expectedClosingDebt == item.closingDebt &&
              !item.closingCash.isNegative &&
              !item.closingDebt.isNegative,
        );
    return PlayerPresidentB3AFinanceEquivalenceResult(
      source: source,
      status: basicX1
          ? PlayerPresidentB3AFinanceEquivalenceStatus
              .fullM65EquivalenceUnproven
          : PlayerPresidentB3AFinanceEquivalenceStatus.sourceMismatch,
      basicX1Verified: basicX1,
      sourceOwned: owned,
      x1ProvenanceVerified: x1Provenance,
      annualWagesByClub: x1Provenance ? wages : const {},
      sponsorAuthorityAvailable: false,
      stadiumAttendanceAuthorityAvailable: false,
      ticketPricingAuthorityAvailable: false,
      managerAdjustedClubAuthorityAvailable: false,
    );
  }
}

class PlayerPresidentB3AFinanceEquivalenceResult {
  PlayerPresidentB3AFinanceEquivalenceResult({
    required this.source,
    required this.status,
    required this.basicX1Verified,
    required this.sourceOwned,
    required this.x1ProvenanceVerified,
    required Map<String, Money> annualWagesByClub,
    required this.sponsorAuthorityAvailable,
    required this.stadiumAttendanceAuthorityAvailable,
    required this.ticketPricingAuthorityAvailable,
    required this.managerAdjustedClubAuthorityAvailable,
  }) : annualWagesByClub = Map.unmodifiable(annualWagesByClub);
  final PlayerPresidentAcceptedPromiseClosingCandidate source;
  final PlayerPresidentB3AFinanceEquivalenceStatus status;
  final bool basicX1Verified;
  final bool sourceOwned;
  final bool x1ProvenanceVerified;
  final Map<String, Money> annualWagesByClub;
  final bool sponsorAuthorityAvailable;
  final bool stadiumAttendanceAuthorityAvailable;
  final bool ticketPricingAuthorityAvailable;
  final bool managerAdjustedClubAuthorityAvailable;
  bool get fullM65Equivalent => false;
}
