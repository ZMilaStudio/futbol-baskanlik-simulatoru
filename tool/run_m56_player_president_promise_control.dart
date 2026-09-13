import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';

void main() {
  final world = const FictionalWorldFactory().build();
  final controlledClubId = world.clubs.first.id;
  const ai = PromiseGenerator();
  final player = PlayerPresidentPromiseGenerator(
    controlledClubId: controlledClubId,
    decisionProvider: const _FixedPromiseProvider(
      PresidentPromiseType.finishTopHalf,
    ),
  );

  var aiParityCount = 0;
  PresidentPromise? aiControlled;
  PresidentPromise? playerControlled;
  for (var index = 0; index < world.clubs.length; index++) {
    final club = world.clubs[index];
    final context = PresidentPromiseContext(
      clubId: club.id,
      seasonIndex: 0,
      tier: LeagueTier.first,
      leagueSize: 16,
      expectedPosition: index == 0 ? 1 : 8,
      openingCash: const Money.fromUnits(20000000),
      openingDebt: Money.zero,
    );
    final baseline = ai.generate(
      context: context,
      careerSeed: 56056,
      simulationVersion: 1,
    );
    final selected = player.generate(
      context: context,
      careerSeed: 56056,
      simulationVersion: 1,
    );
    if (club.id == controlledClubId) {
      aiControlled = baseline;
      playerControlled = selected;
    } else if (baseline.signature == selected.signature) {
      aiParityCount++;
    }
  }

  const stressed = PresidentPromiseContext(
    clubId: 'stress_club',
    seasonIndex: 0,
    tier: LeagueTier.first,
    leagueSize: 16,
    expectedPosition: 8,
    openingCash: Money.fromUnits(10000000),
    openingDebt: Money.fromUnits(20000000),
  );
  final debtPromise = PlayerPresidentPromiseGenerator.canonicalPromiseFor(
    context: stressed,
    type: PresidentPromiseType.reduceDebt,
  );

  var invalidBlocked = false;
  try {
    PlayerPresidentPromiseGenerator.canonicalPromiseFor(
      context: stressed,
      type: PresidentPromiseType.earnPromotion,
    );
  } on ArgumentError {
    invalidBlocked = true;
  }

  final replayContext = PresidentPromiseContext(
    clubId: controlledClubId,
    seasonIndex: 0,
    tier: LeagueTier.first,
    leagueSize: 16,
    expectedPosition: 1,
    openingCash: const Money.fromUnits(20000000),
    openingDebt: Money.zero,
  );
  final replay = player.generate(
    context: replayContext,
    careerSeed: 56056,
    simulationVersion: 1,
  );

  final passed = aiParityCount == 47 &&
      aiControlled?.type == PresidentPromiseType.challengeTitle &&
      playerControlled?.type == PresidentPromiseType.finishTopHalf &&
      playerControlled?.targetLeaguePosition == 8 &&
      debtPromise.targetDebtReductionBps == 1200 &&
      invalidBlocked &&
      replay.signature == playerControlled?.signature;

  if (!passed) {
    throw StateError(
      'M56 canonical failure: aiParity=$aiParityCount '
      'ai=${aiControlled?.type.name} player=${playerControlled?.type.name} '
      'debtTarget=${debtPromise.targetDebtReductionBps} '
      'invalidBlocked=$invalidBlocked',
    );
  }

  print(
    'M56_PLAYER_PROMISE_CONTROL_PASS '
    'controlled=$controlledClubId aiParity=$aiParityCount '
    'ai=${aiControlled!.type.name} player=${playerControlled!.type.name} '
    'deterministic=true canonicalTargets=true invalidBlocked=true '
    'worldClubs=${world.clubs.length}',
  );
}

class _FixedPromiseProvider extends PlayerPromiseDecisionProvider {
  const _FixedPromiseProvider(this.type);

  final PresidentPromiseType type;

  @override
  PresidentPromiseType choosePromise(PlayerPromiseDecisionContext context) => type;
}
