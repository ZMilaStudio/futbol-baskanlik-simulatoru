import '../core/simulation_config.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../transfer/advanced_transfer_career_report.dart';
import '../transfer/advanced_transfer_world_career_engine.dart';
import '../world/world_career_hooks.dart';
import '../world/world_league.dart';
import 'promise_career_report.dart';
import 'promise_context.dart';
import 'promise_generator.dart';
import 'promise_opening_context_builder.dart';
import 'promise_resolver.dart';
import 'promise_season_snapshot.dart';

class PromiseCareerEngine {
  const PromiseCareerEngine({
    this.advancedEngine = const AdvancedTransferWorldCareerEngine(),
    this.generator = const PromiseGenerator(),
    this.resolver = const PromiseResolver(),
  });

  final AdvancedTransferWorldCareerEngine advancedEngine;
  final PromiseGenerator generator;
  final PromiseResolver resolver;

  PromiseCareerReport simulate({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
    WorldCareerHooks hooks = const NoopWorldCareerHooks(),
  }) {
    final advancedReport = advancedEngine.simulate(
      clubs: clubs,
      leagues: leagues,
      config: config,
      seasonCount: seasonCount,
      hooks: hooks,
    );
    return simulateFromAdvancedReport(
      advancedReport: advancedReport,
      config: config,
    );
  }

  PromiseCareerReport simulateFromAdvancedReport({
    required AdvancedTransferCareerReport advancedReport,
    required SimulationConfig config,
  }) {
    final snapshots = <PromiseSeasonSnapshot>[];

    for (final season in advancedReport.worldReport.seasons) {
      final contexts = const PromiseOpeningContextBuilder().build(
        seasonIndex: season.seasonIndex,
        effectiveClubs: season.clubs,
        leagues: season.leaguesBeforeSeason,
        openingFinanceStates: [
          for (final finance in season.finances)
            ClubFinanceState(
              clubId: finance.clubId,
              cash: finance.openingCash,
              debt: finance.openingDebt,
            ),
        ],
      );

      // The builder retains the legacy club-ID ascending snapshot order.
      for (final context in contexts) {
        final clubId = context.clubId;
        final league = season.leaguesBeforeSeason.firstWhere(
          (item) => item.tier == context.tier,
        );
        final leagueResult = season.leagueResults.firstWhere(
          (item) => item.tier == league.tier,
        );
        final actualIndex = leagueResult.report.table.indexWhere(
          (row) => row.clubId == clubId,
        );
        if (actualIndex < 0) {
          throw StateError('Missing league row for $clubId.');
        }
        final finance = season.finances.firstWhere(
          (item) => item.clubId == clubId,
        );

        var promoted = false;
        var relegated = false;
        for (final movement in season.movementsAfterSeason) {
          if (movement.clubId != clubId) continue;
          promoted = movement.to.level < movement.from.level;
          relegated = movement.to.level > movement.from.level;
          break;
        }

        final promise = generator.generate(
          context: context,
          careerSeed: config.careerSeed,
          simulationVersion: config.simulationVersion,
        );
        final outcome = PresidentPromiseOutcome(
          clubId: clubId,
          seasonIndex: season.seasonIndex,
          leaguePosition: actualIndex + 1,
          leagueSize: league.clubIds.length,
          openingDebt: finance.openingDebt,
          closingDebt: finance.closingDebt,
          emergencyBorrowing: finance.emergencyBorrowing,
          promoted: promoted,
          relegated: relegated,
        );
        final resolution = resolver.resolve(
          promise: promise,
          outcome: outcome,
        );
        snapshots.add(PromiseSeasonSnapshot(
          context: context,
          promise: promise,
          outcome: outcome,
          resolution: resolution,
        ));
      }
    }

    return PromiseCareerReport(
      advancedTransferReport: advancedReport,
      snapshots: snapshots,
    );
  }

}
