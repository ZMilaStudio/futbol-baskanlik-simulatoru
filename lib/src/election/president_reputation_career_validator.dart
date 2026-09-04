import '../fan/fan_career_validator.dart';
import '../fan/fan_state.dart';
import '../media/media_credibility_engine.dart';
import '../media/media_season_snapshot.dart';
import '../media/media_state.dart';
import '../promise/promise_media_career_validator.dart';
import '../promise/promise_media_impact_engine.dart';
import '../promise/promise_season_snapshot.dart';
import 'president_election.dart';
import 'president_election_engine.dart';
import 'president_reputation_career_report.dart';
import 'president_reputation_handover.dart';
import 'president_tenure.dart';

class PresidentReputationCareerValidator {
  const PresidentReputationCareerValidator({
    this.mediaEngine = const MediaCredibilityEngine(),
    this.promiseMediaEngine = const PromiseMediaImpactEngine(),
    this.electionEngine = const PresidentElectionEngine(),
    this.profileGenerator = const PresidentProfileGenerator(),
    this.handoverPolicy = const PresidentReputationHandoverPolicy(),
  });

  final MediaCredibilityEngine mediaEngine;
  final PromiseMediaImpactEngine promiseMediaEngine;
  final PresidentElectionEngine electionEngine;
  final PresidentProfileGenerator profileGenerator;
  final PresidentReputationHandoverPolicy handoverPolicy;

