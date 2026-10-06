import '../election/president_management_profile.dart';
import '../election/player_president_tenure_control_gate.dart';
import '../crisis/crisis_runtime_integration.dart';
import '../crisis/facility_sponsor_crisis_runtime_composition.dart';
import '../crisis/president_facility_investment_runtime_integration.dart';
import '../save/facility_runtime_checkpoint.dart';
import '../manager/manager_career_controller.dart';
import '../world/world_checkpoint.dart';
import '../save/president_domain_resume_engine.dart';
import '../save/president_runtime_checkpoint.dart';
import '../transfer/advanced_transfer_controller.dart';
import '../transfer/player_president_transfer_strategy_control.dart';
import '../transfer/president_transfer_strategy_world_bridge.dart';
import '../world/world_career_season.dart';
import '../world/world_offseason_projection.dart';
import '../world/world_league_movement_projection.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import '../promise/promise_context.dart';
import '../promise/promise_season_snapshot.dart';
import '../manager/player_president_manager_preparation_projection.dart';
import '../manager/player_president_manager_control.dart';
import '../manager/manager.dart';
import 'player_president_postseason_decision_session.dart';
import 'player_president_interactive_decision_application_session.dart';

part '../save/lossless_postoffseason_runtime_graph.dart';

enum PostseasonRuntimeTransitionPhase {
  closingReady,
  movementReady,
  managerCompleted,
  lifecyclePrepared,
  rosterPrepared,
  marketContextReady,
  transferPending,
  marketReady,
  marketExecuted,
  transferFollowupComplete,
  domainReady,
  sponsorSuccessorReady,
  facilityReady,
  controlReady,
  managerPreparationPending,
  continuationReady,
  moved,
  failed,
}

/// Exact request handle. Its constructor is private and a context/request key
/// alone never authorizes a submission to another transition.
final class PostseasonTransferPending {
  PostseasonTransferPending._(
      this._transition, this.context, this.typedPending);
  final SinglePassPostseasonRuntimeTransition _transition;
  final PlayerTransferStrategyDecisionContext context;
  final PostseasonPending<PlayerTransferStrategyDecisionContext> typedPending;
  Object get owner => _transition.owner;
  Object get revision => _transition.revision;
  Object get executionIdentity => _transition.executionIdentity;
}

final class PostseasonManagerPending {
  PostseasonManagerPending._(this._transition, this.review, this.replacement);
  final SinglePassPostseasonRuntimeTransition _transition;
  final PlayerManagerReviewContext review;
  final PlayerManagerReplacementContext? replacement;
  PostseasonPending? _typedPending;
  PostseasonPending get typedPending => _typedPending!;
  Object get owner => _transition.owner;
  Object get revision => _transition.revision;
  Object get executionIdentity => _transition.executionIdentity;
}

/// Application-owned single-pass transition. Controllers and hooks never
/// escape. Each successful prefix is cached before a player Pending is exposed.
final class SinglePassPostseasonRuntimeTransition {
  SinglePassPostseasonRuntimeTransition._(
      this._applicationToken, this._transfer)
      : _annualClosing = null;
  SinglePassPostseasonRuntimeTransition._annual(this._annualClosing)
      : _applicationToken = null,
        _transfer = null;
  SinglePassPostseasonRuntimeTransition._settled(
      this._releaseAuthority, this._releaseResult)
      : _annualClosing = null,
        _applicationToken = null,
        _transfer = null;
  FullM65RuntimeEconomyContinuationAuthority? _releaseAuthority;
  FullM65CommittedSeasonSettlementResult? _releaseResult;
  bool permitsSettledEconomyRelease(
          FullM65RuntimeEconomyContinuationAuthority authority,
          FullM65CommittedSeasonSettlementResult result) =>
      identical(authority, _releaseAuthority) &&
      identical(result, _releaseResult) &&
      _annualClosing == null &&
      _applicationToken == null &&
      _phase == PostseasonRuntimeTransitionPhase.closingReady;

  factory SinglePassPostseasonRuntimeTransition.fromSettledEconomy({
    required FullM65RuntimeEconomyContinuationAuthority authority,
    required FullM65CommittedSeasonSettlementResult expectedResult,
    required Object expectedOwner,
    required Object expectedRevision,
    required Object expectedProvenance,
    required Object expectedExecution,
    required bool hasNextSeason,
  }) {
    final transition = SinglePassPostseasonRuntimeTransition._settled(
        authority, expectedResult);
    final source = authority.releaseSettledAnnualClosing(
        expectedResult: expectedResult,
        expectedOwner: expectedOwner,
        expectedRevision: expectedRevision,
        expectedProvenance: expectedProvenance,
        expectedExecution: expectedExecution,
        recipient: transition,
        hasNextSeason: hasNextSeason);
    transition._annualClosing = source;
    source.claim(
        expectedOwner: expectedOwner,
        expectedRevision: expectedRevision,
        expectedProvenance: expectedProvenance,
        transition: transition);
    return transition;
  }

