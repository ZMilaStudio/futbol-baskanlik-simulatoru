part of 'manager_career_controller.dart';

/// Original, unadjusted next-season manager lineage. The controller stays
/// private: appointment is not a manager season or a historical review.
final class ManagerContinuationAuthority {
  ManagerContinuationAuthority._(this._controller, this.owner, this.revision,
      this.provenance, this.seasonIndex);
  final ManagerCareerController _controller;
  final Object owner, revision, provenance;
  final int seasonIndex;
  List<Manager> get managers => _controller.managers;
  List<ManagerAssignment> get assignments => _controller.finalAssignments;
  List<ManagerCareerSeason> get completedSeasons => _controller.seasons;
  bool _preparationApplied = false;
  FutureManagerRecipient stageFutureRecipient(FutureRuntimeClaim claim) {
    claim.validateChild(this);
    if (seasonIndex != claim.source.targetSeasonIndex) {
      throw StateError('Manager continuation has the wrong target season.');
    }
    final world = claim.source.worldSuccessor;
    final ids = world.baseClubs.map((club) => club.id).toSet();
    if (!_controller._initialized ||
        _controller.careerSeed != world.config.careerSeed ||
        _controller.simulationVersion != world.config.simulationVersion ||
        _controller._assignments.length != ids.length ||
        !ids.every(_controller._assignments.containsKey)) {
      throw StateError('Manager continuation lacks original target lineage.');
    }
    return FutureManagerRecipient._(this, claim);
  }

  void applyOwnedPreparation({
    required SinglePassPostseasonRuntimeTransition transition,
    required ManagerPreparationRuntimeView view,
    required PlayerManagerReviewContext review,
    required PlayerManagerReviewChoice choice,
    PlayerManagerCandidate? selected,
  }) {
    if (_preparationApplied ||
        !transition.permitsManagerAnswer(
            this, view, review, choice, selected)) {
      throw StateError('Foreign or consumed manager preparation.');
    }
    const projection = PlayerManagerPreparationProjection();
    final ManagerAssignment assignment;
    if (choice == PlayerManagerReviewChoice.retain) {
      if (!review.canRetain || review.forcedRetirement) {
        throw StateError('Manager cannot be retained.');
      }
      assignment = review.aiWouldReplace
          ? projection.retainedAssignmentRuntime(
              view: view,
              clubSeason: review.season,
              completedHistory: completedSeasons)
          : _controller._assignments[review.clubId]!;
    } else {
      if (selected == null ||
          !view.managers.any((m) => identical(m, selected.manager))) {
        throw StateError('Replacement has no original manager identity.');
      }
      assignment = review.aiWouldReplace &&
              identical(selected.manager, review.aiNextManager)
          ? _controller._assignments[review.clubId]!
          : projection.newAssignmentRuntime(
              view: view, clubId: review.clubId, candidate: selected);
    }
    final successors = Map<String, ManagerAssignment>.unmodifiable(
        {..._controller._assignments, review.clubId: assignment});
    // Preparation changes only detached future assignment ownership. It never
    // rebuilds completed history or patches a persisted checkpoint.
    _controller._assignments = successors;
    _preparationApplied = true;
  }

  factory ManagerContinuationAuthority.initialAppointment({
    required ApplicationPostseasonTransitionToken token,
    required WorldCheckpoint successor,
  }) {
    token.validate();
    successor.validate();
    final sourceConfig =
        token.source.sourceState.boundary.proof.seasonOpening.config;
    if (!token.source.hasNextSeason ||
        successor.nextSeasonIndex != token.source.seasonIndex + 1 ||
        successor.config.careerSeed != sourceConfig.careerSeed ||
        successor.config.simulationVersion != sourceConfig.simulationVersion) {
      throw StateError('Invalid initial appointment successor lineage.');
    }
    token.claimManagerAppointment();
    final controller = ManagerCareerController(
      careerSeed: sourceConfig.careerSeed,
      simulationVersion: sourceConfig.simulationVersion,
      initialSeasonIndex: successor.nextSeasonIndex,
    );
    controller._initialize(
      seasonIndex: successor.nextSeasonIndex,
      clubs: successor.baseClubs,
      players: successor.nextSeasonPlayers,
      leagues: successor.nextSeasonLeagues,
      financeStates: successor.nextSeasonFinanceStates,
    );
    return ManagerContinuationAuthority._(controller, token.owner,
        token.revision, token.provenance, successor.nextSeasonIndex);
  }
}

/// Operational facade over the original continuation. No controller escapes.
final class FutureManagerRecipient implements WorldCareerHooks {
  FutureManagerRecipient._(this._source, this._claim);
  final ManagerContinuationAuthority _source;
  final FutureRuntimeClaim _claim;
  bool _adjusted = false;
  bool _captured = false;
  void _check() => _claim.validateChild(_source);
  Object get evidenceIdentity => _source;
  List<Manager> get managers => _source.managers;
  List<ManagerAssignment> get assignments => _source.assignments;
  List<ManagerCareerSeason> get completedSeasons => _source.completedSeasons;
  @override
  List<Club> adjustClubsForSeason(
      {required int seasonIndex,
      required List<Club> squadClubs,
      required List<Player> players,
      required List<WorldLeague> leagues,
      required List<ClubFinanceState> financeStates}) {
    _check();
    final world = _claim.source.worldSuccessor;
    if (_adjusted ||
        seasonIndex != world.nextSeasonIndex ||
        !identical(players, world.nextSeasonPlayers) ||
        !identical(leagues, world.nextSeasonLeagues) ||
        !identical(financeStates, world.nextSeasonFinanceStates)) {
      throw StateError('Foreign or repeated future manager adjustment.');
    }
    _adjusted = true;
    return _source._controller.adjustClubsForSeason(
        seasonIndex: seasonIndex,
        squadClubs: squadClubs,
        players: players,
        leagues: leagues,
        financeStates: financeStates);
  }

