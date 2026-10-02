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
  String hash(String text) => sha256.convert(utf8.encode(text)).toString();
  // Exact-base unchanged oracles inherited from the D0P parity evidence.
  for (final count in [1, 3]) {
    test('advanced $count-season initial output/checkpoint exact-base oracle',
        () {
      final result = const AdvancedRuntimeCareerEngine().simulateWithCheckpoint(
          clubs: world.clubs,
          leagues: world.leagues,
          config: config,
          seasonCount: count);
      expect(
          hash(
              '${result.report.signature}\n${const AdvancedWorldSaveCodec().encode(result.checkpoint)}'),
          count == 1
              ? 'd258cd6a32cbb36e881af58b88a16572be085f9ac6650e3086a8d80d71317a6d'
              : 'a0ad6bb826b4e7fbd4d5b9897c5da3c11f3cbee27b1a506b7d4bdad42f28b425');
    });
  }
  test('legacy M65 initial/null-provider and resume checkpoint oracles', () {
    const engine = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine();
    final initial = engine.simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: world.clubs.first.id,
        seasonCount: 1,
        hasFutureSeasonAfterReport: true);
    const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();
    expect(hash(codec.encode(initial.checkpoint)),
        'd4c5b1fc01aa67f03cd7f1e1f5b9672f174fbdaf44b2629506758223b1519c55');
    expect(
        initial.boundaries.single.pricingDecisions
            .every((d) => !d.providerCalled),
        isTrue);
    final before = codec.encode(initial.checkpoint);
    final resumed =
        engine.resume(checkpoint: initial.checkpoint, seasonCount: 1);
    expect(hash(codec.encode(resumed.checkpoint)),
        '2feb6511770c83f7e83e947a2be55505a5a7c7483ca681b94440a40cbe0d409b');
    expect(codec.encode(initial.checkpoint), before);
  });
  test(
      'real prepared wrapper preserves league/sponsor/ticket/finance callback order',
      () {
    final events = <String>[];
    final engine = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
        sponsorSystem: D0PSponsorProbe(events),
        playerProvider: D0PTicketProbe(events),
        baseWorldEngine: WorldCareerEngine(
            seasonEngine: D0PSeasonProbe(events),
            economyEngine: D0PEconomyProbe(events)));
    engine.simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: world.clubs.first.id,
        seasonCount: 1);
    final expected = List.of(events);
    events.clear();
    final prepared = engine.prepareInitial(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: world.clubs.first.id);
    expect(events, isEmpty);
    engine.executePrepared(prepared,
        expectedOwner: prepared.owner,
        expectedRevision: prepared.revision,
        expectedProvenance: prepared.provenance);
    expect(events, expected);
    expect(prepared.ticketDecisionCount, 48);
    expect(prepared.sponsorProcessedClubCount, 48);
  });
}