  /// Legacy production annual-closing admission, not AR-D application proof.
  factory SinglePassPostseasonRuntimeTransition.fromOwnedAnnualClosing({
    required OwnedAnnualClosingBoundary source,
    required Object expectedOwner,
    required Object expectedRevision,
    required Object expectedProvenance,
  }) {
    final transition = SinglePassPostseasonRuntimeTransition._annual(source);
    source.claim(
        expectedOwner: expectedOwner,
        expectedRevision: expectedRevision,
        expectedProvenance: expectedProvenance,
        transition: transition);
    return transition;
  }

  factory SinglePassPostseasonRuntimeTransition.fromApplication(
    ApplicationPostseasonTransitionToken token,
  ) {
    token.validate();
    return SinglePassPostseasonRuntimeTransition._(
      token,
      token.source.hasNextSeason
          ? AdvancedTransferController.adoptApplicationOpening(token)
          : null,
    );
  }

  final ApplicationPostseasonTransitionToken? _applicationToken;
  ApplicationPostseasonTransitionToken get _token => _applicationToken!;
  OwnedAnnualClosingBoundary? _annualClosing;
  WorldLeagueMovementResult? _movement;
  Object get owner => _annualClosing?.owner ?? _token.owner;
  Object get revision => _annualClosing?.revision ?? _token.revision;
  Object get provenance => _annualClosing?.provenance ?? _token.provenance;
  Object get executionIdentity =>
      _annualClosing?.executionIdentity ?? _token.executionIdentity;
  final AdvancedTransferController? _transfer;
  PostseasonRuntimeTransitionPhase _phase =
      PostseasonRuntimeTransitionPhase.closingReady;
  PostseasonRuntimeTransitionPhase get phase => _phase;
  WorldOffseasonAttempt? _attempt;
  PreparedPlayerTransferStrategy? _strategy;
  PostseasonTransferPending? _pending;
  PlayerTransferStrategyChoice? _acceptedTransfer;
  bool _domainAttempted = false;
  bool _outerAttempted = false;
  WorldOffseasonProjectionResult? _worldSuccessor;
  PresidentDomainSeasonEffects? _domainSuccessor;
  CrisisRuntimeEffects? _crisisSuccessor;
  PresidentFacilityInvestmentEffects? _facilitySuccessor;
  PlayerPresidentTenureControlState? _controlSuccessor;
  FacilityPortfolioRuntimeState? _portfolioSuccessor;
  ManagerContinuationAuthority? _managerSuccessor;
  FacilitySponsorPostseasonContinuation? _facilityGraph;
  LosslessPostOffseasonRuntimeGraph? _preparedPublication;
  ManagerPreparationRuntimeView? _managerView;
  PostseasonManagerPending? _managerPending;
  PlayerManagerReviewChoice? _acceptedReview;
  Manager? _acceptedReplacement;
  PostseasonManagerPending? get managerPending => _managerPending;
  ManagerSeasonAuthority? get originalManagerOpening =>
      _annualClosing?.advanced.managerOpening;
  ManagerPreparationRuntimeView get managerPreparationView {
    _validate();
    if (_phase != PostseasonRuntimeTransitionPhase.managerPreparationPending ||
        _managerView == null) {
      throw StateError('Owned post-offseason manager view unavailable.');
    }
    return _managerView!;
  }

  PostseasonSourceRequirements? _decisionSource;
  PostseasonDecisionSession? _decisions;
  List<PostseasonAcceptedAnswer> get acceptedAnswers =>
      _decisions?.answers ?? const [];
  PostseasonSourceRequirements get decisionSource {
    _validate();
    if (_strategy == null ||
        (_phase != PostseasonRuntimeTransitionPhase.marketContextReady &&
            _phase != PostseasonRuntimeTransitionPhase.transferPending)) {
      throw StateError('Actual market context is not available.');
    }
    return _decisionSource ??= PostseasonSourceRequirements(
        owner: owner,
        revision: revision,
        provenance: provenance,
        transaction: this,
        completedSeason: _annualClosing?.advanced.world.opening.seasonIndex ??
            _token.source.seasonIndex,
        hasNextSeason: true,
        clubId: _strategy!.context.controlledClubId,
        transferContext: _strategy!.context);
  }

