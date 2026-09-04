import '../core/money.dart';
import '../core/seeded_rng.dart';
import '../core/stable_hash.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../player/player_position.dart';
import 'market_value_model.dart';
import 'transfer_activity_policy.dart';
import 'transfer_budget_policy.dart';
import 'transfer_deal.dart';
import 'transfer_installment.dart';
import 'transfer_market_result.dart';
import 'transfer_negotiation_policy.dart';
import 'transfer_youth_preference_policy.dart';

class TransferMarketEngine {
  const TransferMarketEngine({
    this.marketValueModel = const MarketValueModel(),
    this.budgetPolicyProvider,
    this.activityPolicyProvider,
    this.negotiationPolicyProvider,
    this.youthPreferencePolicyProvider,
  });

  final MarketValueModel marketValueModel;
  final TransferBudgetPolicyProvider? budgetPolicyProvider;
  final TransferActivityPolicyProvider? activityPolicyProvider;
  final TransferNegotiationPolicyProvider? negotiationPolicyProvider;
  final TransferYouthPreferencePolicyProvider? youthPreferencePolicyProvider;

  static const Map<PlayerPosition, int> _squadTargets = {
    PlayerPosition.goalkeeper: 2,
    PlayerPosition.defender: 6,
    PlayerPosition.midfielder: 6,
    PlayerPosition.forward: 4,
  };

  static const Map<PlayerPosition, int> _saleFloors = {
    PlayerPosition.goalkeeper: 1,
    PlayerPosition.defender: 4,
    PlayerPosition.midfielder: 3,
    PlayerPosition.forward: 3,
  };

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
    final currentPlayers = List<Player>.of(players);
    final finances = {
      for (final state in financeStates) state.clubId: state,
    };
    final deals = <TransferDeal>[];
    final movedPlayerIds = <String>{};
    var attemptedOffers = 0;

    final orderedClubs = List<Club>.of(clubs)
      ..sort((a, b) => a.id.compareTo(b.id));

