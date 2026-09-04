import '../media/media_credibility_change.dart';
import 'promise_media_credibility_change.dart';

class PromiseMediaSeasonSnapshot {
  const PromiseMediaSeasonSnapshot({
    required this.clubId,
    required this.seasonIndex,
    required this.credibilityBefore,
    required this.credibilityAfterStatement,
    required this.credibilityAfterPromise,
    required this.statementChange,
    required this.promiseChange,
  });

  final String clubId;
  final int seasonIndex;
  final int credibilityBefore;
  final int credibilityAfterStatement;
  final int credibilityAfterPromise;
  final MediaCredibilityChange? statementChange;
  final PromiseMediaCredibilityChange promiseChange;

  String get signature =>
      '$clubId:$seasonIndex:$credibilityBefore>$credibilityAfterStatement>'
      '$credibilityAfterPromise:stmt=${statementChange?.signature ?? 'none'}:'
      'promise=${promiseChange.signature}';
}

class PromiseMediaCareerSeason {
  PromiseMediaCareerSeason({
    required this.seasonIndex,
    required Iterable<PromiseMediaSeasonSnapshot> clubs,
  }) : clubs = List.unmodifiable(clubs);

  final int seasonIndex;
  final List<PromiseMediaSeasonSnapshot> clubs;

  String get signature =>
      '$seasonIndex:${clubs.map((club) => club.signature).join('|')}';
}
