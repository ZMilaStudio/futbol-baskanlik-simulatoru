import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../core/simulation_config.dart';
import '../facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../player/player.dart';
import '../player_president/player_president_interactive_decision_application_session.dart';
import '../save/save_checksum.dart';
import '../world/league_tier.dart';
import '../world/world_league.dart';
import '../world/world_opening_state_initializer.dart';
import 'weekly_world_fixture_result_core.dart';

/// The two genuine sources of a season opening; neither is an in-progress
/// weekly state or a separate persisted game-state authority.
enum SeasonOpeningOriginKind { newGame, completedM65 }

/// An immutable, read-only observation of a *supplied and validated* career
/// source. This is not an M65 checkpoint, save codec, or replay/restore API.
///
/// P1's source revision is content-addressed, NOT a monotonic writer revision.
/// Matching the digest of this object against itself is not source validation:
/// verifyNewGame/verifyCompletedM65 require the independent live source.
class SeasonOpeningProof {
  SeasonOpeningProof._({
    required this.originKind,
    required this.originSourceDigest,
    required this.seasonIndex,
    required this.controlledClubId,
    required this.config,
    required this.orderedWorldDigest,
    required this.playersDigest,
    required this.financeDigest,
    required this.openingCareerStateDigest,
    required this.fixturePlanFingerprint,
    required this.fixtureSnapshot,
    required String canonicalIdentity,
  }) : _canonicalIdentity = canonicalIdentity;

  /// An audited, manually versioned identification of the existing opening,
  /// fixture-generator and match/seed rules at the P1 baseline. It cannot
  /// automatically detect subsequent source-code edits; relevant rule changes
  /// MUST explicitly revise this identifier and their parity tests.
  static const String rulesetId =
      'fbs-opening/1:opening-m79-m65:fixture-m1-legacy:match-m0-seed-v1'
      '@a162c2d671cb7b39e7b661d31f7800f32bd2ec70';

  static const String sourceRevisionKind = 'source-content-sha256-v1';

  final SeasonOpeningOriginKind originKind;
  final String originSourceDigest;
  final int seasonIndex;
  final String controlledClubId;
  final SimulationConfig config;
  final String orderedWorldDigest;
  final String playersDigest;
  final String financeDigest;
  final String openingCareerStateDigest;
  final String fixturePlanFingerprint;

  /// M1's single canonical fixture projection: 720 unplayed fixtures, no
  /// duplicate planner or authoritative standings/results.
  final WeeklyWorldFixtureSnapshot fixtureSnapshot;
  final String _canonicalIdentity;

  /// This is content identity, not a transaction/generation counter.
  String get sourceRevision => originSourceDigest;
  String get sourceRevisionType => sourceRevisionKind;
  String get simulationRulesId => rulesetId;

  /// M79 is the actual application origin. Its M80 bootstrap validates
  /// independently supplied opening clubs/leagues, but supplies no game state.
  /// A nonempty answer transcript is deliberately not treated as a pristine
  /// season opening; P2 must later bind accepted decisions to live career state.
  factory SeasonOpeningProof.fromNewGame({
    required PlayerPresidentInteractiveDecisionApplicationSession application,
    required List<Club> sourceClubs,
    required List<WorldLeague> sourceLeagues,
    required int expectedSeasonIndex,
    required String expectedControlledClubId,
    String expectedRulesetId = rulesetId,
  }) {
    _checkRules(expectedRulesetId);
    if (!application.isNewGame ||
        application.checkpointOrNull != null ||
        application.answeredDecisionCount != 0 ||
        application.completed != null) {
      throw StateError('P1 requires a pristine authoritative M79 new game.');
    }
    final bootstrap = application.newGameBootstrapSnapshot;
    if (bootstrap.transcript.decisionCount != 0) {
      throw StateError('An answered M80 bootstrap is not a P1 opening.');
    }
    bootstrap.validateWorld(clubs: sourceClubs, leagues: sourceLeagues);
    _checkExpectations(
      actualSeason: bootstrap.config.seasonIndex,
      actualClub: bootstrap.controlledClubId,
      expectedSeason: expectedSeasonIndex,
      expectedClub: expectedControlledClubId,
    );

    final opening = const WorldOpeningStateInitializer().prepare(
      clubs: sourceClubs,
      leagues: sourceLeagues,
      config: bootstrap.config,
    );
    final sourceDigest = _digest('new-game-source', {
      'originKind': SeasonOpeningOriginKind.newGame.name,
      'bootstrapWorldFingerprint': bootstrap.worldFingerprint,
      'config': _config(bootstrap.config),
      'controlledClubId': bootstrap.controlledClubId,
      'electionInterval': bootstrap.electionInterval,
      'resumeConfig': bootstrap.resumeConfig.toPayload(),
      'clubsAndLeagues': _orderedWorld(opening),
    });
    return _build(
      originKind: SeasonOpeningOriginKind.newGame,
      originSourceDigest: sourceDigest,
      seasonIndex: bootstrap.config.seasonIndex,
      controlledClubId: bootstrap.controlledClubId,
      config: bootstrap.config,
      opening: opening,
    );
  }

