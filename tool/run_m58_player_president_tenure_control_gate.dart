import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_control_gate.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final config = SimulationConfig(careerSeed: seed);
  final world = const FictionalWorldFactory().build();
  const domainEngine = PresidentDomainCareerEngine();
  const gate = PlayerPresidentTenureControlGate();
  const gateCodec = PlayerPresidentTenureControlSaveCodec();
  const domainCodec = PresidentDomainMemorySaveCodec();

  final before = domainEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 3,
    electionInterval: 4,
    hasFutureSeasonAfterReport: true,
  );
  final after = domainEngine.resume(
    checkpoint: before.checkpoint,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  );
  final beforeByClub = {
    for (final state in before.checkpoint.presidentRuntime.clubs)
      state.clubId: state.tenure.president.id,
  };
  final afterByClub = {
    for (final state in after.checkpoint.presidentRuntime.clubs)
      state.clubId: state.tenure.president.id,
  };
  final turnoverClub = beforeByClub.keys.firstWhere(
    (clubId) => beforeByClub[clubId] != afterByClub[clubId],
  );
  final reelectedClub = beforeByClub.keys.firstWhere(
    (clubId) => beforeByClub[clubId] == afterByClub[clubId],
  );

  final active = gate.capture(
    presidentRuntime: before.checkpoint.presidentRuntime,
    controlledClubId: turnoverClub,
  );
  final lost = gate.refresh(
    state: active,
    presidentRuntime: after.checkpoint.presidentRuntime,
  );
  final reelectedBefore = gate.capture(
    presidentRuntime: before.checkpoint.presidentRuntime,
    controlledClubId: reelectedClub,
  );
  final reelectedAfter = gate.refresh(
    state: reelectedBefore,
    presidentRuntime: after.checkpoint.presidentRuntime,
  );
  final restoredGate = gateCodec.decode(gateCodec.encode(active));
  final restoredDomain = domainCodec.decode(domainCodec.encode(before.checkpoint));
  final resumed = domainEngine.resume(
    checkpoint: restoredDomain,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  );
  final restoredLost = gate.refresh(
    state: restoredGate,
    presidentRuntime: resumed.checkpoint.presidentRuntime,
  );

  final turnoverStopsControl = lost.lost &&
      lost.successorPresidentId == afterByClub[turnoverClub] &&
      !gate.canControl(
        state: lost,
        presidentRuntime: after.checkpoint.presidentRuntime,
      );
  final reelectionKeepsControl = reelectedAfter.active &&
      reelectedAfter.signature == reelectedBefore.signature;
  final stickyLoss = gate
          .refresh(
            state: lost,
            presidentRuntime: before.checkpoint.presidentRuntime,
          )
          .signature ==
      lost.signature;
  final deterministic = restoredLost.signature == lost.signature &&
      resumed.checkpoint.signature == after.checkpoint.signature;

  if (!turnoverStopsControl ||
      !reelectionKeepsControl ||
      !stickyLoss ||
      !deterministic) {
    throw StateError(
      'M58 gate mismatch: turnover=$turnoverStopsControl '
      'reelection=$reelectionKeepsControl sticky=$stickyLoss '
      'deterministic=$deterministic',
    );
  }

  print(
    'M58_PLAYER_PRESIDENT_TENURE_CONTROL_GATE_PASS '
    'turnoverClub=$turnoverClub reelectedClub=$reelectedClub '
    'turnoverStopsControl=$turnoverStopsControl '
    'reelectionKeepsControl=$reelectionKeepsControl '
    'stickyLoss=$stickyLoss deterministic=$deterministic '
    'worldClubs=${world.clubs.length}',
  );
}
