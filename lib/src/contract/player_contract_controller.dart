import '../core/money.dart';
import '../core/seeded_rng.dart';
import '../core/stable_hash.dart';
import '../finance/club_finance_state.dart';
import '../finance/wage_model.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../player/player_position.dart';
import '../transfer/transfer_deal.dart';
import '../world/league_tier.dart';
import '../world/world_league.dart';
import '../world/world_roster_hooks.dart';
import 'contract_event.dart';
import 'player_contract.dart';

class PlayerContractController implements WorldRosterHooks {
  PlayerContractController({
    required this.careerSeed,
    required this.simulationVersion,
    required this.initialSeasonIndex,
    this.wageModel = const WageModel(),
  });

  PlayerContractController.restore({
    required this.careerSeed,
    required this.simulationVersion,
    required this.initialSeasonIndex,
    required Iterable<PlayerContract> activeContracts,
    required Iterable<ContractEvent> events,
    this.wageModel = const WageModel(),
  }) {
    for (final contract in activeContracts) {
      if (_contracts.containsKey(contract.playerId)) {
        throw ArgumentError('Duplicate restored contract ${contract.playerId}.');
      }
      _contracts[contract.playerId] = contract;
    }
    _events.addAll(events);
    _initialized = true;
  }

  final int careerSeed;
  final int simulationVersion;
  final int initialSeasonIndex;
  final WageModel wageModel;

  bool _initialized = false;
  final Map<String, PlayerContract> _contracts = {};
  final List<ContractEvent> _events = [];

  List<PlayerContract> get activeContracts {
    final values = _contracts.values.toList()
      ..sort((a, b) => a.playerId.compareTo(b.playerId));
    return List.unmodifiable(values);
  }

  List<ContractEvent> get events => List.unmodifiable(_events);

  @override
  Map<String, Money>? annualWagesByClub({
    required int seasonIndex,
    required List<Player> players,
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required List<ClubFinanceState> financeStates,
  }) {
    _ensureInitialized(
      seasonIndex: seasonIndex,
      players: players,
      leagues: leagues,
    );
    final playersById = {for (final player in players) player.id: player};
    final totals = {for (final club in clubs) club.id: Money.zero};
    for (final contract in _contracts.values) {
      if (!contract.isActiveDuring(seasonIndex)) continue;
      final player = playersById[contract.playerId];
      if (player == null || player.isFreeAgent) continue;
      if (player.clubId != contract.clubId) {
        throw StateError('Contract club mismatch for ${player.id}.');
      }
      if (!totals.containsKey(contract.clubId)) {
        throw StateError('Unknown contract club ${contract.clubId}.');
      }
      totals[contract.clubId] = totals[contract.clubId]! + contract.annualWage;
    }
    return totals;
  }

