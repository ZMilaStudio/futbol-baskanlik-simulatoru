import '../season/season_validator.dart';
import 'player.dart';
import 'player_career_report.dart';

class PlayerCareerValidator {
  const PlayerCareerValidator({this.seasonValidator = const SeasonValidator()});

  final SeasonValidator seasonValidator;

  List<String> validate(PlayerCareerReport report) {
    final issues = <String>[];
    if (report.seasons.isEmpty) {
      issues.add('Player career contains no seasons.');
      return issues;
    }
    if (report.endDate != report.startDate.addYears(report.seasonCount)) {
      issues.add('Career end date does not match season count.');
    }

    for (var i = 0; i < report.seasons.length; i++) {
      final season = report.seasons[i];
      final expectedStart = report.startDate.addYears(i);
      final expectedEnd = expectedStart.addYears(1);
      if (season.startDate != expectedStart || season.endDate != expectedEnd) {
        issues.add('Season $i has an invalid date window.');
      }
      final expectedSeasonIndex = report.initialSeasonIndex + i;
      if (season.report.seasonIndex != expectedSeasonIndex) {
        issues.add('Season $i has an invalid season index.');
      }
      for (final issue in seasonValidator.validate(season.report)) {
        issues.add('Season $i: $issue');
      }
      issues.addAll(_validatePlayerSet(season.players, seasonIndex: i));

      final clubIds = season.clubs.map((club) => club.id).toSet();
      for (final clubId in clubIds) {
        final clubPlayers = season.players
            .where((player) => player.clubId == clubId)
            .toList();
        if (clubPlayers.length < 11) {
          issues.add('Season $i: $clubId has fewer than 11 players.');
        }
      }

      if (i < report.seasons.length - 1) {
        final currentIds = season.players.map((player) => player.id).toSet();
        final retiredIds =
            season.retiredAfterSeason.map((player) => player.id).toSet();
        final youthIds =
            season.youthIntakeAfterSeason.map((player) => player.id).toSet();
        final expectedNextIds = <String>{
          ...currentIds.where((id) => !retiredIds.contains(id)),
          ...youthIds,
        };
        final actualNextIds =
            report.seasons[i + 1].players.map((player) => player.id).toSet();
        if (expectedNextIds.length != actualNextIds.length ||
            !expectedNextIds.containsAll(actualNextIds)) {
          issues.add('Season $i player conservation mismatch.');
        }
        if (!currentIds.containsAll(retiredIds)) {
          issues.add('Season $i retired player is not from current pool.');
        }
        if (currentIds.any(youthIds.contains)) {
          issues.add('Season $i youth intake reuses an existing player ID.');
        }
        if (season.youthIntakeAfterSeason.length != clubIds.length) {
          issues.add('Season $i youth intake count does not match club count.');
        }
      } else if (season.retiredAfterSeason.isNotEmpty ||
          season.youthIntakeAfterSeason.isNotEmpty) {
        issues.add('Final season must not apply an off-season transition.');
      }
    }

    final finalIds = report.finalPlayers.map((player) => player.id).toSet();
    final lastIds =
        report.seasons.last.players.map((player) => player.id).toSet();
    if (finalIds.length != lastIds.length || !finalIds.containsAll(lastIds)) {
      issues.add('Final players do not match final season pool.');
    }

    final expectedFinalCount = report.initialPlayerCount -
        report.totalRetirements +
        report.totalYouthIntakes;
    if (report.finalPlayers.length != expectedFinalCount) {
      issues.add('Final player count conservation mismatch.');
    }

    return issues;
  }

  List<String> _validatePlayerSet(
    List<Player> players, {
    required int seasonIndex,
  }) {
    final issues = <String>[];
    final ids = players.map((player) => player.id).toList();
    if (ids.toSet().length != ids.length) {
      issues.add('Season $seasonIndex contains duplicate player IDs.');
    }
    for (final player in players) {
      if (player.age < 16 || player.age >= player.retirementAge) {
        issues.add('Season $seasonIndex: ${player.id} has invalid active age.');
      }
      if (player.retirementAge < 34 || player.retirementAge > 38) {
        issues.add(
          'Season $seasonIndex: ${player.id} has invalid retirement age.',
        );
      }
      if (player.ability < 35 || player.ability > 95) {
        issues.add('Season $seasonIndex: ${player.id} ability out of range.');
      }
      if (player.potential < player.ability || player.potential > 95) {
        issues.add('Season $seasonIndex: ${player.id} potential is invalid.');
      }
    }
    return issues;
  }
}
