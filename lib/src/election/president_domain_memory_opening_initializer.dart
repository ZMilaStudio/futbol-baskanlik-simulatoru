import 'president_opening_state_initializer.dart';

/// Zero-history observation of a new game; NOT a completed-career summary.
class PresidentOpeningHistorySummary {
  const PresidentOpeningHistorySummary();

  final int fanSnapshots = 0;
  final int fanReasons = 0;
  final int mediaStatements = 0;
  final int mediaContradictions = 0;
  final int promisesFulfilled = 0;
  final int promisesPartial = 0;
  final int promisesBroken = 0;

  int get totalPromises =>
      promisesFulfilled + promisesPartial + promisesBroken;

  String get signature =>
      'fan=$fanSnapshots:$fanReasons:'
      'media=$mediaStatements:$mediaContradictions:'
      'promise=$promisesFulfilled:$promisesPartial:$promisesBroken';
}

/// Read-only X2-A-backed view before ANY season is completed.
///
/// [opening] is the original X2-A world, not a regenerated presidency or a
/// persisted checkpoint. The Never-typed lists explicitly cannot contain
/// completed-season history at a new-game boundary. An empty resolved-promise
/// list makes no claim about promises that may be offered in future seasons.
class PresidentOpeningDomainMemoryState {
  const PresidentOpeningDomainMemoryState._({
    required this.opening,
    required this.rawHistorySeasons,
  });

  final PresidentOpeningWorldState opening;
  final int rawHistorySeasons;
  final PresidentOpeningHistorySummary summary =
      const PresidentOpeningHistorySummary();

  final List<Never> recentFan = const <Never>[];
  final List<Never> recentMedia = const <Never>[];
  final List<Never> resolvedCurrentTermPromises = const <Never>[];

  int get completedSeasons => 0;
  int get seasonIndex => opening.seasonIndex;
  int get electionInterval => opening.electionInterval;
  int get completedElectionTerms => opening.completedElectionTerms;
  int get seasonsIntoCurrentTerm => opening.seasonsIntoCurrentTerm;
  int get firstElectionSeasonIndex => opening.firstElectionSeasonIndex;
  String? get controlledClubId => opening.controlledClubId;
  String? get controlledPresidentId => opening.controlledPresidentId;

  List<PresidentOpeningClubState> get clubs => opening.clubs;
  Map<String, PresidentOpeningClubState> get byClubId => opening.byClubId;
  List<String> get orderedClubIds => opening.orderedClubIds;
  PresidentOpeningClubState? get controlledClub => opening.controlledClub;

  /// Diagnostic projection identity; neither a save key nor an authority.
  String get signature => <String>[
        'X2-B/new-game-memory/v1',
        'season=$seasonIndex',
        'interval=$electionInterval',
        'terms=$completedElectionTerms',
        'termOffset=$seasonsIntoCurrentTerm',
        'firstElection=$firstElectionSeasonIndex',
        'controlled=$controlledClubId:$controlledPresidentId',
        'window=$rawHistorySeasons',
        'summary=${summary.signature}',
        ...clubs.map((club) => club.signature),
      ].join('|');
}

/// Consumes one already-prepared X2-A source; never invokes its generators.
class PresidentDomainMemoryOpeningInitializer {
  const PresidentDomainMemoryOpeningInitializer();

  PresidentOpeningDomainMemoryState prepare({
    required PresidentOpeningWorldState opening,
    int rawHistorySeasons = 2,
  }) {
    if (rawHistorySeasons <= 0) {
      throw ArgumentError.value(rawHistorySeasons, 'rawHistorySeasons');
    }
    // A new game has no completed seasons. A later opening requires the
    // separate genuine completed-career checkpoint path, not this DTO.
    if (opening.seasonIndex != 0) {
      throw StateError('X2-B requires a pristine season-zero new-game opening.');
    }
    if (opening.electionInterval <= 0 ||
        opening.completedElectionTerms != 0 ||
        opening.seasonsIntoCurrentTerm != 0 ||
        opening.firstElectionSeasonIndex !=
            opening.seasonIndex + opening.electionInterval - 1) {
      throw StateError('X2-A initial election cursor is inconsistent.');
    }
    final controlledId = opening.controlledClubId;
    final controlled = opening.controlledClub;
    if (controlledId == null ||
        controlledId.isEmpty ||
        controlled == null ||
        !identical(opening.byClubId[controlledId], controlled) ||
        opening.controlledPresidentId != controlled.president.id) {
      throw StateError('X2-B requires an X2-A controlled-club president.');
    }
    if (opening.clubs.isEmpty ||
        opening.byClubId.length != opening.clubs.length ||
        opening.orderedClubIds.length != opening.clubs.length) {
      throw StateError('X2-A opening club membership is inconsistent.');
    }
    final seen = <String>{};
    for (final club in opening.clubs) {
      if (club.clubId.isEmpty ||
          !seen.add(club.clubId) ||
          !identical(opening.byClubId[club.clubId], club) ||
          club.president.id.isEmpty ||
          club.tenure.clubId != club.clubId ||
          !identical(club.tenure.president, club.president) ||
          club.tenure.startedSeasonIndex != opening.seasonIndex ||
          club.tenure.tenureNumber != 1 ||
          club.tenure.reelectionsWon != 0 ||
          club.managementProfile.presidentId != club.president.id ||
          club.fan.clubId != club.clubId ||
          club.media.clubId != club.clubId) {
        throw StateError('X2-A opening identity mismatch for ' + club.clubId);
      }
    }
    return PresidentOpeningDomainMemoryState._(
      opening: opening,
      rawHistorySeasons: rawHistorySeasons,
    );
  }
}
