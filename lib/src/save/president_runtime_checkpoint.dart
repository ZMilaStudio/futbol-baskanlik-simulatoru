import '../election/president_management_profile.dart';
import '../election/president_reputation_career_report.dart';
import '../election/president_tenure.dart';
import '../fan/fan_state.dart';
import '../media/media_state.dart';
import 'advanced_history_compaction.dart';

class PresidentClubRuntimeState {
  const PresidentClubRuntimeState({
    required this.tenure,
    required this.managementProfile,
    required this.fanReputation,
    required this.mediaReputation,
  });

  final PresidentTenureState tenure;
  final PresidentManagementProfile managementProfile;
  final FanState fanReputation;
  final MediaState mediaReputation;

  String get clubId => tenure.clubId;

  void validate() {
    if (managementProfile.presidentId != tenure.president.id) {
      throw ArgumentError('President management profile does not match tenure president for $clubId.');
    }
    if (fanReputation.clubId != clubId || mediaReputation.clubId != clubId) {
      throw ArgumentError('President reputation club mismatch for $clubId.');
    }
  }

  String get signature => '${tenure.signature}|${managementProfile.signature}|fan=${fanReputation.signature}|media=${mediaReputation.signature}';
}

class PresidentRuntimeCheckpoint {
  PresidentRuntimeCheckpoint({
    required this.runtime,
    required this.electionInterval,
    required this.completedElectionTerms,
    required this.seasonsIntoCurrentTerm,
    required Iterable<PresidentClubRuntimeState> clubs,
  }) : clubs = List.unmodifiable(clubs) {
    validate();
  }

  factory PresidentRuntimeCheckpoint.capture({
    required CompactAdvancedRuntimeCheckpoint runtime,
    required PresidentReputationCareerReport report,
    PresidentManagementProfileGenerator profileGenerator = const PresidentManagementProfileGenerator(),
  }) {
    if (report.seasonCount != runtime.completedSeasons) {
      throw ArgumentError('President report season count must match compact runtime completed seasons.');
    }
    if (report.electionInterval <= 0) {
      throw ArgumentError.value(report.electionInterval, 'electionInterval');
    }
    final fanByClub = {for (final state in report.finalFanStates) state.clubId: state};
    final mediaByClub = {for (final state in report.finalMediaStates) state.clubId: state};
    final states = <PresidentClubRuntimeState>[];
    for (final tenure in report.finalTenureStates) {
      final fan = fanByClub[tenure.clubId];
      final media = mediaByClub[tenure.clubId];
      if (fan == null || media == null) {
        throw ArgumentError('Missing final president reputation state for ${tenure.clubId}.');
      }
      states.add(PresidentClubRuntimeState(
        tenure: tenure,
        managementProfile: profileGenerator.generate(
          president: tenure.president,
          careerSeed: report.careerSeed,
          simulationVersion: report.simulationVersion,
        ),
        fanReputation: fan,
        mediaReputation: media,
      ));
    }
    states.sort((a, b) => a.clubId.compareTo(b.clubId));
    return PresidentRuntimeCheckpoint(
      runtime: runtime,
      electionInterval: report.electionInterval,
      completedElectionTerms: report.seasonCount ~/ report.electionInterval,
      seasonsIntoCurrentTerm: report.seasonCount % report.electionInterval,
      clubs: states,
    );
  }

  final CompactAdvancedRuntimeCheckpoint runtime;
  final int electionInterval;
  final int completedElectionTerms;
  final int seasonsIntoCurrentTerm;
  final List<PresidentClubRuntimeState> clubs;

  int get nextSeasonIndex => runtime.nextSeasonIndex;
  int get completedSeasons => runtime.completedSeasons;

  void validate() {
    runtime.validate();
    if (electionInterval <= 0) throw ArgumentError.value(electionInterval, 'electionInterval');
    if (completedElectionTerms < 0) throw ArgumentError.value(completedElectionTerms, 'completedElectionTerms');
    if (seasonsIntoCurrentTerm < 0 || seasonsIntoCurrentTerm >= electionInterval) {
      throw ArgumentError.value(seasonsIntoCurrentTerm, 'seasonsIntoCurrentTerm');
    }
    if (completedElectionTerms * electionInterval + seasonsIntoCurrentTerm != completedSeasons) {
      throw ArgumentError('President election cursor does not match completed seasons.');
    }
    if (clubs.length != runtime.runtime.world.clubs.length) {
      throw ArgumentError('President runtime must contain exactly one state per world club.');
    }
    final ids = <String>{};
    for (final state in clubs) {
      state.validate();
      if (!ids.add(state.clubId)) throw ArgumentError('Duplicate president runtime club ${state.clubId}.');
    }
  }

  String get signature => 'next=$nextSeasonIndex:terms=$completedElectionTerms:termOffset=$seasonsIntoCurrentTerm:${clubs.map((item) => item.signature).join('|')}';
}
