import '../core/money.dart';
import '../finance/club_finance_state.dart';
import '../season/season_validator.dart';
import 'league_tier.dart';
import 'world_career_report.dart';
import 'world_career_season.dart';
import 'world_league.dart';

class WorldCareerValidator {
  const WorldCareerValidator({this.seasonValidator = const SeasonValidator()});

  final SeasonValidator seasonValidator;

  List<String> validate(WorldCareerReport report) {
    final issues = <String>[];
    if (report.seasons.isEmpty) {
      issues.add('World career has no seasons.');
      return issues;
    }
    if (report.initialClubCount != 48) {
      issues.add('M5 world must contain exactly 48 clubs.');
    }
    issues.addAll(_validateLeagues(report.initialLeagues, label: 'initial'));

    for (var i = 0; i < report.seasons.length; i++) {
      final season = report.seasons[i];
      final expectedSeasonIndex = report.seasons.first.seasonIndex + i;
      if (season.seasonIndex != expectedSeasonIndex) {
        issues.add('Season $i has invalid season index.');
      }
      issues.addAll(
        _validateLeagues(
          season.leaguesBeforeSeason,
          label: 'season ${season.seasonIndex} opening',
        ),
      );
      if (season.leagueResults.length != LeagueTier.values.length) {
        issues.add('Season ${season.seasonIndex} must contain 3 league reports.');
      }
      final tiers = season.leagueResults.map((result) => result.tier).toSet();
      if (tiers.length != LeagueTier.values.length ||
          !tiers.containsAll(LeagueTier.values)) {
        issues.add('Season ${season.seasonIndex} league report tiers are invalid.');
      }
      for (final result in season.leagueResults) {
        for (final issue in seasonValidator.validate(result.report)) {
          issues.add(
            'Season ${season.seasonIndex} ${result.tier.displayName}: $issue',
          );
        }
        if (result.report.table.length != 16) {
          issues.add(
            'Season ${season.seasonIndex} ${result.tier.displayName} must have 16 clubs.',
          );
        }
        if (result.report.matchCount != 240) {
          issues.add(
            'Season ${season.seasonIndex} ${result.tier.displayName} must have 240 matches.',
          );
        }
      }
      if (season.matchCount != 720) {
        issues.add('Season ${season.seasonIndex} must have 720 matches.');
      }
      if (season.clubs.length != 48 ||
          season.clubs.map((club) => club.id).toSet().length != 48) {
        issues.add('Season ${season.seasonIndex} club set is invalid.');
      }
      issues.addAll(_validatePlayers(season));
      issues.addAll(_validateFinances(report, season, i));

      if (i < report.seasons.length - 1) {
        issues.addAll(_validateMovement(season));
        final next = report.seasons[i + 1];
        if (!_sameLeagues(
          season.leaguesAfterTransition,
          next.leaguesBeforeSeason,
        )) {
          issues.add(
            'Season ${season.seasonIndex} league continuity failed.',
          );
        }
        final currentIds = season.players.map((player) => player.id).toSet();
        final retiredIds =
            season.retiredAfterSeason.map((player) => player.id).toSet();
        final youthIds =
            season.youthIntakeAfterSeason.map((player) => player.id).toSet();
        final expectedNextIds = <String>{
          ...currentIds.where((id) => !retiredIds.contains(id)),
          ...youthIds,
        };
        final actualNextIds = next.players.map((player) => player.id).toSet();
        if (expectedNextIds.length != actualNextIds.length ||
            !expectedNextIds.containsAll(actualNextIds)) {
          issues.add(
            'Season ${season.seasonIndex} player conservation failed.',
          );
        }
        if (season.youthIntakeAfterSeason.length != 48) {
          issues.add(
            'Season ${season.seasonIndex} must generate 48 youth players.',
          );
        }
      } else {
        if (season.movementsAfterSeason.isNotEmpty ||
            season.retiredAfterSeason.isNotEmpty ||
            season.youthIntakeAfterSeason.isNotEmpty ||
            season.transfersAfterSeason.isNotEmpty ||
            season.cashMovementsAfterWindow.isNotEmpty) {
          issues.add('Final season must not apply an off-season transition.');
        }
      }
    }

    if (report.totalMatches != report.seasonCount * 720) {
      issues.add('World career total match count is invalid.');
    }
    if (report.totalMovements != (report.seasonCount - 1) * 12) {
      issues.add('World career movement count is invalid.');
    }
    final expectedFinalPlayerCount = report.initialPlayerCount -
        report.totalRetirements +
        report.totalYouthIntakes;
    if (report.finalPlayers.length != expectedFinalPlayerCount) {
      issues.add('Final player count conservation failed.');
    }
    final finalPlayerIds = report.finalPlayers.map((player) => player.id).toSet();
    final lastPlayerIds =
        report.seasons.last.players.map((player) => player.id).toSet();
    if (finalPlayerIds.length != lastPlayerIds.length ||
        !finalPlayerIds.containsAll(lastPlayerIds)) {
      issues.add('Final players do not match final season pool.');
    }
    if (!_sameLeagues(report.finalLeagues, report.seasons.last.leaguesAfterTransition)) {
      issues.add('Final league membership mismatch.');
    }
    issues.addAll(_validateLeagues(report.finalLeagues, label: 'final'));
    return issues;
  }

