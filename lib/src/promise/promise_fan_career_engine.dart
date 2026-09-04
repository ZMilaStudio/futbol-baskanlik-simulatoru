import '../core/simulation_config.dart';
import '../fan/fan_career_engine.dart';
import '../league/club.dart';
import '../transfer/advanced_transfer_world_career_engine.dart';
import '../world/world_career_hooks.dart';
import '../world/world_league.dart';
import 'promise_career_engine.dart';
import 'promise_fan_career_report.dart';
import 'promise_fan_impact_engine.dart';

class PromiseFanCareerEngine {
  const PromiseFanCareerEngine({
    this.advancedEngine = const AdvancedTransferWorldCareerEngine(),
    this.promiseEngine = const PromiseCareerEngine(),
    this.fanEngine = const FanCareerEngine(),
    this.impactEngine = const PromiseFanImpactEngine(),
  });

  final AdvancedTransferWorldCareerEngine advancedEngine;
  final PromiseCareerEngine promiseEngine;
  final FanCareerEngine fanEngine;
  final PromiseFanImpactEngine impactEngine;

  PromiseFanCareerReport simulate({
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
    final promiseReport = promiseEngine.simulateFromAdvancedReport(
      advancedReport: advancedReport,
      config: config,
    );
    final baselineFanReport = fanEngine.simulateFromAdvancedReport(
      advancedReport: advancedReport,
    );
    final promiseByClubSeason = {
      for (final snapshot in promiseReport.snapshots)
        '${snapshot.context.seasonIndex}|${snapshot.context.clubId}': snapshot,
    };
    final fanReport = fanEngine.simulateFromAdvancedReport(
      advancedReport: advancedReport,
      extraReasonProvider: (context) {
        final key = '${context.seasonIndex}|${context.clubId}';
        final promiseSnapshot = promiseByClubSeason[key];
        if (promiseSnapshot == null) {
          throw StateError('Missing promise resolution for fan context $key.');
        }
        return impactEngine.evaluate(promiseSnapshot.resolution);
      },
    );

    return PromiseFanCareerReport(
      promiseReport: promiseReport,
      baselineFanReport: baselineFanReport,
      fanReport: fanReport,
    );
  }
}