  @override
  List<Player> prepareNextSeasonPlayers({
    required int seasonIndex,
    required int nextSeasonIndex,
    required List<Player> activePlayers,
    required List<Player> retiredPlayers,
    required List<Player> youthIntake,
    required List<Club> clubs,
    required List<WorldLeague> leaguesForNextSeason,
    required List<ClubFinanceState> financeStates,
  }) {
    if (!_initialized) {
      throw StateError('Contracts must be initialized before roster transition.');
    }

    for (final player in retiredPlayers) {
      _contracts.remove(player.id);
    }

    final tierByClub = _tierByClub(leaguesForNextSeason);
    final financeByClub = {
      for (final state in financeStates) state.clubId: state,
    };
    final players = List<Player>.of(activePlayers);

    for (final youth in youthIntake) {
      final tier = tierByClub[youth.clubId];
      if (tier == null) {
        throw StateError('Missing league tier for youth club ${youth.clubId}.');
      }
      final rng = _rng(nextSeasonIndex, youth.id, 'youth-contract');
      final term = 3 + (rng.nextDouble() * 3).floor();
      final wage = _expectedWage(youth, tier, rng, premiumBps: 8000);
      _contracts[youth.id] = PlayerContract(
        playerId: youth.id,
        clubId: youth.clubId,
        startSeasonIndex: nextSeasonIndex,
        endSeasonIndex: nextSeasonIndex + term,
        annualWage: wage,
      );
      _events.add(
        ContractEvent(
          seasonIndex: nextSeasonIndex,
          playerId: youth.id,
          type: ContractEventType.youth,
          fromClubId: null,
          toClubId: youth.clubId,
          annualWage: wage,
          endSeasonIndex: nextSeasonIndex + term,
        ),
      );
    }

    final rosterCounts = <String, int>{for (final club in clubs) club.id: 0};
    for (final player in players) {
      if (!player.isFreeAgent && rosterCounts.containsKey(player.clubId)) {
        rosterCounts[player.clubId] = rosterCounts[player.clubId]! + 1;
      }
    }

    players.sort((a, b) => a.id.compareTo(b.id));
    for (var index = 0; index < players.length; index++) {
      final player = players[index];
      if (player.isFreeAgent) continue;
      final existing = _contracts[player.id];
      if (existing == null || existing.endSeasonIndex > nextSeasonIndex) {
        continue;
      }
      final tier = tierByClub[player.clubId];
      if (tier == null) {
        throw StateError('Missing league tier for ${player.clubId}.');
      }
      final rng = _rng(nextSeasonIndex, player.id, 'renewal');
      final upside = (player.potential - player.ability).clamp(0.0, 20.0);
      final agePenalty = player.age > 29 ? (player.age - 29) * 1.8 : 0.0;
      final renewalScore =
          player.ability + upside * 0.22 - agePenalty + rng.nextDouble() * 7.0;
      final mustKeep = (rosterCounts[player.clubId] ?? 0) <= 16;
      final renew = mustKeep || renewalScore >= 60.0;

      if (renew) {
        final term = _renewalTerm(player, rng);
        final premiumBps = 10100 + (rng.nextDouble() * 900).floor();
        final wage = _expectedWage(
          player,
          tier,
          rng,
          premiumBps: premiumBps,
        );
        _contracts[player.id] = PlayerContract(
          playerId: player.id,
          clubId: player.clubId,
          startSeasonIndex: nextSeasonIndex,
          endSeasonIndex: nextSeasonIndex + term,
          annualWage: wage,
        );
        _events.add(
          ContractEvent(
            seasonIndex: nextSeasonIndex,
            playerId: player.id,
            type: ContractEventType.renewal,
            fromClubId: player.clubId,
            toClubId: player.clubId,
            annualWage: wage,
            endSeasonIndex: nextSeasonIndex + term,
          ),
        );
      } else {
        final oldClubId = player.clubId;
        _contracts.remove(player.id);
        players[index] = player.copyWith(clubId: Player.freeAgentClubId);
        rosterCounts[oldClubId] = rosterCounts[oldClubId]! - 1;
        _events.add(
          ContractEvent(
            seasonIndex: nextSeasonIndex,
            playerId: player.id,
            type: ContractEventType.released,
            fromClubId: oldClubId,
            toClubId: null,
            annualWage: null,
            endSeasonIndex: null,
          ),
        );
      }
    }

    _signFreeAgents(
      nextSeasonIndex: nextSeasonIndex,
      players: players,
      clubs: clubs,
      tierByClub: tierByClub,
      financeByClub: financeByClub,
    );

    return List.unmodifiable(players);
  }

  @override
  Map<String, int>? contractYearsRemainingForTransfer({
    required int nextSeasonIndex,
    required List<Player> players,
  }) {
    final result = <String, int>{};
    for (final player in players) {
      if (player.isFreeAgent) continue;
      final contract = _contracts[player.id];
      if (contract == null || !contract.isActiveDuring(nextSeasonIndex)) {
        continue;
      }
      result[player.id] = contract.yearsRemainingAt(nextSeasonIndex);
    }
    return result;
  }

