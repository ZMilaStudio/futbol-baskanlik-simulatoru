import '../core/money.dart';
import '../election/player_president_tenure_control_gate.dart';
import '../election/president_tenure.dart';
import '../facility/academy_facility.dart';
import '../facility/stadium_facility.dart';
import '../facility/training_ground_facility.dart';
import '../finance/club_finance_state.dart';
import '../manager/manager.dart';
import '../manager/manager_assignment.dart';
import '../sponsor/sponsor_system.dart';
import '../world/league_tier.dart';
import '../world/world_league.dart';

/// Immutable application-facing observation of the authoritative club state at
/// one prepared season opening.
///
/// This object is deliberately not persisted or serialized. Gameplay never
/// reads decisions from it; application/UI consumers only observe it.
class PlayerPresidentPreparedSeasonDashboardSnapshot {
  PlayerPresidentPreparedSeasonDashboardSnapshot({
    required this.controlledClubId,
    required this.seasonIndex,
    required this.league,
    required this.finance,
    required this.fanOverallTrust,
    required this.presidentTenure,
    required this.playerControl,
    required this.manager,
    required this.managerAssignment,
    required this.academyFacility,
    required this.stadiumFacility,
    required this.trainingGroundFacility,
    required this.activeSponsor,
  }) {
    _validate();
  }

  final String controlledClubId;

  /// The season that is about to be played, never the completed season index.
  final int seasonIndex;

  final WorldLeague league;
  final ClubFinanceState finance;
  final int fanOverallTrust;
  final PresidentTenureState presidentTenure;
  final PlayerPresidentTenureControlState playerControl;
  final Manager manager;
  final ManagerAssignment managerAssignment;
  final AcademyFacilityState academyFacility;
  final StadiumFacilityState stadiumFacility;
  final TrainingGroundFacilityState trainingGroundFacility;
  final SponsorContract? activeSponsor;

  LeagueTier get leagueTier => league.tier;
  String get leagueId => league.id;
  Money get cash => finance.cash;
  Money get debt => finance.debt;
  bool get playerControlActive => playerControl.active;
  double get boardRelationship => managerAssignment.boardRelationship;
  int get academyLevel => academyFacility.level;
  int get stadiumLevel => stadiumFacility.level;
  int get trainingGroundLevel => trainingGroundFacility.level;

  /// Runtime-only deterministic equality aid for tests/observation.
  ///
  /// It is not a save signature and is never encoded into persistence.
  String get signature => [
        controlledClubId,
        seasonIndex,
        league.signature,
        finance.signature,
        fanOverallTrust,
        presidentTenure.signature,
        playerControl.signature,
        manager.signature,
        managerAssignment.signature,
        'academy=${academyFacility.level}',
        'stadium=${stadiumFacility.level}',
        'training=${trainingGroundFacility.level}',
        'sponsor=${activeSponsor?.signature ?? 'none'}',
      ].join('||');

  void _validate() {
    if (controlledClubId.isEmpty) {
      throw StateError('Prepared dashboard controlled club cannot be empty.');
    }
    if (seasonIndex < 0) {
      throw StateError('Prepared dashboard season index cannot be negative.');
    }
    final membershipCount =
        league.clubIds.where((clubId) => clubId == controlledClubId).length;
    if (membershipCount != 1) {
      throw StateError(
        'Prepared dashboard requires exactly one controlled-club league '
        'membership inside the selected league.',
      );
    }
    if (finance.clubId != controlledClubId) {
      throw StateError('Prepared dashboard finance club mismatch.');
    }
    if (fanOverallTrust < 0 || fanOverallTrust > 100) {
      throw StateError('Prepared dashboard fan trust must be 0..100.');
    }
    if (presidentTenure.clubId != controlledClubId ||
        presidentTenure.startedSeasonIndex > seasonIndex) {
      throw StateError('Prepared dashboard president tenure is inconsistent.');
    }

    playerControl.validate();
    if (playerControl.controlledClubId != controlledClubId) {
      throw StateError('Prepared dashboard player-control club mismatch.');
    }
    if (playerControl.active) {
      if (playerControl.playerPresidentId != presidentTenure.president.id) {
        throw StateError(
          'Active prepared dashboard player president is not the incumbent.',
        );
      }
    } else if (playerControl.playerPresidentId ==
        presidentTenure.president.id) {
      throw StateError(
        'Lost prepared dashboard player control cannot still own the '
        'incumbent president.',
      );
    }

    if (managerAssignment.clubId != controlledClubId ||
        managerAssignment.managerId != manager.id ||
        managerAssignment.appointedSeasonIndex > seasonIndex ||
        managerAssignment.completedSeasons < 0 ||
        !managerAssignment.boardRelationship.isFinite ||
        managerAssignment.boardRelationship < 0 ||
        managerAssignment.boardRelationship > 100) {
      throw StateError('Prepared dashboard manager authority is inconsistent.');
    }

    if (academyFacility.clubId != controlledClubId ||
        stadiumFacility.clubId != controlledClubId ||
        trainingGroundFacility.clubId != controlledClubId) {
      throw StateError('Prepared dashboard facility club mismatch.');
    }

    final sponsor = activeSponsor;
    if (sponsor != null &&
        (sponsor.offer.clubId != controlledClubId ||
            !sponsor.isActiveAt(seasonIndex))) {
      throw StateError('Prepared dashboard active sponsor is inconsistent.');
    }
  }
}
