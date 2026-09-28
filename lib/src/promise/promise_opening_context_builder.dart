import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../world/world_league.dart';
import 'promise_context.dart';

/// Pure preseason source for M11 promise contexts.
///
/// [effectiveClubs] are the actual season-opening clubs after roster strength
/// derivation and applicable world hooks. [openingFinanceStates] must be the
/// finance state *before* this season; no completed report is consumed.
/// This builder neither generates nor resolves promises.
class PromiseOpeningContextBuilder {
  const PromiseOpeningContextBuilder();

  List<PresidentPromiseContext> build({
    required int seasonIndex,
    required Iterable<Club> effectiveClubs,
    required Iterable<WorldLeague> leagues,
    required Iterable<ClubFinanceState> openingFinanceStates,
  }) {
    if (seasonIndex < 0) {
      throw ArgumentError.value(seasonIndex, 'seasonIndex');
    }

    final byClub = <String, Club>{};
    for (final club in effectiveClubs) {
      if (club.id.isEmpty || !club.strength.isFinite ||
          byClub.containsKey(club.id)) {
        throw ArgumentError('Invalid or duplicate preseason club ${club.id}.');
      }
      byClub[club.id] = club;
    }
    if (byClub.isEmpty) {
      throw ArgumentError('Preseason clubs cannot be empty.');
    }

    final byFinance = <String, ClubFinanceState>{};
    for (final state in openingFinanceStates) {
      if (state.clubId.isEmpty || byFinance.containsKey(state.clubId)) {
        throw ArgumentError(
          'Invalid or duplicate opening finance for ${state.clubId}.',
        );
      }
      byFinance[state.clubId] = state;
    }
    if (byFinance.length != byClub.length ||
        !byFinance.keys.toSet().containsAll(byClub.keys)) {
      throw ArgumentError('Opening finance must cover each club exactly once.');
    }

    final contexts = <String, PresidentPromiseContext>{};
    final seenTiers = <int>{};
    for (final league in leagues) {
      if (!seenTiers.add(league.tier.level) || league.clubIds.isEmpty) {
        throw ArgumentError('Duplicate tier or empty preseason league.');
      }
      final members = <Club>[];
      for (final clubId in league.clubIds) {
        final club = byClub[clubId];
        if (clubId.isEmpty || club == null || contexts.containsKey(clubId) ||
            members.any((member) => member.id == clubId)) {
          throw ArgumentError(
            'Unknown or duplicate league membership: $clubId.',
          );
        }
        members.add(club);
      }
      final ranked = List<Club>.of(members)
        ..sort((a, b) {
          final strength = b.strength.compareTo(a.strength);
          return strength != 0 ? strength : a.id.compareTo(b.id);
        });
      for (var index = 0; index < ranked.length; index++) {
        final clubId = ranked[index].id;
        final finance = byFinance[clubId]!;
        contexts[clubId] = PresidentPromiseContext(
          clubId: clubId,
          seasonIndex: seasonIndex,
          tier: league.tier,
          leagueSize: league.clubIds.length,
          expectedPosition: index + 1,
          openingCash: finance.cash,
          openingDebt: finance.debt,
        );
      }
    }

    if (contexts.length != byClub.length) {
      throw ArgumentError('League membership must cover each club exactly once.');
    }
    final ordered = contexts.values.toList()
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    return List.unmodifiable(ordered);
  }
}
