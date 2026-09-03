enum LeagueTier {
  first(
    level: 1,
    displayName: 'Taç Ligi',
    economicScaleBps: 10000,
  ),
  second(
    level: 2,
    displayName: 'Birlik Ligi',
    economicScaleBps: 7600,
  ),
  third(
    level: 3,
    displayName: 'Ufuk Ligi',
    economicScaleBps: 5800,
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