    for (final buyer in orderedClubs) {
      final budgetPolicy = budgetPoliciesByClub?[buyer.id] ??
          budgetPolicyProvider?.call(buyer.id, seasonIndex + 1) ??
          TransferBudgetPolicy.neutral;
      final activityPolicy = activityPoliciesByClub?[buyer.id] ??
          activityPolicyProvider?.call(buyer.id, seasonIndex + 1) ??
          TransferActivityPolicy.neutral;
      final negotiationPolicy = negotiationPoliciesByClub?[buyer.id] ??
          negotiationPolicyProvider?.call(buyer.id, seasonIndex + 1) ??
          TransferNegotiationPolicy.neutral;
      final youthPreferencePolicy = youthPreferencePoliciesByClub?[buyer.id] ??
          youthPreferencePolicyProvider?.call(buyer.id, seasonIndex + 1) ??
          TransferYouthPreferencePolicy.neutral;
      for (var slot = 0; slot < activityPolicy.maxDealsPerWindow; slot++) {
        final buyerState = finances[buyer.id];
        if (buyerState == null) {
          throw StateError('Missing finance state for ${buyer.id}.');
        }
        final spendable = buyerState.cash - budgetPolicy.reserveCash;
        if (spendable <= Money.zero) break;

        final buyerRoster = currentPlayers
            .where((player) => player.clubId == buyer.id)
            .toList(growable: false);
        final position = _mostNeededPosition(buyerRoster);
        final buyerPositionAverage = _positionAverage(buyerRoster, position);

        final candidates = currentPlayers.where((player) {
          if (player.isFreeAgent) return false;
          if (player.clubId == buyer.id) return false;
          if (player.position != position) return false;
          if (player.age > 33) return false;
          if (movedPlayerIds.contains(player.id)) return false;
          final sellerRoster = currentPlayers
              .where((candidate) => candidate.clubId == player.clubId)
              .toList(growable: false);
          if (sellerRoster.length <= 15) return false;
          final sellerPositionCount = sellerRoster
              .where((candidate) => candidate.position == position)
              .length;
          if (sellerPositionCount <= _saleFloors[position]!) return false;
          final developmentUpside = player.potential - player.ability;
          return player.ability >= buyerPositionAverage - 1.5 ||
              (player.age <= 22 && developmentUpside >= 8.0);
        }).toList();

        candidates.sort((a, b) {
          final aScore = _candidateScore(
            a,
            careerSeed,
            seasonIndex,
            youthPreferencePolicy,
          );
          final bScore = _candidateScore(
            b,
            careerSeed,
            seasonIndex,
            youthPreferencePolicy,
          );
          final scoreCompare = bScore.compareTo(aScore);
          return scoreCompare != 0 ? scoreCompare : a.id.compareTo(b.id);
        });

        TransferDeal? completed;
        for (final candidate in candidates.take(8)) {
          attemptedOffers++;
          final sellerState = finances[candidate.clubId];
          if (sellerState == null) continue;

          final marketValue = marketValueModel.value(
            candidate,
            contractYearsRemaining:
                contractYearsRemainingByPlayer?[candidate.id],
          );
          final sellerRoster = currentPlayers
              .where((player) => player.clubId == candidate.clubId)
              .toList(growable: false);
          final sellerPositionCount = sellerRoster
              .where((player) => player.position == candidate.position)
              .length;
          final sellerTarget = _squadTargets[candidate.position]!;
          final buyerPositionCount = buyerRoster
              .where((player) => player.position == candidate.position)
              .length;
          final buyerTarget = _squadTargets[candidate.position]!;

          final rng = SeededRng(
            StableHash.combine32([
              careerSeed,
              simulationVersion,
              seasonIndex,
              StableHash.string32(buyer.id),
              StableHash.string32(candidate.id),
              StableHash.string32('transfer-negotiation'),
            ]),
          );
          final sellerScarcityBps = sellerPositionCount <= sellerTarget
              ? 1800
              : sellerPositionCount == sellerTarget + 1
                  ? 800
                  : 0;
          final youthPremiumBps = candidate.age <= 22 &&
                  candidate.potential - candidate.ability >= 10.0
              ? 1000
              : 0;
          final sellerPressureBps = sellerState.cash <=
                  const Money.fromUnits(3000000)
              ? -800
              : sellerState.debt > sellerState.cash
                  ? -400
                  : 0;
          final askBps = 9800 +
              sellerScarcityBps +
              youthPremiumBps +
              sellerPressureBps +
              (rng.nextDouble() * 700).floor();
          final shortage =
              (buyerTarget - buyerPositionCount).clamp(0, 3).toInt();
          final maxBidBps = 10300 +
              shortage * 700 +
              (rng.nextDouble() * 900).floor() +
              negotiationPolicy.maxBidAdjustmentBps;
          final askingPrice = marketValue.scaleBasisPoints(askBps);
          final maximumBid = marketValue.scaleBasisPoints(maxBidBps);
          final windowSpendCap =
              buyerState.cash.scaleBasisPoints(budgetPolicy.windowSpendCapBps);
          final affordable = spendable.min(windowSpendCap);

          if (askingPrice > maximumBid) continue;

          var upfrontFee = askingPrice;
          List<TransferInstallment> installments = const [];
          final regularAffordable = askingPrice <= affordable;

          if (enableInstallments &&
              askingPrice >= const Money.fromUnits(5000000)) {
            final acceptanceChance = regularAffordable
                ? 0.10
                : sellerPressureBps < 0
                    ? 0.48
                    : 0.25;
            final sellerAcceptsInstallments =
                rng.nextDouble() < acceptanceChance;
            if (sellerAcceptsInstallments) {
              final upfrontBps = 5800 + (rng.nextDouble() * 1500).floor();
              final proposedUpfront = askingPrice.scaleBasisPoints(upfrontBps);
              final totalCommitmentCap = buyerState.cash.scaleBasisPoints(
                budgetPolicy.totalCommitmentCapBps,
              );
              final installmentAffordable =
                  proposedUpfront <= affordable &&
                  askingPrice <= totalCommitmentCap;
              if (installmentAffordable) {
                upfrontFee = proposedUpfront;
                final future = askingPrice - upfrontFee;
                final firstMinor = future.minorUnits ~/ 2;
                installments = [
                  TransferInstallment(
                    dueSeasonIndex: seasonIndex + 1,
                    amount: Money.fromMinorUnits(firstMinor),
                  ),
                  TransferInstallment(
                    dueSeasonIndex: seasonIndex + 2,
                    amount: Money.fromMinorUnits(
                      future.minorUnits - firstMinor,
                    ),
                  ),
                ];
              } else if (!regularAffordable) {
                continue;
              }
            } else if (!regularAffordable) {
              continue;
            }
          } else if (!regularAffordable) {
            continue;
          }

          finances[buyer.id] = ClubFinanceState(
            clubId: buyer.id,
            cash: buyerState.cash - upfrontFee,
            debt: buyerState.debt,
          );
          finances[candidate.clubId] = ClubFinanceState(
            clubId: candidate.clubId,
            cash: sellerState.cash + upfrontFee,
            debt: sellerState.debt,
          );

          final index = currentPlayers.indexWhere(
            (player) => player.id == candidate.id,
          );
          currentPlayers[index] = candidate.copyWith(clubId: buyer.id);
          movedPlayerIds.add(candidate.id);
          completed = TransferDeal(
            playerId: candidate.id,
            playerName: candidate.name,
            position: candidate.position,
            fromClubId: candidate.clubId,
            toClubId: buyer.id,
            marketValue: marketValue,
            fee: askingPrice,
            upfrontFee: upfrontFee,
            installments: installments,
          );
          deals.add(completed);
          break;
        }

        if (completed == null) break;
      }
    }

