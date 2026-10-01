import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_facility_sponsor_crisis_manager_promise_media_transfer_ticket_pricing_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_facility_sponsor_crisis_promise_media_transfer_ticket_pricing_runtime_composition.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/src/manager/player_president_manager_preparation_projection.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_postseason_decision_session.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:futbol_baskanlik_m0/src/transfer/president_transfer_strategy_world_bridge.dart';
import 'package:test/test.dart';
import 'p2_ar_a_manager_authority_test.dart'
    show CapturedManagerFixture, CountingManagerPool;
import 'p2_ar_c_postseason_decision_session_test.dart' show PostseasonFixture;

/// TEST FIXTURE / NOT AUTHORITATIVE PRODUCER. Real setup + detached completion,
/// never a B2 handoff or application publication.
class ManagerPreparationFixture extends CapturedManagerFixture {
  ManagerPreparationFixture({CountingManagerPool? pool})
      : super(pool ?? CountingManagerPool());
  late AdvancedRuntimeCheckpoint advanced;
  @override
  void run() {
    final world = const FictionalWorldFactory().build();
    final result = const WorldCareerEngine().simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: const SimulationConfig(careerSeed: 20260903, seasonIndex: 1),
        seasonCount: 1,
        hooks: this);
    final detached = fork();
    detached.onSeasonCompleted(
        seasonIndex: 1,
        hasNextSeason: true,
        squadClubs: squads,
        effectiveClubs: effective,
        players: openingPlayers,
        leaguesBeforeSeason: openingLeagues,
        leaguesForNextSeason: nextLeagues,
        leagueResults: results,
        finances: closing);
    advanced = AdvancedRuntimeCheckpoint(
        world: result.checkpoint,
        transfer: AdvancedTransferRuntimeState(
            activeContracts: const [],
            contractEvents: const [],
            activeLoans: const [],
            loanHistory: const [],
            installmentObligations: const []),
        manager: ManagerRuntimeState(
            managers: detached.managers,
            assignments: detached.finalAssignments,
            seasons: detached.seasons));
  }

  PostseasonDecisionSession continuation(
      {bool terminal = false,
      PlayerManagerPreparationProjection projection =
          const PlayerManagerPreparationProjection()}) {
    final profile = const PresidentManagementProfile(
        presidentId: 'p',
        archetype: PresidentManagementArchetype.balanced,
        financialDiscipline: 50,
        riskAppetite: 50,
        transferAmbition: 50,
        youthOrientation: 50,
        managerPatience: 50);
    final context = PlayerTransferStrategyDecisionContext(
        window: PresidentTransferStrategyWindowContext(
            clubs: advanced.world.baseClubs,
            players: advanced.world.nextSeasonPlayers,
            financeStates: advanced.world.nextSeasonFinanceStates,
            careerSeed: 20260903,
            seasonIndex: 1,
            simulationVersion: 1),
        controlledClubId: squads.first.id,
        aiProfile: profile);
    final source = PostseasonSourceRequirements(
        owner: owner,
        revision: revision,
        provenance: advanced,
        transaction: Object(),
        completedSeason: 1,
        hasNextSeason: !terminal,
        clubId: squads.first.id,
        transferContext: context);
    final session = PostseasonDecisionSession.forContractFixture(source,
        projection: projection);
    if (!terminal) {
      final pending = session.requestTransfer(context)!;
      session.answer(
          request: pending.request,
          choice: PlayerTransferStrategyChoice.fromProfile(profile),
          owner: owner,
          revision: revision,
          provenance: advanced,
          transaction: source.transaction);
      session.completePhase(pending.request);
    }
    return session;
  }
}

class _CaptureProvider extends PlayerManagerDecisionProvider {
  final List<String> events = [];
  PlayerManagerReviewContext? reviewContext;
  PlayerManagerReplacementContext? replacementContext;
  @override
  PlayerManagerReviewChoice review(PlayerManagerReviewContext context) {
    events.add('review');
    reviewContext = context;
    return PlayerManagerReviewChoice.replace;
  }

  @override
  void onReviewApplied(
      PlayerManagerReviewContext context, PlayerManagerReviewChoice choice) {
    events.add('review-applied');
  }

  @override
  PlayerManagerReplacementChoice chooseReplacement(
      PlayerManagerReplacementContext context) {
    events.add('replacement');
    replacementContext = context;
    return PlayerManagerReplacementChoice(managerId: context.aiChoice.id);
  }

  @override
  void onReplacementApplied(PlayerPresidentManagerRuntimeDecision decision,
      ManagerAssignment assignment) {
    events.add('replacement-applied');
  }
}

