import '../election/president_reputation_career_report.dart';
import 'president_runtime_checkpoint.dart';

class PresidentDomainHistorySummary {
  const PresidentDomainHistorySummary({
    required this.fanSnapshots,
    required this.fanReasons,
    required this.mediaStatements,
    required this.mediaContradictions,
    required this.promisesFulfilled,
    required this.promisesPartial,
    required this.promisesBroken,
  });

  final int fanSnapshots;
  final int fanReasons;
  final int mediaStatements;
  final int mediaContradictions;
  final int promisesFulfilled;
  final int promisesPartial;
  final int promisesBroken;

  int get totalPromises =>
      promisesFulfilled + promisesPartial + promisesBroken;

  void validate() {
    final values = <int>[
      fanSnapshots,
      fanReasons,
      mediaStatements,
      mediaContradictions,
      promisesFulfilled,
      promisesPartial,
      promisesBroken,
    ];
    if (values.any((value) => value < 0)) {
      throw ArgumentError('President domain history summary cannot be negative.');
    }
    if (mediaContradictions > mediaStatements) {
      throw ArgumentError('Media contradictions cannot exceed statements.');
    }
  }

  String get signature =>
      'fan=$fanSnapshots:$fanReasons:'
      'media=$mediaStatements:$mediaContradictions:'
      'promise=$promisesFulfilled:$promisesPartial:$promisesBroken';
}

class RecentFanMemory {
  RecentFanMemory({
    required this.clubId,
    required this.seasonIndex,
    required this.expectationSignature,
    required this.stateSignature,
    required Iterable<String> reasonSignatures,
  }) : reasonSignatures = List.unmodifiable(reasonSignatures);

  final String clubId;
  final int seasonIndex;
  final String expectationSignature;
  final String stateSignature;
  final List<String> reasonSignatures;

  void validate() {
    if (clubId.isEmpty || expectationSignature.isEmpty || stateSignature.isEmpty) {
      throw ArgumentError('Recent fan memory contains an empty identity.');
    }
    if (reasonSignatures.any((item) => item.isEmpty)) {
      throw ArgumentError('Recent fan memory contains an empty reason.');
    }
  }

  String get signature =>
      '$clubId:s$seasonIndex:$expectationSignature:$stateSignature:'
      '${reasonSignatures.join(',')}';
}

class RecentMediaMemory {
  const RecentMediaMemory({
    required this.clubId,
    required this.seasonIndex,
    required this.managerId,
    required this.managerChanged,
    required this.credibilityBefore,
    required this.credibilityAfter,
    required this.statementSignature,
    required this.changeSignature,
  });

  final String clubId;
  final int seasonIndex;
  final String managerId;
  final bool managerChanged;
  final int credibilityBefore;
  final int credibilityAfter;
  final String? statementSignature;
  final String? changeSignature;

  void validate() {
    if (clubId.isEmpty || managerId.isEmpty) {
      throw ArgumentError('Recent media memory contains an empty identity.');
    }
    if (credibilityBefore < 0 ||
        credibilityBefore > 100 ||
        credibilityAfter < 0 ||
        credibilityAfter > 100) {
      throw ArgumentError('Recent media credibility must be within 0..100.');
    }
  }

  String get signature =>
      '$clubId:$managerId:s$seasonIndex:$managerChanged:'
      '$credibilityBefore>$credibilityAfter:'
      '${statementSignature ?? 'none'}:${changeSignature ?? 'none'}';
}

class CurrentTermPromiseMemory {
  const CurrentTermPromiseMemory({
    required this.clubId,
    required this.seasonIndex,
    required this.promiseType,
    required this.status,
    required this.score,
  });

  final String clubId;
  final int seasonIndex;
  final String promiseType;
  final String status;
  final int score;

  void validate() {
    if (clubId.isEmpty || promiseType.isEmpty || status.isEmpty) {
      throw ArgumentError('Current-term promise memory contains an empty identity.');
    }
    if (score < 0 || score > 100) {
      throw ArgumentError.value(score, 'score', 'Promise score must be 0..100.');
    }
  }

  String get signature => '$clubId:s$seasonIndex:$promiseType:$status:$score';
}

class PresidentDomainMemoryCheckpoint {
  PresidentDomainMemoryCheckpoint({
    required this.presidentRuntime,
    required this.summary,
    required this.rawHistorySeasons,
    required Iterable<RecentFanMemory> recentFan,
    required Iterable<RecentMediaMemory> recentMedia,
    required Iterable<CurrentTermPromiseMemory> currentTermPromises,
  })  : recentFan = List.unmodifiable(recentFan),
        recentMedia = List.unmodifiable(recentMedia),
        currentTermPromises = List.unmodifiable(currentTermPromises) {
    validate();
  }

