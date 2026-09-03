import 'dart:math' as math;

import '../core/money.dart';
import '../core/seeded_rng.dart';
import '../core/stable_hash.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../season/season_report.dart';
import 'club_finance_season.dart';
import 'club_finance_state.dart';
import 'financial_health.dart';
import 'wage_model.dart';

class BasicEconomyEngine {
  const BasicEconomyEngine({this.wageModel = const WageModel()});

  final WageModel wageModel;

  List<ClubFinanceState> initialStates({
    required List<Club> clubs,
    required int careerSeed,
    required int simulationVersion,
    int economicScaleBps = 10000,
  }) {
    _validateEconomicScale(economicScaleBps);
    return List.unmodifiable(
      clubs.map((club) {
        final deltaHundredths =
            math.max(0, (club.strength * 100).round() - 5500);
        final rng = SeededRng(
          StableHash.combine32([
            careerSeed,
            simulationVersion,
            StableHash.string32(club.id),
            StableHash.string32('initial-finance-state'),
          ]),
        );

        final cashBase = 10000000 + deltaHundredths * 9000;
        final cashModifierBps =
            9000 + (rng.nextDouble() * 2000).floor();
        final debtBase = 7000000 + deltaHundredths * 6500;
        final debtModifierBps =
            7500 + (rng.nextDouble() * 7000).floor();

        return ClubFinanceState(
          clubId: club.id,
          cash: Money.fromUnits(
            (cashBase * cashModifierBps) ~/ 10000,
          ).scaleBasisPoints(economicScaleBps),
          debt: Money.fromUnits(
            (debtBase * debtModifierBps) ~/ 10000,
          ).scaleBasisPoints(economicScaleBps),
        );
      }),
    );
  }

  List<ClubFinanceSeason> simulateSeason({
    required List<Club> clubs,
    required List<Player> players,
    required SeasonReport seasonReport,
    required List<ClubFinanceState> openingStates,
    int economicScaleBps = 10000,
  }) {
    _validateEconomicScale(economicScaleBps);
    final clubById = {for (final club in clubs) club.id: club};
    final stateById = {
      for (final state in openingStates) state.clubId: state,
    };
    final playersByClub = <String, List<Player>>{};
    for (final player in players) {
      playersByClub.putIfAbsent(player.clubId, () => []).add(player);
    }
    final positionByClub = <String, int>{};
    for (var i = 0; i < seasonReport.table.length; i++) {
      positionByClub[seasonReport.table[i].clubId] = i + 1;
    }

    final results = <ClubFinanceSeason>[];
    for (final clubId in clubById.keys) {
      final club = clubById[clubId]!;
      final opening = stateById[clubId];
      if (opening == null) {
        throw StateError('Missing opening finance state for $clubId.');
      }

      final strengthDeltaHundredths =
          math.max(0, (club.strength * 100).round() - 5500);
      final squad = playersByClub[clubId] ?? const <Player>[];

      final centralRevenue = const Money.fromUnits(12000000)
          .scaleBasisPoints(economicScaleBps);
      final sponsorRevenue = Money.fromUnits(
        4000000 + strengthDeltaHundredths * 3500,
      ).scaleBasisPoints(economicScaleBps);
      final matchdayRevenue = Money.fromUnits(
        4000000 + strengthDeltaHundredths * 2200,
      ).scaleBasisPoints(economicScaleBps);
      final prizeRevenue = Money.fromUnits(
        _prizeForPosition(positionByClub[clubId] ?? 16),
      ).scaleBasisPoints(economicScaleBps);

      final wageExpense = wageModel.annualSquadWages(squad);
      final operatingExpense = Money.fromUnits(
        13000000 + strengthDeltaHundredths * 3000,
      ).scaleBasisPoints(economicScaleBps);
      final interestExpense = opening.debt.scaleBasisPoints(500);

      final principalRepaid = opening.debt.scaleBasisPoints(500);
      final cashBeforeEmergency =
          opening.cash +
          centralRevenue +
          sponsorRevenue +
          matchdayRevenue +
          prizeRevenue -
          wageExpense -
          operatingExpense -
          interestExpense -
          principalRepaid;
      final debtBeforeEmergency = opening.debt - principalRepaid;

      const minimumCash = Money.fromUnits(2000000);
      final emergencyBorrowing = cashBeforeEmergency < minimumCash
          ? minimumCash - cashBeforeEmergency
          : Money.zero;

      final closingCash = cashBeforeEmergency + emergencyBorrowing;
      final closingDebt = debtBeforeEmergency + emergencyBorrowing;
      final totalRevenue =
          centralRevenue + sponsorRevenue + matchdayRevenue + prizeRevenue;
      final pAndLExpenses =
          wageExpense + operatingExpense + interestExpense;

      results.add(
        ClubFinanceSeason(
          clubId: clubId,
          openingCash: opening.cash,
          openingDebt: opening.debt,
          centralRevenue: centralRevenue,
          sponsorRevenue: sponsorRevenue,
          matchdayRevenue: matchdayRevenue,
          prizeRevenue: prizeRevenue,
          wageExpense: wageExpense,
          operatingExpense: operatingExpense,
          interestExpense: interestExpense,
          principalRepaid: principalRepaid,
          emergencyBorrowing: emergencyBorrowing,
          closingCash: closingCash,
          closingDebt: closingDebt,
          health: _health(
            cash: closingCash,
            debt: closingDebt,
            annualRevenue: totalRevenue,
            annualExpenses: pAndLExpenses,
            emergencyBorrowing: emergencyBorrowing,
          ),
        ),
      );
    }

    return List.unmodifiable(results);
  }

  static void _validateEconomicScale(int economicScaleBps) {
    if (economicScaleBps <= 0) {
      throw ArgumentError.value(
        economicScaleBps,
        'economicScaleBps',
        'Must be positive.',
      );
    }
  }

  static int _prizeForPosition(int position) => switch (position) {
        1 => 8000000,
        2 => 6000000,
        3 => 4500000,
        4 => 3500000,
        5 => 2750000,
        6 => 2000000,
        7 => 1250000,
        _ => 750000,
      };

  static FinancialHealth _health({
    required Money cash,
    required Money debt,
    required Money annualRevenue,
    required Money annualExpenses,
    required Money emergencyBorrowing,
  }) {
    if (emergencyBorrowing > Money.zero) {
      return FinancialHealth.debtCrisis;
    }

    final revenue = math.max(1, annualRevenue.minorUnits);
    final expenses = math.max(1, annualExpenses.minorUnits);
    final debtToRevenueBps = (debt.minorUnits * 10000) ~/ revenue;
    final cashCoverageBps = (cash.minorUnits * 10000) ~/ expenses;

    if (debtToRevenueBps <= 2000 && cashCoverageBps >= 7500) {
      return FinancialHealth.veryStrong;
    }
    if (debtToRevenueBps <= 5000 && cashCoverageBps >= 4000) {
      return FinancialHealth.solid;
    }
    if (debtToRevenueBps <= 9000) {
      return FinancialHealth.balanced;
    }
    if (debtToRevenueBps <= 15000) {
      return FinancialHealth.tight;
    }
    return FinancialHealth.debtCrisis;
  }
}
