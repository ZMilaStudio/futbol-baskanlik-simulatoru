import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_control_gate.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const gate = PlayerPresidentTenureControlGate();
  const gateCodec = PlayerPresidentTenureControlSaveCodec();
  const domainCodec = PresidentDomainMemorySaveCodec();
  const domainEngine = PresidentDomainCareerEngine();

  late PresidentDomainResumeResult beforeElection;
  late PresidentDomainResumeResult afterElection;
  late String turnoverClubId;
  late String reelectedClubId;

  setUpAll(() {
    final world = const FictionalWorldFactory().build();
    final config = SimulationConfig(careerSeed: seed);
    beforeElection = domainEngine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      seasonCount: 3,
      electionInterval: 4,
      hasFutureSeasonAfterReport: true,
    );
    afterElection = domainEngine.resume(
      checkpoint: beforeElection.checkpoint,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );

    final beforeByClub = {
      for (final state in beforeElection.checkpoint.presidentRuntime.clubs)
        state.clubId: state.tenure.president.id,
    };
    final afterByClub = {
      for (final state in afterElection.checkpoint.presidentRuntime.clubs)
        state.clubId: state.tenure.president.id,
    };
    turnoverClubId = beforeByClub.keys.firstWhere(
      (clubId) => beforeByClub[clubId] != afterByClub[clubId],
    );
    reelectedClubId = beforeByClub.keys.firstWhere(
      (clubId) => beforeByClub[clubId] == afterByClub[clubId],
    );
  });

  test('M58 captures the real incumbent identity as active player control', () {
    final state = gate.capture(
      presidentRuntime: beforeElection.checkpoint.presidentRuntime,
      controlledClubId: turnoverClubId,
    );
    final incumbent = beforeElection.checkpoint.presidentRuntime.clubs
        .firstWhere((item) => item.clubId == turnoverClubId);

    expect(state.controlledClubId, turnoverClubId);
    expect(state.playerPresidentId, incumbent.tenure.president.id);
    expect(state.active, isTrue);
    expect(state.lostAtCompletedSeason, isNull);
    expect(state.successorPresidentId, isNull);
    expect(
      gate.canControl(
        state: state,
        presidentRuntime: beforeElection.checkpoint.presidentRuntime,
      ),
      isTrue,
    );
  });

  test('M58 real election turnover permanently deactivates player control', () {
    final before = gate.capture(
      presidentRuntime: beforeElection.checkpoint.presidentRuntime,
      controlledClubId: turnoverClubId,
    );
    final after = gate.refresh(
      state: before,
      presidentRuntime: afterElection.checkpoint.presidentRuntime,
    );
    final successor = afterElection.checkpoint.presidentRuntime.clubs
        .firstWhere((item) => item.clubId == turnoverClubId)
        .tenure
        .president
        .id;

    expect(after.lost, isTrue);
    expect(after.lostAtCompletedSeason, 4);
    expect(after.successorPresidentId, successor);
    expect(successor, isNot(before.playerPresidentId));
    expect(
      gate.canControl(
        state: after,
        presidentRuntime: afterElection.checkpoint.presidentRuntime,
      ),
      isFalse,
    );
  });

  test('M58 reelection keeps the same player-president control active', () {
    final before = gate.capture(
      presidentRuntime: beforeElection.checkpoint.presidentRuntime,
      controlledClubId: reelectedClubId,
    );
    final after = gate.refresh(
      state: before,
      presidentRuntime: afterElection.checkpoint.presidentRuntime,
    );

    expect(after.signature, before.signature);
    expect(after.active, isTrue);
    expect(
      gate.canControl(
        state: after,
        presidentRuntime: afterElection.checkpoint.presidentRuntime,
      ),
      isTrue,
    );
  });

  test('M58 a lost presidency never reactivates from a later identity match', () {
    final captured = gate.capture(
      presidentRuntime: beforeElection.checkpoint.presidentRuntime,
      controlledClubId: turnoverClubId,
    );
    final lost = gate.refresh(
      state: captured,
      presidentRuntime: afterElection.checkpoint.presidentRuntime,
    );
    final replayedOldIncumbent = gate.refresh(
      state: lost,
      presidentRuntime: beforeElection.checkpoint.presidentRuntime,
    );

    expect(replayedOldIncumbent.signature, lost.signature);
    expect(replayedOldIncumbent.lost, isTrue);
  });

  test('M58 control identity survives save load and deterministic resume', () {
    final captured = gate.capture(
      presidentRuntime: beforeElection.checkpoint.presidentRuntime,
      controlledClubId: turnoverClubId,
    );
    final encodedGate = gateCodec.encode(captured);
    final encodedDomain = domainCodec.encode(beforeElection.checkpoint);

    final restoredGate = gateCodec.decode(encodedGate);
    final restoredDomain = domainCodec.decode(encodedDomain);
    final resumed = domainEngine.resume(
      checkpoint: restoredDomain,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    );
    final baseline = gate.refresh(
      state: captured,
      presidentRuntime: afterElection.checkpoint.presidentRuntime,
    );
    final restored = gate.refresh(
      state: restoredGate,
      presidentRuntime: resumed.checkpoint.presidentRuntime,
    );

    expect(gateCodec.encode(restoredGate), encodedGate);
    expect(restored.signature, baseline.signature);
    expect(resumed.checkpoint.signature, afterElection.checkpoint.signature);
    expect(restored.lost, isTrue);
  });
}
