import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_promise_control.dart';
import 'package:futbol_baskanlik_m0/src/promise/promise_opening_context_builder.dart';
import 'package:futbol_baskanlik_m0/src/world/world_career_season.dart';
import 'package:futbol_baskanlik_m0/src/world/world_opening_state_initializer.dart';
import 'package:test/test.dart';

// Deliberately independent oracle: a copy of the original M11 lookup/ranking
// algorithm, NOT a call to PromiseOpeningContextBuilder or the new delegation.
List<PresidentPromiseContext> _originalM11Contexts(WorldCareerSeason season) {
  final positions = <String, int>{};
  final clubById = {for (final club in season.clubs) club.id: club};
  for (final league in season.leaguesBeforeSeason) {
    final ranked = league.clubIds.map((id) => clubById[id]!).toList()
      ..sort((a, b) {
        final strength = b.strength.compareTo(a.strength);
        return strength != 0 ? strength : a.id.compareTo(b.id);
      });
    for (var index = 0; index < ranked.length; index++) {
      positions[ranked[index].id] = index + 1;
    }
  }

  final clubIds = season.clubs.map((club) => club.id).toList()..sort();
  return [
    for (final clubId in clubIds)
      (() {
        final league = season.leaguesBeforeSeason.firstWhere(
          (item) => item.clubIds.contains(clubId),
        );
        final finance = season.finances.firstWhere(
          (item) => item.clubId == clubId,
        );
        return PresidentPromiseContext(
          clubId: clubId,
          seasonIndex: season.seasonIndex,
          tier: league.tier,
          leagueSize: league.clubIds.length,
          expectedPosition: positions[clubId]!,
          openingCash: finance.openingCash,
          openingDebt: finance.openingDebt,
        );
      })(),
  ];
}

List<ClubFinanceState> _originalOpeningFinance(WorldCareerSeason season) => [
      for (final item in season.finances)
        ClubFinanceState(
          clubId: item.clubId,
          cash: item.openingCash,
          debt: item.openingDebt,
        ),
    ];

List<PresidentPromiseType> _originalAllowed(PresidentPromiseContext context) {
  final types = <PresidentPromiseType>[PresidentPromiseType.finishTopHalf];
  if (context.financialStress) {
    types.add(PresidentPromiseType.reduceDebt);
    types.add(PresidentPromiseType.stabilizeFinances);
  }
  if (context.expectedPosition >= context.leagueSize - 3) {
    types.add(PresidentPromiseType.avoidRelegation);
  }
  if (context.tier != LeagueTier.first && context.expectedPosition <= 5) {
    types.add(PresidentPromiseType.earnPromotion);
  }
  if (context.tier == LeagueTier.first && context.expectedPosition <= 3) {
    types.add(PresidentPromiseType.challengeTitle);
  }
  return types;
}

void _assertSevenFieldParity(
  PresidentPromiseContext actual,
  PresidentPromiseContext oracle,
) {
  expect(actual.clubId, oracle.clubId);
  expect(actual.seasonIndex, oracle.seasonIndex);
  expect(actual.tier, oracle.tier);
  expect(actual.leagueSize, oracle.leagueSize);
  expect(actual.expectedPosition, oracle.expectedPosition);
  expect(actual.openingCash, oracle.openingCash);
  expect(actual.openingDebt, oracle.openingDebt);
  expect(actual.financialStress, oracle.financialStress);
  expect(actual.severeFinancialStress, oracle.severeFinancialStress);
  expect(actual.signature, oracle.signature);
}

PresidentPromiseOutcome _originalM11Outcome(
  WorldCareerSeason season,
  PresidentPromiseContext context,
) {
  final league = season.leaguesBeforeSeason.firstWhere(
    (item) => item.clubIds.contains(context.clubId),
  );
  final leagueResult = season.leagueResults.firstWhere(
    (item) => item.tier == league.tier,
  );
  final index = leagueResult.report.table.indexWhere(
    (row) => row.clubId == context.clubId,
  );
  final finance = season.finances.firstWhere(
    (item) => item.clubId == context.clubId,
  );
  var promoted = false;
  var relegated = false;
  for (final movement in season.movementsAfterSeason) {
    if (movement.clubId != context.clubId) continue;
    promoted = movement.to.level < movement.from.level;
    relegated = movement.to.level > movement.from.level;
    break;
  }
  return PresidentPromiseOutcome(
    clubId: context.clubId,
    seasonIndex: season.seasonIndex,
    leaguePosition: index + 1,
    leagueSize: league.clubIds.length,
    openingDebt: finance.openingDebt,
    closingDebt: finance.closingDebt,
    emergencyBorrowing: finance.emergencyBorrowing,
    promoted: promoted,
    relegated: relegated,
  );
}