class _RetiringPool extends CountingManagerPool {
  _RetiringPool(this.retiringId);
  final String retiringId;
  @override
  List<Manager> generate(
          {required int careerSeed,
          required int simulationVersion,
          int count = 96}) =>
      super
          .generate(
              careerSeed: careerSeed,
              simulationVersion: simulationVersion,
              count: count)
          .map((m) => m.id != retiringId
              ? m
              : Manager(
                  id: m.id,
                  name: m.name,
                  profile: m.profile,
                  startAge: m.startAge,
                  retirementAge: m.startAge + 1,
                  reputation: m.reputation,
                  coaching: m.coaching,
                  youthDevelopment: m.youthDevelopment,
                  manManagement: m.manManagement,
                  boardCooperation: m.boardCooperation,
                  budgetDemand: m.budgetDemand))
          .toList();
}

class _FailingFit extends ManagerFitModel {
  @override
  double score(
          {required Manager manager,
          required Club club,
          required List<Player> players,
          required LeagueTier leagueTier,
          required ClubFinanceState financeState}) =>
      throw StateError('detached fit failure');
}

void main() {
  late ManagerPreparationFixture f;
  const projection = PlayerManagerPreparationProjection();
  setUpAll(() {
    f = ManagerPreparationFixture()..run();
  });

  test(
      'real original setup/fork/completion; detached read-only preparation deterministic',
      () {
    final before = const AdvancedWorldSaveCodec().encode(f.advanced);
    final assignments = f.finalAssignments;
    final pendingA = f.continuation().prepareManagerForContractFixture(
        originalOpening: f.authority,
        postOffseason: f.advanced,
        presidentId: 'p')!;
    final pendingB = f.continuation().prepareManagerForContractFixture(
        originalOpening: f.authority,
        postOffseason: f.advanced,
        presidentId: 'p')!;
    expect((pendingA.request.context as PlayerManagerReviewContext).signature,
        (pendingB.request.context as PlayerManagerReviewContext).signature);
    expect(f.seasons, isEmpty); // Original still has its opening pending.
    expect(f.finalAssignments, assignments);
    expect(f.counter.calls, 1); // No initializer/reconstruction on projection.
    expect(const AdvancedWorldSaveCodec().encode(f.advanced), before);
    expect(f.fork().seasons, isEmpty); // Pending capture remains forkable.
  });

  test('squad-only and initial appointment never acquire fake review authority',
      () {
    final session = f.continuation();
    expect(
        session.prepareManagerForContractFixture(
            originalOpening: null, postOffseason: f.advanced, presidentId: 'p'),
        isNull);
    expect(
        session.status, PostseasonDecisionStatus.decisionContractUnavailable);
    expect(session.phase, PostseasonDecisionPhase.awaitingOffseason);
    expect(session.answers, hasLength(1));
    // An initial setup has zero completed seasons and is not retain/replace.
    expect(f.authority.seasons, isEmpty);
    final firstEntry = PostseasonFixture();
    final transfer = firstEntry.pending;
    firstEntry.answer(PostseasonFixture.choice);
    firstEntry.session.completePhase(transfer.request);
    // Season-1 initial appointment cannot be used to review squad-only season 0.
    expect(
        firstEntry.session.prepareManagerForContractFixture(
            originalOpening: f.authority,
            postOffseason: f.advanced,
            presidentId: 'p'),
        isNull);
    expect(firstEntry.session.status,
        PostseasonDecisionStatus.decisionContractUnavailable);
    expect(firstEntry.session.phase, PostseasonDecisionPhase.awaitingOffseason);
  });

  test('terminal produces no manager preparation or future request', () {
    final session = f.continuation(terminal: true);
    expect(
        session.prepareManagerForContractFixture(
            originalOpening: f.authority,
            postOffseason: f.advanced,
            presidentId: 'p'),
        isNull);
    expect(session.phase, PostseasonDecisionPhase.terminal);
    expect(session.answers, isEmpty);
    expect(f.counter.calls, 1);
  });

  test(
      'owner/revision mismatch fail-closed before review; no checkpoint mutation',
      () {
    final foreign = ManagerPreparationFixture()..run();
    final session = f.continuation();
    expect(
        session.prepareManagerForContractFixture(
            originalOpening: foreign.authority,
            postOffseason: f.advanced,
            presidentId: 'p'),
        isNull);
    expect(
        session.status, PostseasonDecisionStatus.decisionContractUnavailable);
    expect(f.seasons, isEmpty);
  });

  test('real forced retirement skips review and rejects retain', () {
    final id = f.authority.assignments[f.squads.first.id]!.managerId;
    final retiring = ManagerPreparationFixture(pool: _RetiringPool(id))..run();
    final review = projection.review(
        advanced: retiring.advanced,
        clubId: retiring.squads.first.id,
        presidentId: 'p');
    expect(review.currentManager.id, id);
    expect(review.forcedRetirement, isTrue);
    expect(review.canRetain, isFalse);
    expect(review.aiReason, ManagerChangeReason.retirement);
    final session = retiring.continuation();
    final pending = session.prepareManagerForContractFixture(
        originalOpening: retiring.authority,
        postOffseason: retiring.advanced,
        presidentId: 'p')!;
    expect(session.phase, PostseasonDecisionPhase.managerReplacement);
    expect(pending.request.context, isA<PlayerManagerReplacementContext>());
    final source = pending.request.source;
    expect(
        () => session.answer(
            request: pending.request,
            choice: PlayerManagerReviewChoice.retain,
            owner: source.owner,
            revision: source.revision,
            provenance: source.provenance,
            transaction: source.transaction),
        throwsArgumentError);
    expect(session.answers, hasLength(1)); // Only the earlier transfer choice.
  });

  test(
      'next-phase preparation failure preserves Pending and accepted prior answers',
      () {
    final session = f.continuation(
        projection:
            PlayerManagerPreparationProjection(fitModel: _FailingFit()));
    final pending = session.prepareManagerForContractFixture(
        originalOpening: f.authority,
        postOffseason: f.advanced,
        presidentId: 'p')!;
    final source = pending.request.source;
    final before = session.answers.single;
    final checkpoint = const AdvancedWorldSaveCodec().encode(f.advanced);
    expect(
        () => session.answer(
            request: pending.request,
            choice: PlayerManagerReviewChoice.replace,
            owner: source.owner,
            revision: source.revision,
            provenance: source.provenance,
            transaction: source.transaction),
        throwsStateError);
    expect(session.pending, same(pending));
    expect(session.phase, PostseasonDecisionPhase.managerReview);
    expect(session.answers.single, same(before));
    expect(const AdvancedWorldSaveCodec().encode(f.advanced), checkpoint);
  });

  test('replacement order/eligibility/limit; exact offered identity only', () {
    final review = projection.review(
        advanced: f.advanced, clubId: f.squads.first.id, presidentId: 'p');
    final first = projection.replacement(advanced: f.advanced, review: review);
    final second = projection.replacement(advanced: f.advanced, review: review);
    expect(first.signature, second.signature);
    expect(first.candidates.length, lessThanOrEqualTo(5));
    final elsewhere = f.advanced.manager.assignments
        .where((a) => a.clubId != review.clubId)
        .map((a) => a.managerId)
        .toSet();
    for (final candidate in first.candidates) {
      expect(elsewhere.contains(candidate.manager.id), isFalse);
      expect(candidate.manager.id, isNot(review.currentManager.id));
      expect(candidate.manager.startAge + 1,
          lessThan(candidate.manager.retirementAge));
      expect(projection.validateSelected(first, candidate.manager),
          same(candidate));
    }
    expect(() => projection.validateSelected(first, review.currentManager),
        throwsArgumentError);
    final offered = first.candidates.first.manager;
    final fabricated = Manager(
        id: offered.id,
        name: offered.name,
        profile: offered.profile,
        startAge: offered.startAge,
        retirementAge: offered.retirementAge,
        reputation: offered.reputation,
        coaching: offered.coaching,
        youthDevelopment: offered.youthDevelopment,
        manManagement: offered.manManagement,
        boardCooperation: offered.boardCooperation,
        budgetDemand: offered.budgetDemand);
    expect(fabricated.id, offered.id);
    expect(() => projection.validateSelected(first, fabricated),
        throwsArgumentError);
    expect(() => first.candidates.clear(), throwsUnsupportedError);
    // Deterministic ordering includes M71's preferred-AI-first rule.
    final sortedTail = first.candidates
        .where((c) =>
            !review.aiWouldReplace || c.manager.id != review.aiNextManager.id)
        .toList();
    for (var i = 1; i < sortedTail.length; i++) {
      expect(sortedTail[i - 1].selectionScore,
          greaterThanOrEqualTo(sortedTail[i].selectionScore));
    }
    // Preserve M71's exact preferred-first limit behavior (including its limit-1
    // boundary), not a silently changed filtering/truncation algorithm.
    final limited = const PlayerManagerPreparationProjection(candidateLimit: 1)
        .replacement(advanced: f.advanced, review: review);
    final preferred = review.aiWouldReplace &&
        limited.candidates.first.manager.id == review.aiNextManager.id;
    expect(limited.candidates.length, preferred ? 2 : 1);
  });

  test('manager phase cannot be entered early; review answer stays detached',
      () {
    final session = f.continuation();
    final p = session.prepareManagerForContractFixture(
        originalOpening: f.authority,
        postOffseason: f.advanced,
        presidentId: 'p')!;
    final source = p.request.source;
    final before = const AdvancedWorldSaveCodec().encode(f.advanced);
    session.answer(
        request: p.request,
        choice: PlayerManagerReviewChoice.replace,
        owner: source.owner,
        revision: source.revision,
        provenance: source.provenance,
        transaction: source.transaction);
    expect(session.pending, same(p));
    session.completePhase(p.request);
    final replacement = session.pending!;
    expect(session.phase, PostseasonDecisionPhase.managerReplacement);
    expect(
        () => session.answer(
            request: p.request,
            choice: PlayerManagerReviewChoice.retain,
            owner: source.owner,
            revision: source.revision,
            provenance: source.provenance,
            transaction: source.transaction),
        throwsStateError);
    final context =
        replacement.request.context as PlayerManagerReplacementContext;
    session.answer(
        request: replacement.request,
        choice: context.candidates.first.manager,
        owner: source.owner,
        revision: source.revision,
        provenance: source.provenance,
        transaction: source.transaction);
    session.completePhase(replacement.request);
    expect(session.phase, PostseasonDecisionPhase.prepared);
    expect(const AdvancedWorldSaveCodec().encode(f.advanced), before);
    expect(f.seasons, isEmpty);
  });

  test('legacy M71 review/replacement contexts match shared projection', () {
    final world = const FictionalWorldFactory().build();
    const source =
        PlayerPresidentTenureGatedFacilitySponsorCrisisPromiseMediaTransferTicketPricingRuntimeCareerEngine();
    const config = SimulationConfig(careerSeed: 20260903);
    final baseline = source.simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: world.clubs.first.id,
        seasonCount: 1,
        hasFutureSeasonAfterReport: true);
    final advanced = baseline
        .checkpoint.runtime.runtime.domain.presidentRuntime.runtime.runtime;
    final president = baseline
        .checkpoint.runtime.runtime.domain.presidentRuntime.clubs
        .firstWhere((c) => c.clubId == world.clubs.first.id)
        .tenure
        .president
        .id;
    final provider = _CaptureProvider();
    final result =
        PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine(
                sourceEngine: source, managerProvider: provider)
            .simulateWithCheckpoint(
                clubs: world.clubs,
                leagues: world.leagues,
                config: config,
                controlledClubId: world.clubs.first.id,
                seasonCount: 1,
                hasFutureSeasonAfterReport: true);
    final review = projection.review(
        advanced: advanced,
        clubId: world.clubs.first.id,
        presidentId: president);
    expect(result.managerDecisions.single.reviewContext.signature,
        review.signature);
    expect(result.managerDecisions.single.replacementContext!.signature,
        projection.replacement(advanced: advanced, review: review).signature);
    expect(provider.events,
        ['review', 'review-applied', 'replacement', 'replacement-applied']);
  });

  test(
      'exact-base M71 oracle captures checkpoint/result/resume/callback signatures',
      () {
    final world = const FictionalWorldFactory().build();
    final provider = _CaptureProvider();
    final engine =
        PlayerPresidentTenureGatedFacilitySponsorCrisisManagerPromiseMediaTransferTicketPricingRuntimeCareerEngine(
            managerProvider: provider);
    const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();
    final first = engine.simulateWithCheckpoint(
        clubs: world.clubs,
        leagues: world.leagues,
        config: const SimulationConfig(careerSeed: 20260903),
        controlledClubId: world.clubs.first.id,
        seasonCount: 1,
        hasFutureSeasonAfterReport: true);
    final resumed = engine.resume(
        checkpoint: codec.decode(codec.encode(first.checkpoint)),
        seasonCount: 1);
    final bytes = jsonEncode([
      first.signature,
      codec.encode(first.checkpoint),
      resumed.signature,
      codec.encode(resumed.checkpoint),
      provider.events
    ]);
    final digest = sha256.convert(utf8.encode(bytes)).toString();
    // Captured from unmodified a275e482 M71 before applying the shared seam.
    expect(digest,
        'b477ded6cd9a936b4b05d06d577696d5770fd6ed81d4d5d7f3bb0a78737e5ee8');
  });
}
