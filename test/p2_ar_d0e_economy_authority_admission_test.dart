import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/finance/season_finance_authority_receipt.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:test/test.dart';
import 'p2_ar_d0p_owned_season_preparation_test.dart'
    show D0PSeasonProbe, D0PEconomyProbe, D0PSponsorProbe, D0PTicketProbe;

FullM65RuntimeEconomyContinuationAuthority claimEconomy(
        PreparedTicketRuntimeSeason p) =>
    FullM65RuntimeEconomyContinuationAuthority.claim(p,
        expectedOwner: p.owner,
        expectedRevision: p.revision,
        expectedProvenance: p.provenance,
        expectedExecution: p.executionIdentity);

void main() {
  final world = const FictionalWorldFactory().build();
  const config = SimulationConfig(careerSeed: 42002);
  test('genuine initial mint moves graph without executing any producer', () {
    final events = <String>[];
    final engine = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
        baseWorldEngine: WorldCareerEngine(
            seasonEngine: D0PSeasonProbe(events),
            economyEngine: D0PEconomyProbe(events)),
        sponsorSystem: D0PSponsorProbe(events),
        playerProvider: D0PTicketProbe(events));
    final p = engine.prepareInitial(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: world.clubs.first.id,
        captureManagerAuthority: true);
    expect(p.openingContractCount, 0);
    final authority = claimEconomy(p);
    expect(events, isEmpty);
    expect(authority.contractCount, 0);
    expect(authority.sponsorProcessedClubCount, 0);
    expect(authority.ticketDecisionCount, 0);
    expect(authority.result, isNull);
    expect(authority.state, RuntimeEconomyState.awaitingCommittedSeason);
    expect(identical(authority.opening, p.opening), isTrue);
    expect(identical(authority.managerAuthority, p.managerAuthority), isTrue);
    expect(
        identical(authority.managerAuthority.effectiveClubs,
            p.opening.effectiveClubs),
        isTrue);
    expect(p.state, PreparedExecutionState.moved);
    expect(() => claimEconomy(p), throwsStateError);
    expect(
        () => engine.executePrepared(p,
            expectedOwner: p.owner,
            expectedRevision: p.revision,
            expectedProvenance: p.provenance),
        throwsStateError);
    expect(
        () => p.move(
            expectedOwner: p.owner,
            expectedRevision: p.revision,
            expectedProvenance: p.provenance),
        throwsStateError);
  });
  for (final field in ['owner', 'revision', 'provenance', 'execution']) {
    test('foreign $field rejected before lease consumption', () {
      const engine =
          PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine();
      final p = engine.prepareInitial(
          clubs: world.clubs,
          leagues: world.leagues,
          config: config,
          controlledClubId: world.clubs.first.id,
          captureManagerAuthority: true);
      expect(
          () => FullM65RuntimeEconomyContinuationAuthority.claim(p,
              expectedOwner: field == 'owner' ? Object() : p.owner,
              expectedRevision: field == 'revision' ? Object() : p.revision,
              expectedProvenance:
                  field == 'provenance' ? Object() : p.provenance,
              expectedExecution:
                  field == 'execution' ? Object() : p.executionIdentity),
          throwsStateError);
      expect(p.state, PreparedExecutionState.prepared);
      expect(claimEconomy(p).contractCount, 0);
    });
  }
  test('missing original manager capture rejects without reconstruction', () {
    const engine = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine();
    final p = engine.prepareInitial(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: world.clubs.first.id);
    expect(() => claimEconomy(p), throwsStateError);
    expect(p.state, PreparedExecutionState.prepared);
  });
  test('genuine resume adopts existing lineage without execution', () {
    const engine = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine();
    final first = engine.simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: world.clubs.first.id,
        seasonCount: 1,
        hasFutureSeasonAfterReport: true);
    final p = engine.prepareResume(
        checkpoint: first.checkpoint, captureManagerAuthority: true);
    final count = p.openingContractCount;
    final authority = claimEconomy(p);
    expect(authority.contractCount, count);
    expect(authority.opening.seasonIndex, first.checkpoint.nextSeasonIndex);
    expect(authority.sponsorProcessedClubCount, 0);
    expect(authority.ticketDecisionCount, 0);
    expect(identical(authority.opening, p.opening), isTrue);
  });
  test('already observer-bound graph rejected before ownership move', () {
    final recorder = FullM65SeasonFinancePipeline(
        owner: Object(),
        sourceRevision: Object(),
        provenance: Object(),
        seasonIndex: 0);
    final engine = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
        financeRecording: recorder);
    final p = engine.prepareInitial(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: world.clubs.first.id,
        captureManagerAuthority: true);
    expect(() => claimEconomy(p), throwsStateError);
    expect(p.state, PreparedExecutionState.prepared);
    expect(recorder.receipt, isNull);
  });
}
