import 'president_election.dart';

class PresidentElectionSnapshot {
  PresidentElectionSnapshot({
    required this.clubId,
    required this.seasonIndex,
    required this.termNumber,
    required this.fanOverallTrust,
    required this.fanIdentityTrust,
    required this.mediaCredibility,
    required this.promiseScore,
    required this.approval,
    required this.challengerStrength,
    required this.margin,
    required this.outcome,
    required Iterable<PresidentApprovalContribution> contributions,
  }) : contributions = List.unmodifiable(contributions);

  final String clubId;
  final int seasonIndex;
  final int termNumber;
  final int fanOverallTrust;
  final int fanIdentityTrust;
  final int mediaCredibility;
  final int promiseScore;
  final int approval;
  final int challengerStrength;
  final int margin;
  final PresidentElectionOutcome outcome;
  final List<PresidentApprovalContribution> contributions;

  String get signature =>
      '$clubId:s$seasonIndex:term=$termNumber:fan=$fanOverallTrust:'
      'identity=$fanIdentityTrust:media=$mediaCredibility:promise=$promiseScore:'
      'approval=$approval:challenger=$challengerStrength:margin=$margin:'
      'outcome=${outcome.name}:reasons=${contributions.map((item) => item.signature).join(',')}';
}
