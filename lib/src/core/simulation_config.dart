class SimulationConfig {
  const SimulationConfig({
    required this.careerSeed,
    this.simulationVersion = 1,
    this.seasonIndex = 0,
    this.homeAdvantageRating = 2.0,
    this.baseHomeGoals = 1.35,
    this.baseAwayGoals = 1.15,
    this.ratingScale = 45.0,
    this.minExpectedGoals = 0.25,
    this.maxExpectedGoals = 3.50,
  });

  final int careerSeed;
  final int simulationVersion;
  final int seasonIndex;
  final double homeAdvantageRating;
  final double baseHomeGoals;
  final double baseAwayGoals;
  final double ratingScale;
  final double minExpectedGoals;
  final double maxExpectedGoals;

  SimulationConfig copyWith({int? careerSeed, int? seasonIndex}) =>
      SimulationConfig(
        careerSeed: careerSeed ?? this.careerSeed,
        simulationVersion: simulationVersion,
        seasonIndex: seasonIndex ?? this.seasonIndex,
        homeAdvantageRating: homeAdvantageRating,
        baseHomeGoals: baseHomeGoals,
        baseAwayGoals: baseAwayGoals,
        ratingScale: ratingScale,
        minExpectedGoals: minExpectedGoals,
        maxExpectedGoals: maxExpectedGoals,
      );
}