  /// The real completed M65 v1 source carries the next-season world. Do not
  /// substitute M2's nextRound=31 for this checkpoint.
  factory SeasonOpeningProof.fromCompletedM65({
    required PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
    required int expectedSeasonIndex,
    required String expectedControlledClubId,
    String expectedRulesetId = rulesetId,
  }) {
    _checkRules(expectedRulesetId);
    checkpoint.validate();
    if (checkpoint.completedSeasons <= 0) {
      throw StateError('P1 requires a completed-season M65 checkpoint.');
    }
    final world = checkpoint.runtime.runtime.domain.presidentRuntime
        .runtime.runtime.world;
    if (world.completedSeasons != checkpoint.completedSeasons ||
        world.nextSeasonIndex != checkpoint.nextSeasonIndex ||
        !checkpoint.playerControlActive) {
      throw StateError('M65 source has an invalid next-season boundary.');
    }
    _checkExpectations(
      actualSeason: checkpoint.nextSeasonIndex,
      actualClub: checkpoint.controlledClubId,
      expectedSeason: expectedSeasonIndex,
      expectedClub: expectedControlledClubId,
    );
    final config = world.config.copyWith(seasonIndex: checkpoint.nextSeasonIndex);
    final opening = WorldOpeningState(
      baseClubs: world.baseClubs,
      leagues: world.nextSeasonLeagues,
      players: world.nextSeasonPlayers,
      financeStates: world.nextSeasonFinanceStates,
    );
    final sourceBytes =
        const PlayerPresidentTicketPricingRuntimeSaveCodec().encode(checkpoint);
    return _build(
      originKind: SeasonOpeningOriginKind.completedM65,
      originSourceDigest: _digestRaw('completed-m65-v1-source', sourceBytes),
      seasonIndex: checkpoint.nextSeasonIndex,
      controlledClubId: checkpoint.controlledClubId,
      config: config,
      opening: opening,
    );
  }

  /// Verifies against a freshly supplied independent M79 application source;
  /// comparing two digests derived only from this proof would be insufficient.
  void verifyNewGame({
    required PlayerPresidentInteractiveDecisionApplicationSession application,
    required List<Club> sourceClubs,
    required List<WorldLeague> sourceLeagues,
    String expectedRulesetId = rulesetId,
  }) {
    if (originKind != SeasonOpeningOriginKind.newGame) {
      throw StateError('Opening origin mismatch: expected newGame.');
    }
    final fresh = SeasonOpeningProof.fromNewGame(
      application: application,
      sourceClubs: sourceClubs,
      sourceLeagues: sourceLeagues,
      expectedSeasonIndex: seasonIndex,
      expectedControlledClubId: controlledClubId,
      expectedRulesetId: expectedRulesetId,
    );
    _verifyExact(fresh);
  }

  /// The supplied checkpoint, not the proof's own hash, is the source.
  void verifyCompletedM65({
    required PlayerPresidentTicketPricingRuntimeCheckpoint checkpoint,
    String expectedRulesetId = rulesetId,
  }) {
    if (originKind != SeasonOpeningOriginKind.completedM65) {
      throw StateError('Opening origin mismatch: expected completedM65.');
    }
    final fresh = SeasonOpeningProof.fromCompletedM65(
      checkpoint: checkpoint,
      expectedSeasonIndex: seasonIndex,
      expectedControlledClubId: controlledClubId,
      expectedRulesetId: expectedRulesetId,
    );
    _verifyExact(fresh);
  }

  void _verifyExact(SeasonOpeningProof fresh) {
    if (originSourceDigest != fresh.originSourceDigest ||
        _canonicalIdentity != fresh._canonicalIdentity) {
      throw StateError('Opening does not match the supplied career authority.');
    }
  }

  /// Diagnostic check of independently observed opening data. This does not
  /// authenticate the observed data: first verify the original M79/M65 source
  /// with verifyNewGame/verifyCompletedM65. Used to detect later projection
  /// drift without giving the projection game-state authority.
  void assertOpeningProjectionMatches(WorldOpeningState observed) {
    _validateOpening(observed, seasonIndex, controlledClubId, config);
    final observedState = {
      'seasonIndex': seasonIndex,
      'controlledClubId': controlledClubId,
      'config': _config(config),
      'orderedWorld': _orderedWorld(observed),
      'players': _players(observed.players),
      'finance': _finance(observed.financeStates),
    };
    if (_digest('opening-career-state', observedState) !=
        openingCareerStateDigest) {
      throw StateError('Observed opening differs from authoritative source.');
    }
  }

