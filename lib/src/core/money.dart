class Money implements Comparable<Money> {
  const Money.fromMinorUnits(this.minorUnits);
  const Money.fromUnits(int units) : minorUnits = units * 100;

  static const Money zero = Money.fromMinorUnits(0);

  final int minorUnits;

  bool get isNegative => minorUnits < 0;
  bool get isZero => minorUnits == 0;

  Money operator +(Money other) =>
      Money.fromMinorUnits(minorUnits + other.minorUnits);

  Money operator -(Money other) =>
      Money.fromMinorUnits(minorUnits - other.minorUnits);

  Money operator -() => Money.fromMinorUnits(-minorUnits);

  Money scaleBasisPoints(int basisPoints) {
    if (basisPoints < 0) {
      throw ArgumentError.value(
        basisPoints,
        'basisPoints',
        'Must be non-negative.',
      );
    }
    return Money.fromMinorUnits((minorUnits * basisPoints) ~/ 10000);
  }

  Money min(Money other) => this <= other ? this : other;
  Money max(Money other) => this >= other ? this : other;

  double get units => minorUnits / 100.0;
  double get millions => units / 1000000.0;

  @override
  int compareTo(Money other) => minorUnits.compareTo(other.minorUnits);

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is Money && other.minorUnits == minorUnits;

  @override
  int get hashCode => minorUnits.hashCode;

  @override
  String toString() => '${millions.toStringAsFixed(2)}M';
}
