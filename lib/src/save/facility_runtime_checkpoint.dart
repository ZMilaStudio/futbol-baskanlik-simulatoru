import '../core/money.dart';
import '../facility/academy_facility.dart';
import '../world/world_checkpoint.dart';

class FacilityRuntimeCheckpoint {
  FacilityRuntimeCheckpoint({
    required this.world,
    required Iterable<AcademyFacilityState> academyFacilities,
    required this.totalInvestmentSpent,
  }) : academyFacilities = List.unmodifiable(
          academyFacilities.toList(growable: false)
            ..sort((a, b) => a.clubId.compareTo(b.clubId)),
        ) {
    validate();
  }

  factory FacilityRuntimeCheckpoint.initial(WorldCheckpoint world) =>
      FacilityRuntimeCheckpoint(
        world: world,
        academyFacilities: world.baseClubs.map(
          (club) => AcademyFacilityState(clubId: club.id, level: 0),
        ),
        totalInvestmentSpent: Money.zero,
      );

  final WorldCheckpoint world;
  final List<AcademyFacilityState> academyFacilities;
  final Money totalInvestmentSpent;

  int get completedSeasons => world.completedSeasons;
  int get nextSeasonIndex => world.nextSeasonIndex;

  AcademyFacilityState facilityFor(String clubId) =>
      academyFacilities.firstWhere((state) => state.clubId == clubId);

  void validate() {
    world.validate();
    if (academyFacilities.length != world.baseClubs.length) {
      throw ArgumentError('Facility checkpoint requires one academy per club.');
    }
    final worldIds = world.baseClubs.map((club) => club.id).toSet();
    final facilityIds = <String>{};
    for (final state in academyFacilities) {
      if (!worldIds.contains(state.clubId) || !facilityIds.add(state.clubId)) {
        throw ArgumentError('Invalid or duplicate academy ${state.clubId}.');
      }
    }
    if (facilityIds.length != worldIds.length) {
      throw ArgumentError('Facility checkpoint must cover every world club.');
    }
    if (totalInvestmentSpent.isNegative) {
      throw ArgumentError('Facility investment total cannot be negative.');
    }
  }

  String get signature => [
        completedSeasons,
        nextSeasonIndex,
        totalInvestmentSpent.minorUnits,
        academyFacilities.map((state) => '${state.clubId}:${state.level}').join('|'),
        world.nextSeasonFinanceStates.map((state) => state.signature).join('|'),
      ].join('||');
}
