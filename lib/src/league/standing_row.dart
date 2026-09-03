class StandingRow {
  StandingRow({required this.clubId});

  final String clubId;
  int played = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;
  int points = 0;

  int get goalDifference => goalsFor - goalsAgainst;

  void record({required int scored, required int conceded}) {
    played++;
    goalsFor += scored;
    goalsAgainst += conceded;
    if (scored > conceded) {
      wins++;
      points += 3;
    } else if (scored == conceded) {
      draws++;
      points += 1;
    } else {
      losses++;
    }
  }

  Map<String, Object> toJson() => {
        'clubId': clubId,
        'played': played,
        'wins': wins,
        'draws': draws,
        'losses': losses,
        'goalsFor': goalsFor,
        'goalsAgainst': goalsAgainst,
        'goalDifference': goalDifference,
        'points': points,
      };
}
