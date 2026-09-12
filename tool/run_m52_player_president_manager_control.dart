import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_crisis_control.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final config = SimulationConfig(careerSeed: seed);
  const controlled = 't1_02';
  final world = const FictionalWorldFactory().build();
  const baselineEngine = PlayerPresidentCrisisControlCareerEngine();

  final neutralBaseline = baselineEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 3,
  );
  final neutralM52 = const PlayerPresidentManagerControlCareerEngine()
      .simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 3,
  );
  if (neutralM52.checkpoint.control.signature != neutralBaseline.checkpoint.signature ||
      neutralM52.managerDecisions.isNotEmpty) {
    throw StateError('M52 no-provider path must preserve M51 exactly.');
  }

  final oneSeasonBaseline = baselineEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  );
  final oneSeasonPlayer = const PlayerPresidentManagerControlCareerEngine(
    managerProvider: _AlternativeReplacementProvider(),
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  );
  final baselineAssignments = {
    for (final item in _managerState(oneSeasonBaseline.checkpoint).assignments)
      item.clubId: item.managerId,
  };
  final playerAssignments = {
    for (final item in _managerState(oneSeasonPlayer.checkpoint.control).assignments)
      item.clubId: item.managerId,
  };
  var aiParityCount = 0;
  for (final club in world.clubs.where((item) => item.id != controlled)) {
    if (baselineAssignments[club.id] != playerAssignments[club.id]) {
      throw StateError('M52 must preserve the other clubs at the decision boundary.');
    }
    aiParityCount++;
  }
  final firstDecision = oneSeasonPlayer.managerDecisions.single;
  if (!firstDecision.changedFromAi ||
      playerAssignments[controlled] != firstDecision.selectedManager?.id) {
    throw StateError('M52 must apply the controlled manager override.');
  }

  final wired = const PlayerPresidentManagerControlCareerEngine(
    managerProvider: _AlternativeReplacementProvider(),
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 2,
  );
  final selectedFirst = wired.managerDecisions.single.selectedManager!;
  final secondSeason = _managerState(wired.checkpoint.control)
      .seasons
      .firstWhere((item) => item.seasonIndex == config.seasonIndex + 1);
  final nextSeasonWired = secondSeason.clubs
          .firstWhere((item) => item.clubId == controlled)
          .managerId ==
      selectedFirst.id;
  if (!nextSeasonWired) {
    throw StateError('M52 selected manager must coach the next real season.');
  }

  final probeManager = _managerState(oneSeasonBaseline.checkpoint);
  final probeSeason = probeManager.seasons.last;
  final retainable = probeSeason.changesAfterSeason.firstWhere(
    (item) =>
        item.reason != ManagerChangeReason.retirement &&
        !probeManager.assignments.any(
          (assignment) =>
              assignment.clubId != item.clubId &&
              assignment.managerId == item.fromManagerId,
        ),
  );
  final retained = const PlayerPresidentManagerControlCareerEngine(
    managerProvider: _RetainProvider(),
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: retainable.clubId,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  );
  final retainedDecision = retained.managerDecisions.single;
  final retainedAssignment = _managerState(retained.checkpoint.control)
      .assignments
      .firstWhere((item) => item.clubId == retainable.clubId);
  final retainOverride = retainedDecision.changedFromAi &&
      retainedDecision.reviewChoice == PlayerManagerReviewChoice.retain &&
      retainedAssignment.managerId == retainable.fromManagerId;
  if (!retainOverride) {
    throw StateError('M52 must allow a legal player retain override.');
  }

  const forcedCrisis = CrisisDecisionEngine(activationThreshold: 0);
  const engine = PlayerPresidentManagerControlCareerEngine(
    managerProvider: _RotatingManagerProvider(),
    crisisProvider: _RotatingCrisisProvider(),
    sponsorProvider: _BoldSponsorProvider(),
    facilityProvider: _AlternatingFacilityProvider(),
    aiCrisisEngine: forcedCrisis,
  );
  const codec = PlayerPresidentManagerControlSaveCodec();
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
  final save = codec.encode(first.checkpoint);
  final loaded = codec.decode(save);
  final second = engine.resume(
    checkpoint: loaded,
    seasonCount: 2,
    hasFutureSeasonAfterReport: true,
  );
  final finalCheckpointMatch =
      codec.encode(second.checkpoint) == codec.encode(direct.checkpoint);
  final boundaryMatch = _signatures([...first.boundaries, ...second.boundaries]) ==
      _signatures(direct.boundaries);
  final managerDecisionMatch =
      _signatures([...first.managerDecisions, ...second.managerDecisions]) ==
          _signatures(direct.managerDecisions);
  final crisisDecisionMatch =
      _signatures([...first.crisisDecisions, ...second.crisisDecisions]) ==
          _signatures(direct.crisisDecisions);
  final sponsorDecisionMatch =
      _signatures([...first.sponsorDecisions, ...second.sponsorDecisions]) ==
          _signatures(direct.sponsorDecisions);
  if (!finalCheckpointMatch ||
      !boundaryMatch ||
      !managerDecisionMatch ||
      !crisisDecisionMatch ||
      !sponsorDecisionMatch ||
      loaded.controlledClubId != controlled) {
    throw StateError('M52 composed save/resume parity failed.');
  }

  print('M52_PLAYER_MANAGER_CONTROL_PASS');
  print('seed=$seed');
  print('controlledClub=$controlled');
  print('aiParityCount=$aiParityCount');
  print('managerDecisionWindows=${direct.managerDecisions.length}');
  print('changedFromAiCount=${direct.managerDecisions.where((item) => item.changedFromAi).length}');
  print('firstAiReview=${firstDecision.reviewContext.aiWouldReplace ? 'replace' : 'retain'}');
  print('firstPlayerReview=${firstDecision.reviewChoice.name}');
  print('firstAiManager=${firstDecision.reviewContext.aiNextManager.id}');
  print('firstPlayerManager=${firstDecision.selectedManager?.id ?? 'none'}');
  print('neutralM51Parity=true');
  print('nextSeasonWired=$nextSeasonWired');
  print('retainOverride=$retainOverride');
  print('controlledClubPersisted=${loaded.controlledClubId == controlled}');
  print('finalCheckpointMatch=$finalCheckpointMatch');
  print('boundaryMatch=$boundaryMatch');
  print('managerDecisionMatch=$managerDecisionMatch');
  print('crisisDecisionMatch=$crisisDecisionMatch');
  print('sponsorDecisionMatch=$sponsorDecisionMatch');
  print('saveBytes=${save.length}');
}

ManagerRuntimeState _managerState(PlayerPresidentCrisisControlCheckpoint checkpoint) =>
    checkpoint.control.control.runtime.runtime.domain.presidentRuntime.runtime
        .runtime.manager;

String _signatures(Iterable<dynamic> values) =>
    values.map((item) => item.signature as String).join('||');

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
    if (!context.canRetain) {
      throw StateError('Canonical retain target must be retainable.');
    }
    return PlayerManagerReviewChoice.retain;
  }

  @override
  PlayerManagerReplacementChoice chooseReplacement(
    PlayerManagerReplacementContext context,
  ) {
    throw StateError('Retain canonical must not request replacement.');
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
