import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:test/test.dart';
import 'p2_b3b1_first_future_bootstrap_test.dart' show B3B1ApplicationFixture;

void main() {
  test(
      'M65 initial/resume/null-provider frozen oracle unchanged without reservation',
      () {
    final world = const FictionalWorldFactory().build();
    const engine = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine();
    const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();
    final initial = engine.simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: const SimulationConfig(careerSeed: 42002),
        controlledClubId: world.clubs.first.id,
        seasonCount: 1,
        hasFutureSeasonAfterReport: true);
    String digest(String value) =>
        sha256.convert(utf8.encode(value)).toString();
    final before = codec.encode(initial.checkpoint);
    expect(digest(before),
        'd4c5b1fc01aa67f03cd7f1e1f5b9672f174fbdaf44b2629506758223b1519c55');
    final resumed =
        engine.resume(checkpoint: initial.checkpoint, seasonCount: 1);
    expect(digest(codec.encode(resumed.checkpoint)),
        '2feb6511770c83f7e83e947a2be55505a5a7c7483ca681b94440a40cbe0d409b');
    expect(codec.encode(initial.checkpoint), before);
  });
  test('season-0 M79 promise/weekly/B1/B2 pointers remain isolated', () {
    final fixture = B3B1ApplicationFixture();
    final signatures = fixture.signatures;
    expect(fixture.application.activeFutureSeasonOpening, isNull);
    expect(fixture.application.futureRuntimeAdmission, isNull);
    expect(fixture.source.sourceState.completedMatchCount, 720);
    expect(fixture.application.acceptedPromiseClosingCandidate,
        same(fixture.source));
    expect(fixture.signatures, signatures);
  });
}