  List<String> _validatePlayers(WorldCareerSeason season) {
    final issues = <String>[];
    final ids = season.players.map((player) => player.id).toList();
    if (ids.toSet().length != ids.length) {
      issues.add('Season ${season.seasonIndex} contains duplicate player IDs.');
    }
    final clubIds = season.clubs.map((club) => club.id).toSet();
    for (final player in season.players) {
      if (!player.isFreeAgent && !clubIds.contains(player.clubId)) {
        issues.add(
          'Season ${season.seasonIndex} player ${player.id} has unknown club.',
        );
      }
      if (player.age < 16 || player.age >= player.retirementAge) {
        issues.add(
          'Season ${season.seasonIndex} player ${player.id} has invalid age.',
        );
      }
      if (player.ability < 35 || player.ability > 95 ||
          player.potential < player.ability || player.potential > 95) {
        issues.add(
          'Season ${season.seasonIndex} player ${player.id} has invalid ability.',
        );
      }
    }
    for (final clubId in clubIds) {
      final count = season.players.where((player) => player.clubId == clubId).length;
      if (count < 11) {
        issues.add(
          'Season ${season.seasonIndex} club $clubId has fewer than 11 players.',
        );
      }
    }
    return issues;
  }

  List<String> _validateFinances(
    WorldCareerReport report,
    WorldCareerSeason season,
    int seasonOffset,
  ) {
    final issues = <String>[];
    if (season.finances.length != 48 ||
        season.finances.map((finance) => finance.clubId).toSet().length != 48) {
      issues.add('Season ${season.seasonIndex} finance set is invalid.');
      return issues;
    }
    final closingByClub = {
      for (final finance in season.finances)
        finance.clubId: ClubFinanceState(
          clubId: finance.clubId,
          cash: finance.closingCash,
          debt: finance.closingDebt,
        ),
    };
    final afterByClub = {
      for (final state in season.financeStatesAfterWindow) state.clubId: state,
    };
    final expectedCash = {
      for (final entry in closingByClub.entries) entry.key: entry.value.cash,
    };
    final movedPlayers = <String>{};
    for (final deal in season.transfersAfterSeason) {
      if (!movedPlayers.add(deal.playerId)) {
        issues.add(
          'Season ${season.seasonIndex} player ${deal.playerId} transferred twice.',
        );
      }
      if (deal.fromClubId == deal.toClubId ||
          deal.fee <= Money.zero ||
          deal.upfrontFee <= Money.zero ||
          deal.upfrontFee > deal.fee) {
        issues.add('Season ${season.seasonIndex} contains invalid transfer.');
        continue;
      }
      if (closingByClub[deal.fromClubId] == null ||
          closingByClub[deal.toClubId] == null) {
        issues.add('Season ${season.seasonIndex} transfer references unknown club.');
        continue;
      }
      final futureTotal = deal.futureInstallmentTotal;
      if (deal.upfrontFee + futureTotal != deal.fee) {
        issues.add(
          'Season ${season.seasonIndex} installment total mismatch ${deal.playerId}.',
        );
      }
      for (final installment in deal.installments) {
        if (installment.amount <= Money.zero ||
            installment.dueSeasonIndex <= season.seasonIndex) {
          issues.add(
            'Season ${season.seasonIndex} invalid installment ${deal.playerId}.',
          );
        }
      }
      expectedCash[deal.fromClubId] =
          expectedCash[deal.fromClubId]! + deal.upfrontFee;
      expectedCash[deal.toClubId] =
          expectedCash[deal.toClubId]! - deal.upfrontFee;
    }
    for (final movement in season.cashMovementsAfterWindow) {
      if (movement.fromClubId == movement.toClubId ||
          movement.amount <= Money.zero ||
          closingByClub[movement.fromClubId] == null ||
          closingByClub[movement.toClubId] == null) {
        issues.add(
          'Season ${season.seasonIndex} invalid transfer cash movement.',
        );
        continue;
      }
      expectedCash[movement.fromClubId] =
          expectedCash[movement.fromClubId]! - movement.amount;
      expectedCash[movement.toClubId] =
          expectedCash[movement.toClubId]! + movement.amount;
    }
    for (final entry in closingByClub.entries) {
      final post = afterByClub[entry.key];
      if (post == null) {
        issues.add(
          'Season ${season.seasonIndex} missing post-window finance ${entry.key}.',
        );
        continue;
      }
      if (post.cash != expectedCash[entry.key]) {
        issues.add(
          'Season ${season.seasonIndex} transfer cash mismatch ${entry.key}.',
        );
      }
      if (post.debt != entry.value.debt) {
        issues.add(
          'Season ${season.seasonIndex} transfer changed debt ${entry.key}.',
        );
      }
      if (post.cash < Money.zero || post.debt < Money.zero) {
        issues.add(
          'Season ${season.seasonIndex} negative finance ${entry.key}.',
        );
      }
    }
    if (seasonOffset + 1 < report.seasons.length) {
      final next = report.seasons[seasonOffset + 1];
      final nextOpening = {
        for (final finance in next.finances) finance.clubId: finance,
      };
      for (final state in season.financeStatesAfterWindow) {
        final opening = nextOpening[state.clubId];
        if (opening == null ||
            opening.openingCash != state.cash ||
            opening.openingDebt != state.debt) {
          issues.add(
            'Season ${next.seasonIndex} opening finance continuity failed ${state.clubId}.',
          );
        }
      }
    } else {
      final finalByClub = {
        for (final state in report.finalFinanceStates) state.clubId: state,
      };
      for (final state in season.financeStatesAfterWindow) {
        final finalState = finalByClub[state.clubId];
        if (finalState == null ||
            finalState.cash != state.cash ||
            finalState.debt != state.debt) {
          issues.add('Final finance state mismatch ${state.clubId}.');
        }
      }
    }
    return issues;
  }

