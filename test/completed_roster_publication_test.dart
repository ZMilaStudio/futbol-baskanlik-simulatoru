import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/facility_sponsor_crisis_runtime_composition.dart'
    show TrainingGroundFacilityState;
import 'package:futbol_baskanlik_m0/player_president_manager_control.dart';
import 'package:futbol_baskanlik_m0/player_president_transfer_strategy_control.dart';
import 'package:test/test.dart';
import 'p2_b3b1_postseason_outer_transition_test.dart' show B3B1LegacyClosing;

class _LifecycleRecorder extends PlayerLifecycleEngine {
  PlayerLifecycleResult? result;
  List<Player>? before;
  int calls = 0;
  @override
  PlayerLifecycleResult advance({
    required List<Player> currentPlayers,
    required List<Club> currentClubs,
    required List<Club> referenceClubs,
    required int careerSeed,
    required int nextSeasonIndex,
    required int simulationVersion,
    Map<String, AcademyFacilityState> academyFacilities = const {},
    Map<String, TrainingGroundFacilityState> trainingGroundFacilities =
        const {},
  }) {
    calls++;
    before = currentPlayers;
    return result = super.advance(
        currentPlayers: currentPlayers,
        currentClubs: currentClubs,
        referenceClubs: referenceClubs,
        careerSeed: careerSeed,
        nextSeasonIndex: nextSeasonIndex,
        simulationVersion: simulationVersion,
        academyFacilities: academyFacilities,
        trainingGroundFacilities: trainingGroundFacilities);
  }
}

void main() {
  test(
      'lifecycle publication copies real post-lifecycle values and source order',
      () {
    final recorder = _LifecycleRecorder();
    final fixture = B3B1LegacyClosing(
        config: const SimulationConfig(careerSeed: 20260903),
        worldEngine: WorldCareerEngine(lifecycleEngine: recorder));
    final transition = fixture.claim();
    expect(transition.completedRosterLifecycle, isNull);
    final pending = transition.prepareTransfer()!;
    final producer = recorder.result!;
    expect(transition.completedRosterLifecycle, isNull);
    transition.submitTransfer(
        expectedPending: pending,
        choice: PlayerTransferStrategyChoice.fromProfile(
            pending.context.aiProfile));
    transition.prepareDomain();
    transition.prepareOuterSuccessor();
    final manager = transition.managerPending!;
    if (manager.review.canRetain) {
      transition.submitManagerReview(
          expectedPending: manager, choice: PlayerManagerReviewChoice.retain);
    } else {
      final replacement = transition.submitManagerReview(
          expectedPending: manager, choice: PlayerManagerReviewChoice.replace)!;
      transition.submitManagerReplacement(
          expectedPending: replacement,
          selected: replacement.replacement!.candidates.first.manager);
    }
    expect(transition.completedRosterLifecycle, isNull);
    final graph = transition.moveOwnedAnnualContinuation();
    final snapshot = transition.completedRosterLifecycle!;
    final retired = producer.retiredPlayers
        .where((player) => player.clubId == graph.control.controlledClubId)
        .toList();
    final youth = producer.youthIntake
        .where((player) => player.clubId == graph.control.controlledClubId)
        .toList();
    expect(retired, isNotEmpty);
    expect(youth, isNotEmpty);
    expect(snapshot.completedSeasonIndex, graph.targetSeasonIndex - 1);
    expect(snapshot.targetSeasonIndex, graph.targetSeasonIndex);
    expect(snapshot.controlledClubId, graph.control.controlledClubId);
    for (final (rows, source) in [
      (snapshot.retiredPlayers, retired),
      (snapshot.youthIntake, youth)
    ]) {
      expect(rows, hasLength(source.length));
      for (var i = 0; i < source.length; i++) {
        expect(rows[i].playerId, source[i].id);
        expect(rows[i].name, source[i].name);
        expect(rows[i].position, source[i].position);
        expect(rows[i].age, source[i].age);
        expect(rows[i].ability, source[i].ability);
        expect(rows[i].potential, source[i].potential);
        expect(rows[i].isAcademyGraduate, source[i].isAcademyGraduate);
      }
      expect(() => rows.clear(), throwsUnsupportedError);
    }
    expect(
        snapshot.retiredPlayers.first.age,
        greaterThan(recorder.before!
            .singleWhere((player) => player.id == retired.first.id)
            .age));
    final signature = snapshot.signature;
    expect(transition.moveOwnedAnnualContinuation(), same(graph));
    expect(transition.completedRosterLifecycle, same(snapshot));
    expect(snapshot.signature, signature);
    expect(recorder.calls, 1);
  });
}