  void validateDecisionSource(PostseasonSourceRequirements source) {
    _validate();
    if (!identical(source, _decisionSource) ||
        !identical(source.transaction, this) ||
        !identical(source.transferContext, _strategy?.context)) {
      throw StateError('Foreign transition decision source.');
    }
  }

  void _openTransferPending() {
    final decisions = PostseasonDecisionSession.fromRuntimeTransition(this);
    _decisions = decisions;
    final context = _strategy!.context;
    _pending = PostseasonTransferPending._(
        this, context, decisions.requestTransfer(context)!);
    _phase = PostseasonRuntimeTransitionPhase.transferPending;
  }

  PresidentDomainSeasonEffects? get domainSuccessor => _domainSuccessor;

  void prepareOuterSuccessor() {
    _validate();
    if (_phase == PostseasonRuntimeTransitionPhase.continuationReady) return;
    if (_phase == PostseasonRuntimeTransitionPhase.managerPreparationPending)
      return;
    if (_phase != PostseasonRuntimeTransitionPhase.domainReady) {
      throw StateError('Outer successor requires the completed domain phase.');
    }
    if (_outerAttempted)
      throw StateError('Outer successor already in progress.');
    _outerAttempted = true;
    if (_annualClosing != null) {
      _prepareAnnualOuter();
      return;
    }
    try {
      final source = _token.source;
      final opening = source.sourceState.boundary.opening;
      final proof = source.sourceState.boundary.proof;
      final post = _worldSuccessor!;
      final crisis = const CrisisRuntimeIntegrationEngine().projectEffects(
        seasonIndex: source.seasonIndex,
        presidentClubs: _domainSuccessor!.clubs,
        financeStates: post.financeStates,
      );
      _crisisSuccessor = crisis;
      _phase = PostseasonRuntimeTransitionPhase.sponsorSuccessorReady;
      final world = WorldCheckpoint(
        config: proof.seasonOpening.config,
        completedSeasons: source.seasonIndex + 1,
        baseClubs: opening.baseClubs,
        nextSeasonLeagues: post.nextLeagues,
        nextSeasonPlayers: post.players,
        nextSeasonFinanceStates: crisis.financeStates,
      );
      // This subsystem genuinely starts here for the first bootstrap only.
      // No past facility investment, sponsor payment or manager history exists.
      final zero =
          FacilityPortfolioRuntimeState.forClubs(clubs: opening.baseClubs);
      final investment =
          const PresidentFacilityInvestmentRuntimeEngine().projectRuntimeView(
        facilities: FacilityRuntimeCheckpoint(
          world: world,
          academyFacilities: zero.academyFacilities,
          stadiumFacilities: zero.stadiumFacilities,
          trainingGroundFacilities: zero.trainingGroundFacilities,
          totalInvestmentSpent: zero.totalInvestmentSpent,
        ),
        profiles: {
          for (final club in crisis.presidentClubs)
            club.clubId: club.managementProfile
        },
      );
      _facilitySuccessor = investment;
      _phase = PostseasonRuntimeTransitionPhase.facilityReady;
      _controlSuccessor =
          const PlayerPresidentTenureControlGate().refreshRuntimeView(
        state: PlayerPresidentTenureControlState.initial(
          controlledClubId: source.controlledClubId,
          playerPresidentId: source.controlledPresidentId,
        ),
        incumbent: crisis.presidentClubs
            .singleWhere((club) => club.clubId == source.controlledClubId),
        completedSeasons: world.completedSeasons,
      );
      _phase = PostseasonRuntimeTransitionPhase.controlReady;
      _managerSuccessor = ManagerContinuationAuthority.initialAppointment(
        token: _token,
        successor: investment.facilities.world,
      );
      _facilityGraph = const FacilitySponsorCrisisRuntimeCareerEngine()
          .activateFirstPostseason(
        token: _token,
        world: investment.facilities.world,
        facilities: FacilityPortfolioRuntimeState(
          academyFacilities: investment.facilities.academyFacilities,
          stadiumFacilities: investment.facilities.stadiumFacilities,
          trainingGroundFacilities:
              investment.facilities.trainingGroundFacilities,
          totalInvestmentSpent: investment.facilities.totalInvestmentSpent,
        ),
        domainClubs: crisis.presidentClubs,
      );
      // Allocate and validate all immutable recipients BEFORE ownership commit.
      _preparedPublication = LosslessPostOffseasonRuntimeGraph._(this);
      _phase = PostseasonRuntimeTransitionPhase.continuationReady;
    } catch (_) {
      _phase = PostseasonRuntimeTransitionPhase.failed;
      rethrow;
    }
  }

