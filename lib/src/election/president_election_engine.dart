import '../core/seeded_rng.dart';
import '../core/stable_hash.dart';
import 'president_election.dart';
import 'president_election_snapshot.dart';

class PresidentElectionEngine {
  const PresidentElectionEngine();

  PresidentElectionSnapshot evaluate({
    required String clubId,
    required int seasonIndex,
    required int termNumber,
    required int fanOverallTrust,
    required int fanIdentityTrust,
    required int mediaCredibility,
    required int promiseScore,
    required int careerSeed,
    required int simulationVersion,
  }) {
    final contributions = <PresidentApprovalContribution>[
      PresidentApprovalContribution(
        reason: PresidentApprovalReason.fanOverall,
        value: fanOverallTrust,
        weightBps: 3500,
      ),
      PresidentApprovalContribution(
        reason: PresidentApprovalReason.fanIdentity,
        value: fanIdentityTrust,
        weightBps: 1500,
      ),
      PresidentApprovalContribution(
        reason: PresidentApprovalReason.mediaCredibility,
        value: mediaCredibility,
        weightBps: 2500,
      ),
      PresidentApprovalContribution(
        reason: PresidentApprovalReason.promiseRecord,
        value: promiseScore,
        weightBps: 2500,
      ),
    ];
    final approval = ((fanOverallTrust * 3500 +
                fanIdentityTrust * 1500 +
                mediaCredibility * 2500 +
                promiseScore * 2500) /
            10000)
        .round()
        .clamp(0, 100)
        .toInt();

    final rng = SeededRng(
      StableHash.combine32([
        careerSeed,
        simulationVersion,
        seasonIndex,
        termNumber,
        StableHash.string32(clubId),
        StableHash.string32('president-election-challenger'),
      ]),
    );
    var challengerStrength = 50 + (rng.nextDouble() * 22).floor();
    if (approval < 50) {
      challengerStrength += 4;
    } else if (approval < 58) {
      challengerStrength += 2;
    } else if (approval > 72) {
      challengerStrength -= 3;
    } else if (approval > 67) {
      challengerStrength -= 1;
    }
    challengerStrength = challengerStrength.clamp(42, 78).toInt();

    final margin = approval - challengerStrength;
    final outcome = margin >= 0
        ? PresidentElectionOutcome.reelected
        : PresidentElectionOutcome.lost;

    return PresidentElectionSnapshot(
      clubId: clubId,
      seasonIndex: seasonIndex,
      termNumber: termNumber,
      fanOverallTrust: fanOverallTrust,
      fanIdentityTrust: fanIdentityTrust,
      mediaCredibility: mediaCredibility,
      promiseScore: promiseScore,
      approval: approval,
      challengerStrength: challengerStrength,
      margin: margin,
      outcome: outcome,
      contributions: contributions,
    );
  }
}
