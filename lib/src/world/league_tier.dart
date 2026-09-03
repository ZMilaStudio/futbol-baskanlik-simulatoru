enum LeagueTier {
  first(
    level: 1,
    displayName: 'Taç Ligi',
    economicScaleBps: 10000,
    costScaleBps: 10000,
  ),
  second(
    level: 2,
    displayName: 'Birlik Ligi',
    economicScaleBps: 9000,
    costScaleBps: 8500,
  ),
  third(
    level: 3,
    displayName: 'Ufuk Ligi',
    economicScaleBps: 8000,
    costScaleBps: 7500,
  );

  const LeagueTier({
    required this.level,
    required this.displayName,
    required this.economicScaleBps,
    required this.costScaleBps,
  });

  final int level;
  final String displayName;
  final int economicScaleBps;
  final int costScaleBps;
}
