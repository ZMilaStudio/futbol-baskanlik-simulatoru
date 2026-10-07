import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:test/test.dart';

String digest(String value) => sha256.convert(utf8.encode(value)).toString();

void main() {
  final world = const FictionalWorldFactory().build();
  const config = SimulationConfig(careerSeed: 42002);
  const engine = AdvancedRuntimeCareerEngine();
  const codec = AdvancedWorldSaveCodec();
  // Frozen pre-D0-T oracles already established by genuine B3-B1/D0-P paths.
  const oracles = {
    1: 'd258cd6a32cbb36e881af58b88a16572be085f9ac6650e3086a8d80d71317a6d',
    3: 'a0ad6bb826b4e7fbd4d5b9897c5da3c11f3cbee27b1a506b7d4bdad42f28b425',
  };
  for (final count in [1, 3]) {
    test('initial/move/execute $count seasons retains frozen advanced oracle',
        () {
      final source = engine.prepareInitial(
          clubs: world.clubs,
          leagues: world.leagues,
          config: config,
          seasonCount: count);
      final moved = source.move(
          expectedOwner: source.owner,
          expectedRevision: source.revision,
          expectedProvenance: source.provenance);
      expect(source.state, PreparedExecutionState.moved);
      expect(
          () => engine.executePrepared(source,
              expectedOwner: source.owner,
              expectedRevision: source.revision,
              expectedProvenance: source.provenance),
          throwsStateError);
      final result = engine.executePrepared(moved,
          expectedOwner: moved.owner,
          expectedRevision: moved.revision,
          expectedProvenance: moved.provenance);
      expect(
          digest(
              '${result.report.signature}\n${codec.encode(result.checkpoint)}'),
          oracles[count]);
      expect(moved.state, PreparedExecutionState.completed);
    });
  }
  test('prepared resume retains frozen checkpoint and original source', () {
    final initial = engine.simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        seasonCount: 1);
    final before = codec.encode(initial.checkpoint);
    final prepared =
        engine.prepareResume(checkpoint: initial.checkpoint, seasonCount: 2);
    final result = engine.executePrepared(prepared,
        expectedOwner: prepared.owner,
        expectedRevision: prepared.revision,
        expectedProvenance: prepared.provenance);
    expect(
        digest(
            '${result.report.signature}\n${codec.encode(result.checkpoint)}'),
        '1b6e67d453d994206094e7ec1272ac4c22bec9bc93be0157f0912518e744f3d8');
    expect(codec.encode(initial.checkpoint), before);
  });
  test('legacy M65 null-provider initial/resume frozen outputs unchanged', () {
    const ticket = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine();
    const save = PlayerPresidentTicketPricingRuntimeSaveCodec();
    final initial = ticket.simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: world.clubs.first.id,
        seasonCount: 1,
        hasFutureSeasonAfterReport: true);
    final before = save.encode(initial.checkpoint);
    expect(digest(before),
        'd4c5b1fc01aa67f03cd7f1e1f5b9672f174fbdaf44b2629506758223b1519c55');
    expect(
        initial.boundaries.single.pricingDecisions
            .every((d) => !d.providerCalled),
        isTrue);
    final resumed =
        ticket.resume(checkpoint: initial.checkpoint, seasonCount: 1);
    expect(digest(save.encode(resumed.checkpoint)),
        '2feb6511770c83f7e83e947a2be55505a5a7c7483ca681b94440a40cbe0d409b');
    expect(save.encode(initial.checkpoint), before);
  });
}