  List<String> validate(PresidentReputationCareerReport report) {
    final issues = <String>[
      ...const PromiseMediaCareerValidator().validate(report.sourceReport),
      ...const FanCareerValidator().validate(report.fanTemplateReport),
    ];
    final worldReport = report.sourceReport.advancedTransferReport.worldReport;
    if (report.fanTemplateReport.advancedTransferReport.signature !=
        report.sourceReport.advancedTransferReport.signature) {
      issues.add('M16 fan/media templates use different worlds.');
    }
    if (report.electionInterval <= 0) {
      issues.add('M16 election interval must be positive.');
      return issues;
    }
    if (report.seasonCount != worldReport.seasonCount) {
      issues.add('M16 season count mismatch.');
    }

    final clubIds = worldReport.initialLeagues
        .expand((league) => league.clubIds)
        .toSet()
        .toList()
      ..sort();
    final firstSeasonIndex = worldReport.seasons.isEmpty
        ? 0
        : worldReport.seasons.first.seasonIndex;
    final initialByClub = {
      for (final state in report.initialTenureStates) state.clubId: state,
    };
    if (initialByClub.length != clubIds.length) {
      issues.add('M16 initial tenure count mismatch.');
    }

    final fanTemplateByKey = {
      for (final item in report.fanTemplateReport.snapshots)
        '${item.context.seasonIndex}|${item.context.clubId}': item,
    };
    final mediaTemplateByKey = <String, MediaSeasonSnapshot>{};
    for (final season in report.sourceReport.baselineMediaReport.seasons) {
      for (final item in season.clubs) {
        mediaTemplateByKey['${season.seasonIndex}|${item.clubId}'] = item;
      }
    }
    final promiseByKey = {
      for (final item in report.sourceReport.promiseReport.snapshots)
        '${item.promise.seasonIndex}|${item.promise.clubId}': item,
    };
    final promisesByClub = <String, List<PromiseSeasonSnapshot>>{};
    for (final item in report.sourceReport.promiseReport.snapshots) {
      promisesByClub.putIfAbsent(item.promise.clubId, () => []).add(item);
    }
    final seasonReportByIndex = {
      for (final season in report.seasons) season.seasonIndex: season,
    };
    final electionByKey = {
      for (final election in report.elections)
        '${election.seasonIndex}|${election.clubId}': election,
    };
    final turnoverByKey = {
      for (final turnover in report.turnovers)
        '${turnover.electionSeasonIndex}|${turnover.clubId}': turnover,
    };
    final handoverByKey = {
      for (final handover in report.handovers)
        '${handover.electionSeasonIndex}|${handover.clubId}': handover,
    };

    var tenureStates = <String, PresidentTenureState>{};
    for (final clubId in clubIds) {
      final initial = initialByClub[clubId];
      if (initial == null) {
        issues.add('M16 missing initial tenure for $clubId.');
        continue;
      }
      if (initial.tenureNumber != 1 ||
          initial.startedSeasonIndex != firstSeasonIndex ||
          initial.reelectionsWon != 0) {
        issues.add('M16 invalid initial tenure for $clubId.');
      }
      tenureStates[clubId] = initial;
    }
    var fanStates = {
      for (final clubId in clubIds) clubId: FanState.initial(clubId),
    };
    var mediaStates = {
      for (final clubId in clubIds)
        clubId: MediaState(clubId: clubId, credibility: 65),
    };

    var expectedElections = 0;
    var expectedLosses = 0;
    for (var offset = 0; offset < worldReport.seasons.length; offset++) {
      final seasonIndex = worldReport.seasons[offset].seasonIndex;
      final seasonReport = seasonReportByIndex[seasonIndex];
      if (seasonReport == null || seasonReport.clubs.length != clubIds.length) {
        issues.add('M16 missing/incomplete season $seasonIndex.');
        continue;
      }
      final snapshotByClub = {
        for (final item in seasonReport.clubs) item.clubId: item,
      };

      for (final clubId in clubIds) {
        final key = '$seasonIndex|$clubId';
        final actual = snapshotByClub[clubId];
        final fanTemplate = fanTemplateByKey[key];
        final mediaTemplate = mediaTemplateByKey[key];
        final promise = promiseByKey[key];
        final tenure = tenureStates[clubId];
        final currentFan = fanStates[clubId];
        final currentMedia = mediaStates[clubId];
        if (actual == null ||
            fanTemplate == null ||
            mediaTemplate == null ||
            promise == null ||
            tenure == null ||
            currentFan == null ||
            currentMedia == null) {
          issues.add('M16 replay source missing $key.');
          continue;
        }
        if (actual.presidentId != tenure.president.id ||
            actual.fanBefore.signature != currentFan.signature ||
            actual.mediaBefore != currentMedia.credibility) {
          issues.add('M16 opening state mismatch $key.');
        }
        final expectedFan = currentFan.apply(fanTemplate.reasons);
        if (actual.fanAfter.signature != expectedFan.signature) {
          issues.add('M16 fan equation mismatch $key.');
        }
        final expectedStatement = mediaTemplate.statement == null
            ? null
            : mediaEngine.evaluate(
                state: currentMedia,
                statement: mediaTemplate.statement!,
                managerChanged: mediaTemplate.managerChanged,
              );
        final expectedAfterStatement =
            expectedStatement?.after ?? currentMedia.credibility;
        if (actual.mediaAfterStatement != expectedAfterStatement ||
            actual.statementChange?.signature != expectedStatement?.signature) {
          issues.add('M16 statement equation mismatch $key.');
        }
        final expectedPromise = promiseMediaEngine.evaluate(
          state: MediaState(
            clubId: clubId,
            credibility: expectedAfterStatement,
          ),
          resolution: promise.resolution,
        );
        if (actual.promiseChange.signature != expectedPromise.signature ||
            actual.mediaAfterPromise != expectedPromise.after) {
          issues.add('M16 promise-media equation mismatch $key.');
        }
        fanStates[clubId] = expectedFan;
        mediaStates[clubId] = MediaState(
          clubId: clubId,
          credibility: expectedPromise.after,
        );
      }

      if ((offset + 1) % report.electionInterval != 0) continue;
      final termNumber = (offset + 1) ~/ report.electionInterval;
      final termStart =
          worldReport.seasons[offset - report.electionInterval + 1].seasonIndex;
      for (final clubId in clubIds) {
        expectedElections++;
        final key = '$seasonIndex|$clubId';
        final fan = fanStates[clubId]!;
        final media = mediaStates[clubId]!;
        final tenure = tenureStates[clubId]!;
        final promises = (promisesByClub[clubId] ?? const <PromiseSeasonSnapshot>[])
            .where((item) =>
                item.promise.seasonIndex >= termStart &&
                item.promise.seasonIndex <= seasonIndex)
            .toList();
        if (promises.length != report.electionInterval) {
          issues.add('M16 promise term coverage mismatch $key.');
          continue;
        }
        final promiseScore = (promises.fold<int>(
                  0,
                  (sum, item) => sum + item.resolution.score,
                ) /
                promises.length)
            .round();
        final expectedElection = electionEngine.evaluate(
          clubId: clubId,
          seasonIndex: seasonIndex,
          termNumber: termNumber,
          fanOverallTrust: fan.overallTrust,
          fanIdentityTrust: fan.identityTrust,
          mediaCredibility: media.credibility,
          promiseScore: promiseScore,
          careerSeed: report.careerSeed,
          simulationVersion: report.simulationVersion,
        );
        final actualElection = electionByKey[key];
        if (actualElection == null ||
            actualElection.signature != expectedElection.signature) {
          issues.add('M16 election equation mismatch $key.');
          continue;
        }
        if (expectedElection.outcome == PresidentElectionOutcome.reelected) {
          if (turnoverByKey.containsKey(key) || handoverByKey.containsKey(key)) {
            issues.add('M16 reelection created handover $key.');
          }
          tenureStates[clubId] = tenure.recordReelection();
          continue;
        }

        expectedLosses++;
        final turnover = turnoverByKey[key];
        final handover = handoverByKey[key];
        if (turnover == null || handover == null) {
          issues.add('M16 election loss missing handover $key.');
          continue;
        }
        final incoming = profileGenerator.generateChallenger(
          clubId: clubId,
          seasonIndex: seasonIndex,
          electionTermNumber: termNumber,
          careerSeed: report.careerSeed,
          simulationVersion: report.simulationVersion,
        );
        if (turnover.outgoing.id != tenure.president.id ||
            turnover.incoming.id != incoming.id ||
            handover.outgoingPresidentId != tenure.president.id ||
            handover.incomingPresidentId != incoming.id) {
          issues.add('M16 president identity handover mismatch $key.');
        }
        final expectedResetFan = handoverPolicy.resetFan(fan);
        final expectedResetMedia = handoverPolicy.resetMedia(media);
        if (handover.fanBefore.signature != fan.signature ||
            handover.fanAfter.signature != expectedResetFan.signature ||
            handover.mediaBefore.signature != media.signature ||
            handover.mediaAfter.signature != expectedResetMedia.signature) {
          issues.add('M16 reputation reset mismatch $key.');
        }
        if (handover.fanAfter.sportingTrust != fan.sportingTrust ||
            handover.fanAfter.financialTrust != fan.financialTrust ||
            handover.fanAfter.transferTrust != fan.transferTrust) {
          issues.add('M16 club-level fan trust changed on handover $key.');
        }
        fanStates[clubId] = expectedResetFan;
        mediaStates[clubId] = expectedResetMedia;
        tenureStates[clubId] = tenure.handover(
          incoming: incoming,
          effectiveSeasonIndex: seasonIndex + 1,
        );
      }
    }

    if (report.totalElections != expectedElections) {
      issues.add('M16 election count mismatch.');
    }
    if (report.losses != expectedLosses ||
        report.totalTurnovers != expectedLosses ||
        report.handovers.length != expectedLosses) {
      issues.add('M16 turnover/reset count mismatch.');
    }

    final finalTenureByClub = {
      for (final item in report.finalTenureStates) item.clubId: item,
    };
    final finalFanByClub = {
      for (final item in report.finalFanStates) item.clubId: item,
    };
    final finalMediaByClub = {
      for (final item in report.finalMediaStates) item.clubId: item,
    };
    for (final clubId in clubIds) {
      if (finalTenureByClub[clubId]?.signature != tenureStates[clubId]?.signature) {
        issues.add('M16 final tenure mismatch $clubId.');
      }
      if (finalFanByClub[clubId]?.signature != fanStates[clubId]?.signature) {
        issues.add('M16 final fan mismatch $clubId.');
      }
      if (finalMediaByClub[clubId]?.signature != mediaStates[clubId]?.signature) {
        issues.add('M16 final media mismatch $clubId.');
      }
    }
    return issues;
  }
}
