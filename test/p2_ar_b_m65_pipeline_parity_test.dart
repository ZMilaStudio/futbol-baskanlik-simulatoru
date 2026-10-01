import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/src/finance/season_finance_authority_receipt.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_b3a_finance_equivalence.dart';
import 'package:test/test.dart';
import 'p2_ar_b_finance_receipt_test.dart'
    show ObservedEconomy, ReceiptProvider;
import 'p2_b3a_finance_equivalence_test.dart' show B3AFixture;

void main() {
  test(
      'AR-B selected-season recording preserves multi-season and 2+2 legacy execution',
      () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 20261001);
    const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();
    final baseline =
        const PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine()
            .simulateWithCheckpoint(
                clubs: world.clubs,
                leagues: world.leagues,
                config: config,
                controlledClubId: world.clubs.first.id,
                seasonCount: 4);
    final observer = FullM65SeasonFinancePipeline(
        owner: Object(),
        sourceRevision: Object(),
        provenance: Object(),
        seasonIndex: 1);
    final first = observer.record(() =>
        PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
                financeRecording: observer)
            .simulateWithCheckpoint(
                clubs: world.clubs,
                leagues: world.leagues,
                config: config,
                controlledClubId: world.clubs.first.id,
                seasonCount: 2,
                hasFutureSeasonAfterReport: true));
    expect(codec.encode(first.checkpoint),
        codec.encode(baseline.boundaries[1].checkpoint));
    expect(observer.receipt!.seasonIndex, 1);
    for (final row in observer.receipt!.results) {
      expect(
          identical(row, first.boundaries[1].financeFor(row.clubId)), isTrue);
    }
    final resumedObserver = FullM65SeasonFinancePipeline(
        owner: Object(),
        sourceRevision: Object(),
        provenance: first.checkpoint,
        seasonIndex: 2);
    final resumed = resumedObserver.record(() =>
        PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
                financeRecording: resumedObserver)
            .resume(
                checkpoint: codec.decode(codec.encode(first.checkpoint)),
                seasonCount: 2));
    expect(codec.encode(resumed.checkpoint), codec.encode(baseline.checkpoint));
    for (final row in resumedObserver.receipt!.results) {
      expect(identical(row, resumed.boundaries.first.financeFor(row.clubId)),
          isTrue);
    }
  });
  test('AR-B default recorded M65 matches unmodified exact-base oracle bytes',
      () {
    // Captured by running the unmodified 41b0833 source in a detached checkout.
    // Covers two checkpoints, resume, all finance rows and pricing outcomes.
    final world = const FictionalWorldFactory().build();
    const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();
    final recorder = FullM65SeasonFinancePipeline(
        owner: Object(),
        sourceRevision: Object(),
        provenance: Object(),
        seasonIndex: 0);
    final first = recorder.record(() =>
        PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
                financeRecording: recorder)
            .simulateWithCheckpoint(
                clubs: world.clubs,
                leagues: world.leagues,
                config: const SimulationConfig(careerSeed: 20261001),
                controlledClubId: world.clubs.first.id,
                seasonCount: 1,
                hasFutureSeasonAfterReport: true));
    final secondRecorder = FullM65SeasonFinancePipeline(
        owner: Object(),
        sourceRevision: Object(),
        provenance: first.checkpoint,
        seasonIndex: 1);
    final second = secondRecorder.record(() =>
        PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
                financeRecording: secondRecorder)
            .resume(
                checkpoint: codec.decode(codec.encode(first.checkpoint)),
                seasonCount: 1));
    final payload = jsonEncode({
      'initial': codec.encode(first.checkpoint),
      'resumed': codec.encode(second.checkpoint),
      'initialSignature': first.checkpoint.signature,
      'resumeSignature': second.checkpoint.signature,
      'firstFinance': world.clubs
          .map((c) => first.boundaries.single.financeFor(c.id).signature)
          .toList(),
      'secondFinance': world.clubs
          .map((c) => second.boundaries.single.financeFor(c.id).signature)
          .toList(),
      'firstPricing': first.boundaries.single.pricingDecisions
          .map((d) => d.signature)
          .toList(),
      'secondPricing': second.boundaries.single.pricingDecisions
          .map((d) => d.signature)
          .toList(),
    });
    expect(sha256.convert(utf8.encode(payload)).toString(),
        'b43247f773184280c10a1d538978328392650569e352f1a89de1d0fd60441c7c');
    expect(recorder.receipt!.effectiveClubSource, isNull);
    expect(secondRecorder.receipt!.effectiveClubSource, isNull);
  });
  test(
      'AR-B real M65 recording OFF/ON and resume preserve checkpoint bytes and callback order',
      () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 20261001);
    final offProvider = ReceiptProvider();
    final offEconomy = ObservedEconomy(provider: offProvider);
    final offEngine =
        PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
            playerProvider: offProvider,
            baseWorldEngine: WorldCareerEngine(economyEngine: offEconomy));
    final off = offEngine.simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: world.clubs.first.id,
        seasonCount: 1,
        hasFutureSeasonAfterReport: true);
    final observer = FullM65SeasonFinancePipeline(
        owner: Object(),
        sourceRevision: Object(),
        provenance: Object(),
        seasonIndex: 0);
    final onProvider = ReceiptProvider(observer: observer);
    final onEconomy = ObservedEconomy(provider: onProvider);
    final onEngine = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
        financeRecording: observer,
        playerProvider: onProvider,
        baseWorldEngine: WorldCareerEngine(economyEngine: onEconomy));
    final on = observer.record(() => onEngine.simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: world.clubs.first.id,
        seasonCount: 1,
        hasFutureSeasonAfterReport: true));
    const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();
    expect(codec.encode(on.checkpoint), codec.encode(off.checkpoint));
    expect(on.checkpoint.signature, off.checkpoint.signature);
    expect(onProvider.events, offProvider.events);
    expect(
        on.boundaries.single.pricingDecisions.map((d) => d.signature).toList(),
        off.boundaries.single.pricingDecisions
            .map((d) => d.signature)
            .toList());
    for (var i = 0; i < 3; i++) {
      expect(onEconomy.calls[i].sponsor, offEconomy.calls[i].sponsor);
      expect(onEconomy.calls[i].multipliers, offEconomy.calls[i].multipliers);
      expect(onEconomy.calls[i].wages, offEconomy.calls[i].wages);
      expect(onEconomy.calls[i].income, offEconomy.calls[i].income);
      expect(onEconomy.calls[i].expense, offEconomy.calls[i].expense);
    }
    for (final club in world.clubs) {
      expect(on.boundaries.single.financeFor(club.id).signature,
          off.boundaries.single.financeFor(club.id).signature);
    }
    final resumeObserver = FullM65SeasonFinancePipeline(
        owner: Object(),
        sourceRevision: Object(),
        provenance: on.checkpoint,
        seasonIndex: 1);
    final resumed = resumeObserver.record(() =>
        PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
                financeRecording: resumeObserver,
                playerProvider: ReceiptProvider())
            .resume(
                checkpoint: codec.decode(codec.encode(on.checkpoint)),
                seasonCount: 1));
    final resumedOff =
        PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
                playerProvider: ReceiptProvider())
            .resume(checkpoint: off.checkpoint, seasonCount: 1);
    expect(
        codec.encode(resumed.checkpoint), codec.encode(resumedOff.checkpoint));
    expect(resumeObserver.receipt!.results.length, 48);
    expect(resumeObserver.receipt!.seasonIndex, 1);
  });

  test('AR-B legacy M65 never recomputes or relabels current B2/B3-A', () {
    final fixture = B3AFixture();
    final b2 = fixture.b2;
    final sourceBefore = fixture.signatures;
    final financeReferences = List<ClubFinanceSeason>.of(b2.finances);
    final closingReferences =
        List<ClubFinanceState>.of(b2.closingFinanceStates);
    final matches = fixture.w30.fixtureSnapshot.fixtures.toList();
    final before = b2.finances.map((r) => r.signature).toList();
    final world = const FictionalWorldFactory().build();
    final observer = FullM65SeasonFinancePipeline(
        owner: Object(),
        sourceRevision: Object(),
        provenance: Object(),
        seasonIndex: 0);
    observer.record(() =>
        PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
                financeRecording: observer)
            .simulateWithCheckpoint(
                clubs: world.clubs,
                leagues: world.leagues,
                config: const SimulationConfig(careerSeed: 20261001),
                controlledClubId: world.clubs.first.id,
                seasonCount: 1));
    expect(identical(fixture.b2, b2), isTrue);
    expect(b2.finances.map((r) => r.signature).toList(), before);
    expect(
        observer.receipt!.results
            .any((r) => b2.finances.any((old) => identical(old, r))),
        isFalse);
    fixture.expectUnchanged(sourceBefore);
    for (var i = 0; i < 48; i++) {
      expect(identical(b2.finances[i], financeReferences[i]), isTrue);
      expect(
          identical(b2.closingFinanceStates[i], closingReferences[i]), isTrue);
    }
    for (var i = 0; i < 720; i++) {
      expect(identical(fixture.w30.fixtureSnapshot.fixtures[i], matches[i]),
          isTrue);
      expect(
          identical(fixture.w30.fixtureSnapshot.fixtures[i].fixture.result,
              matches[i].fixture.result),
          isTrue);
    }
    expect(
        const PlayerPresidentB3AFinanceEquivalence()
            .inspect(b2)
            .fullM65Equivalent,
        isFalse);
  });
}