  void _prepareAnnualOuter() {
    final source = _annualClosing!;
    final opening = source.advanced.world.opening;
    final post = _worldSuccessor!;
    try {
      final crisis = source.projectOwnedCrisis(
          transition: this,
          presidentClubs: _domainSuccessor!.clubs,
          financeStates: post.financeStates);
      _crisisSuccessor = crisis;
      _phase = PostseasonRuntimeTransitionPhase.sponsorSuccessorReady;
      final world = WorldCheckpoint(
          config: opening.config,
          completedSeasons:
              opening.seasonIndex - opening.config.seasonIndex + 1,
          baseClubs: source.advanced.world.baseClubs,
          nextSeasonLeagues: post.nextLeagues,
          nextSeasonPlayers: post.players,
          nextSeasonFinanceStates: crisis.financeStates);
      final investment = source.projectOwnedInvestment(
          transition: this,
          world: world,
          presidentClubs: crisis.presidentClubs);
      _facilitySuccessor = investment;
      _phase = PostseasonRuntimeTransitionPhase.facilityReady;
      final control = source.refreshOwnedControl(
          transition: this,
          incumbent: crisis.presidentClubs.singleWhere(
              (c) => c.clubId == source.tenureControl.controlledClubId),
          completedSeasons: world.completedSeasons);
      _controlSuccessor = control;
      _phase = PostseasonRuntimeTransitionPhase.controlReady;
      final portfolio = FacilityPortfolioRuntimeState(
          academyFacilities: investment.facilities.academyFacilities,
          stadiumFacilities: investment.facilities.stadiumFacilities,
          trainingGroundFacilities:
              investment.facilities.trainingGroundFacilities,
          totalInvestmentSpent: investment.facilities.totalInvestmentSpent);
      _portfolioSuccessor = portfolio;
      _facilityGraph = source.stageSuccessor(
          transition: this,
          world: investment.facilities.world,
          facilities: portfolio,
          domainClubs: crisis.presidentClubs,
          control: control);
      if (control.active) {
        final manager = _managerSuccessor!;
        final view = ManagerPreparationRuntimeView(
            config: opening.config,
            targetSeasonIndex: world.nextSeasonIndex,
            completedSeason: manager.completedSeasons.last,
            managers: manager.managers,
            assignments: manager.assignments,
            baseClubs: world.baseClubs,
            players: world.nextSeasonPlayers,
            financeStates: world.nextSeasonFinanceStates,
            leagues: world.nextSeasonLeagues);
        _managerView = view;
        final review = const PlayerManagerPreparationProjection().reviewRuntime(
            view: view,
            clubId: control.controlledClubId,
            presidentId: control.playerPresidentId);
        if (review.forcedRetirement) {
          final replacement = const PlayerManagerPreparationProjection()
              .replacementRuntime(view: view, review: review);
          _acceptedReview = PlayerManagerReviewChoice.replace;
          _managerPending =
              PostseasonManagerPending._(this, review, replacement);
        } else {
          _managerPending = PostseasonManagerPending._(this, review, null);
        }
        _phase = PostseasonRuntimeTransitionPhase.managerPreparationPending;
        _managerPending!._typedPending =
            _decisions!.prepareManagerFromRuntimeTransition(this);
      } else {
        _finishAnnualPreparation();
      }
    } catch (_) {
      _phase = PostseasonRuntimeTransitionPhase.failed;
      rethrow;
    }
  }

  bool permitsManagerPreparation(
          ManagerContinuationAuthority authority,
          ManagerPreparationRuntimeView view,
          PlayerManagerReviewContext review) =>
      identical(authority, _managerSuccessor) &&
      identical(view, _managerView) &&
      identical(review, _managerPending?.review) &&
      _phase == PostseasonRuntimeTransitionPhase.managerPreparationPending;

  bool permitsOuterSuccessor(
          OwnedAnnualClosingBoundary source,
          WorldCheckpoint world,
          FacilityPortfolioRuntimeState facilities,
          List<PresidentClubRuntimeState> domain,
          PlayerPresidentTenureControlState control) =>
      identical(source, _annualClosing) &&
      _phase == PostseasonRuntimeTransitionPhase.controlReady &&
      identical(world, _facilitySuccessor?.facilities.world) &&
      identical(facilities, _portfolioSuccessor) &&
      identical(domain, _crisisSuccessor?.presidentClubs) &&
      identical(control, _controlSuccessor);

