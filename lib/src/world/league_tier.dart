enum LeagueTier {
  first(
    level: 1,
    displayName: 'Taç Ligi',
    economicScaleBps: 10000,
  ),
  second(
    level: 2,
    displayName: 'Birlik Ligi',
    economicScaleBps: 9000,
  ),
  third(
    level: 3,
    displayName: 'Ufuk Ligi',
    economicScaleBps: 8000,
  );

  const LeagueTier({
    required this.level,
    required this.displayName,
    required this.economicScaleBps,
  });

  final int level;
  final String displayName;
  final int economicScaleBps;
}
