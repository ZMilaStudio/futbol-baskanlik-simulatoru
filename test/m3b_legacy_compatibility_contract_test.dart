import 'dart:convert';
import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_store.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_snapshot.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_persistence_bundle.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_transcript_snapshot.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:test/test.dart';

// These three committed files are frozen *v1 serialized bytes*, transported
// losslessly as gzip/base64 to keep nested canonical saves reviewable in Git.
// No production codec runs to construct the expected fixture on test startup.
String _golden(String name) => utf8.decode(gzip.decode(base64Decode(
      File('test/fixtures/m3b_${name}_v1.json.gz.b64').readAsStringSync().trim(),
    )));

Map<String, dynamic> _envelope(String bytes) =>
    jsonDecode(bytes) as Map<String, dynamic>;

String _resigned(
  String original,
  void Function(Map<String, dynamic>, Map<String, dynamic>) change,
) {
  final root = _envelope(original);
  final payload = root['payload'] as Map<String, dynamic>;
  change(root, payload);
  root['checksum'] = SaveChecksum.forPayload(
    saveVersion: root['saveVersion'] as int,
    payload: payload,
  );
  return SaveChecksum.canonicalJson(root);
}

void _expectFailure(
  Object? Function(String) decode,
  String bytes,
  SaveLoadFailure failure,
) {
  expect(
    () => decode(bytes),
    throwsA(isA<SaveLoadException>().having(
      (exception) => exception.failure,
      'failure',
      failure,
    )),
  );
}

