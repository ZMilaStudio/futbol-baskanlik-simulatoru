import '../election/president_management_profile.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../world/world_career_engine.dart';
import 'president_transfer_strategy_runtime.dart';
import 'transfer_activity_policy.dart';
import 'transfer_budget_policy.dart';
import 'transfer_market_engine.dart';
import 'transfer_market_result.dart';
import 'transfer_negotiation_policy.dart';
import 'transfer_youth_preference_policy.dart';

class PresidentTransferStrategyWindowContext {
  PresidentTransferStrategyWindowContext({
    required Iterable<Club> clubs,
    required Iterable<Player> players,
    required Iterable<ClubFinanceState> financeStates,
    required this.careerSeed,
    required this.seasonIndex,
    required this.simulationVersion,
  })  : clubs = List.unmodifiable(clubs),
        players = List.unmodifiable(players),
        financeStates = List.unmodifiable(financeStates);

  final List<Club> clubs;
  final List<Player> players;
  final List<ClubFinanceState> financeStates;
  final int careerSeed;
  final int seasonIndex;
  final int simulationVersion;

  int get decisionSeasonIndex => seasonIndex + 1;

  String get signature =>
      'season=$seasonIndex:decision=$decisionSeasonIndex:seed=$careerSeed:'
      'version=$simulationVersion:clubs=${clubs.length}:'
      'players=${players.length}:finances=${financeStates.length}';
}

abstract class PresidentTransferStrategyProfileProvider {
  const PresidentTransferStrategyProfileProvider();

  Map<String, PresidentManagementProfile> profilesForWindow(
    PresidentTransferStrategyWindowContext context,
  );
}

/// M54 bridges the proven M53 president transfer strategy adapter into the
/// exact transfer-window seam already used by [WorldCareerEngine].
///
/// The bridge is deliberately opt-in: the default [WorldCareerEngine] remains
/// unchanged. When injected, this engine substitutes for [TransferMarketEngine]
/// and invokes M53 before permanent transfers are selected. Existing explicit
/// policy maps retain priority and are forwarded directly to [delegate].
class PresidentTransferStrategyWorldMarketEngine extends TransferMarketEngine {
  const PresidentTransferStrategyWorldMarketEngine({
    required this.profileProvider,
    this.delegate = const TransferMarketEngine(),
  });

  final PresidentTransferStrategyProfileProvider profileProvider;
  final TransferMarketEngine delegate;

  @override
  TransferMarketResult simulateWindow({
    required List<Club> clubs,
    required List<Player> players,
    required List<ClubFinanceState> financeStates,
    required int careerSeed,
    required int seasonIndex,
    required int simulationVersion,
    Map<String, int>? contractYearsRemainingByPlayer,
    bool enableInstallments = false,
    Map<String, TransferBudgetPolicy>? budgetPoliciesByClub,
    Map<String, TransferActivityPolicy>? activityPoliciesByClub,
    Map<String, TransferNegotiationPolicy>? negotiationPoliciesByClub,
    Map<String, TransferYouthPreferencePolicy>? youthPreferencePoliciesByClub,
  }) {
    final hasExplicitPolicies = budgetPoliciesByClub != null ||
        activityPoliciesByClub != null ||
        negotiationPoliciesByClub != null ||
        youthPreferencePoliciesByClub != null;
    if (hasExplicitPolicies) {
      return delegate.simulateWindow(
        clubs: clubs,
        players: players,
        financeStates: financeStates,
        careerSeed: careerSeed,
        seasonIndex: seasonIndex,
        simulationVersion: simulationVersion,
        contractYearsRemainingByPlayer: contractYearsRemainingByPlayer,
        enableInstallments: enableInstallments,
        budgetPoliciesByClub: budgetPoliciesByClub,
        activityPoliciesByClub: activityPoliciesByClub,
        negotiationPoliciesByClub: negotiationPoliciesByClub,
        youthPreferencePoliciesByClub: youthPreferencePoliciesByClub,
      );
    }

    final context = PresidentTransferStrategyWindowContext(
      clubs: clubs,
      players: players,
      financeStates: financeStates,
      careerSeed: careerSeed,
      seasonIndex: seasonIndex,
      simulationVersion: simulationVersion,
    );
    final profiles = profileProvider.profilesForWindow(context);
    return PresidentTransferStrategyRuntimeEngine(
      marketEngine: delegate,
    ).simulateWindow(
      clubs: clubs,
      players: players,
      financeStates: financeStates,
      presidentProfilesByClub: profiles,
      careerSeed: careerSeed,
      seasonIndex: seasonIndex,
      simulationVersion: simulationVersion,
      contractYearsRemainingByPlayer: contractYearsRemainingByPlayer,
      enableInstallments: enableInstallments,
    ).market;
  }
}

class PresidentTransferStrategyWorldBridge {
  const PresidentTransferStrategyWorldBridge();

  WorldCareerEngine wrap({
    required WorldCareerEngine base,
    required PresidentTransferStrategyProfileProvider profileProvider,
  }) =>
      WorldCareerEngine(
        seasonEngine: base.seasonEngine,
        poolGenerator: base.poolGenerator,
        lifecycleEngine: base.lifecycleEngine,
        strengthCalculator: base.strengthCalculator,
        economyEngine: base.economyEngine,
        transferMarketEngine: PresidentTransferStrategyWorldMarketEngine(
          profileProvider: profileProvider,
          delegate: base.transferMarketEngine,
        ),
      );
}
