import '../core/simulation_config.dart';
import '../election/president_reputation_career_engine.dart';
import '../league/club.dart';
import '../save/advanced_history_compaction.dart';
import '../save/advanced_runtime_career_engine.dart';
import '../save/president_domain_career_engine.dart';
import '../save/president_domain_memory_checkpoint.dart';
import '../save/president_domain_resume_engine.dart';
import '../world/league_tier.dart';
import '../world/world_league.dart';
import 'president_promise.dart';
import 'promise_career_engine.dart';
import 'promise_context.dart';
import 'promise_generator.dart';
import 'promise_media_career_engine.dart';

class PlayerPromiseDecisionContext {
  PlayerPromiseDecisionContext({
    required this.context,
    required this.aiPromise,
    required Iterable<PresidentPromiseType> allowedTypes,
  }) : allowedTypes = List.unmodifiable(allowedTypes);

  final PresidentPromiseContext context;
  final PresidentPromise aiPromise;
  final List<PresidentPromiseType> allowedTypes;

  String get controlledClubId => context.clubId;
  int get seasonIndex => context.seasonIndex;

  String get signature =>
      '${context.signature}:ai=${aiPromise.signature}:'
      'allowed=${allowedTypes.map((item) => item.name).join(',')}';
}

abstract class PlayerPromiseDecisionProvider {
  const PlayerPromiseDecisionProvider();

  PresidentPromiseType choosePromise(PlayerPromiseDecisionContext context);

  void onApplied(
    PlayerPromiseDecisionContext context,
    PresidentPromise promise,
  ) {}
}

/// M56 keeps M11's promise meanings and targets canonical while allowing the
/// player-president to select the promise type for the controlled club.
///
/// The provider can only choose a type that is valid for the preseason context.
/// It cannot inject arbitrary league targets, debt targets, scores, fan trust,
/// media credibility, or election effects. All downstream effects continue to
/// flow through the existing M11-M16 engines.
class PlayerPresidentPromiseGenerator extends PromiseGenerator {
  const PlayerPresidentPromiseGenerator({
    required this.controlledClubId,
    this.decisionProvider,
    this.aiGenerator = const PromiseGenerator(),
  });

  final String controlledClubId;
  final PlayerPromiseDecisionProvider? decisionProvider;
  final PromiseGenerator aiGenerator;

  @override
  PresidentPromise generate({
    required PresidentPromiseContext context,
    required int careerSeed,
    required int simulationVersion,
  }) {
    final aiPromise = aiGenerator.generate(
      context: context,
      careerSeed: careerSeed,
      simulationVersion: simulationVersion,
    );
    final provider = decisionProvider;
    if (provider == null) return aiPromise;
    if (controlledClubId.isEmpty) {
      throw ArgumentError('controlledClubId cannot be empty.');
    }
    if (context.clubId != controlledClubId) return aiPromise;

    final allowedTypes = allowedPromiseTypes(context);
    final decisionContext = PlayerPromiseDecisionContext(
      context: context,
      aiPromise: aiPromise,
      allowedTypes: allowedTypes,
    );
    final chosenType = provider.choosePromise(decisionContext);
    final promise = canonicalPromiseFor(context: context, type: chosenType);
    provider.onApplied(decisionContext, promise);
    return promise;
  }

  static List<PresidentPromiseType> allowedPromiseTypes(
    PresidentPromiseContext context,
  ) {
    final types = <PresidentPromiseType>[
      PresidentPromiseType.finishTopHalf,
    ];

    if (context.financialStress) {
      types.add(PresidentPromiseType.reduceDebt);
      types.add(PresidentPromiseType.stabilizeFinances);
    }
    if (context.expectedPosition >= context.leagueSize - 3) {
      types.add(PresidentPromiseType.avoidRelegation);
    }
    if (context.tier != LeagueTier.first && context.expectedPosition <= 5) {
      types.add(PresidentPromiseType.earnPromotion);
    }
    if (context.tier == LeagueTier.first && context.expectedPosition <= 3) {
      types.add(PresidentPromiseType.challengeTitle);
    }

    return List.unmodifiable(types);
  }

  static PresidentPromise canonicalPromiseFor({
    required PresidentPromiseContext context,
    required PresidentPromiseType type,
  }) {
    final allowedTypes = allowedPromiseTypes(context);
    if (!allowedTypes.contains(type)) {
      throw ArgumentError.value(
        type,
        'type',
        'Promise type is not valid for this preseason context.',
      );
    }

    final targetLeaguePosition = switch (type) {
      PresidentPromiseType.finishTopHalf => context.leagueSize ~/ 2,
      PresidentPromiseType.earnPromotion => 3,
      PresidentPromiseType.challengeTitle => 1,
      _ => null,
    };
    final targetDebtReductionBps = type == PresidentPromiseType.reduceDebt
        ? (context.severeFinancialStress ? 1200 : 800)
        : null;

    return PresidentPromise(
      id: 'promise_${context.clubId}_s${context.seasonIndex}',
      clubId: context.clubId,
      seasonIndex: context.seasonIndex,
      type: type,
      targetLeaguePosition: targetLeaguePosition,
      targetDebtReductionBps: targetDebtReductionBps,
    );
  }
}

/// Convenience composition for the persisted president-domain runtime.
///
/// The decision provider is intentionally runtime-only and is not serialized.
/// A caller recreates this wrapper after loading a checkpoint, exactly like the
/// other player-president decision providers introduced in M49-M55.
class PlayerPresidentPromiseDomainCareerEngine {
  PlayerPresidentPromiseDomainCareerEngine({
    required String controlledClubId,
    PlayerPromiseDecisionProvider? decisionProvider,
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
    required PlayerPromiseDecisionProvider? decisionProvider,
    required AdvancedRuntimeCareerEngine runtimeEngine,
    required AdvancedRuntimeHistoryCompactor compactor,
    required PresidentReputationCareerEngine reputationEngine,
  }) {
    final sourceEngine = PromiseMediaCareerEngine(
      promiseEngine: PromiseCareerEngine(
        generator: PlayerPresidentPromiseGenerator(
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
