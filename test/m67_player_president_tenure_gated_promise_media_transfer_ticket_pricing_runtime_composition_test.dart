import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_promise_media_transfer_ticket_pricing_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_transfer_ticket_pricing_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:test/test.dart';

class _AlwaysBalancedPolicy extends PresidentMatchdayTicketPricingPolicy {
  const _AlwaysBalancedPolicy();

  @override
  MatchdayTicketPricingChoice choose({
    required PresidentManagementProfile profile,
    required int fanTrust,
    required StadiumAttendanceProfile base,
  }) =>
      const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.balanced);
}

class _PremiumTicketProvider
    extends PlayerMatchdayTicketPricingDecisionProvider {
  const _PremiumTicketProvider();

  @override
  MatchdayTicketPricingChoice choose(
    PlayerPresidentTicketPricingDecisionContext context,
  ) =>
      const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.premium);
}

class _CountingPremiumTicketProvider
    extends PlayerMatchdayTicketPricingDecisionProvider {
  int calls = 0;

  @override
  MatchdayTicketPricingChoice choose(
    PlayerPresidentTicketPricingDecisionContext context,
  ) {
    calls++;
    return const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.premium);
  }
}

class _YouthTransferProvider extends PlayerTransferStrategyDecisionProvider {
  const _YouthTransferProvider();

  @override
  PlayerTransferStrategyChoice chooseTransferStrategy(
    PlayerTransferStrategyDecisionContext context,
  ) =>
      const PlayerTransferStrategyChoice(
        financialDiscipline: 60,
        transferAmbition: 60,
        riskAppetite: 60,
        youthOrientation: 90,
      );
}

class _CountingYouthTransferProvider
    extends PlayerTransferStrategyDecisionProvider {
  int calls = 0;

  @override
  PlayerTransferStrategyChoice chooseTransferStrategy(
    PlayerTransferStrategyDecisionContext context,
  ) {
    calls++;
    return const PlayerTransferStrategyChoice(
      financialDiscipline: 60,
      transferAmbition: 60,
      riskAppetite: 60,
      youthOrientation: 90,
    );
  }
}

class _AlternativePromiseProvider extends PlayerPromiseDecisionProvider {
  const _AlternativePromiseProvider();

  @override
  PresidentPromiseType choosePromise(PlayerPromiseDecisionContext context) =>
      context.allowedTypes.firstWhere(
        (type) => type != context.aiPromise.type,
        orElse: () => context.aiPromise.type,
      );
}

class _CountingAlternativePromiseProvider
    extends PlayerPromiseDecisionProvider {
  int calls = 0;

  @override
  PresidentPromiseType choosePromise(PlayerPromiseDecisionContext context) {
    calls++;
    return context.allowedTypes.firstWhere(
      (type) => type != context.aiPromise.type,
      orElse: () => context.aiPromise.type,
    );
  }
}

class _AlternativeMediaProvider extends PlayerMediaStatementDecisionProvider {
  const _AlternativeMediaProvider();

  @override
  MediaStance chooseStance(PlayerMediaStatementDecisionContext context) =>
      context.allowedStances.firstWhere(
        (stance) => stance != context.aiStatement.stance,
      );
}

class _CountingAlternativeMediaProvider
    extends PlayerMediaStatementDecisionProvider {
  int calls = 0;

  @override
  MediaStance chooseStance(PlayerMediaStatementDecisionContext context) {
    calls++;
    return context.allowedStances.firstWhere(
      (stance) => stance != context.aiStatement.stance,
    );
  }
}