void main() {
  const m65 = PlayerPresidentTicketPricingRuntimeSaveCodec();
  const m75 = PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec();
  const m80 =
      PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec();
  const transcriptCodec = PlayerPresidentInteractiveDecisionTranscriptSaveCodec();
  late String oldM65;
  late String oldM75;
  late String oldM80;

  setUpAll(() {
    oldM65 = _golden('m65');
    oldM75 = _golden('m75');
    oldM80 = _golden('m80');
  });

  test('frozen M65/M75/M80 v1 bytes open and canonical re-encode unchanged', () {
    final checkpoint = m65.decode(oldM65);
    final bundle = m75.decode(oldM75);
    final bootstrap = m80.decode(oldM80);
    expect(m65.encode(checkpoint), oldM65);
    expect(m75.encode(bundle), oldM75);
    expect(m80.encode(bootstrap), oldM80);
    expect(checkpoint.completedSeasons, 1);
    expect(checkpoint.nextSeasonIndex, 1);
    expect(bundle.checkpoint.signature, checkpoint.signature);
    expect(m65.encode(bundle.checkpoint), oldM65);
    expect(bundle.transcript.decisionCount, 0);
    expect(bootstrap.transcript.decisionCount, 0);
    expect(transcriptCodec.encode(bundle.transcript),
        transcriptCodec.encode(bootstrap.transcript));
    expect(bundle.answeredDecisionCount, 0);
    expect(bootstrap.answeredDecisionCount, 0);

    for (final item in <String>[oldM65, oldM75, oldM80]) {
      final envelope = _envelope(item);
      expect(envelope['saveVersion'], 1);
      expect(
        envelope['checksum'],
        SaveChecksum.forPayload(
          saveVersion: 1,
          payload: envelope['payload'],
        ),
      );
      expect(SaveChecksum.canonicalJson(envelope), item);
    }

    // A v1 checkpoint remains a completed-season / next-season checkpoint;
    // it is not the M2 in-memory nextRound=31 projection.
    expect(bundle.restoreSession().advance(), isNotNull);
    final world = const FictionalWorldFactory().build();
    bootstrap.validateWorld(clubs: world.clubs, leagues: world.leagues);
  });

  test('versions are checked using each existing v1 codec contract', () {
    for (final pair in <(Object? Function(String), String)>[
      (m65.decode, oldM65),
      (m75.decode, oldM75),
      (m80.decode, oldM80),
    ]) {
      _expectFailure(
        pair.$1,
        _resigned(pair.$2, (root, payload) => root['saveVersion'] = 2),
        SaveLoadFailure.unsupportedVersion,
      );
      _expectFailure(
        pair.$1,
        _resigned(pair.$2, (root, payload) => root['saveVersion'] = -1),
        SaveLoadFailure.unsupportedVersion,
      );
    }
    // M65 historically admits version 0 through its range check, but its
    // payload has no v0 decoding path. Freeze that precise fail-closed result.
    _expectFailure(
      m65.decode,
      _resigned(oldM65, (root, payload) => root['saveVersion'] = 0),
      SaveLoadFailure.invalidPayload,
    );
    for (final pair in <(Object? Function(String), String)>[
      (m75.decode, oldM75),
      (m80.decode, oldM80),
    ]) {
      _expectFailure(
        pair.$1,
        _resigned(pair.$2, (root, payload) => root['saveVersion'] = 0),
        SaveLoadFailure.unsupportedVersion,
      );
    }
  });

  test('bad JSON, format, payload and checksum all fail closed', () {
    for (final pair in <(Object? Function(String), String)>[
      (m65.decode, oldM65),
      (m75.decode, oldM75),
      (m80.decode, oldM80),
    ]) {
      final decode = pair.$1;
      final source = pair.$2;
      _expectFailure(decode, '{broken', SaveLoadFailure.malformedJson);
      _expectFailure(
        decode,
        _resigned(source, (root, payload) => root['format'] = 'wrong-format'),
        SaveLoadFailure.invalidEnvelope,
      );
      final corrupt = _envelope(source);
      (corrupt['payload'] as Map<String, dynamic>)['corrupted'] = true;
      _expectFailure(
        decode,
        jsonEncode(corrupt),
        SaveLoadFailure.checksumMismatch,
      );
    }
    _expectFailure(
      m65.decode,
      _resigned(oldM65, (root, payload) => payload['runtimeSave'] = null),
      SaveLoadFailure.invalidPayload,
    );
    _expectFailure(
      m75.decode,
      _resigned(oldM75, (root, payload) => payload['resumeConfig'] = null),
      SaveLoadFailure.invalidPayload,
    );
    _expectFailure(
      m80.decode,
      _resigned(oldM80, (root, payload) => payload['config'] = null),
      SaveLoadFailure.invalidPayload,
    );
  });

  test('M75 outer checksum cannot hide corrupt nested M65 or M74 saves', () {
    _expectFailure(
      m75.decode,
      _resigned(
        oldM75,
        (root, payload) => payload['gameStateSave'] = '{broken',
      ),
      SaveLoadFailure.malformedJson,
    );
    _expectFailure(
      m75.decode,
      _resigned(
        oldM75,
        (root, payload) => payload['transcriptSave'] = '{broken',
      ),
      SaveLoadFailure.malformedJson,
    );
    _expectFailure(
      m80.decode,
      _resigned(oldM80, (root, payload) => payload['transcript'] = '{broken'),
      SaveLoadFailure.malformedJson,
    );
  });

  test('frozen M75/M80 physical same-id siblings retain source isolation', () {
    final root = Directory.systemTemp.createTempSync('fbs_m3b_golden_');
    try {
      final checkpointDir = Directory('${root.path}/checkpoints')
        ..createSync(recursive: true);
      final bootstrapDir = Directory('${root.path}/bootstraps')
        ..createSync(recursive: true);
      const slot = 'shared';
      final checkpointFile = File('${checkpointDir.path}/$slot.fbs.json')
        ..writeAsStringSync(oldM75, flush: true);
      final bootstrapFile = File('${bootstrapDir.path}/$slot.fbs.bootstrap.json')
        ..writeAsStringSync(oldM80, flush: true);
      final checkpointStore = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
        rootDirectory: checkpointDir,
      );
      final bootstrapStore =
          PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
        rootDirectory: bootstrapDir,
      );
      final world = const FictionalWorldFactory().build();
      expect(checkpointStore.listSlotIds(), [slot]);
      expect(bootstrapStore.listSlotIds(), [slot]);
      expect(
        checkpointStore.load(slot)!.encodePersistenceBundle(),
        oldM75,
      );
      expect(
        bootstrapStore.load(
          slotId: slot,
          clubs: world.clubs,
          leagues: world.leagues,
        )!.encodeNewGameBootstrapSnapshot(),
        oldM80,
      );

      // Freeze M77's current backup-over-target recovery contract with v1
      // bytes. A stray .tmp is not promoted over the committed .bak.
      final backup = File('${checkpointFile.path}.bak')
        ..writeAsStringSync(oldM75, flush: true);
      final temporary = File('${checkpointFile.path}.tmp')
        ..writeAsStringSync('incomplete', flush: true);
      checkpointFile.deleteSync();
      expect(
        checkpointStore.load(slot)!.encodePersistenceBundle(),
        oldM75,
      );
      expect(checkpointFile.readAsStringSync(), oldM75);
      expect(backup.existsSync(), isFalse);
      expect(temporary.existsSync(), isTrue); // current M77 behavior
      expect(bootstrapFile.readAsStringSync(), oldM80);
      expect(checkpointStore.delete(slot), isTrue);
      expect(temporary.existsSync(), isFalse);
      expect(bootstrapFile.readAsStringSync(), oldM80);
      expect(bootstrapStore.listSlotIds(), [slot]);
    } finally {
      root.deleteSync(recursive: true);
    }
  });
}
