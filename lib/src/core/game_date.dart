class GameDate implements Comparable<GameDate> {
  const GameDate(this.year, this.month, this.day)
      : assert(month >= 1 && month <= 12),
        assert(day >= 1 && day <= 31);

  final int year;
  final int month;
  final int day;

  GameDate addYears(int years) => GameDate(year + years, month, day);

  @override
  int compareTo(GameDate other) {
    var cmp = year.compareTo(other.year);
    if (cmp != 0) return cmp;
    cmp = month.compareTo(other.month);
    if (cmp != 0) return cmp;
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is GameDate &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