  bool permitsManagerAnswer(
          ManagerContinuationAuthority authority,
          ManagerPreparationRuntimeView view,
          PlayerManagerReviewContext review,
          PlayerManagerReviewChoice choice,
          PlayerManagerCandidate? selected) =>
      permitsManagerPreparation(authority, view, review) &&
      (choice == PlayerManagerReviewChoice.retain
          ? _managerPending?.replacement == null && selected == null
          : _acceptedReview == PlayerManagerReviewChoice.replace &&
              (_managerPending?.replacement?.candidates
                      .any((c) => identical(c, selected)) ??
                  false));

  PostseasonManagerPending? submitManagerReview({
    required PostseasonManagerPending expectedPending,
    required PlayerManagerReviewChoice choice,
  }) {
    _validate();
    if (!identical(expectedPending._transition, this) ||
        !identical(expectedPending, _managerPending)) {
      throw StateError('Foreign or stale manager review.');
    }
    if (_acceptedReview != null) {
      if (_acceptedReview != choice)
        throw StateError('Conflicting manager review.');
      return choice == PlayerManagerReviewChoice.retain
          ? null
          : _managerPending;
    }
    if (_phase != PostseasonRuntimeTransitionPhase.managerPreparationPending ||
        (choice == PlayerManagerReviewChoice.retain &&
            (!expectedPending.review.canRetain ||
                expectedPending.review.forcedRetirement))) {
      throw StateError('Invalid manager review choice/phase.');
    }
    if (choice == PlayerManagerReviewChoice.replace) {
      _decisions!.answer(
          request: expectedPending.typedPending.request,
          choice: choice,
          owner: owner,
          revision: revision,
          provenance: provenance,
          transaction: this);
      _decisions!.completePhase(expectedPending.typedPending.request);
      final typed = _decisions!.pending!;
      final replacement =
          typed.request.context as PlayerManagerReplacementContext;
      _acceptedReview = choice;
      return _managerPending =
          (PostseasonManagerPending._(this, expectedPending.review, replacement)
            .._typedPending = typed);
    }
    _decisions!.answer(
        request: expectedPending.typedPending.request,
        choice: choice,
        owner: owner,
        revision: revision,
        provenance: provenance,
        transaction: this);
    try {
      _managerSuccessor!.applyOwnedPreparation(
          transition: this,
          view: _managerView!,
          review: expectedPending.review,
          choice: choice);
      _acceptedReview = choice;
      _decisions!.completePhase(expectedPending.typedPending.request);
      _finishAnnualPreparation();
    } catch (_) {
      _phase = PostseasonRuntimeTransitionPhase.failed;
      rethrow;
    }
    return null;
  }

  void submitManagerReplacement(
      {required PostseasonManagerPending expectedPending,
      required Manager selected}) {
    _validate();
    if (!identical(expectedPending, _managerPending) ||
        !identical(expectedPending._transition, this) ||
        expectedPending.replacement == null ||
        _acceptedReview != PlayerManagerReviewChoice.replace) {
      throw StateError('Foreign or stale manager replacement.');
    }
    final accepted = _acceptedReplacement;
    if (accepted != null) {
      if (!identical(accepted, selected))
        throw StateError('Conflicting replacement.');
      return;
    }
    final candidate = const PlayerManagerPreparationProjection()
        .validateSelected(expectedPending.replacement!, selected);
    _decisions!.answer(
        request: expectedPending.typedPending.request,
        choice: selected,
        owner: owner,
        revision: revision,
        provenance: provenance,
        transaction: this);
    try {
      _managerSuccessor!.applyOwnedPreparation(
          transition: this,
          view: _managerView!,
          review: expectedPending.review,
          choice: PlayerManagerReviewChoice.replace,
          selected: candidate);
      _acceptedReplacement = selected;
      _decisions!.completePhase(expectedPending.typedPending.request);
      _finishAnnualPreparation();
    } catch (_) {
      _phase = PostseasonRuntimeTransitionPhase.failed;
      rethrow;
    }
  }

  void _finishAnnualPreparation() {
    _preparedPublication = LosslessPostOffseasonRuntimeGraph._(this);
    _phase = PostseasonRuntimeTransitionPhase.continuationReady;
  }