  List<String> _validateMovement(WorldCareerSeason season) {
    final issues = <String>[];
    if (season.movementsAfterSeason.length != 12) {
      issues.add('Season ${season.seasonIndex} must have 12 league movements.');
      return issues;
    }
    final movementClubIds =
        season.movementsAfterSeason.map((movement) => movement.clubId).toList();
    if (movementClubIds.toSet().length != movementClubIds.length) {
      issues.add('Season ${season.seasonIndex} moves a club more than once.');
    }
    final beforeTierByClub = <String, LeagueTier>{};
    for (final league in season.leaguesBeforeSeason) {
      for (final clubId in league.clubIds) {
        beforeTierByClub[clubId] = league.tier;
      }
    }
    final afterTierByClub = <String, LeagueTier>{};
    for (final league in season.leaguesAfterTransition) {
      for (final clubId in league.clubIds) {
        afterTierByClub[clubId] = league.tier;
      }
    }
    for (final movement in season.movementsAfterSeason) {
      if ((movement.from.level - movement.to.level).abs() != 1) {
        issues.add('Season ${season.seasonIndex} has non-adjacent movement.');
      }
      if (beforeTierByClub[movement.clubId] != movement.from ||
          afterTierByClub[movement.clubId] != movement.to) {
        issues.add(
          'Season ${season.seasonIndex} movement membership mismatch ${movement.clubId}.',
        );
      }
    }

    final resultByTier = {
      for (final result in season.leagueResults) result.tier: result.report,
    };
    final expected = <String, String>{};
    final firstTable = resultByTier[LeagueTier.first]!.table;
    final secondTable = resultByTier[LeagueTier.second]!.table;
    final thirdTable = resultByTier[LeagueTier.third]!.table;
    for (final row in firstTable.skip(firstTable.length - 3)) {
      expected[row.clubId] = '1>2';
    }
    for (final row in secondTable.take(3)) {
      expected[row.clubId] = '2>1';
    }
    for (final row in secondTable.skip(secondTable.length - 3)) {
      expected[row.clubId] = '2>3';
    }
    for (final row in thirdTable.take(3)) {
      expected[row.clubId] = '3>2';
    }
    for (final movement in season.movementsAfterSeason) {
      final signature = '${movement.from.level}>${movement.to.level}';
      if (expected[movement.clubId] != signature) {
        issues.add(
          'Season ${season.seasonIndex} movement result mismatch ${movement.clubId}.',
        );
      }
    }
    issues.addAll(
      _validateLeagues(
        season.leaguesAfterTransition,
        label: 'season ${season.seasonIndex} transition',
      ),
    );
    return issues;
  }

  List<String> _validateLeagues(
    List<WorldLeague> leagues, {
    required String label,
  }) {
    final issues = <String>[];
    if (leagues.length != 3) {
      issues.add('$label must contain exactly 3 leagues.');
      return issues;
    }
    final tiers = leagues.map((league) => league.tier).toSet();
    if (tiers.length != 3 || !tiers.containsAll(LeagueTier.values)) {
      issues.add('$label league tiers are invalid.');
    }
    final clubIds = <String>[];
    for (final league in leagues) {
      if (league.clubIds.length != 16) {
        issues.add('$label ${league.name} must contain 16 clubs.');
      }
      clubIds.addAll(league.clubIds);
    }
    if (clubIds.length != 48 || clubIds.toSet().length != 48) {
      issues.add('$label league membership must contain 48 unique clubs.');
    }
    return issues;
  }

  bool _sameLeagues(List<WorldLeague> a, List<WorldLeague> b) {
    if (a.length != b.length) return false;
    final aByTier = {for (final league in a) league.tier: league.clubIds.toSet()};
    final bByTier = {for (final league in b) league.tier: league.clubIds.toSet()};
    for (final tier in LeagueTier.values) {
      final aIds = aByTier[tier];
      final bIds = bByTier[tier];
      if (aIds == null || bIds == null ||
          aIds.length != bIds.length || !aIds.containsAll(bIds)) {
        return false;
      }
    }
    return true;
  }
}
