part of 'player_president_future_season_authority.dart';

/// Consumer only: no offseason, B2 recomputation or application publication.
final class FuturePreseasonBoundary {
  FuturePreseasonBoundary.fromCapability(
      FutureOpeningSourceCapability capability)
      : _source = capability.source,
        _capability = capability;

  /// TEST FIXTURE / NOT AUTHORITATIVE PRODUCER.
  /// Exercises the shared consumer behavior, but cannot mint/impersonate the
  /// sealed production capability or publish a next-season application state.
  FuturePreseasonBoundary.forContractFixture(
      FutureOpeningSourceRequirements source)
      : _source = source,
        _capability = null;

  final FutureOpeningSourceRequirements _source;
  final FutureOpeningSourceCapability? _capability;
  bool _consumed = false;

  FutureSeasonOpeningCandidate prepare({
    required FutureOpeningSourceRequirements expectedSource,
    required Object expectedOwner,
    required Object expectedRevision,
    required int expectedSeason,
  }) {
    final source = _source;
    final receipt = source.contractTransferOpening;
    if (_consumed ||
        !identical(source, expectedSource) ||
        !identical(source.owner, expectedOwner) ||
        !identical(source.sourceRevision, expectedRevision) ||
        source.targetSeason != expectedSeason ||
        expectedSeason <= 0 ||
        (_capability != null && !identical(_capability.source, source)) ||
        !identical(receipt.owner, source.owner) ||
        !identical(receipt.sourceRevision, source.sourceRevision) ||
        !identical(receipt.provenance, source.provenance) ||
        receipt.targetSeason != source.targetSeason) {
      throw StateError(
          'Foreign, stale, duplicate or incomplete future source.');
    }
    final clubIds = source.baseClubs.map((c) => c.id).toSet();
    final players = source.postOffseasonPlayers;
    final playerIds = players.map((p) => p.id).toSet();
    final rosteredIds =
        players.where((p) => !p.isFreeAgent).map((p) => p.id).toSet();
    final contracts = receipt.contracts;
    final loans = {for (final loan in receipt.activeLoans) loan.playerId: loan};
    if (source.baseClubs.length != 48 ||
        clubIds.length != 48 ||
        players.isEmpty ||
        playerIds.length != players.length ||
        players.any((p) => !p.isFreeAgent && !clubIds.contains(p.clubId)) ||
        contracts.length != rosteredIds.length ||
        contracts.map((c) => c.playerId).toSet().length != rosteredIds.length ||
        loans.length != receipt.activeLoans.length ||
        loans.values.any((loan) =>
            !rosteredIds.contains(loan.playerId) ||
            !loan.isActiveDuring(expectedSeason) ||
            !clubIds.contains(loan.parentClubId) ||
            !clubIds.contains(loan.loanClubId)) ||
        contracts.any((c) {
          if (!rosteredIds.contains(c.playerId) ||
              !c.isActiveDuring(expectedSeason) ||
              c.annualWage.isNegative) {
            return true;
          }
          final player = players.singleWhere((p) => p.id == c.playerId);
          final loan = loans[c.playerId];
          return loan == null
              ? player.clubId != c.clubId
              : player.clubId != loan.loanClubId ||
                  c.clubId != loan.parentClubId;
        })) {
      throw StateError(
          'Future opening requires exact player/contract coverage.');
    }
    final squadClubs = const TeamStrengthCalculator().deriveClubs(
      baseClubs: source.baseClubs,
      players: players,
    );
    // Validate world/context shape before doing real manager initialization.
    const PromiseOpeningContextBuilder().build(
      seasonIndex: expectedSeason,
      effectiveClubs: squadClubs,
      leagues: source.nextLeagues,
      openingFinanceStates: source.openingFinance,
    );
    final controller = ManagerCareerController(
      careerSeed: source.config.careerSeed,
      simulationVersion: source.config.simulationVersion,
      initialSeasonIndex: expectedSeason,
    );
    final effective = controller.adjustClubsForSeason(
      seasonIndex: expectedSeason,
      squadClubs: squadClubs,
      players: players,
      leagues: source.nextLeagues,
      financeStates: source.openingFinance,
    );
    final capture = controller.captureSeasonAuthority(
      owner: source.owner,
      sourceRevision: source.sourceRevision,
      seasonIndex: expectedSeason,
      effectiveClubs: effective,
    );
    final contexts = const PromiseOpeningContextBuilder().build(
      seasonIndex: expectedSeason,
      effectiveClubs: capture.effectiveClubs,
      leagues: source.nextLeagues,
      openingFinanceStates: source.openingFinance,
    );
    final w0 = const WeeklyWorldFixtureResultCore().prepare(
      clubs: capture.effectiveClubs,
      leagues: source.nextLeagues,
      config: source.config,
    );
    final candidate = FutureSeasonOpeningCandidate._(
      source: source,
      isAuthoritative: _capability != null,
      managerAuthority: capture,
      w0: w0,
      promiseContexts: contexts,
    );
    // Consume only after all fallible detached preparation succeeded.
    _consumed = true;
    return candidate;
  }
}
