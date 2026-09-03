import 'season_report.dart';

class SeasonValidator {
  const SeasonValidator();

  List<String> validate(SeasonReport report) {
    final issues = <String>[];
    final clubCount = report.table.length;
    final expectedMatches = clubCount * (clubCount - 1);
    final expectedPlayedPerClub = 2 * (clubCount - 1);

    if (report.matchCount != expectedMatches) {
      issues.add('Expected $expectedMatches matches, got ${report.matchCount}.');
    }
    if (report.fixtures.any((f) => !f.isPlayed)) {
      issues.add('At least one fixture is not completed.');
    }
    if (report.fixtures.any((f) => f.homeClubId == f.awayClubId)) {
      issues.add('Self-match detected.');
    }
    if (report.fixtures.map((f) => f.id).toSet().length !=
        report.fixtures.length) {
      issues.add('Duplicate fixture ID detected.');
    }

    var sumPlayed = 0;
    var sumFor = 0;
    var sumAgainst = 0;
    var sumPoints = 0;
    for (final row in report.table) {
      sumPlayed += row.played;
      sumFor += row.goalsFor;
      sumAgainst += row.goalsAgainst;
      sumPoints += row.points;
      if (row.played != expectedPlayedPerClub) {
        issues.add(
          '${row.clubId}: expected $expectedPlayedPerClub played, got ${row.played}.',
        );
      }
      if (row.wins + row.draws + row.losses != row.played) {
        issues.add('${row.clubId}: W+D+L != played.');
      }
      if (row.goalDifference != row.goalsFor - row.goalsAgainst) {
        issues.add('${row.clubId}: invalid goal difference.');
      }
      if (row.points != row.wins * 3 + row.draws) {
        issues.add('${row.clubId}: invalid points total.');
      }
    }

    if (sumPlayed != report.matchCount * 2) {
      issues.add('League played sum mismatch.');
    }
    if (sumFor != sumAgainst) {
      issues.add('Goals for/against totals mismatch.');
    }
    final expectedLeaguePoints =
        (report.homeWins + report.awayWins) * 3 + report.draws * 2;
    if (sumPoints != expectedLeaguePoints) {
      issues.add('League points conservation mismatch.');
    }
    if (report.table.isNotEmpty &&
        report.championClubId != report.table.first.clubId) {
      issues.add('Champion does not match table leader.');
    }
    return issues;
  }
}
