import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

class CountingManagerPool extends ManagerPoolGenerator {
  int calls = 0;
  @override
  List<Manager> generate(
      {required int careerSeed,
      required int simulationVersion,
      int count = 96}) {
    calls++;
    return super.generate(
        careerSeed: careerSeed,
        simulationVersion: simulationVersion,
        count: count);
  }
}

/// Real engine setup/completion inputs. Completion is recorded, not applied to
/// the original controller. Only detached forks are completed by these tests.
class CapturedManagerFixture extends ManagerCareerController {
  CapturedManagerFixture(this.counter, {ManagerPatienceProvider? patience})
      : super(
            careerSeed: 20260903,
            simulationVersion: 1,
            initialSeasonIndex: 1,
            poolGenerator: counter,
            patienceProvider: patience);
  final CountingManagerPool counter;
  final Object owner = Object(), revision = Object();
  late ManagerSeasonAuthority authority;
  late List<Club> squads, effective;
  late List<Player> openingPlayers;
  late List<WorldLeague> openingLeagues, nextLeagues;
  late List<ClubFinanceState> openingFinance;
  late List<LeagueSeasonSnapshot> results;
  late List<ClubFinanceSeason> closing;

  void run() {
    final world = const FictionalWorldFactory().build();
    const WorldCareerEngine().simulate(
        clubs: world.clubs,
        leagues: world.leagues,
        config: const SimulationConfig(careerSeed: 20260903, seasonIndex: 1),
        seasonCount: 1,
        hooks: this);
  }

  @override
  List<Club> adjustClubsForSeason(
      {required int seasonIndex,
      required List<Club> squadClubs,
      required List<Player> players,
      required List<WorldLeague> leagues,
      required List<ClubFinanceState> financeStates}) {
    squads = squadClubs;
    openingPlayers = players;
    openingLeagues = leagues;
    openingFinance = financeStates;
    effective = super.adjustClubsForSeason(
        seasonIndex: seasonIndex,
        squadClubs: squadClubs,
        players: players,
        leagues: leagues,
        financeStates: financeStates);
    authority = captureSeasonAuthority(
        owner: owner,
        sourceRevision: revision,
        seasonIndex: seasonIndex,
        effectiveClubs: effective);
    return effective;
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
    results = leagueResults;
    closing = finances;
    nextLeagues = leaguesForNextSeason;
  }

  ManagerCareerController fork() => forkSeasonAuthority(
      authority: authority,
      owner: owner,
      sourceRevision: revision,
      seasonIndex: 1);

  void complete(ManagerCareerController target) => target.onSeasonCompleted(
      seasonIndex: 1,
      hasNextSeason: false,
      squadClubs: squads,
      effectiveClubs: effective,
      players: openingPlayers,
      leaguesBeforeSeason: openingLeagues,
      leaguesForNextSeason: nextLeagues,
      leagueResults: results,
      finances: closing);
}

