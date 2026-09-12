import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const config = SimulationConfig(careerSeed: seed);
  const controlled = 't1_02';
  const m51 = PlayerPresidentCrisisControlCareerEngine();
  const codec = PlayerPresidentManagerControlSaveCodec();

  test('M52 without a manager provider preserves M51 exactly', () {
    final world = const FictionalWorldFactory().build();
    final baseline = m51.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 3,
    );
    final player = const PlayerPresidentManagerControlCareerEngine()
        .simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 3,
    );

    expect(player.managerDecisions, isEmpty);
    expect(player.checkpoint.control.signature, baseline.checkpoint.signature);
    expect(player.sourceSegments, hasLength(1));
    expect(player.sourceSegments.single.signature, baseline.signature);
  });

  test('M52 replacement override changes only the controlled assignment', () {
    final world = const FictionalWorldFactory().build();
    final baseline = m51.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final player = const PlayerPresidentManagerControlCareerEngine(
      managerProvider: _AlternativeReplacementProvider(),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );

    expect(player.managerDecisions, hasLength(1));
    final decision = player.managerDecisions.single;
    expect(decision.clubId, controlled);
    expect(decision.replaced, isTrue);
    expect(decision.selectedManager, isNotNull);
    expect(decision.changedFromAi, isTrue);

    final baselineAssignments = {
      for (final item in _managerState(baseline.checkpoint).assignments)
        item.clubId: item.managerId,
    };
    final playerAssignments = {
      for (final item in _managerState(player.checkpoint.control).assignments)
        item.clubId: item.managerId,
    };
    expect(
      playerAssignments[controlled],
      decision.selectedManager!.id,
    );
    expect(
      playerAssignments[controlled],
      isNot(baselineAssignments[controlled]),
    );
    for (final club in world.clubs.where((item) => item.id != controlled)) {
      expect(playerAssignments[club.id], baselineAssignments[club.id]);
    }
  });

  test('M52 selected manager coaches the next real season', () {
    final world = const FictionalWorldFactory().build();
    final player = const PlayerPresidentManagerControlCareerEngine(
      managerProvider: _AlternativeReplacementProvider(),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 2,
    );

    expect(player.managerDecisions, hasLength(1));
    final selected = player.managerDecisions.single.selectedManager!;
    final manager = _managerState(player.checkpoint.control);
    final nextSeason = manager.seasons.firstWhere(
      (item) => item.seasonIndex == config.seasonIndex + 1,
    );
    final controlledSeason = nextSeason.clubs.firstWhere(
      (item) => item.clubId == controlled,
    );
    expect(controlledSeason.managerId, selected.id);
  });

  test('M52 can retain a non-retiring manager the AI would dismiss', () {
    final world = const FictionalWorldFactory().build();
    final probe = m51.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final probeManager = _managerState(probe.checkpoint);
    final probeSeason = probeManager.seasons.last;
    final change = probeSeason.changesAfterSeason.firstWhere(
      (item) =>
          item.reason != ManagerChangeReason.retirement &&
          !probeManager.assignments.any(
            (assignment) =>
                assignment.clubId != item.clubId &&
                assignment.managerId == item.fromManagerId,
          ),
    );

    final player = const PlayerPresidentManagerControlCareerEngine(
      managerProvider: _RetainProvider(),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: change.clubId,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final decision = player.managerDecisions.single;
    final assignment = _managerState(player.checkpoint.control)
        .assignments
        .firstWhere((item) => item.clubId == change.clubId);

    expect(decision.reviewContext.aiWouldReplace, isTrue);
    expect(decision.reviewContext.forcedRetirement, isFalse);
    expect(decision.reviewChoice, PlayerManagerReviewChoice.retain);
    expect(decision.changedFromAi, isTrue);
    expect(assignment.managerId, change.fromManagerId);
  });

  test('M52 save round trip and 2 plus 2 resume match four seasons', () {
    final world = const FictionalWorldFactory().build();
    const forcedCrisis = CrisisDecisionEngine(activationThreshold: 0);
    const engine = PlayerPresidentManagerControlCareerEngine(
      managerProvider: _RotatingManagerProvider(),
      crisisProvider: _RotatingCrisisProvider(),
      sponsorProvider: _BoldSponsorProvider(),
      facilityProvider: _AlternatingFacilityProvider(),
      aiCrisisEngine: forcedCrisis,
    );
    final direct = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 4,
      electionInterval: 2,
      hasFutureSeasonAfterReport: true,
    );
    final first = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 2,
      electionInterval: 2,
      hasFutureSeasonAfterReport: true,
    );
    final encoded = codec.encode(first.checkpoint);
    final loaded = codec.decode(encoded);
    final second = engine.resume(
      checkpoint: loaded,
      seasonCount: 2,
      hasFutureSeasonAfterReport: true,
    );

    expect(loaded.controlledClubId, controlled);
    expect(codec.encode(loaded), encoded);
    expect(codec.encode(second.checkpoint), codec.encode(direct.checkpoint));
    expect(
      [...first.managerDecisions, ...second.managerDecisions]
          .map((item) => item.signature)
          .toList(),
      direct.managerDecisions.map((item) => item.signature).toList(),
    );
    expect(
      [...first.boundaries, ...second.boundaries]
          .map((item) => item.signature)
          .toList(),
      direct.boundaries.map((item) => item.signature).toList(),
    );
    expect(
      [...first.crisisDecisions, ...second.crisisDecisions]
          .map((item) => item.signature)
          .toList(),
      direct.crisisDecisions.map((item) => item.signature).toList(),
    );
    expect(
      [...first.sponsorDecisions, ...second.sponsorDecisions]
          .map((item) => item.signature)
          .toList(),
      direct.sponsorDecisions.map((item) => item.signature).toList(),
    );
  });
}

