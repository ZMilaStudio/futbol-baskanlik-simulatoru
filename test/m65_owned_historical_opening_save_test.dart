import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_durable_historical_opening_application.dart';
import 'package:futbol_baskanlik_m0/player_president_owned_historical_opening_persistence.dart';
import 'package:test/test.dart';
import 'package:futbol_baskanlik_m0/player_president_owned_season_application.dart'
    show PlayerPresidentOwnedSeasonPromisePending;

import 'support/owned_first_future_opening_worker.dart'
    show createGenuineOpening;
import 'support/owned_historical_opening_worker.dart' as worker;

const _codec = PlayerPresidentTicketPricingRuntimeSaveCodec();
Map<String, dynamic> _map(Object? value) => value as Map<String, dynamic>;
String _signed(Map<String, dynamic> envelope) {
  envelope['checksum'] = SaveChecksum.forPayload(
      saveVersion: envelope['saveVersion'] as int,
      payload: envelope['payload']);
  return SaveChecksum.canonicalJson(envelope);
}

String _change(String raw, void Function(Map<String, dynamic>) mutate) {
  final envelope = _map(jsonDecode(raw));
  mutate(_map(envelope['payload']));
  return _signed(envelope);
}

// Re-sign the public wire identity only for deliberately altered NEGATIVE fixtures.
// This never mints producer provenance or executable ownership.
void _rebindDecision(Map<String, dynamic> p) {
  _map(p['pending'])['decisionId'] = sha256
      .convert(utf8.encode(SaveChecksum.canonicalJson({
        'careerInstanceId': p['careerInstanceId'],
        'clubId': p['controlledClubId'],
        'playerPresidentId': p['expectedPlayerPresidentId'],
        'seasonIndex': 0,
        'phase': p['phase'],
        'kind': 'promise',
        'contextSignature': _map(p['pending'])['contextSignature'],
      })))
      .toString();
}

Matcher _failure(SaveLoadFailure failure) =>
    isA<SaveLoadException>().having((e) => e.failure, 'failure', failure);
String _legacy() => utf8.decode(gzip.decode(base64Decode(
    File('test/fixtures/m3b_m65_v1.json.gz.b64').readAsStringSync().trim())));

