import '../core/money.dart';
import '../election/president_financial_discipline_transfer_policy.dart';
import '../election/president_management_profile.dart';
import '../election/president_risk_appetite_negotiation_policy.dart';
import '../election/president_transfer_ambition_activity_policy.dart';
import '../election/president_youth_orientation_transfer_policy.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import 'transfer_activity_policy.dart';
import 'transfer_budget_policy.dart';
import 'transfer_market_engine.dart';
import 'transfer_market_result.dart';
import 'transfer_negotiation_policy.dart';
import 'transfer_youth_preference_policy.dart';

class PresidentTransferStrategyPolicySet {
  const PresidentTransferStrategyPolicySet({
    required this.clubId,
    required this.decisionSeasonIndex,
    required this.profile,
    required this.budget,
    required this.activity,
    required this.negotiation,
    required this.youthPreference,
  });

  final String clubId;
  final int decisionSeasonIndex;
  final PresidentManagementProfile profile;
  final TransferBudgetPolicy budget;
  final TransferActivityPolicy activity;
  final TransferNegotiationPolicy negotiation;
  final TransferYouthPreferencePolicy youthPreference;

  String get signature =>
      '$clubId:s$decisionSeasonIndex:${profile.signature}:'
      'budget=${budget.signature}:activity=${activity.signature}:'
      'negotiation=${negotiation.signature}:'
      'youth=${youthPreference.youthSignalScaleBps}';
}

class PresidentTransferStrategyRuntimeResult {
  PresidentTransferStrategyRuntimeResult({
    required this.market,
    required Iterable<PresidentTransferStrategyPolicySet> policies,
  }) : policies = List.unmodifiable(
          policies.toList(growable: false)
            ..sort((a, b) => a.clubId.compareTo(b.clubId)),
        );

  final TransferMarketResult market;
  final List<PresidentTransferStrategyPolicySet> policies;

  PresidentTransferStrategyPolicySet policyFor(String clubId) =>
      policies.firstWhere((item) => item.clubId == clubId);

  String get signature =>
      '${policies.map((item) => item.signature).join('|')}:'
      'market=${market.signature}';
}

/// M53 adapts the president-management traits introduced in M20-M24 to one
/// real TransferMarketEngine window without changing M0-M52 runtime semantics.
///
/// The hook is deliberately stateless. President profiles remain the source of
/// truth and every club must be covered explicitly. M54 can compose this hook
/// into the player-president runtime after the lower-level contract is proven.
class PresidentTransferStrategyRuntimeEngine {
  const PresidentTransferStrategyRuntimeEngine({
    this.marketEngine = const TransferMarketEngine(),
    this.financialPolicy = const PresidentFinancialDisciplineTransferPolicy(),
    this.activityPolicy = const PresidentTransferAmbitionActivityPolicy(),
    this.negotiationPolicy = const PresidentRiskAppetiteNegotiationPolicy(),
    this.youthPolicy = const PresidentYouthOrientationTransferPolicy(),
  });

  final TransferMarketEngine marketEngine;
  final PresidentFinancialDisciplineTransferPolicy financialPolicy;
  final PresidentTransferAmbitionActivityPolicy activityPolicy;
  final PresidentRiskAppetiteNegotiationPolicy negotiationPolicy;
  final PresidentYouthOrientationTransferPolicy youthPolicy;

  PresidentTransferStrategyPolicySet resolvePolicy({
    required String clubId,
    required int decisionSeasonIndex,
    required PresidentManagementProfile profile,
  }) {
    if (clubId.isEmpty) {
      throw ArgumentError('clubId cannot be empty.');
    }
    if (decisionSeasonIndex < 0) {
      throw ArgumentError.value(
        decisionSeasonIndex,
        'decisionSeasonIndex',
        'Must be non-negative.',
      );
    }
    return PresidentTransferStrategyPolicySet(
      clubId: clubId,
      decisionSeasonIndex: decisionSeasonIndex,
      profile: profile,
      budget: financialPolicy.forProfile(profile),
      activity: activityPolicy.forProfile(profile),
      negotiation: negotiationPolicy.forProfile(profile),
      youthPreference: youthPolicy.forYouthOrientation(profile.youthOrientation),
    );
  }

  PresidentTransferStrategyRuntimeResult simulateWindow({
    required List<Club> clubs,
    required List<Player> players,
    required List<ClubFinanceState> financeStates,
    required Map<String, PresidentManagementProfile> presidentProfilesByClub,
    required int careerSeed,
    required int seasonIndex,
    required int simulationVersion,
    Map<String, int>? contractYearsRemainingByPlayer,
    bool enableInstallments = false,
  }) {
    final clubIds = clubs.map((club) => club.id).toSet();
    final profileIds = presidentProfilesByClub.keys.toSet();
    if (profileIds.length != clubIds.length ||
        profileIds.difference(clubIds).isNotEmpty ||
        clubIds.difference(profileIds).isNotEmpty) {
      throw ArgumentError(
        'President transfer profiles must cover every market club exactly.',
      );
    }

    final ordered = clubs.toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));
    final policies = <PresidentTransferStrategyPolicySet>[];
    final budget = <String, TransferBudgetPolicy>{};
    final activity = <String, TransferActivityPolicy>{};
    final negotiation = <String, TransferNegotiationPolicy>{};
    final youth = <String, TransferYouthPreferencePolicy>{};
    final decisionSeasonIndex = seasonIndex + 1;

    for (final club in ordered) {
      final profile = presidentProfilesByClub[club.id]!;
      final policy = resolvePolicy(
        clubId: club.id,
        decisionSeasonIndex: decisionSeasonIndex,
        profile: profile,
      );
      policies.add(policy);
      budget[club.id] = policy.budget;
      activity[club.id] = policy.activity;
      negotiation[club.id] = policy.negotiation;
      youth[club.id] = policy.youthPreference;
    }

    final market = marketEngine.simulateWindow(
      clubs: clubs,
      players: players,
      financeStates: financeStates,
      careerSeed: careerSeed,
      seasonIndex: seasonIndex,
      simulationVersion: simulationVersion,
      contractYearsRemainingByPlayer: contractYearsRemainingByPlayer,
      enableInstallments: enableInstallments,
      budgetPoliciesByClub: budget,
      activityPoliciesByClub: activity,
      negotiationPoliciesByClub: negotiation,
      youthPreferencePoliciesByClub: youth,
    );
    return PresidentTransferStrategyRuntimeResult(
      market: market,
      policies: policies,
    );
  }
}