    return TransferMarketResult(
      players: currentPlayers,
      financeStates: orderedClubs
          .map((club) => finances[club.id]!)
          .toList(growable: false),
      deals: deals,
      attemptedOffers: attemptedOffers,
    );
  }

  PlayerPosition _mostNeededPosition(List<Player> roster) {
    PlayerPosition? selected;
    var bestScore = double.negativeInfinity;
    for (final position in PlayerPosition.values) {
      final positionPlayers =
          roster.where((player) => player.position == position).toList();
      final target = _squadTargets[position]!;
      final shortage = target - positionPlayers.length;
      final average = _positionAverage(roster, position);
      final qualityGap = (72.0 - average).clamp(0.0, 25.0);
      final score = shortage * 20.0 + qualityGap;
      if (score > bestScore) {
        bestScore = score;
        selected = position;
      }
    }
    return selected!;
  }

  double _positionAverage(List<Player> roster, PlayerPosition position) {
    final players = roster.where((player) => player.position == position);
    if (players.isEmpty) return 45.0;
    final total = players.fold<double>(0, (sum, player) => sum + player.ability);
    return total / players.length;
  }

  double _candidateScore(
    Player player,
    int careerSeed,
    int seasonIndex,
    TransferYouthPreferencePolicy youthPreferencePolicy,
  ) {
    final upside = (player.potential - player.ability).clamp(0.0, 20.0);
    final ageBonus = player.age <= 23 ? 4.0 : player.age >= 31 ? -4.0 : 0.0;
    final youthSignal = upside * 0.25 + ageBonus;
    final noise = (StableHash.combine32([
              careerSeed,
              seasonIndex,
              StableHash.string32(player.id),
              StableHash.string32('transfer-candidate-score'),
            ]) &
            0xffff) /
        65535.0;
    return player.ability +
        youthPreferencePolicy.applyYouthSignal(youthSignal) +
        noise;
  }
}
