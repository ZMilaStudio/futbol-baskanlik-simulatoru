import 'media_credibility_change.dart';
import 'media_state.dart';
import 'media_statement.dart';

class MediaCredibilityEngine {
  const MediaCredibilityEngine();

  MediaCredibilityChange evaluate({
    required MediaState state,
    required MediaStatement statement,
    required bool managerChanged,
  }) {
    final MediaCredibilityReason reason;
    final MediaResolution resolution;
    final int rawDelta;

    if (managerChanged) {
      switch (statement.stance) {
        case MediaStance.strongSupport:
          reason = MediaCredibilityReason.supportBroken;
          resolution = MediaResolution.contradiction;
          rawDelta = -10;
        case MediaStance.measuredSupport:
          reason = MediaCredibilityReason.measuredSupportBroken;
          resolution = MediaResolution.contradiction;
          rawDelta = -4;
        case MediaStance.pressure:
          reason = MediaCredibilityReason.pressureFollowedByChange;
          resolution = MediaResolution.consistent;
          rawDelta = 3;
        case MediaStance.noComment:
          reason = MediaCredibilityReason.noComment;
          resolution = MediaResolution.neutral;
          rawDelta = 0;
      }
    } else {
      switch (statement.stance) {
        case MediaStance.strongSupport:
          reason = MediaCredibilityReason.supportHonored;
          resolution = MediaResolution.consistent;
          rawDelta = 2;
        case MediaStance.measuredSupport:
          reason = MediaCredibilityReason.measuredSupportHonored;
          resolution = MediaResolution.consistent;
          rawDelta = 1;
        case MediaStance.pressure:
          reason = MediaCredibilityReason.pressureWithoutChange;
          resolution = MediaResolution.neutral;
          rawDelta = 0;
        case MediaStance.noComment:
          reason = MediaCredibilityReason.noComment;
          resolution = MediaResolution.neutral;
          rawDelta = 0;
      }
    }

    var adjustedDelta = rawDelta;
    final projected = state.credibility + adjustedDelta;
    if (projected > 85) {
      adjustedDelta -= 1;
    } else if (projected < 35) {
      adjustedDelta += 1;
    }

    final after = (state.credibility + adjustedDelta).clamp(0, 100).toInt();
    return MediaCredibilityChange(
      reason: reason,
      resolution: resolution,
      delta: after - state.credibility,
      before: state.credibility,
      after: after,
    );
  }
}