void main() {
  const config = SimulationConfig(careerSeed: 20260903);
  const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();

  late FictionalWorldSetup world;
  late String interactiveClubId;

  setUpAll(() {
    world = const FictionalWorldFactory().build();
    final baseline = const
        PlayerPresidentTenureGatedTransferTicketPricingRuntimeCareerEngine(
      transferStrategyProvider: _YouthTransferProvider(),
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: world.clubs.first.id,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final source = baseline
        .boundaries.single.source.source.sponsor.report.sourceReport;
    final mediaByClub = {
      for (final item in source.baselineMediaReport.seasons.single.clubs)
        item.clubId: item,
    };
    interactiveClubId = source.promiseReport.snapshots
        .firstWhere(
          (snapshot) =>
              mediaByClub[snapshot.promise.clubId]!.statement != null &&
              PlayerPresidentPromiseGenerator.allowedPromiseTypes(
                snapshot.context,
              ).any((type) => type != snapshot.promise.type),
        )
        .promise
        .clubId;
  });

  test('M67 without promise or media providers preserves M66 exactly', () {
    const m66 =
        PlayerPresidentTenureGatedTransferTicketPricingRuntimeCareerEngine(
      transferStrategyProvider: _YouthTransferProvider(),
      ticketPricingProvider: _PremiumTicketProvider(),
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    );
    const m67 =
        PlayerPresidentTenureGatedPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      transferStrategyProvider: _YouthTransferProvider(),
      ticketPricingProvider: _PremiumTicketProvider(),
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    );

    final baseline = m66.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 2,
    );
    final composed = m67.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 2,
    );

    expect(codec.encode(composed.checkpoint), codec.encode(baseline.checkpoint));
    expect(
      composed.boundaries.map((item) => item.signature).toList(),
      baseline.boundaries.map((item) => item.signature).toList(),
    );
  });

  test('M67 composes promise media transfer and ticket decisions in one season',
      () {
    const baselineEngine =
        PlayerPresidentTenureGatedPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      transferStrategyProvider: _YouthTransferProvider(),
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    );
    final promise = _CountingAlternativePromiseProvider();
    final media = _CountingAlternativeMediaProvider();
    final transfer = _CountingYouthTransferProvider();
    final ticket = _CountingPremiumTicketProvider();
    final composedEngine =
        PlayerPresidentTenureGatedPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      promiseProvider: promise,
      mediaProvider: media,
      transferStrategyProvider: transfer,
      ticketPricingProvider: ticket,
      ticketAiPolicy: const _AlwaysBalancedPolicy(),
    );

    final baseline = baselineEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 1,
    );
    final composed = composedEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 1,
    );

    final baselineBoundary = baseline.boundaries.single;
    final boundary = composed.boundaries.single;
    final baselineSource =
        baselineBoundary.source.source.sponsor.report.sourceReport;
    final source = boundary.source.source.sponsor.report.sourceReport;
    final baselinePromise = baselineSource.promiseReport.snapshots
        .singleWhere((item) => item.promise.clubId == interactiveClubId);
    final actualPromise = source.promiseReport.snapshots
        .singleWhere((item) => item.promise.clubId == interactiveClubId);
    final baselineMedia = baselineSource.baselineMediaReport.seasons.single.clubs
        .singleWhere((item) => item.clubId == interactiveClubId);
    final actualMedia = source.baselineMediaReport.seasons.single.clubs
        .singleWhere((item) => item.clubId == interactiveClubId);

    expect(promise.calls, 1);
    expect(media.calls, 1);
    expect(transfer.calls, greaterThan(0));
    expect(ticket.calls, 1);
    expect(actualPromise.promise.type, isNot(baselinePromise.promise.type));
    expect(actualMedia.statement!.stance, isNot(baselineMedia.statement!.stance));
    expect(actualMedia.statement!.id, baselineMedia.statement!.id);
    expect(actualMedia.statement!.topic, baselineMedia.statement!.topic);
    expect(boundary.decisionFor(interactiveClubId).providerCalled, isTrue);
    expect(
      boundary.financeFor(interactiveClubId).matchdayRevenue,
      greaterThan(baselineBoundary.financeFor(interactiveClubId).matchdayRevenue),
    );
  });

  test('M67 one persisted lost tenure blocks all four external providers', () {
    final first = const
        PlayerPresidentTenureGatedPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final lost = PlayerPresidentTicketPricingRuntimeCheckpoint(
      runtime: first.checkpoint.runtime,
      tenureControl: PlayerPresidentTenureControlState(
        controlledClubId: interactiveClubId,
        playerPresidentId: 'm67-former-president',
        status: PlayerPresidentTenureControlStatus.lost,
        lostAtCompletedSeason: first.checkpoint.completedSeasons,
        successorPresidentId: 'm67-successor-president',
      ),
    );
    final promise = _CountingAlternativePromiseProvider();
    final media = _CountingAlternativeMediaProvider();
    final transfer = _CountingYouthTransferProvider();
    final ticket = _CountingPremiumTicketProvider();
    final resumed =
        PlayerPresidentTenureGatedPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      promiseProvider: promise,
      mediaProvider: media,
      transferStrategyProvider: transfer,
      ticketPricingProvider: ticket,
      ticketAiPolicy: const _AlwaysBalancedPolicy(),
    ).resume(
      checkpoint: lost,
      seasonCount: 1,
    );

    expect(promise.calls, 0);
    expect(media.calls, 0);
    expect(transfer.calls, 0);
    expect(ticket.calls, 0);
    expect(resumed.boundaries.single.decisionFor(interactiveClubId).providerCalled,
        isFalse);
    expect(resumed.checkpoint.tenureControl.lost, isTrue);
  });

  test('M67 incumbent mismatch blocks all providers and becomes sticky loss', () {
    final first = const
        PlayerPresidentTenureGatedPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      ticketAiPolicy: _AlwaysBalancedPolicy(),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final mismatch = PlayerPresidentTicketPricingRuntimeCheckpoint(
      runtime: first.checkpoint.runtime,
      tenureControl: PlayerPresidentTenureControlState(
        controlledClubId: interactiveClubId,
        playerPresidentId: 'm67-non-incumbent-president',
        status: PlayerPresidentTenureControlStatus.active,
      ),
    );
    final promise = _CountingAlternativePromiseProvider();
    final media = _CountingAlternativeMediaProvider();
    final transfer = _CountingYouthTransferProvider();
    final ticket = _CountingPremiumTicketProvider();
    final resumed =
        PlayerPresidentTenureGatedPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      promiseProvider: promise,
      mediaProvider: media,
      transferStrategyProvider: transfer,
      ticketPricingProvider: ticket,
      ticketAiPolicy: const _AlwaysBalancedPolicy(),
    ).resume(
      checkpoint: mismatch,
      seasonCount: 1,
    );

    expect(promise.calls, 0);
    expect(media.calls, 0);
    expect(transfer.calls, 0);
    expect(ticket.calls, 0);
    expect(resumed.checkpoint.tenureControl.lost, isTrue);
  });

  test('M67 save round trip and 2 plus 2 resume match four seasons', () {
    const engine =
        PlayerPresidentTenureGatedPromiseMediaTransferTicketPricingRuntimeCareerEngine(
      promiseProvider: _AlternativePromiseProvider(),
      mediaProvider: _AlternativeMediaProvider(),
      transferStrategyProvider: _YouthTransferProvider(),
      ticketPricingProvider: _PremiumTicketProvider(),
    );
    final direct = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 4,
      electionInterval: 4,
    );
    final first = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: interactiveClubId,
      seasonCount: 2,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    final loaded = codec.decode(codec.encode(first.checkpoint));
    final resumed = engine.resume(
      checkpoint: loaded,
      seasonCount: 2,
    );

    expect(codec.encode(resumed.checkpoint), codec.encode(direct.checkpoint));
    expect(
      [...first.boundaries, ...resumed.boundaries]
          .map((item) => item.signature)
          .toList(),
      direct.boundaries.map((item) => item.signature).toList(),
    );
  });
}
