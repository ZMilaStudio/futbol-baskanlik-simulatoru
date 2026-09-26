// One-time baseline capture. This file is replaced by fixed golden fixtures
// in the final M3-B candidate; it is not a production save path.
import 'dart:convert';
import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_snapshot.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_persistence_bundle.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_transcript_snapshot.dart';
import 'package:futbol_baskanlik_m0/player_president_unified_decision_gateway_runtime.dart';
import 'package:test/test.dart';

void _emit(String label, String encoded) {
  final zipped = base64Encode(gzip.encode(utf8.encode(encoded)));
  print('M3B_CAPTURE_${label}_BEGIN');
  for (var i = 0; i < zipped.length; i += 1200) {
    final end = i + 1200 > zipped.length ? zipped.length : i + 1200;
    print('M3B_CAPTURE_${label}_CHUNK:${zipped.substring(i, end)}');
  }
  print('M3B_CAPTURE_${label}_END rawLength=${encoded.length} gzipBase64Length=${zipped.length}');
}

void main() {
  test('one-time M65 M75 M80 v1 canonical historical baseline capture', () {
    const config = SimulationConfig(careerSeed: 20260903);
    const m65 = PlayerPresidentTicketPricingRuntimeSaveCodec();
    const m75 = PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec();
    const m80 = PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec();
    final world = const FictionalWorldFactory().build();
    final controlledClubId = world.clubs.first.id;
    final checkpoint = const PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine()
        .simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlledClubId,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    ).checkpoint;
    final transcript = PlayerPresidentInteractiveDecisionTranscriptSnapshot(
      entries: const [],
    );
    const resumeConfig = PlayerPresidentInteractiveDecisionResumeConfig(
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
      crisisActivationThreshold: 55,
      candidateLimit: 5,
    );
    final checkpointSave = m65.encode(checkpoint);
    final bundleSave = m75.encode(PlayerPresidentInteractiveDecisionPersistenceBundle(
      checkpoint: checkpoint,
      transcript: transcript,
      resumeConfig: resumeConfig,
    ));
    final bootstrapSave = m80.encode(
      PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshot(
        worldFingerprint:
            PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshot.worldFingerprintFor(
          clubs: world.clubs,
          leagues: world.leagues,
        ),
        config: config,
        controlledClubId: controlledClubId,
        electionInterval: 4,
        resumeConfig: resumeConfig,
        transcript: transcript,
      ),
    );
    expect(m65.encode(m65.decode(checkpointSave)), checkpointSave);
    expect(m75.encode(m75.decode(bundleSave)), bundleSave);
    expect(m80.encode(m80.decode(bootstrapSave)), bootstrapSave);
    _emit('M65', checkpointSave);
    _emit('M75', bundleSave);
    _emit('M80', bootstrapSave);
  });
}
