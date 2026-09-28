import '../core/simulation_config.dart';
import '../fan/fan_state.dart';
import '../league/club.dart';
import '../media/media_state.dart';
import '../world/world_league.dart';
import 'president_management_profile.dart';
import 'president_tenure.dart';

/// The immutable, non-persisted opening of ONE incumbent presidency.
///
/// This does not represent a completed season or an M65/domain checkpoint.
class PresidentOpeningClubState {
  const PresidentOpeningClubState._({
    required this.clubId,
    required this.president,
    required this.tenure,
    required this.managementProfile,
    required this.fan,
    required this.media,
  });

  final String clubId;
  final PresidentProfile president;
  final PresidentTenureState tenure;
  final PresidentManagementProfile managementProfile;
  final FanState fan;
  final MediaState media;

  String get signature =>
      '$clubId:${president.signature}:${managementProfile.signature}:'
      '${tenure.signature}:fan=${fan.signature}:media=${media.signature}';
}

/// A read-only collection in canonical league / league.clubIds order.
///
/// Election fields describe the *initial cursor*, not an owned, persisted
/// election runtime. Existing engines remain the authority for later terms.
class PresidentOpeningWorldState {
  PresidentOpeningWorldState._({
    required Iterable<PresidentOpeningClubState> clubs,
    required this.seasonIndex,
    required this.electionInterval,
    required this.controlledClubId,
  })  : clubs = List<PresidentOpeningClubState>.unmodifiable(clubs),
        byClubId = Map<String, PresidentOpeningClubState>.unmodifiable({
          for (final club in clubs) club.clubId: club,
        });

  final List<PresidentOpeningClubState> clubs;
  final Map<String, PresidentOpeningClubState> byClubId;
  final int seasonIndex;
  final int electionInterval;
  final String? controlledClubId;

  int get completedElectionTerms => 0;
  int get seasonsIntoCurrentTerm => 0;
  int get firstElectionSeasonIndex => seasonIndex + electionInterval - 1;
  List<String> get orderedClubIds =>
      List<String>.unmodifiable(clubs.map((club) => club.clubId));

  PresidentOpeningClubState? get controlledClub =>
      controlledClubId == null ? null : byClubId[controlledClubId];

  String? get controlledPresidentId => controlledClub?.president.id;
}

/// The only X2-A opening rule source. It delegates to the existing production
/// initial generators, preserving their seed tokens and independent RNG draws.
/// Challenger generation, later elections, persistence and restore are NOT
/// handled here.
class PresidentOpeningStateInitializer {
  const PresidentOpeningStateInitializer({
    this.presidentGenerator = const PresidentProfileGenerator(),
    this.managementGenerator = const PresidentManagementProfileGenerator(),
  });

  final PresidentProfileGenerator presidentGenerator;
  final PresidentManagementProfileGenerator managementGenerator;

  PresidentOpeningClubState prepareClub({
    required String clubId,
    required SimulationConfig config,
    int? startedSeasonIndex,
  }) {
    final start = startedSeasonIndex ?? config.seasonIndex;
    if (clubId.isEmpty) {
      throw ArgumentError.value(clubId, 'clubId', 'Must not be empty.');
    }
    if (start < 0 || config.seasonIndex < 0 || config.simulationVersion <= 0) {
      throw ArgumentError('Invalid president opening season/version.');
    }

    // Do not replace either injected generator with its default instance.
    final president = presidentGenerator.generateInitial(
      clubId: clubId,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );
    final tenure = PresidentTenureState.initial(
      clubId: clubId,
      president: president,
      startedSeasonIndex: start,
    );
    final management = managementGenerator.generate(
      president: president,
      careerSeed: config.careerSeed,
      simulationVersion: config.simulationVersion,
    );
    final fan = FanState.initial(clubId);
    final media = MediaState(clubId: clubId, credibility: 65);
    if (president.id.isEmpty ||
        president.name.isEmpty ||
        tenure.clubId != clubId ||
        !identical(tenure.president, president) ||
        tenure.tenureNumber != 1 ||
        tenure.reelectionsWon != 0 ||
        tenure.startedSeasonIndex != start ||
        management.presidentId != president.id ||
        fan.clubId != clubId ||
        media.clubId != clubId) {
      throw StateError('Invalid initial president/management/tenure identity for $clubId.');
    }
    return PresidentOpeningClubState._(
      clubId: clubId,
      president: president,
      tenure: tenure,
      managementProfile: management,
      fan: fan,
      media: media,
    );
  }

  /// Uses the real supplied world, not an invented fixed 48-club roster.
  ///
  /// League order is canonical by tier, while each league's clubIds sequence
  /// is preserved exactly. Duplicate, missing or unassigned IDs fail closed.
  PresidentOpeningWorldState prepareWorld({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    String? controlledClubId,
    int electionInterval = 4,
  }) {
    if (config.seasonIndex < 0 ||
        config.simulationVersion <= 0 ||
        electionInterval <= 0) {
      throw ArgumentError('Invalid president opening parameters.');
    }
    if (clubs.isEmpty || leagues.isEmpty) {
      throw ArgumentError('President opening requires clubs and leagues.');
    }
    final inputIds = <String>{};
    for (final club in clubs) {
      if (club.id.isEmpty || !inputIds.add(club.id)) {
        throw StateError('Missing or duplicated opening club ID: ${club.id}.');
      }
    }
    final orderedLeagues = List<WorldLeague>.of(leagues)
      ..sort((a, b) => a.tier.level.compareTo(b.tier.level));
    final tiers = <int>{};
    final orderedIds = <String>[];
    final assignedIds = <String>{};
    for (final league in orderedLeagues) {
      if (!tiers.add(league.tier.level)) {
        throw StateError('Duplicate opening league tier ${league.tier.level}.');
      }
      for (final clubId in league.clubIds) {
        if (!inputIds.contains(clubId) || !assignedIds.add(clubId)) {
          throw StateError('Missing/duplicate opening league member: $clubId.');
        }
        orderedIds.add(clubId);
      }
    }
    if (assignedIds.length != inputIds.length) {
      throw StateError('Opening league membership does not cover all clubs.');
    }
    if (controlledClubId != null &&
        (controlledClubId.isEmpty || !assignedIds.contains(controlledClubId))) {
      throw ArgumentError.value(controlledClubId, 'controlledClubId');
    }

    final states = [
      for (final id in orderedIds) prepareClub(clubId: id, config: config),
    ];
    final result = PresidentOpeningWorldState._(
      clubs: states,
      seasonIndex: config.seasonIndex,
      electionInterval: electionInterval,
      controlledClubId: controlledClubId,
    );
    if (result.byClubId.length != states.length ||
        (controlledClubId != null &&
            result.controlledPresidentId != result.byClubId[controlledClubId]?.president.id)) {
      throw StateError('Inconsistent president opening world identities.');
    }
    return result;
  }
}
