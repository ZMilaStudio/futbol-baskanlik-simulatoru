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
