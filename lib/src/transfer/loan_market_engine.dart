import '../contract/player_contract.dart';
import '../core/money.dart';
import '../core/seeded_rng.dart';
import '../core/stable_hash.dart';
import '../finance/club_finance_state.dart';
import '../finance/transfer_cash_movement.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../player/player_position.dart';
import 'loan_agreement.dart';
import 'loan_market_result.dart';
import 'market_value_model.dart';

class LoanMarketEngine {
  const LoanMarketEngine({this.marketValueModel = const MarketValueModel()});

  final MarketValueModel marketValueModel;

  static const Map<PlayerPosition, int> _targets = {
    PlayerPosition.goalkeeper: 2,
    PlayerPosition.defender: 6,
    PlayerPosition.midfielder: 6,
    PlayerPosition.forward: 4,
  };

  LoanMarketResult simulateWindow({
    required List<Club> clubs,
    required List<Player> players,
    required List<ClubFinanceState> financeStates,
    required Map<String, PlayerContract> contractsByPlayer,
    required Set<String> permanentlyMovedPlayerIds,
    required int careerSeed,
    required int seasonIndex,
    required int nextSeasonIndex,
    required int simulationVersion,
  }) {
    final currentPlayers = List<Player>.of(players);
    final finances = {
      for (final state in financeStates) state.clubId: state,
    };
    final agreements = <LoanAgreement>[];
    final cashMovements = <TransferCashMovement>[];
    final loanedPlayerIds = <String>{};
    final loansOutByClub = <String, int>{};

    final orderedBorrowers = List<Club>.of(clubs)
      ..sort((a, b) => a.id.compareTo(b.id));

    for (final borrower in orderedBorrowers) {
      final borrowerState = finances[borrower.id];
      if (borrowerState == null) continue;
      final roster = currentPlayers
          .where((player) => player.clubId == borrower.id)
          .toList(growable: false);
      final neededPosition = _mostNeededPosition(roster);
      final positionAverage = _positionAverage(roster, neededPosition);

      final candidates = currentPlayers.where((player) {
        if (player.isFreeAgent || player.clubId == borrower.id) return false;
        if (player.position != neededPosition || player.age > 24) return false;
        if (permanentlyMovedPlayerIds.contains(player.id) ||
            loanedPlayerIds.contains(player.id)) {
          return false;
        }
        final contract = contractsByPlayer[player.id];
        if (contract == null ||
            contract.clubId != player.clubId ||
            !contract.isActiveDuring(nextSeasonIndex)) {
          return false;
        }
        final parentRoster = currentPlayers
            .where((candidate) => candidate.clubId == player.clubId)
            .toList(growable: false);
        if (parentRoster.length <= 17) return false;
        final parentPositionCount = parentRoster
            .where((candidate) => candidate.position == player.position)
            .length;
        if (parentPositionCount <= _targets[player.position]!) return false;
        if ((loansOutByClub[player.clubId] ?? 0) >= 2) return false;
        final upside = player.potential - player.ability;
        return upside >= 5.0 &&
            player.ability >= positionAverage - 7.0 &&
            player.ability <= positionAverage + 12.0;
      }).toList();

      candidates.sort((a, b) {
        final aScore = _candidateScore(a, careerSeed, seasonIndex, borrower.id);
        final bScore = _candidateScore(b, careerSeed, seasonIndex, borrower.id);
        final compare = bScore.compareTo(aScore);
        return compare != 0 ? compare : a.id.compareTo(b.id);
      });

      for (final candidate in candidates.take(8)) {
        final parentState = finances[candidate.clubId];
        final contract = contractsByPlayer[candidate.id];
        if (parentState == null || contract == null) continue;

        final rng = SeededRng(
          StableHash.combine32([
            careerSeed,
            simulationVersion,
            seasonIndex,
            StableHash.string32(borrower.id),
            StableHash.string32(candidate.id),
            StableHash.string32('loan-negotiation'),
          ]),
        );
        final value = marketValueModel.value(
          candidate,
          contractYearsRemaining: contract.yearsRemainingAt(nextSeasonIndex),
        );
        var loanFee = value.scaleBasisPoints(
          350 + (rng.nextDouble() * 350).floor(),
        );
        loanFee = loanFee
            .max(const Money.fromUnits(100000))
            .min(const Money.fromUnits(1500000));
        const reserve = Money.fromUnits(2000000);
        final spendable = borrowerState.cash - reserve;
        final feeCap = borrowerState.cash.scaleBasisPoints(800);
        final affordable = spendable.min(feeCap);
        if (affordable <= Money.zero || loanFee > affordable) continue;

        final wageShareBps = 4500 + (rng.nextDouble() * 3500).floor();
        final parentClubId = candidate.clubId;
        finances[borrower.id] = ClubFinanceState(
          clubId: borrower.id,
          cash: borrowerState.cash - loanFee,
          debt: borrowerState.debt,
        );
        finances[parentClubId] = ClubFinanceState(
          clubId: parentClubId,
          cash: parentState.cash + loanFee,
          debt: parentState.debt,
        );

        final index = currentPlayers.indexWhere(
          (player) => player.id == candidate.id,
        );
        currentPlayers[index] = candidate.copyWith(clubId: borrower.id);
        final agreement = LoanAgreement(
          playerId: candidate.id,
          parentClubId: parentClubId,
          loanClubId: borrower.id,
          startSeasonIndex: nextSeasonIndex,
          endSeasonIndex: nextSeasonIndex + 1,
          loanFee: loanFee,
          loanClubWageShareBps: wageShareBps,
        );
        agreements.add(agreement);
        cashMovements.add(
          TransferCashMovement(
            fromClubId: borrower.id,
            toClubId: parentClubId,
            amount: loanFee,
            reason: 'loan_fee',
            referenceId: candidate.id,
          ),
        );
        loanedPlayerIds.add(candidate.id);
        loansOutByClub[parentClubId] = (loansOutByClub[parentClubId] ?? 0) + 1;
        break;
      }
    }

    return LoanMarketResult(
      players: currentPlayers,
      financeStates: orderedBorrowers
          .map((club) => finances[club.id]!)
          .toList(growable: false),
      agreements: agreements,
      cashMovements: cashMovements,
    );
  }

  PlayerPosition _mostNeededPosition(List<Player> roster) {
    PlayerPosition? selected;
    var bestScore = double.negativeInfinity;
    for (final position in PlayerPosition.values) {
      final positionPlayers =
          roster.where((player) => player.position == position).toList();
      final shortage = _targets[position]! - positionPlayers.length;
      final average = _positionAverage(roster, position);
      final qualityGap = (68.0 - average).clamp(0.0, 25.0);
      final score = shortage * 18.0 + qualityGap;
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
    String borrowerId,
  ) {
    final upside = (player.potential - player.ability).clamp(0.0, 20.0);
    final noise = (StableHash.combine32([
              careerSeed,
              seasonIndex,
              StableHash.string32(borrowerId),
              StableHash.string32(player.id),
              StableHash.string32('loan-candidate-score'),
            ]) &
            0xffff) /
        65535.0;
    return player.ability + upside * 0.45 + noise * 2.0;
  }
}