  factory PresidentDomainMemoryCheckpoint.capture({
    required PresidentRuntimeCheckpoint presidentRuntime,
    required PresidentReputationCareerReport report,
    int rawHistorySeasons = 2,
  }) {
    if (rawHistorySeasons <= 0) {
      throw ArgumentError.value(rawHistorySeasons, 'rawHistorySeasons');
    }
    if (report.seasonCount != presidentRuntime.completedSeasons) {
      throw ArgumentError(
        'President report season count must match president runtime completed seasons.',
      );
    }
    if (report.electionInterval != presidentRuntime.electionInterval) {
      throw ArgumentError(
        'President report election interval must match president runtime.',
      );
    }

    final promiseReport = report.sourceReport.promiseReport;
    final mediaReport = report.sourceReport.baselineMediaReport;
    final fanReport = report.fanTemplateReport;
    final summary = PresidentDomainHistorySummary(
      fanSnapshots: fanReport.snapshots.length,
      fanReasons: fanReport.reasonCount,
      mediaStatements: mediaReport.totalStatements,
      mediaContradictions: mediaReport.totalContradictions,
      promisesFulfilled: promiseReport.fulfilledPromises,
      promisesPartial: promiseReport.partialPromises,
      promisesBroken: promiseReport.brokenPromises,
    );

    final lastSeasonIndex = report.seasons.isEmpty
        ? presidentRuntime.nextSeasonIndex - 1
        : report.seasons.last.seasonIndex;
    final recentStart = lastSeasonIndex - rawHistorySeasons + 1;
    final recentFan = fanReport.snapshots
        .where((item) => item.context.seasonIndex >= recentStart)
        .map(
          (item) => RecentFanMemory(
            clubId: item.context.clubId,
            seasonIndex: item.context.seasonIndex,
            expectationSignature: item.expectation.signature,
            stateSignature: item.state.signature,
            reasonSignatures: item.reasons.map((reason) => reason.signature),
          ),
        )
        .toList()
      ..sort((a, b) {
        final season = a.seasonIndex.compareTo(b.seasonIndex);
        return season != 0 ? season : a.clubId.compareTo(b.clubId);
      });

    final recentMedia = <RecentMediaMemory>[];
    for (final season in mediaReport.seasons) {
      if (season.seasonIndex < recentStart) continue;
      for (final item in season.clubs) {
        recentMedia.add(
          RecentMediaMemory(
            clubId: item.clubId,
            seasonIndex: item.seasonIndex,
            managerId: item.managerId,
            managerChanged: item.managerChanged,
            credibilityBefore: item.credibilityBefore,
            credibilityAfter: item.credibilityAfter,
            statementSignature: item.statement?.signature,
            changeSignature: item.change?.signature,
          ),
        );
      }
    }
    recentMedia.sort((a, b) {
      final season = a.seasonIndex.compareTo(b.seasonIndex);
      return season != 0 ? season : a.clubId.compareTo(b.clubId);
    });

    final currentTermPromises = <CurrentTermPromiseMemory>[];
    final termOffset = presidentRuntime.seasonsIntoCurrentTerm;
    if (termOffset > 0) {
      final termStartSeasonIndex = lastSeasonIndex - termOffset + 1;
      for (final item in promiseReport.snapshots) {
        if (item.promise.seasonIndex < termStartSeasonIndex) continue;
        currentTermPromises.add(
          CurrentTermPromiseMemory(
            clubId: item.promise.clubId,
            seasonIndex: item.promise.seasonIndex,
            promiseType: item.promise.type.name,
            status: item.resolution.status.name,
            score: item.resolution.score,
          ),
        );
      }
      currentTermPromises.sort((a, b) {
        final season = a.seasonIndex.compareTo(b.seasonIndex);
        return season != 0 ? season : a.clubId.compareTo(b.clubId);
      });
    }

    return PresidentDomainMemoryCheckpoint(
      presidentRuntime: presidentRuntime,
      summary: summary,
      rawHistorySeasons: rawHistorySeasons,
      recentFan: recentFan,
      recentMedia: recentMedia,
      currentTermPromises: currentTermPromises,
    );
  }

  final PresidentRuntimeCheckpoint presidentRuntime;
  final PresidentDomainHistorySummary summary;
  final int rawHistorySeasons;
  final List<RecentFanMemory> recentFan;
  final List<RecentMediaMemory> recentMedia;
  final List<CurrentTermPromiseMemory> currentTermPromises;

  int get completedSeasons => presidentRuntime.completedSeasons;
  int get nextSeasonIndex => presidentRuntime.nextSeasonIndex;

  void validate() {
    presidentRuntime.validate();
    summary.validate();
    if (rawHistorySeasons <= 0) {
      throw ArgumentError.value(rawHistorySeasons, 'rawHistorySeasons');
    }
    final clubIds = presidentRuntime.clubs.map((item) => item.clubId).toSet();
    for (final item in recentFan) {
      item.validate();
      if (!clubIds.contains(item.clubId)) {
        throw ArgumentError('Recent fan memory references unknown club ${item.clubId}.');
      }
    }
    for (final item in recentMedia) {
      item.validate();
      if (!clubIds.contains(item.clubId)) {
        throw ArgumentError('Recent media memory references unknown club ${item.clubId}.');
      }
    }
    for (final item in currentTermPromises) {
      item.validate();
      if (!clubIds.contains(item.clubId)) {
        throw ArgumentError(
          'Current-term promise memory references unknown club ${item.clubId}.',
        );
      }
    }

    final expectedRecentPerDomain =
        completedSeasons < rawHistorySeasons ? completedSeasons : rawHistorySeasons;
    final expectedRecentCount = clubIds.length * expectedRecentPerDomain;
    if (recentFan.length != expectedRecentCount ||
        recentMedia.length != expectedRecentCount) {
      throw ArgumentError(
        'Recent president memory must contain exactly the bounded raw history window.',
      );
    }

    final expectedPromiseCount =
        clubIds.length * presidentRuntime.seasonsIntoCurrentTerm;
    if (currentTermPromises.length != expectedPromiseCount) {
      throw ArgumentError(
        'Current-term promise memory does not match the election cursor.',
      );
    }
  }

  String get signature =>
      '${presidentRuntime.signature}|summary=${summary.signature}:'
      'window=$rawHistorySeasons:'
      'fan=${recentFan.map((item) => item.signature).join('|')}:'
      'media=${recentMedia.map((item) => item.signature).join('|')}:'
      'term=${currentTermPromises.map((item) => item.signature).join('|')}';
}
