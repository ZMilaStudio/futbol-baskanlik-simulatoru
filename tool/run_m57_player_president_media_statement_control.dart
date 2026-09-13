import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_media_statement_control.dart';

void main() {
  final world = const FictionalWorldFactory().build();
  const config = SimulationConfig(careerSeed: 57057);
  final baseline = const MediaCareerEngine().simulate(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 1,
  );
  final baselineSeason = baseline.seasons.single;
  final controlledBaseline = baselineSeason.clubs.firstWhere(
    (item) => item.statement != null,
  );
  final chosen = controlledBaseline.statement!.stance == MediaStance.strongSupport
      ? MediaStance.pressure
      : MediaStance.strongSupport;
  final engine = MediaCareerEngine(
    statementEngine: PlayerPresidentMediaStatementEngine(
      controlledClubId: controlledBaseline.clubId,
      decisionProvider: _FixedMediaStanceProvider(chosen),
    ),
  );
  final player = engine.fromManagerReport(
    managerReport: baseline.managerReport,
    config: config,
  );
  final replay = engine.fromManagerReport(
    managerReport: baseline.managerReport,
    config: config,
  );
  final controlledPlayer = player.seasons.single.clubs.firstWhere(
    (item) => item.clubId == controlledBaseline.clubId,
  );

  var aiParity = 0;
  for (final baselineClub in baselineSeason.clubs) {
    if (baselineClub.clubId == controlledBaseline.clubId) continue;
    final playerClub = player.seasons.single.clubs.firstWhere(
      (item) => item.clubId == baselineClub.clubId,
    );
    if (baselineClub.signature == playerClub.signature) aiParity++;
  }

  final noEvent = baselineSeason.clubs.firstWhere(
    (item) => item.statement == null,
  );
  final counter = _CountingMediaStanceProvider(MediaStance.strongSupport);
  final noEventReport = MediaCareerEngine(
    statementEngine: PlayerPresidentMediaStatementEngine(
      controlledClubId: noEvent.clubId,
      decisionProvider: counter,
    ),
  ).fromManagerReport(
    managerReport: baseline.managerReport,
    config: config,
  );
  final noEventPlayer = noEventReport.seasons.single.clubs.firstWhere(
    (item) => item.clubId == noEvent.clubId,
  );

  final metadataPreserved = controlledPlayer.statement!.id ==
          controlledBaseline.statement!.id &&
      controlledPlayer.statement!.targetManagerId ==
          controlledBaseline.statement!.targetManagerId &&
      controlledPlayer.statement!.topic == controlledBaseline.statement!.topic;
  final eventPreserved = noEventPlayer.statement == null && counter.calls == 0;
  final realCredibility = controlledPlayer.credibilityAfter !=
      controlledBaseline.credibilityAfter;
  final deterministic = player.signature == replay.signature;

  final passed = aiParity == 47 &&
      controlledPlayer.statement!.stance == chosen &&
      metadataPreserved &&
      eventPreserved &&
      realCredibility &&
      deterministic;
  if (!passed) {
    throw StateError(
      'M57 canonical failure: controlled=${controlledBaseline.clubId} '
      'aiParity=$aiParity ai=${controlledBaseline.statement!.stance.name} '
      'player=${controlledPlayer.statement!.stance.name} '
      'metadataPreserved=$metadataPreserved eventPreserved=$eventPreserved '
      'realCredibility=$realCredibility deterministic=$deterministic',
    );
  }

  print(
    'M57_PLAYER_MEDIA_STATEMENT_CONTROL_PASS '
    'controlled=${controlledBaseline.clubId} aiParity=$aiParity '
    'ai=${controlledBaseline.statement!.stance.name} '
    'player=${controlledPlayer.statement!.stance.name} '
    'eventPreserved=true metadataPreserved=true realCredibility=true '
    'deterministic=true worldClubs=${world.clubs.length}',
  );
}

class _FixedMediaStanceProvider extends PlayerMediaStatementDecisionProvider {
  const _FixedMediaStanceProvider(this.stance);

  final MediaStance stance;

  @override
  MediaStance chooseStance(PlayerMediaStatementDecisionContext context) => stance;
}

class _CountingMediaStanceProvider extends PlayerMediaStatementDecisionProvider {
  _CountingMediaStanceProvider(this.stance);

  final MediaStance stance;
  int calls = 0;

  @override
  MediaStance chooseStance(PlayerMediaStatementDecisionContext context) {
    calls++;
    return stance;
  }
}