  static SeasonOpeningProof _build({
    required SeasonOpeningOriginKind originKind,
    required String originSourceDigest,
    required int seasonIndex,
    required String controlledClubId,
    required SimulationConfig config,
    required WorldOpeningState opening,
  }) {
    _validateOpening(opening, seasonIndex, controlledClubId, config);
    final snapshot = const WeeklyWorldFixtureResultCore().prepare(
      clubs: opening.baseClubs,
      leagues: opening.leagues,
      config: config,
    );
    if (snapshot.nextRound != 1 ||
        snapshot.seasonIndex != seasonIndex ||
        snapshot.totalRounds != 30 ||
        snapshot.completedMatchCount != 0 ||
        snapshot.fixtures.length != 720 ||
        snapshot.fixtures.any((f) => f.isPlayed) ||
        snapshot.fixtures.map((f) => f.globalKey).toSet().length != 720) {
      throw StateError('Season opening does not have the canonical M1 plan.');
    }

    final orderedWorld = _orderedWorld(opening);
    final players = _players(opening.players);
    final finance = _finance(opening.financeStates);
    final fixturePlan = [
      for (var i = 0; i < snapshot.fixtures.length; i++)
        {
          'position': i,
          'worldKey': snapshot.fixtures[i].globalKey,
          'tierLevel': snapshot.fixtures[i].tier.level,
          'legacyFixtureId': snapshot.fixtures[i].fixture.id,
          'seasonIndex': snapshot.fixtures[i].fixture.seasonIndex,
          'round': snapshot.fixtures[i].round,
          'homeClubId': snapshot.fixtures[i].fixture.homeClubId,
          'awayClubId': snapshot.fixtures[i].fixture.awayClubId,
        }
    ];
    final openingState = {
      'seasonIndex': seasonIndex,
      'controlledClubId': controlledClubId,
      'config': _config(config),
      'orderedWorld': orderedWorld,
      'players': players,
      'finance': finance,
    };
    final canonicalIdentity = SaveChecksum.canonicalJson({
      'contract': 'FBS-P1-season-opening-v1',
      'originKind': originKind.name,
      'originSourceDigest': originSourceDigest,
      'rulesetId': rulesetId,
      'sourceRevisionKind': sourceRevisionKind,
      'opening': openingState,
      'fixturePlan': fixturePlan,
    });
    return SeasonOpeningProof._(
      originKind: originKind,
      originSourceDigest: originSourceDigest,
      seasonIndex: seasonIndex,
      controlledClubId: controlledClubId,
      config: config,
      orderedWorldDigest: _digest('ordered-world', orderedWorld),
      playersDigest: _digest('opening-players', players),
      financeDigest: _digest('opening-finance', finance),
      openingCareerStateDigest: _digest('opening-career-state', openingState),
      fixturePlanFingerprint: _digest('m1-canonical-fixture-plan', fixturePlan),
      fixtureSnapshot: snapshot,
      canonicalIdentity: canonicalIdentity,
    );
  }

  static void _checkRules(String expected) {
    if (expected != rulesetId) {
      throw StateError('P1 simulation ruleset identity mismatch.');
    }
  }

  static void _checkExpectations({
    required int actualSeason,
    required String actualClub,
    required int expectedSeason,
    required String expectedClub,
  }) {
    if (actualSeason < 0 ||
        actualSeason != expectedSeason ||
        actualClub.isEmpty ||
        actualClub != expectedClub) {
      throw StateError('P1 authoritative season or controlled club mismatch.');
    }
  }

