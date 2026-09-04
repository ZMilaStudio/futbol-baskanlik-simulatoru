import '../core/simulation_config.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import 'league_tier.dart';
import 'world_league.dart';

class WorldCheckpoint {
  WorldCheckpoint({
    required this.config,
    required this.completedSeasons,
    required Iterable<Club> baseClubs,
    required Iterable<WorldLeague> nextSeasonLeagues,
    required Iterable<Player> nextSeasonPlayers,
    required Iterable<ClubFinanceState> nextSeasonFinanceStates,
  })  : baseClubs = List.unmodifiable(baseClubs),
        nextSeasonLeagues = List.unmodifiable(nextSeasonLeagues),
        nextSeasonPlayers = List.unmodifiable(nextSeasonPlayers),
        nextSeasonFinanceStates = List.unmodifiable(nextSeasonFinanceStates) {
    validate();
  }

  final SimulationConfig config;
  final int completedSeasons;
  final List<Club> baseClubs;
  final List<WorldLeague> nextSeasonLeagues;
  final List<Player> nextSeasonPlayers;
  final List<ClubFinanceState> nextSeasonFinanceStates;

  int get nextSeasonIndex => config.seasonIndex + completedSeasons;

  void validate() {
    if (completedSeasons < 0) {
      throw ArgumentError.value(
        completedSeasons,
        'completedSeasons',
        'Must be non-negative.',
      );
    }
    if (baseClubs.length != 48) {
      throw ArgumentError('World checkpoint requires exactly 48 base clubs.');
    }

    final clubIds = <String>{};
    for (final club in baseClubs) {
      if (club.id.isEmpty || club.name.isEmpty) {
        throw ArgumentError('Checkpoint clubs require non-empty IDs and names.');
      }
      if (!clubIds.add(club.id)) {
        throw ArgumentError('Checkpoint club IDs must be unique.');
      }
      if (!club.strength.isFinite || club.strength < 40 || club.strength > 100) {
        throw ArgumentError('Invalid base strength for ${club.id}.');
      }
    }

    if (nextSeasonLeagues.length != LeagueTier.values.length) {
      throw ArgumentError('World checkpoint requires exactly 3 leagues.');
    }
    final tiers = <LeagueTier>{};
    final memberships = <String>[];
    for (final league in nextSeasonLeagues) {
      if (!tiers.add(league.tier)) {
        throw ArgumentError('League tiers must be unique in checkpoint.');
      }
      if (league.clubIds.length != 16) {
        throw ArgumentError('${league.name} must contain exactly 16 clubs.');
      }
      memberships.addAll(league.clubIds);
    }
    if (tiers.length != LeagueTier.values.length ||
        memberships.length != 48 ||
        memberships.toSet().length != 48 ||
        memberships.toSet().difference(clubIds).isNotEmpty ||
        clubIds.difference(memberships.toSet()).isNotEmpty) {
      throw ArgumentError(
        'Checkpoint league membership must contain every club exactly once.',
      );
    }

    final playerIds = <String>{};
    for (final player in nextSeasonPlayers) {
      if (player.id.isEmpty || player.name.isEmpty) {
        throw ArgumentError('Checkpoint players require non-empty IDs and names.');
      }
      if (!playerIds.add(player.id)) {
        throw ArgumentError('Checkpoint player IDs must be unique.');
      }
      if (!clubIds.contains(player.clubId) && !player.isFreeAgent) {
        throw ArgumentError(
          'Player ${player.id} references unknown club ${player.clubId}.',
        );
      }
      if (player.age < 15 || player.age > 60 || player.retirementAge < player.age) {
        throw ArgumentError('Invalid age state for player ${player.id}.');
      }
      if (!player.ability.isFinite ||
          !player.potential.isFinite ||
          player.ability < 0 ||
          player.ability > 100 ||
          player.potential < 0 ||
          player.potential > 100) {
        throw ArgumentError('Invalid ability state for player ${player.id}.');
      }
    }

    if (nextSeasonFinanceStates.length != 48) {
      throw ArgumentError(
        'World checkpoint requires exactly 48 club finance states.',
      );
    }
    final financeIds = <String>{};
    for (final state in nextSeasonFinanceStates) {
      if (!clubIds.contains(state.clubId) || !financeIds.add(state.clubId)) {
        throw ArgumentError('Invalid or duplicate finance state ${state.clubId}.');
      }
    }
    if (financeIds.length != clubIds.length ||
        financeIds.difference(clubIds).isNotEmpty ||
        clubIds.difference(financeIds).isNotEmpty) {
      throw ArgumentError('Finance state must contain every club exactly once.');
    }
  }
}
