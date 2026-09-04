import 'media_credibility_change.dart';
import 'media_statement.dart';

class MediaSeasonSnapshot {
  const MediaSeasonSnapshot({
    required this.clubId,
    required this.managerId,
    required this.seasonIndex,
    required this.managerChanged,
    required this.credibilityBefore,
    required this.credibilityAfter,
    required this.statement,
    required this.change,
  });

  final String clubId;
  final String managerId;
  final int seasonIndex;
  final bool managerChanged;
  final int credibilityBefore;
  final int credibilityAfter;
  final MediaStatement? statement;
  final MediaCredibilityChange? change;

  String get signature =>
      '$clubId:$managerId:s$seasonIndex:$managerChanged:'
      '$credibilityBefore>$credibilityAfter:'
      '${statement?.signature ?? 'none'}:${change?.signature ?? 'none'}';
}

class MediaCareerSeason {
  MediaCareerSeason({
    required this.seasonIndex,
    required Iterable<MediaSeasonSnapshot> clubs,
  }) : clubs = List.unmodifiable(clubs);

  final int seasonIndex;
  final List<MediaSeasonSnapshot> clubs;

  String get signature {
    final sorted = List<MediaSeasonSnapshot>.of(clubs)
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    return 's$seasonIndex|${sorted.map((club) => club.signature).join('|')}';
  }
}
