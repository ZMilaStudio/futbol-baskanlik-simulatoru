import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:test/test.dart';
import 'p2_ar_d0e_committed_settlement_test.dart'
    show runD0EContractHarness, contractCases;

void main() {
  test(
      'E settled-only release contract preserves original graph without resettlement',
      () async {
    // TEST FIXTURE / NOT AUTHORITATIVE PRODUCER. This tests only E consumer
    // release guards; the later-origin production proof uses legacy capture.
    final helpers = contractCases.substring(
        0, contractCases.indexOf('void runFixtureTests()'));
    final run = await runD0EContractHarness('$helpers\n$_settledReleaseCases');
    print(run.stdout);
    expect(run.exitCode, 0, reason: '${run.stdout}\n${run.stderr}');
  }, timeout: const Timeout(Duration(minutes: 5)));
  final world = const FictionalWorldFactory().build();
  const config = SimulationConfig(careerSeed: 42002);
  String hash(String value) => sha256.convert(utf8.encode(value)).toString();
  for (final count in [1, 3]) {
    test('unchanged advanced $count-season exact-base oracle', () {
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
  test('M65 null-provider/initial/resume signatures retain frozen oracle', () {
    const engine = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine();
    const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();
    final initial = engine.simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: world.clubs.first.id,
        seasonCount: 1,
        hasFutureSeasonAfterReport: true);
    final before = codec.encode(initial.checkpoint);
    expect(hash(before),
        'd4c5b1fc01aa67f03cd7f1e1f5b9672f174fbdaf44b2629506758223b1519c55');
    expect(
        initial.boundaries.single.pricingDecisions
            .every((d) => !d.providerCalled),
        isTrue);
    final resumed =
        engine.resume(checkpoint: initial.checkpoint, seasonCount: 1);
    expect(hash(codec.encode(resumed.checkpoint)),
        '2feb6511770c83f7e83e947a2be55505a5a7c7483ca681b94440a40cbe0d409b');
    expect(codec.encode(initial.checkpoint), before);
  });
}

const _settledReleaseCases = r'''
void runFixtureTests() {
  test('settled receipt/result/execution guards and once-only original graph release', () {
    final probe = _FinanceProbe();
    final a = _open(economy: probe);
    final cap = _Fixture(a, _reports(a));
    a.prepareSettlement(cap);
    a.submitTicket(a.pending!,
        const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.balanced),
        expectedRevision: a.revision);
    final result = a.executeSettlement(expectedCommitted: cap);
    final rows = List.of(probe.rows);
    final foreign = FullM65CommittedSeasonSettlementResult._(
        cap, result.receipt, result.executionIdentity);
    expect(() => SinglePassPostseasonRuntimeTransition.fromSettledEconomy(
        authority: a, expectedResult: foreign, expectedOwner: a.owner,
        expectedRevision: a.revision, expectedProvenance: a.provenance,
        expectedExecution: a.executionIdentity, hasNextSeason: true), throwsStateError);
    expect(a._releaseAttempted, isFalse);
    final transition = SinglePassPostseasonRuntimeTransition.fromSettledEconomy(
        authority: a, expectedResult: result, expectedOwner: a.owner,
        expectedRevision: a.revision, expectedProvenance: a.provenance,
        expectedExecution: a.executionIdentity, hasNextSeason: true);
    expect(a._released, isTrue);
    final pending = transition.prepareTransfer();
    expect(pending, isNotNull);
    expect(transition.prepareTransfer(), same(pending));
    expect(probe.rows.length, 48);
    for (var i = 0; i < rows.length; i++) expect(probe.rows[i], same(rows[i]));
    expect(a.result, same(result));
    expect(() => a.executeSettlement(expectedCommitted: cap), throwsStateError);
    expect(() => SinglePassPostseasonRuntimeTransition.fromSettledEconomy(
        authority: a, expectedResult: result, expectedOwner: a.owner,
        expectedRevision: a.revision, expectedProvenance: a.provenance,
        expectedExecution: a.executionIdentity, hasNextSeason: true), throwsStateError);
  });
}
''';
