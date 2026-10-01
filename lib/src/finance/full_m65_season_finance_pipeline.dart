part of 'season_finance_authority_receipt.dart';

/// Single-use observer for the existing M65 call graph. Never settles by itself.
/// Failed observers cannot retry: this prevents replaying producer side effects;
/// transaction/recovery orchestration remains outside AR-B.
final class FullM65SeasonFinancePipeline {
  // Weak owner keys: runtime claims do not retain discarded application owners.
  // Revision maps use identity, not value equality. A failed claim remains used;
  // AR-B deliberately offers no transaction recovery/re-settlement operation.
  static final _claims =
      Expando<Map<Object, Set<int>>>('M65 settlement attempts');
  FullM65SeasonFinancePipeline(
      {required this.owner,
      required this.sourceRevision,
      required this.provenance,
      required this.seasonIndex,
      this.effectiveClubSource});
  final Object owner;
  final Object sourceRevision;
  final Object provenance;
  final int seasonIndex;
  final Object? effectiveClubSource;
  bool _attempted = false;
  bool _active = false;
  final Map<String, FinanceAttendanceEvidence> _attendance = {};
  final Map<String, SponsorSeasonResolution> _sponsors = {};
  final Map<String, ClubFinanceConsumedInput> _inputs = {};
  final List<ClubFinanceSeason> _results = [];
  int _leagueCalls = 0;
  SeasonFinanceAuthorityReceipt? _receipt;
  SeasonFinanceAuthorityReceipt? get receipt => _receipt;

  /// Observe one selected season without changing multi-season legacy execution.
  FullM65SeasonFinancePipeline? forSeason(int actualSeason) =>
      actualSeason == seasonIndex ? this : null;

  T record<T>(T Function() operation) {
    if (_attempted) throw StateError('Settlement observer already attempted.');
    _attempted = true;
    final revisions = _claims[owner] ??= HashMap<Object, Set<int>>.identity();
    final seasons = revisions.putIfAbsent(sourceRevision, () => <int>{});
    if (!seasons.add(seasonIndex)) {
      throw StateError('Owner/source/season settlement was already attempted.');
    }
    _active = true;
    try {
      final result = operation();
      if (_leagueCalls != 3 || _inputs.length != 48 || _results.length != 48) {
        throw StateError(
            'Full M65 receipt requires three leagues and 48 clubs.');
      }
      final receipt = SeasonFinanceAuthorityReceipt._(
          owner: owner,
          sourceRevision: sourceRevision,
          provenance: provenance,
          seasonIndex: seasonIndex,
          effectiveClubSource: effectiveClubSource,
          inputs: _inputs,
          results: _results);
      receipt.verify(
          expectedOwner: owner,
          expectedRevision: sourceRevision,
          expectedProvenance: provenance,
          expectedSeason: seasonIndex,
          expectedResults: _results,
          expectedEffectiveClubSource: effectiveClubSource);
      _receipt = receipt;
      return result;
    } finally {
      _active = false;
      _attendance.clear();
      _sponsors.clear();
      _inputs.clear();
      _results.clear();
    }
  }

  void observeAttendance(FinanceAttendanceEvidence evidence) {
    _requireActive();
    if (_attendance.containsKey(evidence.club.id)) {
      throw StateError('Duplicate attendance observation.');
    }
    _attendance[evidence.club.id] = evidence;
  }

  void observeSponsor(
      Iterable<String> clubIds, SponsorSeasonResolution actualResolution) {
    _requireActive();
    for (final id in clubIds) {
      if (_sponsors.containsKey(id))
        throw StateError('Duplicate sponsor observation.');
      _sponsors[id] = actualResolution;
    }
  }

  /// Called after the actual delegate returned; consumes already-computed maps.
  void observeSettlement(
      {required int actualSeason,
      required List<Club> clubs,
      required List<ClubFinanceState> openingStates,
      required Map<String, Money>? wages,
      required Map<String, Money>? installmentIncome,
      required Map<String, Money>? installmentExpense,
      required Map<String, Money>? sponsorRevenue,
      required Map<String, int> incomingMultipliers,
      required Map<String, int> finalMultipliers,
      required Map<String, PlayerPresidentTicketPricingDecision> tickets,
      required int economicScaleBps,
      required int costScaleBps,
      required List<ClubFinanceSeason> results}) {
    _requireActive();
    final openings = {for (final row in openingStates) row.clubId: row};
    final rows = {for (final row in results) row.clubId: row};
    if (actualSeason != seasonIndex ||
        clubs.length != 16 ||
        rows.length != 16 ||
        results.length != 16 ||
        openings.length != openingStates.length) {
      throw StateError('Invalid league settlement observation.');
    }
    for (final club in clubs) {
      final id = club.id;
      if (_inputs.containsKey(id) ||
          openings[id] == null ||
          rows[id] == null ||
          wages?[id] == null ||
          sponsorRevenue?[id] == null ||
          _attendance[id] == null ||
          _sponsors[id] == null ||
          tickets[id] == null ||
          finalMultipliers[id] == null ||
          incomingMultipliers[id] == null) {
        throw StateError('Incomplete or duplicate consumed input for $id.');
      }
      _inputs[id] = ClubFinanceConsumedInput(
          club: club,
          opening: openings[id]!,
          wages: wages![id]!,
          installmentIncome: installmentIncome?[id] ?? Money.zero,
          installmentExpense: installmentExpense?[id] ?? Money.zero,
          sponsorRevenue: sponsorRevenue![id]!,
          sponsorSource: _sponsors[id]!,
          attendance: _attendance[id]!,
          ticket: tickets[id]!,
          incomingMultiplierBps: incomingMultipliers[id]!,
          finalMultiplierBps: finalMultipliers[id]!,
          economicScaleBps: economicScaleBps,
          costScaleBps: costScaleBps);
      _results.add(rows[id]!);
    }
    _leagueCalls++;
  }

  void _requireActive() {
    if (!_active)
      throw StateError('Observation requires the active settlement call.');
  }
}
