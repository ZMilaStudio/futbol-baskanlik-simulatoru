import 'president_management_career_report.dart';
import 'president_management_profile.dart';
import 'president_tenure.dart';

class PresidentManagerPatienceState {
  const PresidentManagerPatienceState({
    required this.clubId,
    required this.seasonIndex,
    required this.presidentId,
    required this.archetype,
    required this.managerPatience,
  });

  final String clubId;
  final int seasonIndex;
  final String presidentId;
  final PresidentManagementArchetype archetype;
  final int managerPatience;

  String get signature =>
      '$clubId:s$seasonIndex:$presidentId:${archetype.name}:'
      'patience=$managerPatience';
}

class PresidentManagerPatienceTimeline {
  PresidentManagerPatienceTimeline._({
    required Map<String, PresidentProfile> initialPresidentByClub,
    required Map<String, List<PresidentTurnoverEvent>> turnoversByClub,
    required Map<String, PresidentManagementProfile> profileByPresident,
  })  : _initialPresidentByClub = Map.unmodifiable(initialPresidentByClub),
        _turnoversByClub = Map.unmodifiable({
          for (final entry in turnoversByClub.entries)
            entry.key: List<PresidentTurnoverEvent>.unmodifiable(entry.value),
        }),
        _profileByPresident = Map.unmodifiable(profileByPresident);

  factory PresidentManagerPatienceTimeline.fromReport(
    PresidentManagementCareerReport report,
  ) {
    final initialPresidentByClub = <String, PresidentProfile>{
      for (final state in report.sourceReport.initialTenureStates)
        state.clubId: state.president,
    };
    final turnoversByClub = <String, List<PresidentTurnoverEvent>>{};
    for (final turnover in report.sourceReport.turnovers) {
      turnoversByClub.putIfAbsent(turnover.clubId, () => []).add(turnover);
    }
    for (final turnovers in turnoversByClub.values) {
      turnovers.sort(
        (a, b) => a.effectiveSeasonIndex.compareTo(b.effectiveSeasonIndex),
      );
    }
    final profileByPresident = <String, PresidentManagementProfile>{
      for (final profile in report.profiles) profile.presidentId: profile,
    };
    return PresidentManagerPatienceTimeline._(
      initialPresidentByClub: initialPresidentByClub,
      turnoversByClub: turnoversByClub,
      profileByPresident: profileByPresident,
    );
  }

  final Map<String, PresidentProfile> _initialPresidentByClub;
  final Map<String, List<PresidentTurnoverEvent>> _turnoversByClub;
  final Map<String, PresidentManagementProfile> _profileByPresident;

  PresidentManagerPatienceState resolve(String clubId, int seasonIndex) {
    final initial = _initialPresidentByClub[clubId];
    if (initial == null) {
      throw StateError('Missing initial president for $clubId.');
    }
    var presidentId = initial.id;
    for (final turnover in
        _turnoversByClub[clubId] ?? const <PresidentTurnoverEvent>[]) {
      if (turnover.effectiveSeasonIndex > seasonIndex) break;
      presidentId = turnover.incoming.id;
    }
    final profile = _profileByPresident[presidentId];
    if (profile == null) {
      throw StateError('Missing management profile for $presidentId.');
    }
    return PresidentManagerPatienceState(
      clubId: clubId,
      seasonIndex: seasonIndex,
      presidentId: presidentId,
      archetype: profile.archetype,
      managerPatience: profile.managerPatience,
    );
  }

  int patienceFor(String clubId, int seasonIndex) =>
      resolve(clubId, seasonIndex).managerPatience;
}
