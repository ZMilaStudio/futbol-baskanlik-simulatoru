import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:test/test.dart';
import 'p2_ar_d0p_owned_season_preparation_test.dart'
    show D0PSeasonProbe, D0PEconomyProbe, D0PSponsorProbe, D0PTicketProbe;

void main() {
  final world = const FictionalWorldFactory().build();
  const config = SimulationConfig(careerSeed: 42002);
  const codec = AdvancedWorldSaveCodec();
  const engine = AdvancedRuntimeCareerEngine();

  // Recorded from the unchanged c7b6fdb7acfe0b5bfb103c4405c4e852fc7b7a09
  // detached checkout, not from the newly extracted preparation implementation.
  String digest(String value) => sha256.convert(utf8.encode(value)).toString();
  const oldAdvanced = {
    1: 'd258cd6a32cbb36e881af58b88a16572be085f9ac6650e3086a8d80d71317a6d',
    3: 'a0ad6bb826b4e7fbd4d5b9897c5da3c11f3cbee27b1a506b7d4bdad42f28b425',
  };

  for (final count in [1, 3]) {
    test(
        'prepared initial $count seasons matches legacy outputs and checkpoint',
        () {
      final legacy = engine.simulateWithCheckpoint(
          clubs: world.clubs,
          leagues: world.leagues,
          config: config,
          seasonCount: count);
      final p = engine.prepareInitial(
          clubs: world.clubs,
          leagues: world.leagues,
          config: config,
          seasonCount: count);
      final result = engine.executePrepared(p,
          expectedOwner: p.owner,
          expectedRevision: p.revision,
          expectedProvenance: p.provenance);
      expect(result.report.signature, legacy.report.signature);
      expect(codec.encode(result.checkpoint), codec.encode(legacy.checkpoint));
      expect(result.checkpoint.manager.seasons.length, count);
      expect(
          digest(
              '${result.report.signature}\n${codec.encode(result.checkpoint)}'),
          oldAdvanced[count]);
    });
  }

  test('prepared resumed segment matches legacy continuation exactly', () {
    final first = engine.simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        seasonCount: 1);
    final before = codec.encode(first.checkpoint);
    final legacy = engine.resume(checkpoint: first.checkpoint, seasonCount: 2);
    final p =
        engine.prepareResume(checkpoint: first.checkpoint, seasonCount: 2);
    final result = engine.executePrepared(p,
        expectedOwner: p.owner,
        expectedRevision: p.revision,
        expectedProvenance: p.provenance);
    expect(result.report.signature, legacy.report.signature);
    expect(codec.encode(result.checkpoint), codec.encode(legacy.checkpoint));
    expect(codec.encode(first.checkpoint), before);
    expect(
        digest(
            '${result.report.signature}\n${codec.encode(result.checkpoint)}'),
        '1b6e67d453d994206094e7ec1272ac4c22bec9bc93be0157f0912518e744f3d8');
  });

  test(
      'world terminal report and checkpoint continuation policies stay distinct',
      () {
    const e = WorldCareerEngine();
    final terminal = e.simulate(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        seasonCount: 1);
    final owner = Object(), revision = Object(), provenance = Object();
    final p = e.prepareInitial(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        owner: owner,
        revision: revision,
        provenance: provenance,
        advanceAfterFinalSeason: false);
    final r = e.executePrepared(p,
        expectedOwner: owner,
        expectedRevision: revision,
        expectedProvenance: provenance);
    expect(r.report.signature, terminal.signature);
    expect(r.report.seasons.single.transfersAfterSeason, isEmpty);
    final continuing = e.simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        seasonCount: 1);
    expect(continuing.report.signature, isNot(terminal.signature));
    expect(continuing.report.seasons.single.movementsAfterSeason.length, 12);
  });

  test('execution failure poisons the actual lease without retry or move', () {
    final events = <String>[];
    final season = D0PSeasonProbe(events)..fail = true;
    final e = AdvancedRuntimeCareerEngine(
        worldEngine: WorldCareerEngine(seasonEngine: season));
    final p = e.prepareInitial(
        clubs: world.clubs, leagues: world.leagues, config: config);
    expect(events, isEmpty);
    expect(
        () => e.executePrepared(p,
            expectedOwner: p.owner,
            expectedRevision: p.revision,
            expectedProvenance: p.provenance),
        throwsStateError);
    expect(p.state, PreparedExecutionState.failed);
    expect(events, ['league']);
    season.fail = false;
    expect(
        () => e.executePrepared(p,
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
    expect(events, ['league']);
  });

  test(
      'real M65 initial prepare/execute has legacy finance/sponsor/ticket ordering',
      () {
    final events = <String>[];
    final e = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
        sponsorSystem: D0PSponsorProbe(events),
        playerProvider: D0PTicketProbe(events),
        baseWorldEngine: WorldCareerEngine(
            seasonEngine: D0PSeasonProbe(events),
            economyEngine: D0PEconomyProbe(events)));
    final legacy = e.simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: world.clubs.first.id,
        seasonCount: 1);
    final legacyEvents = List<String>.of(events);
    events.clear();
    final p = e.prepareInitial(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: world.clubs.first.id);
    expect(events, isEmpty);
    final result = e.executePrepared(p,
        expectedOwner: p.owner,
        expectedRevision: p.revision,
        expectedProvenance: p.provenance);
    expect(events, legacyEvents);
    final oldWorld = legacy.boundaries.single.source.source.sponsor.report
        .sourceReport.advancedTransferReport.worldReport;
    expect(result.report.signature, oldWorld.signature);
    expect(p.sponsorProcessedClubCount, 48);
    expect(p.ticketDecisionCount,
        legacy.boundaries.single.pricingDecisions.length);
    expect(p.sponsorSeasonRevenue,
        legacy.boundaries.single.source.source.sponsorRevenue);
  });

  test(
      'real resumed M65 graph retains non-default facility/domain/sponsor/tenure lineage',
      () {
    const e = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine();
    final first = e.simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: world.clubs.first.id,
        seasonCount: 1,
        hasFutureSeasonAfterReport: true);
    final before = const PlayerPresidentTicketPricingRuntimeSaveCodec()
        .encode(first.checkpoint);
    expect(digest(before),
        'd4c5b1fc01aa67f03cd7f1e1f5b9672f174fbdaf44b2629506758223b1519c55');
    final legacy = e.resume(checkpoint: first.checkpoint, seasonCount: 1);
    final p = e.prepareResume(
        checkpoint: first.checkpoint, captureManagerAuthority: true);
    expect(p.origin, PreparedRuntimeOrigin.resumed);
    expect(p.facilities, same(first.checkpoint.runtime.facilities));
    expect(p.openingSponsor, same(first.checkpoint.runtime.runtime.sponsor));
    expect(p.tenureControl, same(first.checkpoint.tenureControl));
    for (final s
        in first.checkpoint.runtime.runtime.domain.presidentRuntime.clubs) {
      expect(p.sponsorFanStates[s.clubId], same(s.fanReputation));
      expect(p.pricingFanStates[s.clubId], same(s.fanReputation));
      expect(p.pricingProfiles[s.clubId], same(s.managementProfile));
    }
    expect(p.ticketDecisionCount, 0);
    expect(p.sponsorProcessedClubCount, 0);
    final r = e.executePrepared(p,
        expectedOwner: p.owner,
        expectedRevision: p.revision,
        expectedProvenance: p.provenance);
    final oldWorld = legacy.boundaries.single.source.source.sponsor.report
        .sourceReport.advancedTransferReport.worldReport;
    expect(r.report.signature, oldWorld.signature);
    expect(digest(r.report.signature),
        'd3f67a6e11cb63ec9d057606950e73c0ac51d150a455138a45e75eb87ca3f6a7');
    expect(
        digest(const PlayerPresidentTicketPricingRuntimeSaveCodec()
            .encode(legacy.checkpoint)),
        '2feb6511770c83f7e83e947a2be55505a5a7c7483ca681b94440a40cbe0d409b');
    expect(
        const PlayerPresidentTicketPricingRuntimeSaveCodec()
            .encode(first.checkpoint),
        before);
  });
}