void main() {
  late CapturedManagerFixture source;
  setUpAll(() {
    source = CapturedManagerFixture(CountingManagerPool())..run();
  });

  test('capture requires actual setup and exact returned list', () {
    final empty = ManagerCareerController(
        careerSeed: 1, simulationVersion: 1, initialSeasonIndex: 1);
    expect(
        () => empty.captureSeasonAuthority(
            owner: Object(),
            sourceRevision: Object(),
            seasonIndex: 1,
            effectiveClubs: const []),
        throwsStateError);
    final controller = ManagerCareerController(
        careerSeed: 20260903, simulationVersion: 1, initialSeasonIndex: 1);
    final effective = controller.adjustClubsForSeason(
        seasonIndex: 1,
        squadClubs: source.squads,
        players: source.openingPlayers,
        leagues: source.openingLeagues,
        financeStates: source.openingFinance);
    expect(
        () => controller.captureSeasonAuthority(
            owner: source.owner,
            sourceRevision: source.revision,
            seasonIndex: 1,
            effectiveClubs: List.of(effective)),
        throwsStateError);
    final capture = controller.captureSeasonAuthority(
        owner: source.owner,
        sourceRevision: source.revision,
        seasonIndex: 1,
        effectiveClubs: effective);
    expect(capture.effectiveClubs, same(effective));
    expect(capture.seasons, isEmpty);
    expect(
        () => controller.captureSeasonAuthority(
            owner: source.owner,
            sourceRevision: source.revision,
            seasonIndex: 1,
            effectiveClubs: effective),
        throwsStateError);
  });

  test(
      'lossless pending completion equals original setup, without reconstruction',
      () {
    final before = source.finalAssignments.map((a) => a.signature).toList();
    final fork = source.fork(), repeat = source.fork();
    expect(source.counter.calls, 1);
    expect(fork.poolGenerator, same(source.poolGenerator));
    expect(fork.fitModel, same(source.fitModel));
    expect(fork.impactModel, same(source.impactModel));
    expect(fork.dismissalPolicy, same(source.dismissalPolicy));
    expect(fork.managers.map((m) => m.signature),
        source.managers.map((m) => m.signature));
    for (var i = 0; i < source.managers.length; i++) {
      expect(fork.managers[i], same(source.managers[i]));
    }
    source.complete(fork);
    source.complete(repeat);
    final original = ManagerCareerController(
        careerSeed: 20260903, simulationVersion: 1, initialSeasonIndex: 1);
    original.adjustClubsForSeason(
        seasonIndex: 1,
        squadClubs: source.squads,
        players: source.openingPlayers,
        leagues: source.openingLeagues,
        financeStates: source.openingFinance);
    source.complete(original);
    expect(fork.seasons.single.signature, original.seasons.single.signature);
    expect(repeat.seasons.single.signature, original.seasons.single.signature);
    expect(fork.finalAssignments.map((a) => a.signature),
        original.finalAssignments.map((a) => a.signature));
    expect(source.counter.calls, 1);
    expect(source.seasons, isEmpty);
    expect(source.finalAssignments.map((a) => a.signature), before);
    expect(source.authority.assignments.length, 48);
    expect(() => source.authority.assignments.clear(), throwsUnsupportedError);
    expect(
        () => source.authority.effectiveClubs.clear(), throwsUnsupportedError);
  });

  test(
      'foreign owner/revision/season/controller and copied captures fail closed',
      () {
    for (final action in <void Function()>[
      () => source.forkSeasonAuthority(
          authority: source.authority,
          owner: Object(),
          sourceRevision: source.revision,
          seasonIndex: 1),
      () => source.forkSeasonAuthority(
          authority: source.authority,
          owner: source.owner,
          sourceRevision: Object(),
          seasonIndex: 1),
      () => source.forkSeasonAuthority(
          authority: source.authority,
          owner: source.owner,
          sourceRevision: source.revision,
          seasonIndex: 2),
      () => source.fork().forkSeasonAuthority(
          authority: source.authority,
          owner: source.owner,
          sourceRevision: source.revision,
          seasonIndex: 1),
    ]) {
      expect(action, throwsStateError);
    }
    final other = CapturedManagerFixture(CountingManagerPool())..run();
    expect(other.authority.effectiveClubs.map((c) => c.strength),
        source.effective.map((c) => c.strength));
    expect(
        () => source.forkSeasonAuthority(
            authority: other.authority,
            owner: source.owner,
            sourceRevision: source.revision,
            seasonIndex: 1),
        throwsStateError);
  });

  test('restore stays pending-empty; fork exception leaves original reusable',
      () {
    final restored = ManagerCareerController.restore(
        careerSeed: source.careerSeed,
        simulationVersion: 1,
        initialSeasonIndex: 1,
        managers: source.managers,
        assignments: source.finalAssignments,
        seasons: source.seasons);
    expect(() => source.complete(restored), throwsStateError);
    var fail = true;
    final failing =
        CapturedManagerFixture(CountingManagerPool(), patience: (_, __) {
      if (fail) throw StateError('detached failure');
      return 50;
    })
          ..run();
    expect(() => failing.complete(failing.fork()), throwsStateError);
    expect(failing.seasons, isEmpty);
    expect(
        failing.finalAssignments.every((a) => a.completedSeasons == 0), isTrue);
    fail = false;
    final recovered = failing.fork();
    failing.complete(recovered);
    expect(recovered.seasons.single.clubs.length, 48);
    expect(failing.seasons, isEmpty);
    expect(failing.counter.calls, 1);
  });

  test('history and policy identity survive capture, stale capture is rejected',
      () {
    final pool = CountingManagerPool();
    final controller = ManagerCareerController(
        careerSeed: 20260903,
        simulationVersion: 1,
        initialSeasonIndex: 1,
        poolGenerator: pool);
    final first = controller.adjustClubsForSeason(
        seasonIndex: 1,
        squadClubs: source.squads,
        players: source.openingPlayers,
        leagues: source.openingLeagues,
        financeStates: source.openingFinance);
    final capture = controller.captureSeasonAuthority(
        owner: source.owner,
        sourceRevision: source.revision,
        seasonIndex: 1,
        effectiveClubs: first);
    source.complete(controller);
    expect(
        () => capture.forkDetached(
            expectedOwner: source.owner,
            expectedRevision: source.revision,
            expectedSeason: 1),
        throwsStateError);
    final next = controller.adjustClubsForSeason(
        seasonIndex: 2,
        squadClubs: source.squads,
        players: source.openingPlayers,
        leagues: source.openingLeagues,
        financeStates: source.openingFinance);
    final nextCapture = controller.captureSeasonAuthority(
        owner: source.owner,
        sourceRevision: source.revision,
        seasonIndex: 2,
        effectiveClubs: next);
    final fork = nextCapture.forkDetached(
        expectedOwner: source.owner,
        expectedRevision: source.revision,
        expectedSeason: 2);
    expect(pool.calls, 1);
    expect(nextCapture.seasons.single, same(controller.seasons.single));
    expect(fork.seasons.single, same(controller.seasons.single));
    expect(fork.finalAssignments.map((a) => a.signature),
        controller.finalAssignments.map((a) => a.signature));
    expect(nextCapture.initialSeasonIndex, 1);
    expect(nextCapture.seasonIndex, 2);
    expect(nextCapture.careerSeed, controller.careerSeed);
    expect(nextCapture.simulationVersion, controller.simulationVersion);
    expect(fork.poolGenerator, same(pool));
    expect(() => nextCapture.seasons.clear(), throwsUnsupportedError);
  });
}
