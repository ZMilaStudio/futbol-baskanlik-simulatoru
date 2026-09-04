class MediaState {
  const MediaState({
    required this.clubId,
    required this.credibility,
  });

  final String clubId;
  final int credibility;

  MediaState copyWith({int? credibility}) => MediaState(
        clubId: clubId,
        credibility: credibility ?? this.credibility,
      );

  String get signature => '$clubId:$credibility';
}