  LosslessPostOffseasonRuntimeGraph moveOwnedAnnualContinuation() {
    if (_phase == PostseasonRuntimeTransitionPhase.moved &&
        _annualClosing != null) {
      _annualClosing!.validate();
      return _preparedPublication!;
    }
    _validate();
    final source = _annualClosing;
    if (source == null ||
        _phase != PostseasonRuntimeTransitionPhase.continuationReady) {
      throw StateError('Annual continuation is not ready to move.');
    }
    source.validateSuccessorMove(this);
    final result = _preparedPublication!;
    source.commitSuccessorMove(this);
    _phase = PostseasonRuntimeTransitionPhase.moved;
    return result;
  }

  LosslessPostOffseasonRuntimeGraph preparedPublication(
    ApplicationPostseasonTransitionToken expectedToken,
  ) {
    _validate();
    if (!identical(expectedToken, _token) ||
        _phase != PostseasonRuntimeTransitionPhase.continuationReady) {
      throw StateError('Foreign or incomplete continuation publication.');
    }
    return _preparedPublication!;
  }

  void commitPublication(ApplicationPostseasonTransitionToken expectedToken) {
    // Application prevalidates through preparedPublication before its pointer
    // commit. This final assignment has no engine, callback or allocation.
    if (!identical(expectedToken, _token) ||
        _phase != PostseasonRuntimeTransitionPhase.continuationReady) {
      throw StateError('Unvalidated continuation commit.');
    }
    _phase = PostseasonRuntimeTransitionPhase.moved;
  }

  void _validate() {
    if (_annualClosing case final source?) {
      source.validate();
    } else {
      _token.validate();
    }
    if (_phase == PostseasonRuntimeTransitionPhase.failed ||
        _phase == PostseasonRuntimeTransitionPhase.moved) {
      throw StateError('Failed or moved postseason transition.');
    }
  }

  PostseasonTransferPending? prepareTransfer() {
    _validate();
    if (_phase == PostseasonRuntimeTransitionPhase.transferPending) {
      return _pending!;
    }
    if (_phase != PostseasonRuntimeTransitionPhase.closingReady) {
      throw StateError('Transfer prefix already consumed.');
    }
    if (_annualClosing != null) return _prepareAnnualTransfer();
    final source = _token.source;
    if (!source.hasNextSeason) return null;
    try {
      // B2 already owns its movement: adopt exact evidence, never resettle B2.
      _phase = PostseasonRuntimeTransitionPhase.movementReady;
      // A squad-only source has no original manager season to complete/review.
      _phase = PostseasonRuntimeTransitionPhase.managerCompleted;
      final opening = source.sourceState.boundary.opening;
      final profiles = _OpeningProfiles({
        for (final state
            in source.sourceState.boundary.proof.presidentOpening.clubs)
          state.clubId: state.managementProfile,
      });
      final playerProvider = PlayerPresidentTransferStrategyProfileProvider(
        aiProfileProvider: profiles,
        controlledClubId: source.controlledClubId,
      );
      final attempt = WorldOffseasonProjection(
        transferMarketEngine: PresidentTransferStrategyWorldMarketEngine(
          profileProvider: playerProvider,
        ),
      ).beginAttempt(
        seasonIndex: source.seasonIndex,
        config: source.sourceState.boundary.proof.seasonOpening.config,
        players: opening.players,
        baseClubs: opening.baseClubs,
        squadClubs: source.sourceState.effectiveClubs,
        closingFinanceStates: source.closingFinanceStates,
        nextLeagues: source.candidateNextLeagues,
        rosterHooks: _transfer!,
        transferHooks: _transfer,
        enableTransferInstallments: true,
      );
      _attempt = attempt;
      attempt.prepareLifecycle();
      _phase = PostseasonRuntimeTransitionPhase.lifecyclePrepared;
      attempt.prepareRoster();
      _phase = PostseasonRuntimeTransitionPhase.rosterPrepared;
      attempt.prepareStrength();
      attempt.prepareContractYears();
      final context = attempt.prepareStrategyContext();
      _phase = PostseasonRuntimeTransitionPhase.marketContextReady;
      final strategy = playerProvider.prepareControlled(context);
      _strategy = strategy;
      _openTransferPending();
      return _pending!;
    } catch (_) {
      _phase = PostseasonRuntimeTransitionPhase.failed;
      rethrow;
    }
  }