class _FixedChoice extends PlayerPromiseDecisionProvider {
  const _FixedChoice(this.value);
  final PresidentPromiseType value;

  @override
  PresidentPromiseType choosePromise(PlayerPromiseDecisionContext context) =>
      value;
}

void main() {
  final world = const FictionalWorldFactory().build();
  const config = SimulationConfig(careerSeed: 20260903);
  const builder = PromiseOpeningContextBuilder();
  final advanced = const AdvancedTransferWorldCareerEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 2,
  );
  final report = const PromiseCareerEngine().simulateFromAdvancedReport(
    advancedReport: advanced,
    config: config,
  );

  test('P2-A1a canonical 48 contexts and independent seven-field M11 parity',
      () {
    expect(advanced.worldReport.seasons.length, 2);
    expect(world.clubs.length, 48);
    expect(world.leagues.length, 3);
    expect(world.leagues.every((league) => league.clubIds.length == 16), isTrue);
    for (final season in advanced.worldReport.seasons) {
      final actual = builder.build(
        seasonIndex: season.seasonIndex,
        effectiveClubs: season.clubs,
        leagues: season.leaguesBeforeSeason,
        openingFinanceStates: _originalOpeningFinance(season),
      );
      final oracle = _originalM11Contexts(season);
      expect(actual.length, 48);
      expect(oracle.length, 48);
      final ids = season.leaguesBeforeSeason
          .expand((league) => league.clubIds)
          .toList();
      expect(ids.length, 48);
      expect(ids.toSet().length, 48);
      expect(actual.map((c) => c.clubId).toSet(), ids.toSet());
      expect(
        actual.map((c) => c.clubId).toList(),
        [...ids]..sort(),
      );
      expect(
        actual.map((c) => c.signature).toList(),
        oracle.map((c) => c.signature).toList(),
      );
      for (var i = 0; i < 48; i++) {
        _assertSevenFieldParity(actual[i], oracle[i]);
        final membership = season.leaguesBeforeSeason.singleWhere(
          (league) => league.clubIds.contains(actual[i].clubId),
        );
        expect(actual[i].tier, membership.tier);
        expect(actual[i].leagueSize, membership.clubIds.length);
      }
      final snapshots = report.snapshots
          .where((item) => item.context.seasonIndex == season.seasonIndex)
          .toList();
      expect(snapshots.length, 48);
      expect(
        snapshots.map((item) => item.context.signature).toList(),
        oracle.map((context) => context.signature).toList(),
      );
    }
  });

  test('P2-A1a real opening source uses roster-derived effective clubs', () {
    final opening = const WorldOpeningStateInitializer().prepare(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
    );
    final effective = const TeamStrengthCalculator().deriveClubs(
      baseClubs: opening.baseClubs,
      players: opening.players,
    );
    final actual = builder.build(
      seasonIndex: config.seasonIndex,
      effectiveClubs: effective,
      leagues: opening.leagues,
      openingFinanceStates: opening.financeStates,
    );
    final legacySeason = advanced.worldReport.seasons.first;
    final oracle = _originalM11Contexts(legacySeason);
    expect(actual.length, 48);
    for (var i = 0; i < actual.length; i++) {
      _assertSevenFieldParity(actual[i], oracle[i]);
    }
  });

  test('P2-A1a opening finance, not closing finance, across two seasons', () {
    final first = advanced.worldReport.seasons[0];
    final second = advanced.worldReport.seasons[1];
    expect(second.seasonIndex, first.seasonIndex + 1);
    var firstClosingDiffers = false;
    var nextOpeningDiffers = false;
    for (final season in [first, second]) {
      final contexts = builder.build(
        seasonIndex: season.seasonIndex,
        effectiveClubs: season.clubs,
        leagues: season.leaguesBeforeSeason,
        openingFinanceStates: _originalOpeningFinance(season),
      );
      for (final context in contexts) {
        final finance = season.finances.singleWhere(
          (item) => item.clubId == context.clubId,
        );
        expect(context.openingCash, finance.openingCash);
        expect(context.openingDebt, finance.openingDebt);
        expect(context.signature,
            contains('cash=${finance.openingCash.minorUnits}'));
        expect(context.signature,
            contains('debt=${finance.openingDebt.minorUnits}'));
        if (season.seasonIndex == first.seasonIndex &&
            (finance.openingCash != finance.closingCash ||
                finance.openingDebt != finance.closingDebt)) {
          firstClosingDiffers = true;
        }
        if (season.seasonIndex == second.seasonIndex) {
          final old = first.finances.singleWhere(
            (item) => item.clubId == context.clubId,
          );
          if (finance.openingCash != old.openingCash ||
              finance.openingDebt != old.openingDebt) {
            nextOpeningDiffers = true;
          }
        }
      }
    }
    expect(firstClosingDiffers, isTrue);
    expect(nextOpeningDiffers, isTrue);
  });

  test('P2-A1a AI and controlled promise option, ID and target parity', () {
    const ai = PromiseGenerator();
    for (final season in advanced.worldReport.seasons) {
      final actual = builder.build(
        seasonIndex: season.seasonIndex,
        effectiveClubs: season.clubs,
        leagues: season.leaguesBeforeSeason,
        openingFinanceStates: _originalOpeningFinance(season),
      );
      final oracle = _originalM11Contexts(season);
      for (var i = 0; i < actual.length; i++) {
        final oldContext = oracle[i];
        final newContext = actual[i];
        final expectedAllowed = _originalAllowed(oldContext);
        expect(PlayerPresidentPromiseGenerator.allowedPromiseTypes(newContext),
            orderedEquals(expectedAllowed));
        final expectedAi = ai.generate(
          context: oldContext,
          careerSeed: config.careerSeed,
          simulationVersion: config.simulationVersion,
        );
        final actualAi = ai.generate(
          context: newContext,
          careerSeed: config.careerSeed,
          simulationVersion: config.simulationVersion,
        );
        expect(actualAi.id, expectedAi.id);
        expect(actualAi.type, expectedAi.type);
        expect(actualAi.targetLeaguePosition, expectedAi.targetLeaguePosition);
        expect(actualAi.targetDebtReductionBps, expectedAi.targetDebtReductionBps);
        expect(actualAi.signature, expectedAi.signature);
        expect(actualAi.id,
            'promise_${newContext.clubId}_s${newContext.seasonIndex}');
        for (final type in expectedAllowed) {
          final expected = PlayerPresidentPromiseGenerator.canonicalPromiseFor(
            context: oldContext,
            type: type,
          );
          final actualPromise =
              PlayerPresidentPromiseGenerator.canonicalPromiseFor(
            context: newContext,
            type: type,
          );
          expect(actualPromise.id, expected.id);
          expect(actualPromise.type, expected.type);
          expect(actualPromise.targetLeaguePosition,
              expected.targetLeaguePosition);
          expect(actualPromise.targetDebtReductionBps,
              expected.targetDebtReductionBps);
          expect(actualPromise.signature, expected.signature);
        }
      }
      final controlled = oracle.firstWhere(
        (context) => _originalAllowed(context).length > 1,
      );
      final choice = _originalAllowed(controlled).last;
      final originalControlled = PlayerPresidentPromiseGenerator(
        controlledClubId: controlled.clubId,
        decisionProvider: _FixedChoice(choice),
      );
      final newControlled = PlayerPresidentPromiseGenerator(
        controlledClubId: controlled.clubId,
        decisionProvider: _FixedChoice(choice),
      );
      for (var i = 0; i < 48; i++) {
        final oldPromise = originalControlled.generate(
          context: oracle[i],
          careerSeed: config.careerSeed,
          simulationVersion: config.simulationVersion,
        );
        final newPromise = newControlled.generate(
          context: actual[i],
          careerSeed: config.careerSeed,
          simulationVersion: config.simulationVersion,
        );
        expect(newPromise.signature, oldPromise.signature);
        if (actual[i].clubId == controlled.clubId) {
          expect(newPromise.type, choice);
        } else {
          expect(newPromise.signature, ai.generate(
            context: oracle[i],
            careerSeed: config.careerSeed,
            simulationVersion: config.simulationVersion,
          ).signature);
        }
      }
    }
  });

  test('P2-A1a full legacy report agrees with independent old M11 oracle', () {
    const ai = PromiseGenerator();
    const resolver = PromiseResolver();
    final expectedSignature = StringBuffer(advanced.signature);
    var total = 0;
    for (final season in advanced.worldReport.seasons) {
      for (final context in _originalM11Contexts(season)) {
        final promise = ai.generate(
          context: context,
          careerSeed: config.careerSeed,
          simulationVersion: config.simulationVersion,
        );
        final outcome = _originalM11Outcome(season, context);
        final resolution = resolver.resolve(promise: promise, outcome: outcome);
        final expected = PromiseSeasonSnapshot(
          context: context,
          promise: promise,
          outcome: outcome,
          resolution: resolution,
        );
        final actual = report.snapshots[total++];
        _assertSevenFieldParity(actual.context, expected.context);
        expect(actual.promise.signature, expected.promise.signature);
        expect(actual.outcome.signature, expected.outcome.signature);
        expect(actual.resolution.signature, expected.resolution.signature);
        expect(actual.signature, expected.signature);
        expectedSignature.write('|promise=${expected.signature}');
      }
    }
    expect(total, 96);
    expect(report.totalPromises, total);
    expect(report.signature, expectedSignature.toString());
    expect(const PromiseCareerValidator().validate(report), isEmpty);
  });

  test('P2-A1a exact strength tie-break and sorted context output', () {
    const clubs = [
      Club(id: 'z', name: 'Z', strength: 72),
      Club(id: 'b', name: 'B', strength: 80),
      Club(id: 'a', name: 'A', strength: 80),
      Club(id: 'q', name: 'Q', strength: 60),
    ];
    final leagues = [
      WorldLeague(tier: LeagueTier.first, clubIds: ['z', 'b', 'a', 'q']),
    ];
    const finances = [
      ClubFinanceState(clubId: 'a', cash: Money.zero, debt: Money.zero),
      ClubFinanceState(clubId: 'b', cash: Money.zero, debt: Money.zero),
      ClubFinanceState(clubId: 'q', cash: Money.zero, debt: Money.zero),
      ClubFinanceState(clubId: 'z', cash: Money.zero, debt: Money.zero),
    ];
    final actual = builder.build(
      seasonIndex: 7,
      effectiveClubs: clubs,
      leagues: leagues,
      openingFinanceStates: finances,
    );
    expect(actual.map((c) => c.clubId).toList(), ['a', 'b', 'q', 'z']);
    expect({for (final c in actual) c.clubId: c.expectedPosition},
        {'a': 1, 'b': 2, 'q': 4, 'z': 3});
    expect(actual.every((c) => c.seasonIndex == 7 && c.leagueSize == 4),
        isTrue);
    expect(() => actual.clear(), throwsUnsupportedError);
  });

  test('P2-A1a rejects malformed or ambiguous preseason sources', () {
    const clubs = [
      Club(id: 'a', name: 'A', strength: 80),
      Club(id: 'b', name: 'B', strength: 70),
    ];
    final leagues = [
      WorldLeague(tier: LeagueTier.first, clubIds: ['a', 'b']),
    ];
    const finances = [
      ClubFinanceState(clubId: 'a', cash: Money.zero, debt: Money.zero),
      ClubFinanceState(clubId: 'b', cash: Money.zero, debt: Money.zero),
    ];
    void invalid({
      int seasonIndex = 0,
      Iterable<Club> effectiveClubs = clubs,
      Iterable<WorldLeague>? leagueInput,
      Iterable<ClubFinanceState> financeInput = finances,
    }) {
      expect(() => builder.build(
        seasonIndex: seasonIndex,
        effectiveClubs: effectiveClubs,
        leagues: leagueInput ?? leagues,
        openingFinanceStates: financeInput,
      ), throwsArgumentError);
    }

    invalid(seasonIndex: -1);
    invalid(effectiveClubs: []);
    invalid(effectiveClubs: [clubs.first]);
    invalid(effectiveClubs: [...clubs, clubs.first]);
    invalid(effectiveClubs: [clubs.first,
        const Club(id: 'b', name: 'B', strength: double.nan)]);
    invalid(financeInput: [finances.first]);
    invalid(financeInput: [...finances, finances.first]);
    invalid(financeInput: [
      finances.first,
      const ClubFinanceState(
          clubId: 'other', cash: Money.zero, debt: Money.zero),
    ]);
    invalid(leagueInput: []);
    invalid(leagueInput: [
      WorldLeague(tier: LeagueTier.first, clubIds: ['a']),
    ]);
    invalid(leagueInput: [
      WorldLeague(tier: LeagueTier.first, clubIds: ['a', 'a']),
    ]);
    invalid(leagueInput: [
      WorldLeague(tier: LeagueTier.first, clubIds: ['a', 'unknown']),
    ]);
    invalid(leagueInput: [
      WorldLeague(tier: LeagueTier.first, clubIds: []),
      WorldLeague(tier: LeagueTier.second, clubIds: ['a', 'b']),
    ]);
    invalid(leagueInput: [
      WorldLeague(tier: LeagueTier.first, clubIds: ['a']),
      WorldLeague(tier: LeagueTier.first, clubIds: ['b']),
    ]);
    invalid(leagueInput: [
      WorldLeague(tier: LeagueTier.first, clubIds: ['a', 'b']),
      WorldLeague(tier: LeagueTier.second, clubIds: ['a']),
    ]);
  });
}
