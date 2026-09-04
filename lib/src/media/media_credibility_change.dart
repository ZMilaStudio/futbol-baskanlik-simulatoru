enum MediaResolution {
  consistent,
  contradiction,
  neutral,
}

enum MediaCredibilityReason {
  supportHonored,
  supportBroken,
  measuredSupportHonored,
  measuredSupportBroken,
  pressureFollowedByChange,
  pressureWithoutChange,
  noComment,
}

class MediaCredibilityChange {
  const MediaCredibilityChange({
    required this.reason,
    required this.resolution,
    required this.delta,
    required this.before,
    required this.after,
  });

  final MediaCredibilityReason reason;
  final MediaResolution resolution;
  final int delta;
  final int before;
  final int after;

  String get signature =>
      '${reason.name}:${resolution.name}:$delta:$before>$after';
}