  PostseasonTransferPending? _prepareAnnualTransfer() {
    final source = _annualClosing!;
    try {
      final annual = source.advanced.world;
      final movement = const WorldLeagueMovementProjection().project(
          currentLeagues: annual.opening.leagues,
          leagueResults: annual.reports,
          hasNextSeason: source.hasNextSeason);
      _movement = movement;
      _phase = PostseasonRuntimeTransitionPhase.movementReady;
      _managerSuccessor = source.advanced.completeManager(
          transition: this,
          hasNextSeason: source.hasNextSeason,
          nextLeagues: movement.nextLeagues);
      _phase = PostseasonRuntimeTransitionPhase.managerCompleted;
      if (!source.hasNextSeason) return null;
      final provider = PlayerPresidentTransferStrategyProfileProvider(
          aiProfileProvider: _OpeningProfiles({
            for (final state in source.presidentStates)
              state.clubId: state.managementProfile
          }),
          controlledClubId: source.tenureControl.controlledClubId);
      final attempt = source.advanced.beginOffseason(
          transition: this,
          nextLeagues: movement.nextLeagues,
          profileProvider: provider);
      _attempt = attempt;
      attempt.prepareLifecycle();
      _phase = PostseasonRuntimeTransitionPhase.lifecyclePrepared;
      attempt.prepareRoster();
      _phase = PostseasonRuntimeTransitionPhase.rosterPrepared;
      attempt.prepareStrength();
      attempt.prepareContractYears();
      final context = attempt.prepareStrategyContext();
      _phase = PostseasonRuntimeTransitionPhase.marketContextReady;
      if (source.tenureControl.lost) {
        // There is no controlled-player decision after ownership was lost.
        // This is the existing uncontrolled AI policy, not a player fallback.
        _executeTransferSuffix(
            context, provider.aiProfileProvider.profilesForWindow(context));
        return null;
      }
      final strategy = provider.prepareControlled(context);
      _strategy = strategy;
      _openTransferPending();
      return _pending;
    } catch (_) {
      _phase = PostseasonRuntimeTransitionPhase.failed;
      rethrow;
    }
  }

  void submitTransfer({
    required PostseasonTransferPending expectedPending,
    required PlayerTransferStrategyChoice choice,
  }) {
    _validate();
    if (!identical(expectedPending, _pending) ||
        !identical(expectedPending._transition, this)) {
      throw StateError('Foreign or stale transfer request.');
    }
    choice.validate(); // No phase/effect change on invalid answer.
    final accepted = _acceptedTransfer;
    if (accepted != null) {
      if (accepted.signature != choice.signature) {
        throw StateError('Conflicting duplicate transfer answer.');
      }
      return;
    }
    if (_phase != PostseasonRuntimeTransitionPhase.transferPending) {
      throw StateError('Wrong transfer answer phase.');
    }
    _decisions!.answer(
        request: expectedPending.typedPending.request,
        choice: choice,
        owner: owner,
        revision: revision,
        provenance: provenance,
        transaction: this);
    try {
      final profiles = _strategy!
          .accept(expectedContext: expectedPending.context, choice: choice);
      _acceptedTransfer = choice;
      _executeTransferSuffix(expectedPending.context.window, profiles);
      _decisions!.completePhase(expectedPending.typedPending.request);
    } catch (_) {
      _phase = PostseasonRuntimeTransitionPhase.failed;
      rethrow;
    }
  }

  void _executeTransferSuffix(PresidentTransferStrategyWindowContext context,
      Map<String, PresidentManagementProfile> profiles) {
    _phase = PostseasonRuntimeTransitionPhase.marketReady;
    _attempt!.executePreparedStrategy(
        expectedContext: context, acceptedProfiles: profiles);
    _phase = PostseasonRuntimeTransitionPhase.marketExecuted;
    _attempt!.completeContractCallback();
    _worldSuccessor = _attempt!.completeFollowup();
    _phase = PostseasonRuntimeTransitionPhase.transferFollowupComplete;
  }

