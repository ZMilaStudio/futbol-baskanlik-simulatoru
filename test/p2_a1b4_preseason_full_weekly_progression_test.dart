import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';
import 'package:test/test.dart';

class _FailOnWeekNineteen extends MatchEngine {
  const _FailOnWeekNineteen();

  @override
  MatchResult simulate({
    required Fixture fixture,
    required Club home,
    required Club away,
    required SimulationConfig config,
  }) {
    if (fixture.round == 19) {
      throw StateError('Injected real M2 MatchEngine failure at W19.');
    }
    return super.simulate(
      fixture: fixture, home: home, away: away, config: config,
    );
  }
}