ManagerRuntimeState _managerState(PlayerPresidentCrisisControlCheckpoint checkpoint) =>
    checkpoint.control.control.runtime.runtime.domain.presidentRuntime.runtime
        .runtime.manager;

class _AlternativeReplacementProvider extends PlayerManagerDecisionProvider {
  const _AlternativeReplacementProvider();

  @override
  PlayerManagerReviewChoice review(PlayerManagerReviewContext context) =>
      PlayerManagerReviewChoice.replace;

  @override
  PlayerManagerReplacementChoice chooseReplacement(
    PlayerManagerReplacementContext context,
  ) {
    final candidate = context.candidates.firstWhere(
      (item) => item.manager.id != context.aiChoice.id,
      orElse: () => context.candidates.first,
    );
    return PlayerManagerReplacementChoice(managerId: candidate.manager.id);
  }
}

class _RetainProvider extends PlayerManagerDecisionProvider {
  const _RetainProvider();

  @override
  PlayerManagerReviewChoice review(PlayerManagerReviewContext context) {
    expect(context.canRetain, isTrue);
    return PlayerManagerReviewChoice.retain;
  }

  @override
  PlayerManagerReplacementChoice chooseReplacement(
    PlayerManagerReplacementContext context,
  ) {
    throw StateError('Replacement must not be requested after retain.');
  }
}

class _RotatingManagerProvider extends PlayerManagerDecisionProvider {
  const _RotatingManagerProvider();

  @override
  PlayerManagerReviewChoice review(PlayerManagerReviewContext context) =>
      PlayerManagerReviewChoice.replace;

  @override
  PlayerManagerReplacementChoice chooseReplacement(
    PlayerManagerReplacementContext context,
  ) {
    final index = context.seasonIndex % context.candidates.length;
    return PlayerManagerReplacementChoice(
      managerId: context.candidates[index].manager.id,
    );
  }
}

class _RotatingCrisisProvider extends PlayerCrisisDecisionProvider {
  const _RotatingCrisisProvider();

  @override
  PlayerCrisisActionChoice choose(PlayerCrisisDecisionContext context) {
    final index =
        (context.seasonIndex + context.scenario.type.index) %
            context.availableDecisions.length;
    return PlayerCrisisActionChoice(
      action: context.availableDecisions[index].action,
    );
  }
}

class _BoldSponsorProvider extends PlayerSponsorDecisionProvider {
  const _BoldSponsorProvider();

  @override
  PlayerSponsorOfferChoice choose(PlayerSponsorDecisionContext context) {
    final offer = context.offers.firstWhere((item) => item.id.endsWith('-bold'));
    return PlayerSponsorOfferChoice(offerId: offer.id);
  }
}

class _AlternatingFacilityProvider
    extends PlayerFacilityInvestmentDecisionProvider {
  const _AlternatingFacilityProvider();

  @override
  PlayerFacilityInvestmentChoice choose(PlayerFacilityInvestmentContext context) {
    if (context.seasonIndex.isEven) {
      return const PlayerFacilityInvestmentChoice(stadiumUpgrades: 1);
    }
    return const PlayerFacilityInvestmentChoice(trainingGroundUpgrades: 1);
  }
}