  static void _validateOpening(
    WorldOpeningState opening,
    int seasonIndex,
    String controlledClubId,
    SimulationConfig config,
  ) {
    if (config.seasonIndex != seasonIndex) {
      throw StateError('Opening config season cursor mismatch.');
    }
    final params = [
      config.homeAdvantageRating,
      config.baseHomeGoals,
      config.baseAwayGoals,
      config.ratingScale,
      config.minExpectedGoals,
      config.maxExpectedGoals,
    ];
    if (config.simulationVersion <= 0 ||
        config.ratingScale <= 0 ||
        config.minExpectedGoals <= 0 ||
        config.maxExpectedGoals < config.minExpectedGoals ||
        params.any((n) => !n.isFinite)) {
      throw StateError('Opening simulation config is invalid.');
    }
    final clubs = opening.baseClubs;
    final byId = {for (final club in clubs) club.id: club};
    if (clubs.length != 48 ||
        byId.length != 48 ||
        !byId.containsKey(controlledClubId) ||
        clubs.any((c) =>
            c.id.isEmpty ||
            c.name.isEmpty ||
            !c.strength.isFinite ||
            c.strength < 40 ||
            c.strength > 100)) {
      throw StateError('Opening must have 48 valid authoritative clubs.');
    }
    final leagues = {for (final league in opening.leagues) league.tier: league};
    if (opening.leagues.length != 3 || leagues.length != 3) {
      throw StateError('Opening must have exactly three league tiers.');
    }
    final allMembers = <String>{};
    for (final tier in LeagueTier.values) {
      final ids = leagues[tier]?.clubIds;
      if (ids == null ||
          ids.length != 16 ||
          ids.toSet().length != 16 ||
          ids.any((id) => !byId.containsKey(id))) {
        throw StateError('Invalid ordered league membership.');
      }
      for (final id in ids) {
        if (!allMembers.add(id)) {
          throw StateError('Club appears in more than one opening league.');
        }
      }
    }
    if (allMembers.length != 48) {
      throw StateError('Opening league membership does not cover every club.');
    }
    final ids = <String>{};
    final playersByClub = <String, int>{};
    for (final p in opening.players) {
      if (p.id.isEmpty ||
          p.name.isEmpty ||
          !ids.add(p.id) ||
          (!byId.containsKey(p.clubId) && !p.isFreeAgent) ||
          p.age < 15 ||
          p.age > 60 ||
          p.retirementAge < p.age ||
          !p.ability.isFinite ||
          !p.potential.isFinite ||
          p.ability < 0 ||
          p.ability > 100 ||
          p.potential < 0 ||
          p.potential > 100) {
        throw StateError('Invalid opening roster or player state.');
      }
      if (!p.isFreeAgent) {
        playersByClub[p.clubId] = (playersByClub[p.clubId] ?? 0) + 1;
      }
    }
    if (byId.keys.any((id) => (playersByClub[id] ?? 0) < 11)) {
      throw StateError('Opening contains a club without a usable squad.');
    }
    final financeIds = <String>{};
    if (opening.financeStates.length != 48 ||
        opening.financeStates.any(
          (s) => !byId.containsKey(s.clubId) || !financeIds.add(s.clubId),
        ) ||
        financeIds.length != 48) {
      throw StateError('Opening finance state must cover all 48 clubs.');
    }
  }

  static Map<String, Object?> _config(SimulationConfig config) => {
        'careerSeed': config.careerSeed,
        'simulationVersion': config.simulationVersion,
        'seasonIndex': config.seasonIndex,
        'homeAdvantageRating': config.homeAdvantageRating,
        'baseHomeGoals': config.baseHomeGoals,
        'baseAwayGoals': config.baseAwayGoals,
        'ratingScale': config.ratingScale,
        'minExpectedGoals': config.minExpectedGoals,
        'maxExpectedGoals': config.maxExpectedGoals,
      };

  static List<Map<String, Object?>> _orderedWorld(WorldOpeningState source) => [
        for (final c in source.baseClubs)
          {'kind': 'club', 'id': c.id, 'name': c.name, 'strength': c.strength},
        for (final tier in LeagueTier.values)
          {
            'kind': 'league',
            'tierLevel': tier.level,
            'clubIds': source.leagues.singleWhere((l) => l.tier == tier).clubIds,
          },
      ];

  static List<Map<String, Object?>> _players(List<Player> source) => [
        for (final p in source)
          {
            'id': p.id,
            'name': p.name,
            'clubId': p.clubId,
            'position': p.position.name,
            'age': p.age,
            'ability': p.ability,
            'potential': p.potential,
            'retirementAge': p.retirementAge,
            'isAcademyGraduate': p.isAcademyGraduate,
          },
      ];

  static List<Map<String, Object?>> _finance(
    List<ClubFinanceState> source,
  ) {
    final sorted = List<ClubFinanceState>.of(source)
      ..sort((a, b) => a.clubId.compareTo(b.clubId));
    return [
      for (final s in sorted)
        {
          'clubId': s.clubId,
          'cashMinorUnits': s.cash.minorUnits,
          'debtMinorUnits': s.debt.minorUnits,
        },
    ];
  }

  static String _digest(String domain, Object? value) =>
      _digestRaw(domain, SaveChecksum.canonicalJson(value));

  static String _digestRaw(String domain, String canonical) => sha256
      .convert(utf8.encode('FBS-P1/season-opening/$domain/v1\u0000$canonical'))
      .toString();
}