  @override
  void onTransferWindowCompleted({
    required int seasonIndex,
    required int nextSeasonIndex,
    required List<Player> playersBeforeWindow,
    required List<Player> playersAfterWindow,
    required List<TransferDeal> transfers,
    required List<Club> clubs,
    required List<WorldLeague> leaguesForNextSeason,
    required List<ClubFinanceState> financeStates,
  }) {
    if (transfers.isEmpty) return;
    final tierByClub = _tierByClub(leaguesForNextSeason);
    final playersById = {
      for (final player in playersAfterWindow) player.id: player,
    };
    for (final deal in transfers) {
      final player = playersById[deal.playerId];
      final tier = tierByClub[deal.toClubId];
      if (player == null || tier == null) {
        throw StateError('Missing transfer contract context for ${deal.playerId}.');
      }
      final rng = _rng(nextSeasonIndex, player.id, 'transfer-contract');
      final term = 3 + (rng.nextDouble() * 3).floor();
      final premiumBps = 10600 + (rng.nextDouble() * 1100).floor();
      final wage = _expectedWage(
        player,
        tier,
        rng,
        premiumBps: premiumBps,
      );
      _contracts[player.id] = PlayerContract(
        playerId: player.id,
        clubId: deal.toClubId,
        startSeasonIndex: nextSeasonIndex,
        endSeasonIndex: nextSeasonIndex + term,
        annualWage: wage,
      );
      _events.add(
        ContractEvent(
          seasonIndex: nextSeasonIndex,
          playerId: player.id,
          type: ContractEventType.transferContract,
          fromClubId: deal.fromClubId,
          toClubId: deal.toClubId,
          annualWage: wage,
          endSeasonIndex: nextSeasonIndex + term,
        ),
      );
    }
  }

  void _ensureInitialized({
    required int seasonIndex,
    required List<Player> players,
    required List<WorldLeague> leagues,
  }) {
    if (_initialized) return;
    if (seasonIndex != initialSeasonIndex) {
      throw StateError('Contract initialization season mismatch.');
    }
    final tierByClub = _tierByClub(leagues);
    final ordered = List<Player>.of(players)..sort((a, b) => a.id.compareTo(b.id));
    for (final player in ordered) {
      final tier = tierByClub[player.clubId];
      if (tier == null) {
        throw StateError('Missing initial league tier for ${player.clubId}.');
      }
      final rng = _rng(seasonIndex, player.id, 'initial-contract');
      final term = _initialTerm(player, rng);
      final wage = _expectedWage(player, tier, rng);
      _contracts[player.id] = PlayerContract(
        playerId: player.id,
        clubId: player.clubId,
        startSeasonIndex: seasonIndex,
        endSeasonIndex: seasonIndex + term,
        annualWage: wage,
      );
      _events.add(
        ContractEvent(
          seasonIndex: seasonIndex,
          playerId: player.id,
          type: ContractEventType.initial,
          fromClubId: null,
          toClubId: player.clubId,
          annualWage: wage,
          endSeasonIndex: seasonIndex + term,
        ),
      );
    }
    _initialized = true;
  }

