import '../fan/fan_career_validator.dart';
import '../promise/promise_media_career_validator.dart';
import '../promise/promise_season_snapshot.dart';
import 'president_election.dart';
import 'president_election_career_report.dart';

class PresidentElectionCareerValidator {
  const PresidentElectionCareerValidator();

  List<String> validate(PresidentElectionCareerReport report) {
    final issues = <String>[
      ...const PromiseMediaCareerValidator().validate(report.reputationReport),
      ...const FanCareerValidator().validate(report.fanReport),
    ];

    if (report.electionInterval <= 0) {
      issues.add('Election interval must be positive.');
      return issues;
    }
    if (report.fanReport.advancedTransferReport.signature !=
        report.reputationReport.advancedTransferReport.signature) {
      issues.add('Election fan and reputation layers use different worlds.');
    }

    final worldReport = report.reputationReport.advancedTransferReport.worldReport;
    final completedTerms = worldReport.seasonCount ~/ report.electionInterval;
    final expectedElections = worldReport.initialClubCount * completedTerms;
    if (report.totalElections != expectedElections) {
      issues.add(
        'Election count mismatch: ${report.totalElections}/$expectedElections.',
      );
    }

    final fanByKey = {
      for (final snapshot in report.fanReport.snapshots)
        '${snapshot.context.seasonIndex}|${snapshot.context.clubId}': snapshot,
    };
    final mediaByKey = {
      for (final snapshot in report.reputationReport.snapshots)
        '${snapshot.seasonIndex}|${snapshot.clubId}': snapshot,
    };
    final promiseByClub = <String, List<PromiseSeasonSnapshot>>{};
    for (final snapshot in report.reputationReport.promiseReport.snapshots) {
      promiseByClub.putIfAbsent(snapshot.promise.clubId, () => []).add(snapshot);
    }
    final worldSeasons = worldReport.seasons;
    final electionSeasonToTerm = <int, int>{};
    final termStarts = <int, int>{};
    for (var offset = report.electionInterval - 1;
        offset < worldSeasons.length;
        offset += report.electionInterval) {
      final term = (offset + 1) ~/ report.electionInterval;
      electionSeasonToTerm[worldSeasons[offset].seasonIndex] = term;
      termStarts[worldSeasons[offset].seasonIndex] =
          worldSeasons[offset - report.electionInterval + 1].seasonIndex;
    }

    final seen = <String>{};
    final countsByClub = <String, int>{};
    final reelectionsByClub = <String, int>{};
    final lossesByClub = <String, int>{};

    for (final election in report.elections) {
      final key = '${election.seasonIndex}|${election.clubId}';
      if (!seen.add(key)) issues.add('Duplicate election $key.');
      final expectedTerm = electionSeasonToTerm[election.seasonIndex];
      if (expectedTerm == null || election.termNumber != expectedTerm) {
        issues.add('Election term/season mismatch $key.');
      }
      final fan = fanByKey[key];
      final media = mediaByKey[key];
      if (fan == null || media == null) {
        issues.add('Missing election reputation input $key.');
        continue;
      }
      if (election.fanOverallTrust != fan.state.overallTrust ||
          election.fanIdentityTrust != fan.state.identityTrust ||
          election.mediaCredibility != media.credibilityAfterPromise) {
        issues.add('Election reputation values mismatch $key.');
      }

      final startSeason = termStarts[election.seasonIndex];
      if (startSeason == null) {
        issues.add('Missing election term start $key.');
      } else {
        final promises = (promiseByClub[election.clubId] ??
                const <PromiseSeasonSnapshot>[])
            .where((snapshot) =>
                snapshot.promise.seasonIndex >= startSeason &&
                snapshot.promise.seasonIndex <= election.seasonIndex)
            .toList();
        if (promises.length != report.electionInterval) {
          issues.add('Election promise term coverage mismatch $key.');
        } else {
          final expectedPromiseScore = (promises.fold<int>(
                    0,
                    (sum, snapshot) => sum + snapshot.resolution.score,
                  ) /
                  promises.length)
              .round();
          if (election.promiseScore != expectedPromiseScore) {
            issues.add('Election promise score mismatch $key.');
          }
        }
      }

      if (election.contributions.length != 4 ||
          election.contributions.fold<int>(
                0,
                (sum, item) => sum + item.weightBps,
              ) !=
              10000) {
        issues.add('Election contribution weights mismatch $key.');
      }
      final expectedApproval = ((election.fanOverallTrust * 3500 +
                  election.fanIdentityTrust * 1500 +
                  election.mediaCredibility * 2500 +
                  election.promiseScore * 2500) /
              10000)
          .round();
      if (election.approval != expectedApproval ||
          election.approval < 0 ||
          election.approval > 100) {
        issues.add('Election approval equation failed $key.');
      }
      if (election.challengerStrength < 0 ||
          election.challengerStrength > 100 ||
          election.margin != election.approval - election.challengerStrength) {
        issues.add('Election challenger/margin invalid $key.');
      }
      final expectedOutcome = election.margin >= 0
          ? PresidentElectionOutcome.reelected
          : PresidentElectionOutcome.lost;
      if (election.outcome != expectedOutcome) {
        issues.add('Election outcome mismatch $key.');
      }

      countsByClub.update(
        election.clubId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      if (election.outcome == PresidentElectionOutcome.reelected) {
        reelectionsByClub.update(
          election.clubId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      } else {
        lossesByClub.update(
          election.clubId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    if (report.finalStates.length != worldReport.initialClubCount) {
      issues.add('Final election-state count mismatch.');
    }
    for (final state in report.finalStates) {
      final clubElections = report.elections
          .where((election) => election.clubId == state.clubId)
          .toList();
      if (state.electionsHeld != (countsByClub[state.clubId] ?? 0) ||
          state.reelections != (reelectionsByClub[state.clubId] ?? 0) ||
          state.losses != (lossesByClub[state.clubId] ?? 0) ||
          state.electionsHeld != state.reelections + state.losses) {
        issues.add('Final election counters mismatch for ${state.clubId}.');
      }
      final expectedApproval =
          clubElections.isEmpty ? 60 : clubElections.last.approval;
      if (state.approval != expectedApproval) {
        issues.add('Final election approval mismatch for ${state.clubId}.');
      }
    }

    if (report.totalElections >= 20 &&
        (report.reelections == 0 || report.losses == 0)) {
      issues.add('Election outcomes lack reelected/lost variety.');
    }

    return issues;
  }
}
