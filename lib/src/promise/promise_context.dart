import '../core/money.dart';
import '../world/league_tier.dart';

class PresidentPromiseContext {
  const PresidentPromiseContext({
    required this.clubId,
    required this.seasonIndex,
    required this.tier,
    required this.leagueSize,
    required this.expectedPosition,
    required this.openingCash,
    required this.openingDebt,
  });

  final String clubId;
  final int seasonIndex;
  final LeagueTier tier;
  final int leagueSize;
  final int expectedPosition;
  final Money openingCash;
  final Money openingDebt;

  bool get hasMeaningfulDebt =>
      openingDebt >= const Money.fromUnits(5000000);

  bool get financialStress =>
      hasMeaningfulDebt && openingDebt >= openingCash.scaleBasisPoints(12000);

  bool get severeFinancialStress =>
      hasMeaningfulDebt && openingDebt >= openingCash.scaleBasisPoints(18000);

  String get signature =>
      '$clubId:s$seasonIndex:t${tier.level}:size=$leagueSize:'
      'expected=$expectedPosition:cash=${openingCash.minorUnits}:'
      'debt=${openingDebt.minorUnits}';
}

class PresidentPromiseOutcome {
  const PresidentPromiseOutcome({
    required this.clubId,
    required this.seasonIndex,
    required this.leaguePosition,
    required this.leagueSize,
    required this.openingDebt,
    required this.closingDebt,
    required this.emergencyBorrowing,
    required this.promoted,
    required this.relegated,
  });

  final String clubId;
  final int seasonIndex;
  final int leaguePosition;
  final int leagueSize;
  final Money openingDebt;
  final Money closingDebt;
  final Money emergencyBorrowing;
  final bool promoted;
  final bool relegated;

  String get signature =>
      '$clubId:s$seasonIndex:pos=$leaguePosition/$leagueSize:'
      'debt=${openingDebt.minorUnits}>${closingDebt.minorUnits}:'
      'emergency=${emergencyBorrowing.minorUnits}:'
      'promoted=$promoted:relegated=$relegated';
}