  ManagerSeasonAuthority capture(PreparedWorldOpening opening) {
    _check();
    if (!_adjusted || _captured || opening.seasonIndex != _source.seasonIndex) {
      throw StateError('Manager capture requires one validated preparation.');
    }
    final result = _source._controller.captureSeasonAuthority(
        owner: _claim.owner,
        sourceRevision: _claim.revision,
        seasonIndex: opening.seasonIndex,
        effectiveClubs: opening.effectiveClubs);
    _captured = true;
    return result;
  }

  @override
  void onSeasonCompleted(
      {required int seasonIndex,
      required bool hasNextSeason,
      required List<Club> squadClubs,
      required List<Club> effectiveClubs,
      required List<Player> players,
      required List<WorldLeague> leaguesBeforeSeason,
      required List<WorldLeague> leaguesForNextSeason,
      required List<LeagueSeasonSnapshot> leagueResults,
      required List<ClubFinanceSeason> finances}) {
    _check();
    _source._controller.onSeasonCompleted(
        seasonIndex: seasonIndex,
        hasNextSeason: hasNextSeason,
        squadClubs: squadClubs,
        effectiveClubs: effectiveClubs,
        players: players,
        leaguesBeforeSeason: leaguesBeforeSeason,
        leaguesForNextSeason: leaguesForNextSeason,
        leagueResults: leagueResults,
        finances: finances);
  }
}

/// Opaque runtime snapshot of an actual successful manager season setup.
/// Pending inputs are private immutable values, not generated opening data.
final class ManagerSeasonAuthority {
  ManagerSeasonAuthority._(ManagerCareerController source, this.owner,
      this.sourceRevision, this.seasonIndex, this.effectiveClubs)
      : _source = source,
        careerSeed = source.careerSeed,
        simulationVersion = source.simulationVersion,
        initialSeasonIndex = source.initialSeasonIndex,
        managers = List.unmodifiable(source._managers),
        assignments = Map.unmodifiable(source._assignments),
        seasons = List.unmodifiable(source._seasons),
        _pending = Map.unmodifiable(source._pending),
        _poolGenerator = source.poolGenerator,
        _fitModel = source.fitModel,
        _impactModel = source.impactModel,
        _patienceProvider = source.patienceProvider,
        _dismissalPolicy = source.dismissalPolicy;

  final ManagerCareerController _source;
  final Object owner, sourceRevision;
  final int careerSeed, simulationVersion, initialSeasonIndex, seasonIndex;
  final List<Club> effectiveClubs;
  final List<Manager> managers;
  final Map<String, ManagerAssignment> assignments;
  final List<ManagerCareerSeason> seasons;
  final Map<String, _PendingManagerClubSeason> _pending;
  final ManagerPoolGenerator _poolGenerator;
  final ManagerFitModel _fitModel;
  final ManagerImpactModel _impactModel;
  final ManagerPatienceProvider? _patienceProvider;
  final ManagerDismissalPolicy _dismissalPolicy;

  ManagerCareerController forkDetached({
    required Object expectedOwner,
    required Object expectedRevision,
    required int expectedSeason,
  }) =>
      _source.forkSeasonAuthority(
          authority: this,
          owner: expectedOwner,
          sourceRevision: expectedRevision,
          seasonIndex: expectedSeason);

  bool _completionAttempted = false;
  ManagerContinuationAuthority completeOwnedAnnualClosing({
    required OwnedWorldAnnualClosing closing,
    required bool hasNextSeason,
    required List<WorldLeague> nextLeagues,
  }) {
    closing.validate();
    final opening = closing.opening;
    if (_completionAttempted ||
        !identical(owner, closing.owner) ||
        !identical(sourceRevision, closing.revision) ||
        seasonIndex != opening.seasonIndex ||
        !identical(effectiveClubs, opening.effectiveClubs)) {
      throw StateError('Foreign or consumed manager annual closing.');
    }
    _completionAttempted = true;
    final fork = forkDetached(
        expectedOwner: owner,
        expectedRevision: sourceRevision,
        expectedSeason: seasonIndex);
    fork.onSeasonCompleted(
      seasonIndex: seasonIndex,
      hasNextSeason: hasNextSeason,
      squadClubs: opening.squadClubs,
      effectiveClubs: opening.effectiveClubs,
      players: opening.players,
      leaguesBeforeSeason: opening.leagues,
      leaguesForNextSeason: nextLeagues,
      leagueResults: closing.reports,
      finances: closing.finances,
    );
    return ManagerContinuationAuthority._(
        fork, owner, sourceRevision, closing.provenance, seasonIndex + 1);
  }

  ManagerCareerController _fork() {
    // Do not use restore: its deliberately empty pending contract is unchanged.
    final fork = ManagerCareerController(
      careerSeed: careerSeed,
      simulationVersion: simulationVersion,
      initialSeasonIndex: initialSeasonIndex,
      poolGenerator: _poolGenerator,
      fitModel: _fitModel,
      impactModel: _impactModel,
      patienceProvider: _patienceProvider,
      dismissalPolicy: _dismissalPolicy,
    );
    fork._initialized = true;
    fork._managers = List.unmodifiable(managers);
    fork._managerById = Map.unmodifiable({for (final m in managers) m.id: m});
    fork._assignments = Map.unmodifiable(assignments);
    fork._seasons.addAll(seasons);
    fork._pending = Map.of(_pending);
    // A fork is not the original capture source and cannot mint that authority.
    return fork;
  }
}