void main() {
  late String genuine;
  late M65OwnedHistoricalOpeningState state;
  setUpAll(() {
    genuine = worker.createHistoricalOpening();
    state = _codec.decodeHistoricalOpening(genuine);
  });

  test('H01 exact v3 envelope and twelve-key untouched blueprint roundtrip',
      () {
    final envelope = _map(jsonDecode(genuine));
    expect(envelope.keys.toSet(),
        {'format', 'saveVersion', 'payload', 'checksum'});
    expect(envelope['saveVersion'], 3);
    final p = _map(envelope['payload']);
    expect(p.keys.toSet(), {
      'careerInstanceId',
      'origin',
      'phase',
      'runtimeProfile',
      'sourceClubs',
      'sourceLeagues',
      'config',
      'controlledClubId',
      'expectedPlayerPresidentId',
      'electionInterval',
      'pending',
      'preparedOpeningDigest'
    });
    expect(p['origin'], 'historicalBasicX1');
    expect(p['phase'], 'historicalPromisePending');
    expect(p['runtimeProfile'], 'canonicalHistoricalOpeningV1');
    expect(p['sourceClubs'], hasLength(48));
    expect(p['sourceLeagues'], hasLength(3));
    expect(_map(p['config'])['seasonIndex'], 0);
    expect(state.careerInstanceId, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(state.decisionId, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(state.historicalManagerAuthorityAvailable, isFalse);
    expect(_codec.encodeHistoricalOpening(state), genuine);
  });

  test(
      'H03 every required envelope/root/leaf rejects missing null and unknown members',
      () {
    final original = _map(jsonDecode(genuine));
    for (final key in original.keys) {
      for (final nullInstead in [false, true]) {
        final e = _map(jsonDecode(genuine));
        if (nullInstead) {
          e[key] = null;
        } else {
          e.remove(key);
        }
        expect(() => _codec.decodeHistoricalOpening(jsonEncode(e)),
            throwsA(isA<SaveLoadException>()),
            reason: 'envelope $key null=$nullInstead');
      }
    }
    final e = _map(jsonDecode(genuine))..['unknown'] = true;
    expect(() => _codec.decodeHistoricalOpening(jsonEncode(e)),
        throwsA(isA<SaveLoadException>()));
    final paths = <List<Object>>[
      [],
      ['config'],
      ['pending'],
      ['sourceClubs', 0],
      ['sourceLeagues', 0]
    ];
    for (final path in paths) {
      Map<String, dynamic> at(Map<String, dynamic> p) {
        dynamic v = p;
        for (final key in path) {
          v = v[key];
        }
        return _map(v);
      }

      final keys = at(_map(original['payload'])).keys.toList();
      for (final key in keys) {
        for (final nullInstead in [false, true]) {
          final encoded = _change(genuine, (p) {
            final m = at(p);
            if (nullInstead) {
              m[key] = null;
            } else {
              m.remove(key);
            }
          });
          expect(() => _codec.decodeHistoricalOpening(encoded),
              throwsA(_failure(SaveLoadFailure.invalidPayload)),
              reason: '$path.$key null=$nullInstead');
        }
      }
      expect(
          () => _codec.decodeHistoricalOpening(
              _change(genuine, (p) => at(p)['unexpected'] = true)),
          throwsA(_failure(SaveLoadFailure.invalidPayload)),
          reason: '$path extra');
    }
  });

  final invalid = <String, void Function(Map<String, dynamic>)>{
    'foreign origin': (p) => p['origin'] = 'legacyFullM65',
    'future profile': (p) => p['runtimeProfile'] = 'canonicalFirstFutureV1',
    'bad nonce': (p) => p['careerInstanceId'] = 'A' * 32,
    'unknown controlled club': (p) => p['controlledClubId'] = 'missing',
    'empty expected president': (p) => p['expectedPlayerPresidentId'] = '',
    'bad digest': (p) => p['preparedOpeningDigest'] = 'xyz',
    'wrong decisionId': (p) => _map(p['pending'])['decisionId'] = '0' * 64,
    'wrong kind': (p) => _map(p['pending'])['kind'] = 'transferStrategy',
    'empty context': (p) => _map(p['pending'])['contextSignature'] = '',
    'duplicate club': (p) =>
        (p['sourceClubs'] as List)[1] = (p['sourceClubs'] as List)[0],
    'missing club': (p) => (p['sourceClubs'] as List).removeLast(),
    'empty club name': (p) =>
        _map((p['sourceClubs'] as List).first)['name'] = '',
    'strength below range': (p) =>
        _map((p['sourceClubs'] as List).first)['strength'] = 39.9,
    'strength above range': (p) =>
        _map((p['sourceClubs'] as List).first)['strength'] = 100.1,
    'boolean strength': (p) =>
        _map((p['sourceClubs'] as List).first)['strength'] = true,
    'duplicate tier': (p) =>
        _map((p['sourceLeagues'] as List)[1])['tierLevel'] = 1,
    'noninteger tier': (p) =>
        _map((p['sourceLeagues'] as List).first)['tierLevel'] = 1.0,
    'unknown tier': (p) =>
        _map((p['sourceLeagues'] as List).first)['tierLevel'] = 4,
    'missing league': (p) => (p['sourceLeagues'] as List).removeLast(),
    'missing member': (p) =>
        (_map((p['sourceLeagues'] as List).first)['clubIds'] as List)
            .removeLast(),
    'foreign member': (p) =>
        (_map((p['sourceLeagues'] as List).first)['clubIds'] as List)[0] =
            'foreign',
    'duplicate member': (p) {
      final ids = _map((p['sourceLeagues'] as List).first)['clubIds'] as List;
      ids[1] = ids[0];
    },
    'bool interval': (p) => p['electionInterval'] = true,
    'double interval': (p) => p['electionInterval'] = 4.0,
    'zero interval': (p) => p['electionInterval'] = 0,
    'negative interval': (p) => p['electionInterval'] = -1,
    'season one': (p) => _map(p['config'])['seasonIndex'] = 1,
    'boolean seed': (p) => _map(p['config'])['careerSeed'] = true,
    'double seed': (p) => _map(p['config'])['careerSeed'] = 42.0,
    'zero simulation version': (p) =>
        _map(p['config'])['simulationVersion'] = 0,
    'double simulation version': (p) =>
        _map(p['config'])['simulationVersion'] = 1.0,
    'zero ratingScale': (p) => _map(p['config'])['ratingScale'] = 0,
    'negative min xG': (p) => _map(p['config'])['minExpectedGoals'] = -1,
    'reversed xG bounds': (p) => _map(p['config'])['maxExpectedGoals'] = 0.01,
    'string goals': (p) => _map(p['config'])['baseHomeGoals'] = '1.35',
  };
  for (final entry in invalid.entries) {
    test('H03/H06 strict v3 rejects ${entry.key} with recomputed checksum', () {
      expect(
          () => _codec.decodeHistoricalOpening(_change(genuine, entry.value)),
          throwsA(_failure(SaveLoadFailure.invalidPayload)));
      expect(_codec.encodeHistoricalOpening(state), genuine);
    });
  }

  test(
      'H09/H10 later phases and fabricated authority fields never become historical Pending',
      () {
    for (final phase in [
      'promiseResolved',
      'runningW0',
      'runningW1',
      'runningW29',
      'runningW30',
      'b1',
      'b2',
      'settled',
      'postseason',
      'firstFuturePromisePending'
    ]) {
      expect(
          () => _codec.decodeHistoricalOpening(
              _change(genuine, (p) => p['phase'] = phase)),
          throwsA(_failure(SaveLoadFailure.invalidPayload)),
          reason: phase);
    }
    for (final key in [
      'manager',
      'managerHistory',
      'receipt',
      'settlementReceipt',
      'worldSave',
      'worldCompletedSeasons',
      'acceptedPromise',
      'choice',
      'acknowledged',
      'playedFixture',
      'roundCursor',
      'authorityOrigin',
      'openingDigest'
    ]) {
      expect(
          () => _codec
              .decodeHistoricalOpening(_change(genuine, (p) => p[key] = 1)),
          throwsA(_failure(SaveLoadFailure.invalidPayload)),
          reason: key);
    }
  });

  test(
      'H04 duplicate root and inline keys reject equal conflicting and escaped names',
      () {
    const phase = '"phase":"historicalPromisePending"';
    for (final replacement in [
      '$phase,$phase',
      '"phase":"runningW1",$phase',
      r'"\u0070hase":"historicalPromisePending",' + phase
    ]) {
      expect(
          () => _codec.decodeHistoricalOpening(
              genuine.replaceFirst(phase, replacement)),
          throwsA(_failure(SaveLoadFailure.invalidPayload)));
    }
    for (final literal in [
      '"seasonIndex":0',
      '"kind":"promise"',
      '"tierLevel":1'
    ]) {
      expect(genuine, contains(literal));
      expect(
          () => _codec.decodeHistoricalOpening(
              genuine.replaceFirst(literal, '$literal,$literal')),
          throwsA(_failure(SaveLoadFailure.invalidPayload)));
    }
    final e = _map(jsonDecode(genuine));
    final checksum = '"checksum":${jsonEncode(e['checksum'])}';
    expect(
        () => _codec.decodeHistoricalOpening(
            genuine.replaceFirst(checksum, '$checksum,$checksum')),
        throwsA(_failure(SaveLoadFailure.invalidPayload)));
  });

  test(
      'H04 valid quoted and braced club names survive strict scanning and preparation',
      () {
    final app = worker.createHistoricalOpeningApplication(
        firstClubName: 'Kulüp "A" {x}: \\ maç');
    final raw = app.captureHistoricalOpening(
        expectedPending:
            app.currentStep as PlayerPresidentOwnedSeasonPromisePending);
    final decoded = _codec.decodeHistoricalOpening(raw);
    expect(decoded.sourceClubs.first.name, 'Kulüp "A" {x}: \\ maç');
    final restored =
        PlayerPresidentDurableHistoricalOpeningApplication.restoreEncoded(raw);
    addTearDown(restored.dispose);
    expect(restored.openingObservation, app.historicalOpeningObservation);
  });

  test(
      'H11 strict syntax/envelope/checksum/version failures have explicit categories',
      () {
    for (final raw in [
      '{',
      '{"a":1,}',
      '[1,]',
      '{"a":01}',
      '{} trailing',
      r'{"a":"\q"}',
      '{"a":"unterminated}'
    ]) {
      expect(() => _codec.decodeHistoricalOpening(raw),
          throwsA(_failure(SaveLoadFailure.malformedJson)));
    }
    expect(() => _codec.decodeHistoricalOpening('[]'),
        throwsA(_failure(SaveLoadFailure.invalidEnvelope)));
    final bad = _map(jsonDecode(genuine))..['checksum'] = '00000000';
    expect(() => _codec.decodeHistoricalOpening(jsonEncode(bad)),
        throwsA(_failure(SaveLoadFailure.checksumMismatch)));
    final format = _map(jsonDecode(genuine))..['format'] = 'foreign';
    expect(() => _codec.decodeHistoricalOpening(jsonEncode(format)),
        throwsA(_failure(SaveLoadFailure.invalidEnvelope)));
    for (final version in <Object>[1, 2, 4, 3.0, '3', true]) {
      final e = _map(jsonDecode(genuine))..['saveVersion'] = version;
      expect(() => _codec.decodeHistoricalOpening(jsonEncode(e)),
          throwsA(_failure(SaveLoadFailure.unsupportedVersion)));
    }
    // A nonfinite numeric literal is never accepted or silently rounded.
    final large =
        genuine.replaceFirst('"baseHomeGoals":1.35', '"baseHomeGoals":1e999');
    expect(large, isNot(genuine));
    expect(() => _codec.decodeHistoricalOpening(large),
        throwsA(isA<SaveLoadException>()));
  });

  test(
      'H15/H16 frozen v1 and genuine v2 retain bytes and typed version separation',
      () {
    final v1 = _legacy();
    final v2 = createGenuineOpening();
    expect(_codec.encode(_codec.decode(v1)), v1);
    expect(_codec.encodeOwnedOpening(_codec.decodeOwnedOpening(v2)), v2);
    expect(PlayerPresidentTicketPricingRuntimeSaveCodec.currentSaveVersion, 1);
    expect(PlayerPresidentTicketPricingRuntimeSaveCodec.ownedOpeningSaveVersion,
        2);
    expect(
        PlayerPresidentTicketPricingRuntimeSaveCodec
            .historicalOpeningSaveVersion,
        3);
    for (final old in [v1, v2]) {
      expect(() => _codec.decodeHistoricalOpening(old),
          throwsA(_failure(SaveLoadFailure.unsupportedVersion)));
    }
    expect(() => _codec.decode(genuine),
        throwsA(_failure(SaveLoadFailure.unsupportedVersion)));
    expect(() => _codec.decodeOwnedOpening(genuine),
        throwsA(_failure(SaveLoadFailure.unsupportedVersion)));
    final oldBad = _map(jsonDecode(v1))..['checksum'] = '00000000';
    expect(() => _codec.decode(jsonEncode(oldBad)),
        throwsA(_failure(SaveLoadFailure.checksumMismatch)));
    expect(_codec.encode(_codec.decode(v1)), v1);
    expect(_codec.encodeOwnedOpening(_codec.decodeOwnedOpening(v2)), v2);
  });

  test(
      'H06/H17 regenerated context/source/president/digest mismatch publishes no owner',
      () {
    final mutations = <void Function(Map<String, dynamic>)>[
      (p) => p['preparedOpeningDigest'] = '0' * 64,
      (p) => p['expectedPlayerPresidentId'] = 'foreign-president',
      (p) => _map(p['pending'])['contextSignature'] = 'foreign-context',
      (p) => _map((p['sourceClubs'] as List).first)['strength'] = 40.25,
      (p) => (p['sourceClubs'] as List)
          .insert(0, (p['sourceClubs'] as List).removeLast()),
      (p) => (p['sourceLeagues'] as List)
          .insert(0, (p['sourceLeagues'] as List).removeLast()),
      (p) {
        final ids = _map((p['sourceLeagues'] as List).first)['clubIds'] as List;
        ids.insert(0, ids.removeLast());
      },
      (p) => _map(p['config'])['baseHomeGoals'] = 1.4,
      (p) => p['electionInterval'] = 1,
      (p) => p['controlledClubId'] = 't1_02',
    ];
    for (final mutate in mutations) {
      final raw = _change(genuine, (p) {
        mutate(p);
        _rebindDecision(p);
      });
      // All syntax/value/stable-ID checks succeed; real preparation must reject.
      expect(_codec.decodeHistoricalOpening(raw).careerInstanceId,
          state.careerInstanceId);
      PlayerPresidentDurableHistoricalOpeningApplication? published;
      expect(() {
        published =
            PlayerPresidentDurableHistoricalOpeningApplication.restoreEncoded(
                raw);
      }, throwsA(isA<SaveLoadException>()));
      expect(published, isNull);
      final clean =
          PlayerPresidentDurableHistoricalOpeningApplication.restoreEncoded(
              genuine);
      expect(clean.encodeCurrentOpening(), genuine);
      clean.dispose();
    }
  });

  group('H11-H14 isolated single-writer typed manual store', () {
    late Directory root;
    late File target;
    const store = M65OwnedHistoricalOpeningFileStore();
    setUp(() {
      root = Directory.systemTemp.createTempSync('historical-v3-store-');
      target = File('${root.path}/opening.json');
    });
    tearDown(() => root.deleteSync(recursive: true));
    Future<M65OwnedHistoricalOpeningState> load(
            {String? career, String? club, String? president}) =>
        store.load(target,
            expectedCareerInstanceId: career ?? state.careerInstanceId,
            expectedClubId: club ?? state.controlledClubId,
            expectedPlayerPresidentId:
                president ?? state.expectedPlayerPresidentId);

    test(
        'save/load exact checkpoint; canonical whitespace/key-order no-op retains raw bytes',
        () async {
      await store.save(target, state);
      expect(target.readAsStringSync(), genuine);
      expect(_codec.encodeHistoricalOpening(await load()), genuine);
      final reversed = _map(jsonDecode(genuine));
      final pretty = const JsonEncoder.withIndent(' ').convert({
        for (final key in reversed.keys.toList().reversed) key: reversed[key]
      });
      target.writeAsStringSync(pretty);
      await store.save(target, state);
      expect(target.readAsStringSync(), pretty);
      expect(root.listSync(), hasLength(1));
    });
    test('invalid prepared witness rejects before IO or parent creation',
        () async {
      final bad = _codec.decodeHistoricalOpening(
          _change(genuine, (p) => p['preparedOpeningDigest'] = '0' * 64));
      await expectLater(store.save(target, bad),
          throwsA(_failure(SaveLoadFailure.invalidPayload)));
      expect(root.listSync(), isEmpty);
      final absent = File('${root.path}/missing/target.json');
      await expectLater(
          store.save(absent, state), throwsA(isA<FileSystemException>()));
      expect(Directory('${root.path}/missing').existsSync(), isFalse);
    });
    test(
        'legacy v1 v2 foreign conflicting corrupt and future targets refuse unchanged',
        () async {
      final foreign = worker.createHistoricalOpening(clubId: 't2_01');
      final future = _map(jsonDecode(genuine))..['saveVersion'] = 4;
      final different =
          _change(genuine, (p) => p['preparedOpeningDigest'] = '0' * 64);
      for (final bytes in [
        _legacy(),
        createGenuineOpening(),
        foreign,
        different,
        '{truncated',
        _signed(future)
      ]) {
        target.writeAsStringSync(bytes);
        await expectLater(store.save(target, state), throwsA(anything));
        expect(target.readAsStringSync(), bytes);
        expect(root.listSync(), hasLength(1));
      }
    });
    test(
        'same career but different fully validated opening refuses canonical conflict',
        () async {
      final app = worker.createHistoricalOpeningApplication(
          firstClubName: 'Real producer alternate club name');
      final alternate = app.captureHistoricalOpening(
          expectedPending:
              app.currentStep as PlayerPresidentOwnedSeasonPromisePending);
      final conflicting = _change(alternate, (p) {
        p['careerInstanceId'] = state.careerInstanceId;
        _rebindDecision(p);
      });
      final valid =
          PlayerPresidentDurableHistoricalOpeningApplication.restoreEncoded(
              conflicting);
      valid.dispose();
      target.writeAsStringSync(conflicting);
      await expectLater(store.save(target, state),
          throwsA(_failure(SaveLoadFailure.invalidPayload)));
      expect(target.readAsStringSync(), conflicting);
      expect(root.listSync(), hasLength(1));
    });

    test(
        'wrong expected identities and failed load never modify original bytes',
        () async {
      await store.save(target, state);
      for (final request in [
        () => load(career: 'f' * 32),
        () => load(club: 't2_01'),
        () => load(president: 'foreign')
      ]) {
        await expectLater(
            request(), throwsA(_failure(SaveLoadFailure.invalidPayload)));
      }
      expect(target.readAsStringSync(), genuine);
      final corrupt =
          _change(genuine, (p) => p['preparedOpeningDigest'] = '0' * 64);
      target.writeAsStringSync(corrupt);
      await expectLater(
          load(), throwsA(_failure(SaveLoadFailure.invalidPayload)));
      expect(target.readAsStringSync(), corrupt);
    });
    test('orphan temp is ignored and absence is never promoted', () async {
      final orphan = File('${target.path}.tmp-orphan')
        ..writeAsStringSync(genuine);
      await expectLater(load(), throwsA(isA<FileSystemException>()));
      expect(target.existsSync(), isFalse);
      expect(orphan.readAsStringSync(), genuine);
    });
  });
  test(
      'H18 public namespaces hide proofs and direct-src cannot forge final private constructors',
      () async {
    final root =
        await Directory.systemTemp.createTemp('historical-namespace-probes-');
    addTearDown(() => root.delete(recursive: true));
    const m76 =
        'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
    const source =
        'package:futbol_baskanlik_m0/src/player_president/player_president_interactive_decision_application_session.dart';
    const persistence =
        'package:futbol_baskanlik_m0/player_president_owned_historical_opening_persistence.dart';
    const facade =
        'package:futbol_baskanlik_m0/player_president_durable_historical_opening_application.dart';
    final probes = <String, String>{
      for (final name in [
        'OwnedHistoricalOpeningCapture',
        'OwnedFirstFutureOpeningCapture',
        'DurableFirstFuturePreparationClaim',
        'DurableFuturePromiseAcceptanceClaim',
        'OwnedFirstFutureOpeningExport'
      ])
        name: "import '$m76';\n$name? forbidden;\nvoid main() {}",
      'world-hide':
          "import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';\nDurablePreparedFirstFutureOpening? forbidden;\nvoid main() {}",
      'proof-final':
          "import '$source';\nclass Fake implements OwnedHistoricalOpeningCapture { dynamic noSuchMethod(Invocation i) => null; }\nvoid main() {}",
      'proof-private':
          "import '$source';\nvoid main() { OwnedHistoricalOpeningCapture(); }",
      'dto-final':
          "import '$persistence';\nclass Fake implements M65OwnedHistoricalOpeningState { dynamic noSuchMethod(Invocation i) => null; }\nvoid main() {}",
      'dto-private':
          "import '$persistence';\nvoid main() { M65OwnedHistoricalOpeningState(); }",
      'owner-private':
          "import '$facade';\nvoid main() { PlayerPresidentDurableHistoricalOpeningApplication(); }",
      'step-final':
          "import '$facade';\nclass Fake implements DurableHistoricalPromisePending { dynamic noSuchMethod(Invocation i) => null; }\nvoid main() {}",
      'inferred-proof-mutation':
          "import '$m76';\nvoid attack(PlayerPresidentInteractiveDecisionApplicationSession app) { final boundary=app.preseasonPromiseBoundary!; final capture=app.captureOwnedHistoricalOpening(boundary:boundary,pending:boundary.pending!); capture.careerInstanceId='caller'; }\nvoid main() {}",
    };
    final packages = '${Directory.current.path}/.dart_tool/package_config.json';
    for (final entry in probes.entries) {
      final file = File('${root.path}/${entry.key}.dart')
        ..writeAsStringSync(entry.value);
      final result = await Process.run(Platform.resolvedExecutable, [
        'compile',
        'kernel',
        '--packages=$packages',
        file.path,
        '-o',
        '${root.path}/${entry.key}.dill'
      ]);
      expect(result.exitCode, isNot(0),
          reason: '${entry.key} unexpectedly compiled');
      expect('${result.stdout} ${result.stderr}', contains('Error:'),
          reason: entry.key);
    }
    final allowed = File('${root.path}/allowed.dart')
      ..writeAsStringSync(
          "import '$facade';\nimport '$persistence';\nvoid main() { const codec=PlayerPresidentTicketPricingRuntimeSaveCodec(); const store=M65OwnedHistoricalOpeningFileStore(); PlayerPresidentDurableHistoricalOpeningApplication? app; print([codec,store,app]); }");
    final good = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'kernel',
      '--packages=$packages',
      allowed.path,
      '-o',
      '${root.path}/allowed.dill'
    ]);
    expect(good.exitCode, 0, reason: '${good.stdout} ${good.stderr}');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