  void prepareDomain() {
    _validate();
    if (_phase == PostseasonRuntimeTransitionPhase.domainReady) return;
    if (_phase != PostseasonRuntimeTransitionPhase.transferFollowupComplete) {
      throw StateError('Domain requires the completed transfer suffix.');
    }
    if (_domainAttempted)
      throw StateError('Domain projection already in progress.');
    _domainAttempted = true;
    if (_annualClosing != null) {
      _prepareAnnualDomain();
      return;
    }
    try {
      final source = _token.source;
      final boundary = source.sourceState.boundary;
      final post = _worldSuccessor!;
      final season = WorldCareerSeason(
        seasonIndex: source.seasonIndex,
        leaguesBeforeSeason: boundary.opening.leagues,
        clubs: source.sourceState.effectiveClubs,
        players: boundary.opening.players,
        leagueResults: source.leagueResults,
        finances: source.finances,
        retiredAfterSeason: post.retired,
        youthIntakeAfterSeason: post.youthIntake,
        transfersAfterSeason: post.transfers,
        financeStatesAfterWindow: post.financeStates,
        movementsAfterSeason: source.movements,
        leaguesAfterTransition: post.nextLeagues,
        cashMovementsAfterWindow: post.cashMovements,
      );
      _domainSuccessor =
          const PresidentDomainResumeEngine().projectRuntimeSeason(
        season: season,
        config: boundary.proof.seasonOpening.config,
        priorClubs: boundary.proof.presidentOpening.clubs
            .map((state) => PresidentClubRuntimeState(
                  tenure: state.tenure,
                  managementProfile: state.managementProfile,
                  fanReputation: state.fan,
                  mediaReputation: state.media,
                )),
        acceptedPromises: source.promiseSnapshots,
        loanHistory: _transfer!.loanHistory,
        electionInterval: boundary.proof.presidentOpening.electionInterval,
        completedElectionTerms:
            boundary.proof.presidentOpening.completedElectionTerms,
        seasonsIntoCurrentTerm:
            boundary.proof.presidentOpening.seasonsIntoCurrentTerm,
        priorTermPromiseScores: const {},
        hasNextSeason: source.hasNextSeason,
      );
      _phase = PostseasonRuntimeTransitionPhase.domainReady;
    } catch (_) {
      _phase = PostseasonRuntimeTransitionPhase.failed;
      rethrow;
    }
  }

  void _prepareAnnualDomain() {
    final source = _annualClosing!;
    final annual = source.advanced.world;
    final opening = annual.opening;
    final post = _worldSuccessor!;
    try {
      final snapshots = <PromiseSeasonSnapshot>[];
      for (var i = 0; i < source.promiseContexts.length; i++) {
        final context = source.promiseContexts[i];
        final promise = source.acceptedPromises[i];
        final report =
            annual.reports.singleWhere((r) => r.tier == context.tier).report;
        final finance =
            annual.finances.singleWhere((f) => f.clubId == context.clubId);
        final movement =
            _movement!.movements.where((m) => m.clubId == context.clubId);
        final outcome = PresidentPromiseOutcome(
            clubId: context.clubId,
            seasonIndex: opening.seasonIndex,
            leaguePosition:
                report.table.indexWhere((r) => r.clubId == context.clubId) + 1,
            leagueSize: report.table.length,
            openingDebt: finance.openingDebt,
            closingDebt: finance.closingDebt,
            emergencyBorrowing: finance.emergencyBorrowing,
            promoted: movement.any((m) => m.to.level < m.from.level),
            relegated: movement.any((m) => m.to.level > m.from.level));
        snapshots.add(PromiseSeasonSnapshot(
            context: context,
            promise: promise,
            outcome: outcome,
            resolution: source.resolveOwnedPromise(
                transition: this, promise: promise, outcome: outcome)));
      }
      final season = WorldCareerSeason(
          seasonIndex: opening.seasonIndex,
          leaguesBeforeSeason: opening.leagues,
          clubs: opening.effectiveClubs,
          players: opening.players,
          leagueResults: annual.reports,
          finances: annual.finances,
          retiredAfterSeason: post.retired,
          youthIntakeAfterSeason: post.youthIntake,
          transfersAfterSeason: post.transfers,
          financeStatesAfterWindow: post.financeStates,
          movementsAfterSeason: _movement!.movements,
          leaguesAfterTransition: post.nextLeagues,
          cashMovementsAfterWindow: post.cashMovements);
      _domainSuccessor = source.projectOwnedDomain(
          transition: this,
          season: season,
          acceptedPromises: snapshots,
          managerSeason: _managerSuccessor!.completedSeasons.last);
      _phase = PostseasonRuntimeTransitionPhase.domainReady;
    } catch (_) {
      _phase = PostseasonRuntimeTransitionPhase.failed;
      rethrow;
    }
  }
}

final class _OpeningProfiles extends PresidentTransferStrategyProfileProvider {
  _OpeningProfiles(Map<String, PresidentManagementProfile> profiles)
      : _profiles = Map.unmodifiable(profiles);
  final Map<String, PresidentManagementProfile> _profiles;
  @override
  Map<String, PresidentManagementProfile> profilesForWindow(
    PresidentTransferStrategyWindowContext context,
  ) =>
      _profiles;
}
