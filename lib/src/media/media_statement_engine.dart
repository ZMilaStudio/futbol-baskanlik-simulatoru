import '../core/seeded_rng.dart';
import '../core/stable_hash.dart';
import '../manager/manager_career_season.dart';
import 'media_statement.dart';

class MediaStatementEngine {
  const MediaStatementEngine();

  MediaStatement? generate({
    required ManagerClubSeason clubSeason,
    required int seasonIndex,
    required int careerSeed,
    required int simulationVersion,
  }) {
    final rng = SeededRng(
      StableHash.combine32([
        careerSeed,
        simulationVersion,
        seasonIndex,
        StableHash.string32(clubSeason.clubId),
        StableHash.string32(clubSeason.managerId),
        StableHash.string32('media-manager-future'),
      ]),
    );

    final underPressure = clubSeason.relationshipAfter < 58 ||
        clubSeason.actualPosition >= clubSeason.expectedPosition + 3;
    final comfortable = clubSeason.relationshipAfter >= 72 &&
        clubSeason.actualPosition <= clubSeason.expectedPosition + 1;

    final eventRoll = rng.nextDouble();
    if (!underPressure && !comfortable && eventRoll >= 0.30) {
      return null;
    }

    final stanceRoll = rng.nextDouble();
    final MediaStance stance;
    if (comfortable) {
      stance = stanceRoll < 0.72
          ? MediaStance.strongSupport
          : MediaStance.measuredSupport;
    } else if (underPressure) {
      if (stanceRoll < 0.18) {
        stance = MediaStance.strongSupport;
      } else if (stanceRoll < 0.48) {
        stance = MediaStance.measuredSupport;
      } else if (stanceRoll < 0.86) {
        stance = MediaStance.pressure;
      } else {
        stance = MediaStance.noComment;
      }
    } else if (stanceRoll < 0.28) {
      stance = MediaStance.strongSupport;
    } else if (stanceRoll < 0.74) {
      stance = MediaStance.measuredSupport;
    } else {
      stance = MediaStance.noComment;
    }

    return MediaStatement(
      id: 'media_${clubSeason.clubId}_s${seasonIndex}_${clubSeason.managerId}',
      clubId: clubSeason.clubId,
      targetManagerId: clubSeason.managerId,
      seasonIndex: seasonIndex,
      topic: MediaTopic.managerFuture,
      stance: stance,
    );
  }
}
