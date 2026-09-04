import 'president_election.dart';

class PresidentApprovalState {
  const PresidentApprovalState({
    required this.clubId,
    required this.approval,
    required this.electionsHeld,
    required this.reelections,
    required this.losses,
  });

  factory PresidentApprovalState.initial(String clubId) =>
      PresidentApprovalState(
        clubId: clubId,
        approval: 60,
        electionsHeld: 0,
        reelections: 0,
        losses: 0,
      );

  final String clubId;
  final int approval;
  final int electionsHeld;
  final int reelections;
  final int losses;

  PresidentApprovalState record({
    required int nextApproval,
    required PresidentElectionOutcome outcome,
  }) =>
      PresidentApprovalState(
        clubId: clubId,
        approval: nextApproval,
        electionsHeld: electionsHeld + 1,
        reelections:
            reelections + (outcome == PresidentElectionOutcome.reelected ? 1 : 0),
        losses: losses + (outcome == PresidentElectionOutcome.lost ? 1 : 0),
      );

  String get signature =>
      '$clubId:$approval:elections=$electionsHeld:reelected=$reelections:lost=$losses';
}
