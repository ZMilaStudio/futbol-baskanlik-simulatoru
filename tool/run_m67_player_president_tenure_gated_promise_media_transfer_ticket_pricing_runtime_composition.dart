import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_promise_media_transfer_ticket_pricing_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_transfer_ticket_pricing_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';

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

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final config = SimulationConfig(careerSeed: seed);
  final world = const FictionalWorldFactory().build();
  const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();

  final discovery = const
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
  final discoverySource =
      discovery.boundaries.single.source.source.sponsor.report.sourceReport;
  final mediaByClub = {
    for (final item in discoverySource.baselineMediaReport.seasons.single.clubs)
      item.clubId: item,
  };
  final controlled = discoverySource.promiseReport.snapshots
      .firstWhere(
        (snapshot) =>
            mediaByClub[snapshot.promise.clubId]!.statement != null &&
            PlayerPresidentPromiseGenerator.allowedPromiseTypes(snapshot.context)
                .any((type) => type != snapshot.promise.type),
      )
      .promise
      .clubId;

  const m66 =
      PlayerPresidentTenureGatedTransferTicketPricingRuntimeCareerEngine(
    transferStrategyProvider: _YouthTransferProvider(),
    ticketPricingProvider: _PremiumTicketProvider(),
    ticketAiPolicy: _AlwaysBalancedPolicy(),
  );
  const parityEngine =
      PlayerPresidentTenureGatedPromiseMediaTransferTicketPricingRuntimeCareerEngine(
    transferStrategyProvider: _YouthTransferProvider(),
    ticketPricingProvider: _PremiumTicketProvider(),
    ticketAiPolicy: _AlwaysBalancedPolicy(),
  );
  final baseline = m66.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 2,
  );
  final parity = parityEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 2,
  );
  final m66ParityWithoutPromiseMedia =
      codec.encode(parity.checkpoint) == codec.encode(baseline.checkpoint) &&
          parity.signature == baseline.signature;

  final promise = _CountingAlternativePromiseProvider();
  final media = _CountingAlternativeMediaProvider();
  final transfer = _CountingYouthTransferProvider();
  final ticket = _CountingPremiumTicketProvider();
  final composed =
      PlayerPresidentTenureGatedPromiseMediaTransferTicketPricingRuntimeCareerEngine(
    promiseProvider: promise,
    mediaProvider: media,
    transferStrategyProvider: transfer,
    ticketPricingProvider: ticket,
    ticketAiPolicy: const _AlwaysBalancedPolicy(),
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 1,
  );
  final fourProviders = promise.calls == 1 &&
      media.calls == 1 &&
      transfer.calls > 0 &&
      ticket.calls == 1 &&
      composed.boundaries.single.decisionFor(controlled).providerCalled;
  final singleCheckpoint = composed.checkpoint.controlledClubId == controlled &&
      composed.boundaries.single.checkpoint.tenureControl.signature ==
          composed.checkpoint.tenureControl.signature;

  final seedCheckpoint = parityEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  ).checkpoint;
  final lostCheckpoint = PlayerPresidentTicketPricingRuntimeCheckpoint(
    runtime: seedCheckpoint.runtime,
    tenureControl: PlayerPresidentTenureControlState(
      controlledClubId: controlled,
      playerPresidentId: 'm67-former-president',
      status: PlayerPresidentTenureControlStatus.lost,
      lostAtCompletedSeason: seedCheckpoint.completedSeasons,
      successorPresidentId: 'm67-successor-president',
    ),
  );
  final blockedPromise = _CountingAlternativePromiseProvider();
  final blockedMedia = _CountingAlternativeMediaProvider();
  final blockedTransfer = _CountingYouthTransferProvider();
  final blockedTicket = _CountingPremiumTicketProvider();
  final blocked =
      PlayerPresidentTenureGatedPromiseMediaTransferTicketPricingRuntimeCareerEngine(
    promiseProvider: blockedPromise,
    mediaProvider: blockedMedia,
    transferStrategyProvider: blockedTransfer,
    ticketPricingProvider: blockedTicket,
    ticketAiPolicy: const _AlwaysBalancedPolicy(),
  ).resume(
    checkpoint: lostCheckpoint,
    seasonCount: 1,
  );
  final lostBlocksAll = blockedPromise.calls == 0 &&
      blockedMedia.calls == 0 &&
      blockedTransfer.calls == 0 &&
      blockedTicket.calls == 0 &&
      blocked.checkpoint.tenureControl.lost;

  const deterministicEngine =
      PlayerPresidentTenureGatedPromiseMediaTransferTicketPricingRuntimeCareerEngine(
    promiseProvider: _AlternativePromiseProvider(),
    mediaProvider: _AlternativeMediaProvider(),
    transferStrategyProvider: _YouthTransferProvider(),
    ticketPricingProvider: _PremiumTicketProvider(),
  );
  final direct = deterministicEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 4,
    electionInterval: 4,
  );
  final first = deterministicEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 2,
    electionInterval: 4,
    hasFutureSeasonAfterReport: true,
  );
  final loaded = codec.decode(codec.encode(first.checkpoint));
  final resumed = deterministicEngine.resume(
    checkpoint: loaded,
    seasonCount: 2,
  );
  final saveResume = codec.encode(resumed.checkpoint) ==
          codec.encode(direct.checkpoint) &&
      [...first.boundaries, ...resumed.boundaries]
              .map((item) => item.signature)
              .join('||') ==
          direct.boundaries.map((item) => item.signature).join('||');

  if (!m66ParityWithoutPromiseMedia ||
      !fourProviders ||
      !singleCheckpoint ||
      !lostBlocksAll ||
      !saveResume) {
    throw StateError(
      'M67 canonical failure: m66Parity=$m66ParityWithoutPromiseMedia '
      'fourProviders=$fourProviders singleCheckpoint=$singleCheckpoint '
      'lostBlocksAll=$lostBlocksAll saveResume=$saveResume',
    );
  }

  print(
    'M67_PLAYER_PRESIDENT_TENURE_GATED_PROMISE_MEDIA_TRANSFER_TICKET_PRICING_RUNTIME_COMPOSITION_PASS '
    'controlled=$controlled m66ParityWithoutPromiseMedia=$m66ParityWithoutPromiseMedia '
    'fourProviders=$fourProviders singleCheckpoint=$singleCheckpoint '
    'lostBlocksAll=$lostBlocksAll saveResume=$saveResume '
    'worldClubs=${world.clubs.length} seed=$seed',
  );
}
