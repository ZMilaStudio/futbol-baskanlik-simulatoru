import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/election/player_president_tenure_control_gate.dart';
import 'package:test/test.dart';

// Runtime-view calculation tests. These views do not mint transition authority
// and are NOT substitutes for the genuine application/settlement source tests.
PresidentClubRuntimeState _incumbent(String clubId, int seed) {
  final opening = const PresidentOpeningStateInitializer().prepareClub(
    clubId: clubId,
    config: SimulationConfig(careerSeed: seed),
  );
  return PresidentClubRuntimeState(
    tenure: opening.tenure,
    managementProfile: opening.managementProfile,
    fanReputation: opening.fan,
    mediaReputation: opening.media,
  );
}

void main() {
  const gate = PlayerPresidentTenureControlGate();
  test('runtime refresh preserves exact active control with genuine incumbent',
      () {
    final incumbent = _incumbent('t1_01', 101);
    final state = PlayerPresidentTenureControlState.initial(
      controlledClubId: incumbent.clubId,
      playerPresidentId: incumbent.tenure.president.id,
    );
    final next = gate.refreshRuntimeView(
      state: state,
      incumbent: incumbent,
      completedSeasons: 1,
    );
    expect(next, same(state));
    expect(next.active, isTrue);
    expect(incumbent.tenure.startedSeasonIndex, 0);
  });

  test('real different incumbent produces irreversible control loss', () {
    final original = _incumbent('t1_01', 101);
    final challenger = const PresidentProfileGenerator().generateChallenger(
      clubId: original.clubId,
      seasonIndex: 3,
      electionTermNumber: 1,
      careerSeed: 101,
      simulationVersion: 1,
    );
    final successor = PresidentClubRuntimeState(
      tenure: original.tenure.handover(
        incoming: challenger,
        effectiveSeasonIndex: 4,
      ),
      managementProfile: const PresidentManagementProfileGenerator().generate(
        president: challenger,
        careerSeed: 101,
        simulationVersion: 1,
      ),
      fanReputation: original.fanReputation,
      mediaReputation: original.mediaReputation,
    );
    expect(successor.tenure.president.id, isNot(original.tenure.president.id));
    final state = PlayerPresidentTenureControlState.initial(
      controlledClubId: original.clubId,
      playerPresidentId: original.tenure.president.id,
    );
    final lost = gate.refreshRuntimeView(
      state: state,
      incumbent: successor,
      completedSeasons: 4,
    );
    expect(lost.lost, isTrue);
    expect(lost.lostAtCompletedSeason, 4);
    expect(lost.successorPresidentId, successor.tenure.president.id);
    expect(state.active, isTrue);
    expect(
        gate.refreshRuntimeView(
          state: lost,
          incumbent: original,
          completedSeasons: 5,
        ),
        same(lost));
    expect(
        gate.refreshRuntimeView(
          state: lost,
          incumbent: successor,
          completedSeasons: 5,
        ),
        same(lost));
  });

  test('foreign club rejected without changing existing state', () {
    final original = _incumbent('t1_01', 101);
    final foreign = _incumbent('t1_02', 101);
    final state = PlayerPresidentTenureControlState.initial(
      controlledClubId: original.clubId,
      playerPresidentId: original.tenure.president.id,
    );
    final before = state.signature;
    expect(
        () => gate.refreshRuntimeView(
              state: state,
              incumbent: foreign,
              completedSeasons: 1,
            ),
        throwsArgumentError);
    expect(state.signature, before);
  });

  test('invalid cursor rejected before loss or control publication', () {
    final original = _incumbent('t1_01', 101);
    final state = PlayerPresidentTenureControlState.initial(
      controlledClubId: original.clubId,
      playerPresidentId: original.tenure.president.id,
    );
    expect(
        () => gate.refreshRuntimeView(
              state: state,
              incumbent: original,
              completedSeasons: -1,
            ),
        throwsArgumentError);
    expect(state.active, isTrue);
  });

  test('mismatched successor evidence rejected before changing control', () {
    final original = _incumbent('t1_01', 101);
    final foreign = _incumbent('t1_02', 101);
    final malformed = PresidentClubRuntimeState(
      tenure: original.tenure,
      managementProfile: foreign.managementProfile,
      fanReputation: original.fanReputation,
      mediaReputation: original.mediaReputation,
    );
    final state = PlayerPresidentTenureControlState.initial(
      controlledClubId: original.clubId,
      playerPresidentId: original.tenure.president.id,
    );
    expect(
        () => gate.refreshRuntimeView(
              state: state,
              incumbent: malformed,
              completedSeasons: 1,
            ),
        throwsArgumentError);
    expect(state.active, isTrue);
  });
}
