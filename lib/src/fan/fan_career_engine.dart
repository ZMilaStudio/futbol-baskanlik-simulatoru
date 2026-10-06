import '../core/money.dart';
import '../core/simulation_config.dart';
import '../league/club.dart';
import '../transfer/advanced_transfer_career_report.dart';
import '../transfer/advanced_transfer_world_career_engine.dart';
import '../transfer/loan_agreement.dart';
import '../world/world_career_hooks.dart';
import '../world/world_career_season.dart';
import '../world/world_league.dart';
import 'fan_career_report.dart';
import 'fan_expectation_engine.dart';
import 'fan_season_context.dart';
import 'fan_season_snapshot.dart';
import 'fan_state.dart';
import 'fan_trust_engine.dart';
import 'fan_trust_reason.dart';

typedef FanExtraReasonProvider = Iterable<FanTrustReason> Function(
  FanSeasonContext context,
);

class FanCareerEngine {
  const FanCareerEngine({
    this.advancedEngine = const AdvancedTransferWorldCareerEngine(),
    this.expectationEngine = const FanExpectationEngine(),
    this.trustEngine = const FanTrustEngine(),
  });

  final AdvancedTransferWorldCareerEngine advancedEngine;
  final FanExpectationEngine expectationEngine;
  final FanTrustEngine trustEngine;

  FanSeasonSnapshot projectSeason({
    required FanState priorState,
    required WorldCareerSeason season,
    required Iterable<LoanAgreement> loanHistory,
    required bool hasNextSeason,
    FanExtraReasonProvider? extraReasonProvider,
  }) {
    final context = buildSeasonContext(
      season: season,
      clubId: priorState.clubId,
      loanHistory: loanHistory,
      hasNextSeason: hasNextSeason,
    );
    final expectation = expectationEngine.generate(context);
    final reasons = <FanTrustReason>[
      ...trustEngine.evaluate(context: context, expectation: expectation),
      if (extraReasonProvider != null) ...extraReasonProvider(context),
    ];
    return FanSeasonSnapshot(
      context: context,
      expectation: expectation,
      state: priorState.apply(reasons),
      reasons: reasons,
    );
  }

  FanCareerReport simulate({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
    WorldCareerHooks hooks = const NoopWorldCareerHooks(),
    FanExtraReasonProvider? extraReasonProvider,
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
      extraReasonProvider: extraReasonProvider,
    );
  }

  FanCareerReport simulateFromAdvancedReport({
    required AdvancedTransferCareerReport advancedReport,
    FanExtraReasonProvider? extraReasonProvider,
    bool hasFutureSeasonAfterReport = false,
  }) {
    final worldReport = advancedReport.worldReport;
    final clubIds = worldReport.initialLeagues
        .expand((league) => league.clubIds)
        .toSet()
        .toList()
      ..sort();
    final states = {
      for (final clubId in clubIds) clubId: FanState.initial(clubId),
    };
    final snapshots = <FanSeasonSnapshot>[];
    final lastSeasonIndex = worldReport.seasons.last.seasonIndex;

    for (final season in worldReport.seasons) {
      final seasonClubIds = season.clubs.map((club) => club.id).toList()
        ..sort();
      for (final clubId in seasonClubIds) {
        final snapshot = projectSeason(
          priorState: states[clubId]!,
          season: season,
          loanHistory: advancedReport.loanHistory,
          hasNextSeason: season.seasonIndex < lastSeasonIndex ||
              hasFutureSeasonAfterReport,
          extraReasonProvider: extraReasonProvider,
        );
        states[clubId] = snapshot.state;
        snapshots.add(snapshot);
      }
    }

    final finalStates = states.values.toList()
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    return FanCareerReport(
      advancedTransferReport: advancedReport,
      snapshots: snapshots,
      finalStates: finalStates,
    );
  }

  /// Read-only calculation view: neither this view nor WorldCareerSeason is
  /// accepted as ownership authority by a runtime transition.
  FanSeasonContext buildSeasonContext({
    required WorldCareerSeason season,
    required String clubId,
    required Iterable<LoanAgreement> loanHistory,
    required bool hasNextSeason,
  }) {
    final league = season.leaguesBeforeSeason.firstWhere(
      (item) => item.clubIds.contains(clubId),
    );
    final leagueResult = season.leagueResults.firstWhere(
      (item) => item.tier == league.tier,
    );
    final positionIndex = leagueResult.report.table.indexWhere(
      (row) => row.clubId == clubId,
    );
    if (positionIndex < 0) {
      throw StateError('Missing league row for $clubId.');
    }
    final finance = season.finances.firstWhere(
      (item) => item.clubId == clubId,
    );
    final club = season.clubs.firstWhere((item) => item.id == clubId);

    var promoted = false;
    var relegated = false;
    for (final movement in season.movementsAfterSeason) {
      if (movement.clubId != clubId) continue;
      promoted = movement.to.level < movement.from.level;
      relegated = movement.to.level > movement.from.level;
      break;
    }

    var permanentBuys = 0;
    var permanentSales = 0;
    var installmentBuys = 0;
    var transferSpend = Money.zero;
    var transferIncome = Money.zero;
    for (final deal in season.transfersAfterSeason) {
      if (deal.toClubId == clubId) {
        permanentBuys++;
        transferSpend += deal.fee;
        if (deal.isInstallmentDeal) installmentBuys++;
      }
      if (deal.fromClubId == clubId) {
        permanentSales++;
        transferIncome += deal.fee;
      }
    }

    final nextSeasonIndex = season.seasonIndex + 1;
    var loanIns = 0;
    var loanOuts = 0;
    for (final loan in loanHistory) {
      if (loan.startSeasonIndex != nextSeasonIndex) continue;
      if (loan.loanClubId == clubId) loanIns++;
      if (loan.parentClubId == clubId) loanOuts++;
    }

    return FanSeasonContext(
      clubId: clubId,
      seasonIndex: season.seasonIndex,
      tier: league.tier,
      leaguePosition: positionIndex + 1,
      leagueSize: league.clubIds.length,
      clubStrength: club.strength,
      financialHealth: finance.health,
      closingCash: finance.closingCash,
      closingDebt: finance.closingDebt,
      emergencyBorrowing: finance.emergencyBorrowing,
      permanentBuys: permanentBuys,
      permanentSales: permanentSales,
      installmentBuys: installmentBuys,
      loanIns: loanIns,
      loanOuts: loanOuts,
      transferSpend: transferSpend,
      transferIncome: transferIncome,
      promoted: promoted,
      relegated: relegated,
      hasTransferWindow: hasNextSeason,
    );
  }
}
