import 'league_tier.dart';

class WorldLeague {
  WorldLeague({
    required this.tier,
    required Iterable<String> clubIds,
  }) : clubIds = List.unmodifiable(clubIds);

  final LeagueTier tier;
  final List<String> clubIds;

  String get id => 'league_${tier.level}';
  String get name => tier.displayName;

  WorldLeague copyWith({Iterable<String>? clubIds}) => WorldLeague(
        tier: tier,
        clubIds: clubIds ?? this.clubIds,
      );

  String get signature =>
      '${tier.level}:${(List<String>.of(clubIds)..sort()).join(',')}';
}
