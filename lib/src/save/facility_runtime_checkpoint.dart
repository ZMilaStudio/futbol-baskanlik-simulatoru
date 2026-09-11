import '../core/money.dart';
import '../facility/academy_facility.dart';
import '../facility/stadium_facility.dart';
import '../facility/training_ground_facility.dart';
import '../world/world_checkpoint.dart';

class FacilityRuntimeCheckpoint {
  FacilityRuntimeCheckpoint({
    required WorldCheckpoint world,
    required Iterable<AcademyFacilityState> academyFacilities,
    Iterable<StadiumFacilityState>? stadiumFacilities,
    Iterable<TrainingGroundFacilityState>? trainingGroundFacilities,
    required this.totalInvestmentSpent,
  })  : world = world,
        academyFacilities = List.unmodifiable(
          academyFacilities.toList(growable: false)
            ..sort((a, b) => a.clubId.compareTo(b.clubId)),
        ),
        stadiumFacilities = List.unmodifiable(
          (stadiumFacilities ??
                  world.baseClubs.map(
                    (club) => StadiumFacilityState(clubId: club.id, level: 0),
                  ))
              .toList(growable: false)
            ..sort((a, b) => a.clubId.compareTo(b.clubId)),
        ),
        trainingGroundFacilities = List.unmodifiable(
          (trainingGroundFacilities ??
                  world.baseClubs.map(
                    (club) =>
                        TrainingGroundFacilityState(clubId: club.id, level: 0),
                  ))
              .toList(growable: false)
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
  final List<StadiumFacilityState> stadiumFacilities;
  final List<TrainingGroundFacilityState> trainingGroundFacilities;
  final Money totalInvestmentSpent;

  int get completedSeasons => world.completedSeasons;
  int get nextSeasonIndex => world.nextSeasonIndex;

  AcademyFacilityState facilityFor(String clubId) =>
      academyFacilities.firstWhere((state) => state.clubId == clubId);

  StadiumFacilityState stadiumFor(String clubId) =>
      stadiumFacilities.firstWhere((state) => state.clubId == clubId);

  TrainingGroundFacilityState trainingGroundFor(String clubId) =>
      trainingGroundFacilities.firstWhere((state) => state.clubId == clubId);

  void validate() {
    world.validate();
    final worldIds = world.baseClubs.map((club) => club.id).toSet();
    _validateCoverage(
      label: 'Academy',
      worldIds: worldIds,
      clubIds: academyFacilities.map((state) => state.clubId),
    );
    _validateCoverage(
      label: 'Stadium',
      worldIds: worldIds,
      clubIds: stadiumFacilities.map((state) => state.clubId),
    );
    _validateCoverage(
      label: 'Training ground',
      worldIds: worldIds,
      clubIds: trainingGroundFacilities.map((state) => state.clubId),
    );
    if (totalInvestmentSpent.isNegative) {
      throw ArgumentError('Facility investment total cannot be negative.');
    }
  }

  void _validateCoverage({
    required String label,
    required Set<String> worldIds,
    required Iterable<String> clubIds,
  }) {
    final ids = <String>{};
    for (final clubId in clubIds) {
      if (!worldIds.contains(clubId) || !ids.add(clubId)) {
        throw ArgumentError('Invalid or duplicate $label facility $clubId.');
      }
    }
    if (ids.length != worldIds.length) {
      throw ArgumentError('$label facilities must cover every world club.');
    }
  }

  String get signature => [
        completedSeasons,
        nextSeasonIndex,
        totalInvestmentSpent.minorUnits,
        academyFacilities.map((state) => '${state.clubId}:${state.level}').join('|'),
        stadiumFacilities.map((state) => '${state.clubId}:${state.level}').join('|'),
        trainingGroundFacilities
            .map((state) => '${state.clubId}:${state.level}')
            .join('|'),
        world.nextSeasonFinanceStates.map((state) => state.signature).join('|'),
      ].join('||');
}
