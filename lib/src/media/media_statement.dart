enum MediaTopic {
  managerFuture,
}

enum MediaStance {
  strongSupport,
  measuredSupport,
  pressure,
  noComment,
}

class MediaStatement {
  const MediaStatement({
    required this.id,
    required this.clubId,
    required this.targetManagerId,
    required this.seasonIndex,
    required this.topic,
    required this.stance,
  });

  final String id;
  final String clubId;
  final String targetManagerId;
  final int seasonIndex;
  final MediaTopic topic;
  final MediaStance stance;

  String get signature =>
      '$id:$clubId:$targetManagerId:s$seasonIndex:${topic.name}:${stance.name}';
}
