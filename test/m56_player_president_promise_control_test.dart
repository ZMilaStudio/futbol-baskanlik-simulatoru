import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:test/test.dart';

void main() {
  test('M56 without a player provider preserves M11 promise generation', () {
    const context = PresidentPromiseContext(
      clubId: 'club_a',
      seasonIndex: 3,
      tier: LeagueTier.first,
      leagueSize: 16,
      expectedPosition: 2,
      openingCash: Money.fromUnits(20000000),
      openingDebt: Money.zero,
    );
    const ai = PromiseGenerator();
    const controlled = PlayerPresidentPromiseGenerator(
      controlledClubId: 'club_a',
    );

    final baseline = ai.generate(
      context: context,
      careerSeed: 56001,
      simulationVersion: 1,
    );
    final result = controlled.generate(
      context: context,
      careerSeed: 56001,
      simulationVersion: 1,
    );

    expect(result.signature, baseline.signature);
  });

  test('M56 overrides only the controlled club and keeps 47 AI promises exact', () {
    final world = const FictionalWorldFactory().build();
    final controlledClubId = world.clubs.first.id;
    const ai = PromiseGenerator();
    final player = PlayerPresidentPromiseGenerator(
      controlledClubId: controlledClubId,
      decisionProvider: const _FixedPromiseProvider(
        PresidentPromiseType.finishTopHalf,
      ),
    );

    var aiParity = 0;
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
        careerSeed: 56002,
        simulationVersion: 1,
      );
      final result = player.generate(
        context: context,
        careerSeed: 56002,
        simulationVersion: 1,
      );
      if (club.id == controlledClubId) {
        expect(baseline.type, PresidentPromiseType.challengeTitle);
        expect(result.type, PresidentPromiseType.finishTopHalf);
        expect(result.targetLeaguePosition, 8);
      } else {
        expect(result.signature, baseline.signature);
        aiParity++;
      }
    }

    expect(aiParity, 47);
  });

  test('M56 keeps canonical targets and rejects context-invalid choices', () {
    const stressed = PresidentPromiseContext(
      clubId: 'club_a',
      seasonIndex: 0,
      tier: LeagueTier.first,
      leagueSize: 16,
      expectedPosition: 8,
      openingCash: Money.fromUnits(10000000),
      openingDebt: Money.fromUnits(20000000),
    );
    final debtPromise = const PlayerPresidentPromiseGenerator(
      controlledClubId: 'club_a',
      decisionProvider: _FixedPromiseProvider(PresidentPromiseType.reduceDebt),
    ).generate(
      context: stressed,
      careerSeed: 56003,
      simulationVersion: 1,
    );

    expect(debtPromise.targetDebtReductionBps, 1200);
    expect(
      PlayerPresidentPromiseGenerator.allowedPromiseTypes(stressed),
      containsAll(<PresidentPromiseType>[
        PresidentPromiseType.finishTopHalf,
        PresidentPromiseType.reduceDebt,
        PresidentPromiseType.stabilizeFinances,
      ]),
    );

    expect(
      () => const PlayerPresidentPromiseGenerator(
        controlledClubId: 'club_a',
        decisionProvider: _FixedPromiseProvider(
          PresidentPromiseType.earnPromotion,
        ),
      ).generate(
        context: stressed,
        careerSeed: 56003,
        simulationVersion: 1,
      ),
      throwsArgumentError,
    );
  });

  test('M56 selected promise flows through real fan and media reputation', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 56004);
    final baseline = const PromiseMediaCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 1,
    );

    PromiseSeasonSnapshot? selected;
    PresidentPromiseType? selectedType;
    for (final snapshot in baseline.promiseReport.snapshots) {
      final allowed = PlayerPresidentPromiseGenerator.allowedPromiseTypes(
        snapshot.context,
      );
      for (final type in allowed) {
        if (type == snapshot.promise.type) continue;
        final alternative = PlayerPresidentPromiseGenerator.canonicalPromiseFor(
          context: snapshot.context,
          type: type,
        );
        final resolution = const PromiseResolver().resolve(
          promise: alternative,
          outcome: snapshot.outcome,
        );
        if (resolution.status != snapshot.resolution.status) {
          selected = snapshot;
          selectedType = type;
          break;
        }
      }
      if (selected != null) break;
    }

    expect(selected, isNotNull);
    expect(selectedType, isNotNull);
    final target = selected!;
    final playerSource = PromiseMediaCareerEngine(
      promiseEngine: PromiseCareerEngine(
        generator: PlayerPresidentPromiseGenerator(
          controlledClubId: target.promise.clubId,
          decisionProvider: _FixedPromiseProvider(selectedType!),
        ),
      ),
    ).simulateFromAdvancedReport(
      advancedReport: baseline.advancedTransferReport,
      managerReport: baseline.managerReport,
      config: config,
    );

    final baselineReputation = const PresidentReputationCareerEngine()
        .simulateFromSourceReport(sourceReport: baseline, config: config);
    final playerReputation = const PresidentReputationCareerEngine()
        .simulateFromSourceReport(sourceReport: playerSource, config: config);
    final baselineState = baselineReputation.seasons.single.clubs.firstWhere(
      (item) => item.clubId == target.promise.clubId,
    );
    final playerState = playerReputation.seasons.single.clubs.firstWhere(
      (item) => item.clubId == target.promise.clubId,
    );
    final playerPromise = playerSource.promiseReport.snapshots.firstWhere(
      (item) => item.promise.clubId == target.promise.clubId,
    );

    expect(playerPromise.promise.type, selectedType);
    expect(playerPromise.resolution.status, isNot(target.resolution.status));
    expect(
      playerState.fanAfter.signature != baselineState.fanAfter.signature ||
          playerState.mediaAfterPromise != baselineState.mediaAfterPromise,
      isTrue,
    );
  });

  test('M56 promise provider stays runtime-only across save and resume', () {
    final world = const FictionalWorldFactory().build();
    const config = SimulationConfig(careerSeed: 56005);
    final controlledClubId = world.clubs.first.id;
    const provider = _FixedPromiseProvider(PresidentPromiseType.finishTopHalf);
    const codec = PresidentDomainMemorySaveCodec();

    final direct = PlayerPresidentPromiseDomainCareerEngine(
      controlledClubId: controlledClubId,
      decisionProvider: provider,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 4,
    );
    final firstHalf = PlayerPresidentPromiseDomainCareerEngine(
      controlledClubId: controlledClubId,
      decisionProvider: provider,
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 2,
    );
    final restored = codec.decode(codec.encode(firstHalf.checkpoint));
    final resumed = PlayerPresidentPromiseDomainCareerEngine(
      controlledClubId: controlledClubId,
      decisionProvider: provider,
    ).resume(
      checkpoint: restored,
      seasonCount: 2,
    );

    expect(codec.encode(resumed.checkpoint), codec.encode(direct.checkpoint));
  });
}

class _FixedPromiseProvider extends PlayerPromiseDecisionProvider {
  const _FixedPromiseProvider(this.type);

  final PresidentPromiseType type;

  @override
  PresidentPromiseType choosePromise(PlayerPromiseDecisionContext context) => type;
}