  void _signFreeAgents({
    required int nextSeasonIndex,
    required List<Player> players,
    required List<Club> clubs,
    required Map<String, LeagueTier> tierByClub,
    required Map<String, ClubFinanceState> financeByClub,
  }) {
    final orderedClubs = List<Club>.of(clubs)..sort((a, b) => a.id.compareTo(b.id));
    for (final club in orderedClubs) {
      var signed = 0;
      while (signed < 3) {
        final roster = players
            .where((player) => player.clubId == club.id)
            .toList(growable: false);
        if (roster.length >= 18) break;
        final position = _mostNeededPosition(roster);
        var candidates = players
            .where(
              (player) =>
                  player.isFreeAgent &&
                  player.age <= 34 &&
                  player.position == position,
            )
            .toList();
        if (candidates.isEmpty) {
          candidates = players
              .where((player) => player.isFreeAgent && player.age <= 34)
              .toList();
        }
        if (candidates.isEmpty) break;
        candidates.sort((a, b) {
          final scoreCompare = _freeAgentScore(b).compareTo(_freeAgentScore(a));
          return scoreCompare != 0 ? scoreCompare : a.id.compareTo(b.id);
        });

        Player? selected;
        Money? selectedWage;
        final tier = tierByClub[club.id]!;
        final finance = financeByClub[club.id]!;
        for (final candidate in candidates.take(10)) {
          final rng = _rng(nextSeasonIndex, candidate.id, 'free-agent-${club.id}');
          final wage = _expectedWage(
            candidate,
            tier,
            rng,
            premiumBps: 10500,
          );
          if (wage <= finance.cash.scaleBasisPoints(1600)) {
            selected = candidate;
            selectedWage = wage;
            break;
          }
        }
        if (selected == null || selectedWage == null) break;

        final index = players.indexWhere((player) => player.id == selected!.id);
        final signedPlayer = selected.copyWith(clubId: club.id);
        players[index] = signedPlayer;
        final rng = _rng(nextSeasonIndex, selected.id, 'free-agent-term-${club.id}');
        final term = selected.age >= 31
            ? 1 + (rng.nextDouble() * 2).floor()
            : 2 + (rng.nextDouble() * 3).floor();
        _contracts[selected.id] = PlayerContract(
          playerId: selected.id,
          clubId: club.id,
          startSeasonIndex: nextSeasonIndex,
          endSeasonIndex: nextSeasonIndex + term,
          annualWage: selectedWage,
        );
        _events.add(
          ContractEvent(
            seasonIndex: nextSeasonIndex,
            playerId: selected.id,
            type: ContractEventType.freeAgentSigning,
            fromClubId: null,
            toClubId: club.id,
            annualWage: selectedWage,
            endSeasonIndex: nextSeasonIndex + term,
          ),
        );
        signed++;
      }
    }
  }

  int _initialTerm(Player player, SeededRng rng) {
    if (player.age <= 21) return 3 + (rng.nextDouble() * 3).floor();
    if (player.age >= 31) return 1 + (rng.nextDouble() * 3).floor();
    return 2 + (rng.nextDouble() * 4).floor();
  }

  int _renewalTerm(Player player, SeededRng rng) {
    if (player.age >= 32) return 1 + (rng.nextDouble() * 2).floor();
    if (player.age <= 23) return 3 + (rng.nextDouble() * 3).floor();
    return 2 + (rng.nextDouble() * 3).floor();
  }

  Money _expectedWage(
    Player player,
    LeagueTier tier,
    SeededRng rng, {
    int premiumBps = 10000,
  }) {
    final market = wageModel.annualWage(player);
    final randomBps = 9300 + (rng.nextDouble() * 1500).floor();
    return market
        .scaleBasisPoints(tier.costScaleBps)
        .scaleBasisPoints(randomBps)
        .scaleBasisPoints(premiumBps)
        .max(const Money.fromUnits(60000));
  }

  Map<String, LeagueTier> _tierByClub(List<WorldLeague> leagues) {
    final result = <String, LeagueTier>{};
    for (final league in leagues) {
      for (final clubId in league.clubIds) {
        result[clubId] = league.tier;
      }
    }
    return result;
  }

  SeededRng _rng(int seasonIndex, String playerId, String purpose) => SeededRng(
        StableHash.combine32([
          careerSeed,
          simulationVersion,
          seasonIndex,
          StableHash.string32(playerId),
          StableHash.string32(purpose),
        ]),
      );

  double _freeAgentScore(Player player) {
    final upside = (player.potential - player.ability).clamp(0.0, 20.0);
    final agePenalty = player.age > 29 ? (player.age - 29) * 1.2 : 0.0;
    return player.ability + upside * 0.18 - agePenalty;
  }

  PlayerPosition _mostNeededPosition(List<Player> roster) {
    const targets = {
      PlayerPosition.goalkeeper: 2,
      PlayerPosition.defender: 6,
      PlayerPosition.midfielder: 6,
      PlayerPosition.forward: 4,
    };
    PlayerPosition? selected;
    var lowestRatio = double.infinity;
    for (final entry in targets.entries) {
      final count = roster.where((player) => player.position == entry.key).length;
      final ratio = count / entry.value;
      if (ratio < lowestRatio) {
        lowestRatio = ratio;
        selected = entry.key;
      }
    }
    return selected!;
  }
}
