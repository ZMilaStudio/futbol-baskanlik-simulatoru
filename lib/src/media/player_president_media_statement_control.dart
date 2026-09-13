import '../core/simulation_config.dart';
import '../election/president_reputation_career_engine.dart';
import '../league/club.dart';
import '../manager/manager_career_season.dart';
import '../promise/promise_media_career_engine.dart';
import '../save/advanced_history_compaction.dart';
import '../save/advanced_runtime_career_engine.dart';
import '../save/president_domain_career_engine.dart';
import '../save/president_domain_memory_checkpoint.dart';
import '../save/president_domain_resume_engine.dart';
import '../world/world_league.dart';
import 'media_career_engine.dart';
import 'media_statement.dart';
import 'media_statement_engine.dart';

class PlayerMediaStatementDecisionContext {
  PlayerMediaStatementDecisionContext({
    required this.clubSeason,
    required this.aiStatement,
    required Iterable<MediaStance> allowedStances,
  }) : allowedStances = List.unmodifiable(allowedStances);

  final ManagerClubSeason clubSeason;
  final MediaStatement aiStatement;
  final List<MediaStance> allowedStances;

  String get controlledClubId => clubSeason.clubId;
  int get seasonIndex => aiStatement.seasonIndex;

  String get signature =>
      '${clubSeason.signature}:ai=${aiStatement.signature}:'
      'allowed=${allowedStances.map((item) => item.name).join(',')}';
}

abstract class PlayerMediaStatementDecisionProvider {
  const PlayerMediaStatementDecisionProvider();

  MediaStance chooseStance(PlayerMediaStatementDecisionContext context);
}

/// M57 preserves M10's canonical statement-event generation while allowing the
/// player-president to choose only the stance of a real statement event for the
/// controlled club.
///
/// Event existence, topic, manager target, statement id and all credibility
/// effects remain canonical. The player cannot create a press event or inject a
/// credibility delta directly.
class PlayerPresidentMediaStatementEngine extends MediaStatementEngine {
  const PlayerPresidentMediaStatementEngine({
    required this.controlledClubId,
    this.decisionProvider,
    this.aiEngine = const MediaStatementEngine(),
  });

  final String controlledClubId;
  final PlayerMediaStatementDecisionProvider? decisionProvider;
  final MediaStatementEngine aiEngine;

  @override
  MediaStatement? generate({
    required ManagerClubSeason clubSeason,
    required int seasonIndex,
    required int careerSeed,
    required int simulationVersion,
  }) {
    final aiStatement = aiEngine.generate(
      clubSeason: clubSeason,
      seasonIndex: seasonIndex,
      careerSeed: careerSeed,
      simulationVersion: simulationVersion,
    );
    final provider = decisionProvider;
    if (provider == null || aiStatement == null) return aiStatement;
    if (controlledClubId.isEmpty) {
      throw ArgumentError('controlledClubId cannot be empty.');
    }
    if (clubSeason.clubId != controlledClubId) return aiStatement;

    final allowedStances = List<MediaStance>.unmodifiable(MediaStance.values);
    final chosenStance = provider.chooseStance(
      PlayerMediaStatementDecisionContext(
        clubSeason: clubSeason,
        aiStatement: aiStatement,
        allowedStances: allowedStances,
      ),
    );
    if (!allowedStances.contains(chosenStance)) {
      throw ArgumentError.value(
        chosenStance,
        'chosenStance',
        'Media stance is not a canonical M10 stance.',
      );
    }

    return MediaStatement(
      id: aiStatement.id,
      clubId: aiStatement.clubId,
      targetManagerId: aiStatement.targetManagerId,
      seasonIndex: aiStatement.seasonIndex,
      topic: aiStatement.topic,
      stance: chosenStance,
    );
  }
}

/// Convenience composition for the persisted president-domain runtime.
///
/// The decision provider is runtime-only and intentionally absent from every
/// save codec. A caller recreates this wrapper after loading a checkpoint.
class PlayerPresidentMediaStatementDomainCareerEngine {
  PlayerPresidentMediaStatementDomainCareerEngine({
    required String controlledClubId,
    PlayerMediaStatementDecisionProvider? decisionProvider,
    AdvancedRuntimeCareerEngine runtimeEngine = const AdvancedRuntimeCareerEngine(),
    AdvancedRuntimeHistoryCompactor compactor =
        const AdvancedRuntimeHistoryCompactor(),
    PresidentReputationCareerEngine reputationEngine =
        const PresidentReputationCareerEngine(),
  }) : _delegate = _buildDelegate(
          controlledClubId: controlledClubId,
          decisionProvider: decisionProvider,
          runtimeEngine: runtimeEngine,
          compactor: compactor,
          reputationEngine: reputationEngine,
        );

  final PresidentDomainCareerEngine _delegate;

  PresidentDomainResumeResult simulateWithCheckpoint({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    int seasonCount = 20,
    int electionInterval = 4,
    bool hasFutureSeasonAfterReport = false,
  }) =>
      _delegate.simulateWithCheckpoint(
        clubs: clubs,
        leagues: leagues,
        config: config,
        seasonCount: seasonCount,
        electionInterval: electionInterval,
        hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
      );

  PresidentDomainResumeResult resume({
    required PresidentDomainMemoryCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
  }) =>
      _delegate.resume(
        checkpoint: checkpoint,
        seasonCount: seasonCount,
        hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
      );

  static PresidentDomainCareerEngine _buildDelegate({
    required String controlledClubId,
    required PlayerMediaStatementDecisionProvider? decisionProvider,
    required AdvancedRuntimeCareerEngine runtimeEngine,
    required AdvancedRuntimeHistoryCompactor compactor,
    required PresidentReputationCareerEngine reputationEngine,
  }) {
    final sourceEngine = PromiseMediaCareerEngine(
      mediaEngine: MediaCareerEngine(
        statementEngine: PlayerPresidentMediaStatementEngine(
          controlledClubId: controlledClubId,
          decisionProvider: decisionProvider,
        ),
      ),
    );
    return PresidentDomainCareerEngine(
      runtimeEngine: runtimeEngine,
      compactor: compactor,
      sourceEngine: sourceEngine,
      reputationEngine: reputationEngine,
      resumeEngine: PresidentDomainResumeEngine(
        runtimeEngine: runtimeEngine,
        compactor: compactor,
        sourceEngine: sourceEngine,
        reputationEngine: reputationEngine,
      ),
    );
  }
}
