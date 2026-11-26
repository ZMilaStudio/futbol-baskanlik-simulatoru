import 'dart:convert';
import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_durable_first_future_opening_application.dart';
import 'package:futbol_baskanlik_m0/player_president_owned_first_future_opening_persistence.dart';
import 'package:test/test.dart';

import 'support/owned_first_future_opening_worker.dart'
    show createGenuineOpening;

const _codec = PlayerPresidentTicketPricingRuntimeSaveCodec();

Map<String, dynamic> _map(Object? value) => value as Map<String, dynamic>;

String _signed(Map<String, dynamic> envelope) {
  envelope['checksum'] = SaveChecksum.forPayload(
    saveVersion: envelope['saveVersion'] as int,
    payload: envelope['payload'],
  );
  return SaveChecksum.canonicalJson(envelope);
}

String _change(String original, void Function(Map<String, dynamic>) change) {
  final envelope = _map(jsonDecode(original));
  change(_map(envelope['payload']));
  return _signed(envelope);
}

String _changeNested(
    String original, String key, void Function(Map<String, dynamic>) change) {
  return _change(original, (payload) {
    final nested = _map(jsonDecode(payload[key] as String));
    change(_map(nested['payload']));
    payload[key] = _signed(nested);
  });
}

Matcher _failure(SaveLoadFailure kind) =>
    isA<SaveLoadException>().having((error) => error.failure, 'failure', kind);

String _legacyFixture() => utf8.decode(gzip.decode(base64Decode(
    File('test/fixtures/m3b_m65_v1.json.gz.b64').readAsStringSync().trim())));

// Rewrite genuine legacy nested envelopes and recompute all enclosing checksums.
// This is deliberately a negative fixture: it never creates accepted authority.
String _withoutLegacyManagerHistory(String encoded) {
  var changed = 0;
  Object? rewrite(Object? value) {
    if (value is String && value.startsWith('{')) {
      return SaveChecksum.canonicalJson(rewrite(jsonDecode(value)));
    }
    if (value is List) return value.map(rewrite).toList();
    if (value is! Map<String, dynamic>) return value;
    final rewritten = <String, dynamic>{
      for (final entry in value.entries) entry.key: rewrite(entry.value),
    };
    final manager = rewritten['manager'];
    if (manager is Map<String, dynamic> && manager.containsKey('seasons')) {
      manager['seasons'] = <Object>[];
      changed++;
    }
    if (rewritten.containsKey('checksum') &&
        rewritten.containsKey('saveVersion') &&
        rewritten.containsKey('payload')) {
      rewritten['checksum'] = SaveChecksum.forPayload(
        saveVersion: rewritten['saveVersion'] as int,
        payload: rewritten['payload'],
      );
    }
    return rewritten;
  }

  final result = SaveChecksum.canonicalJson(rewrite(jsonDecode(encoded)));
  if (changed != 1)
    throw StateError('Expected exactly one legacy manager root.');
  return result;
}

void main() {
  late String genuine;
  late M65OwnedFirstFutureOpeningState state;

  setUpAll(() {
    genuine = createGenuineOpening();
    state = _codec.decodeOwnedOpening(genuine);
  });

  test('real first-future Pending round-trips with honest manager coverage',
      () {
    final payload = _map(_map(jsonDecode(genuine))['payload']);
    final world =
        _map(_map(jsonDecode(payload['worldSave'] as String))['payload']);
    final manager = _map(payload['manager']);
    expect(world['completedSeasons'], 1);
    expect(_map(world['config'])['initialSeasonIndex'], 0);
    expect(manager['completedSeasons'], isEmpty);
    expect(manager['assignments'], hasLength(48));
    for (final assignment in manager['assignments'] as List) {
      expect(_map(assignment)['appointedSeasonIndex'], 1);
      expect(_map(assignment)['completedSeasons'], 0);
    }
    expect(payload['origin'], 'historicalBasicX1ToFirstFuture');
    expect(payload['phase'], 'firstFuturePromisePending');
    expect(state.careerInstanceId, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(state.decisionId, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(state.seasonIndex, 1);
    expect(_codec.encodeOwnedOpening(state), genuine);
  });

  test('legacy M65 v1 fixture preserves exact bytes and typed readers', () {
    final original = _legacyFixture();
    final legacy = _codec.decode(original);
    expect(legacy.completedSeasons, 1);
    expect(_codec.encode(legacy), original);
    expect(PlayerPresidentTicketPricingRuntimeSaveCodec.currentSaveVersion, 1);
    expect(() => _codec.decode(genuine),
        throwsA(_failure(SaveLoadFailure.unsupportedVersion)));
    expect(() => _codec.decodeOwnedOpening(original),
        throwsA(_failure(SaveLoadFailure.unsupportedVersion)));
    expect(_codec.encode(_codec.decode(original)), original);
  });

  test('legacy full-M65 still rejects removed completed manager history', () {
    final original = _legacyFixture();
    expect(() => _codec.decode(_withoutLegacyManagerHistory(original)),
        throwsA(_failure(SaveLoadFailure.invalidPayload)));
    expect(_codec.encode(_codec.decode(original)), original);
  });

  final invalidPayloads = <String, void Function(Map<String, dynamic>)>{
    'fake historical manager history': (p) =>
        _map(p['manager'])['completedSeasons'] = [
          <String, Object>{'seasonIndex': 0}
        ],
    'foreign origin': (p) => p['origin'] = 'legacyFullM65',
    'Running phase': (p) => p['phase'] = 'runningW0',
    'unsupported runtime profile': (p) => p['runtimeProfile'] = 'callerProfile',
    'missing phase': (p) => p.remove('phase'),
    'unknown authority field': (p) => p['historicalManagerAuthority'] = true,
    'malformed career id': (p) => p['careerInstanceId'] = 'not-a-career',
    'missing manager assignment': (p) =>
        (_map(p['manager'])['assignments'] as List).removeLast(),
    'foreign manager reference': (p) =>
        _map((_map(p['manager'])['assignments'] as List).first)['managerId'] =
            'foreign-manager',
    'historical manager appointment': (p) =>
        _map((_map(p['manager'])['assignments'] as List).first)[
            'appointedSeasonIndex'] = 0,
    'completed future manager season': (p) =>
        _map((_map(p['manager'])['assignments'] as List).first)[
            'completedSeasons'] = 1,
    'missing term-score club': (p) =>
        _map(_map(p['presidency'])['termPromiseScores']).remove('t1_01'),
    'foreign decision identity': (p) =>
        _map(p['pending'])['decisionId'] = '0' * 64,
    'wrong pending kind': (p) =>
        _map(p['pending'])['kind'] = 'transferStrategy',
    'unknown nested manager key': (p) =>
        _map(p['manager'])['fakeReceipt'] = true,
  };
  for (final entry in invalidPayloads.entries) {
    test('strict owned contract rejects ${entry.key} with valid checksum', () {
      expect(() => _codec.decodeOwnedOpening(_change(genuine, entry.value)),
          throwsA(_failure(SaveLoadFailure.invalidPayload)));
      expect(_codec.encodeOwnedOpening(state), genuine);
    });
  }

  test('manager age, relationship and unique assignment boundaries reject', () {
    final mutations = <void Function(Map<String, dynamic>)>[
      (p) =>
          _map((_map(p['manager'])['managers'] as List).first)['startAge'] = -1,
      (p) {
        final m = _map((_map(p['manager'])['managers'] as List).first);
        m['retirementAge'] = m['startAge'];
      },
      (p) => _map((_map(p['manager'])['assignments'] as List).first)[
          'boardRelationship'] = -0.5,
      (p) => _map((_map(p['manager'])['assignments'] as List).first)[
          'boardRelationship'] = 100.5,
      (p) {
        final a = _map(p['manager'])['assignments'] as List;
        _map(a[1])['clubId'] = _map(a[0])['clubId'];
      },
      (p) {
        final a = _map(p['manager'])['assignments'] as List;
        _map(a[1])['managerId'] = _map(a[0])['managerId'];
      },
    ];
    for (final mutate in mutations) {
      expect(() => _codec.decodeOwnedOpening(_change(genuine, mutate)),
          throwsA(_failure(SaveLoadFailure.invalidPayload)));
    }
  });

  test('owned fields reject null, numeric coercion and unknown enum tags', () {
    final changes = <void Function(Map<String, dynamic>)>[
      (p) => p['worldSave'] = null,
      (p) => _map(p['presidency'])['electionInterval'] = 100.0,
      (p) => _map(p['presidency'])['electionInterval'] = true,
      (p) => _map(p['pending'])['decisionId'] = 1,
      (p) => _map((_map(p['manager'])['managers'] as List).first)['profile'] =
          'unknown-manager-profile',
      (p) => _map((_map(p['manager'])['managers'] as List).first)['coaching'] =
          50.5,
    ];
    for (final change in changes) {
      expect(() => _codec.decodeOwnedOpening(_change(genuine, change)),
          throwsA(_failure(SaveLoadFailure.invalidPayload)));
    }
    for (final version in <Object>[2.0, '2', true]) {
      final envelope = _map(jsonDecode(genuine))..['saveVersion'] = version;
      expect(() => _codec.decodeOwnedOpening(jsonEncode(envelope)),
          throwsA(isA<SaveLoadException>()));
    }
  });

  test('all later durable phases fail closed with recomputed checksums', () {
    for (final phase in [
      'promiseResolved',
      'runningW1',
      'runningW30',
      'settled',
      'postseason',
      'nextFuturePromisePending'
    ]) {
      expect(
          () => _codec
              .decodeOwnedOpening(_change(genuine, (p) => p['phase'] = phase)),
          throwsA(_failure(SaveLoadFailure.invalidPayload)),
          reason: phase);
    }
  });

  test('scan-first owned parser validates grammar before duplicate rejection',
      () {
    for (final malformed in [
      '{"a":1,"a"}',
      '{"a":1,}',
      '[1,]',
      '{"a" 1}',
      '{"a":01}',
      '{"a":1e}',
      '{"a":+1}',
      '{"a":.2}',
      '{"a":tru}',
      '{"a":[}',
      '{} trailing',
      r'{"\uZZZZ":1}',
      r'{"a":"\q"}',
      '{"a":"unterminated}',
    ]) {
      expect(() => _codec.decodeOwnedOpening(malformed),
          throwsA(_failure(SaveLoadFailure.malformedJson)),
          reason: malformed);
    }
  });

  test('nullable leaf keys remain required and unknown leaf keys reject', () {
    final missing = _change(genuine, (p) {
      final event = (_map(p['transfer'])['contractEvents'] as List)
          .map(_map)
          .firstWhere((event) => event['fromClubId'] == null);
      event.remove('fromClubId');
    });
    final unknown = _change(
        genuine,
        (p) => _map((_map(p['facilities'])['stadiumFacilities'] as List).first)[
            'ownershipToken'] = 'caller');
    for (final encoded in [missing, unknown]) {
      expect(() => _codec.decodeOwnedOpening(encoded),
          throwsA(_failure(SaveLoadFailure.invalidPayload)));
    }
  });

  test('decoded roots cannot be mutated into a second authority', () {
    expect(() => state.assignments.clear(), throwsUnsupportedError);
    expect(() => state.presidentClubs.clear(), throwsUnsupportedError);
    expect(() => state.termPromiseScores.clear(), throwsUnsupportedError);
    expect(() => state.termPromiseScores.values.first.clear(),
        throwsUnsupportedError);
    expect(_codec.encodeOwnedOpening(state), genuine);
  });

  test('completed-world counter cannot be reset to invent manager equivalence',
      () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (world) => world['completedSeasons'] = 0,
      (world) => world['completedSeasons'] = 2,
      (world) => _map(world['config'])['initialSeasonIndex'] = 1,
    ]) {
      expect(
          () => _codec
              .decodeOwnedOpening(_changeNested(genuine, 'worldSave', mutate)),
          throwsA(_failure(SaveLoadFailure.invalidPayload)));
    }
  });

  test('tenure must bind the actual incumbent president', () {
    expect(
        () => _codec.decodeOwnedOpening(_changeNested(
            genuine,
            'tenureControlSave',
            (tenure) => tenure['playerPresidentId'] = 'foreign')),
        throwsA(_failure(SaveLoadFailure.invalidPayload)));
  });

  test('restore rejects recomputed-checksum context and preparation tampering',
      () {
    for (final encoded in [
      _change(
          genuine,
          (p) => _map(p['pending'])['contextSignature'] =
              'foreign-promise-context'),
      _change(genuine, (p) => p['preparedOpeningDigest'] = '0' * 64),
    ]) {
      expect(
          () => PlayerPresidentDurableFirstFutureOpeningApplication
              .restoreEncoded(encoded),
          throwsA(isA<SaveLoadException>()));
    }
    expect(_codec.encodeOwnedOpening(state), genuine);
  });

  test('malformed and corrupted envelopes fail with explicit categories', () {
    expect(() => _codec.decodeOwnedOpening('{'),
        throwsA(_failure(SaveLoadFailure.malformedJson)));
    final badChecksum = _map(jsonDecode(genuine))..['checksum'] = '00000000';
    expect(() => _codec.decodeOwnedOpening(jsonEncode(badChecksum)),
        throwsA(_failure(SaveLoadFailure.checksumMismatch)));
    final future = _map(jsonDecode(genuine))..['saveVersion'] = 3;
    expect(() => _codec.decodeOwnedOpening(_signed(future)),
        throwsA(_failure(SaveLoadFailure.unsupportedVersion)));
    final wrongFormat = _map(jsonDecode(genuine))..['format'] = 'foreign';
    expect(() => _codec.decodeOwnedOpening(jsonEncode(wrongFormat)),
        throwsA(_failure(SaveLoadFailure.invalidEnvelope)));
  });

  test('nested checksum corruption is rejected with a valid outer checksum',
      () {
    for (final key in ['worldSave', 'tenureControlSave']) {
      final corrupted = _change(genuine, (p) {
        final nested = _map(jsonDecode(p[key] as String));
        nested['checksum'] = '00000000';
        p[key] = jsonEncode(nested);
      });
      expect(() => _codec.decodeOwnedOpening(corrupted),
          throwsA(_failure(SaveLoadFailure.checksumMismatch)));
    }
  });

  test('unsupported nested world versions cannot enter owned v2', () {
    final encoded = _change(genuine, (p) {
      final world = _map(jsonDecode(p['worldSave'] as String))
        ..['saveVersion'] = 2;
      p['worldSave'] = _signed(world);
    });
    expect(() => _codec.decodeOwnedOpening(encoded),
        throwsA(isA<SaveLoadException>()));
  });

  test('duplicate JSON member names reject same, conflicting and escaped names',
      () {
    const phase = '"phase":"firstFuturePromisePending"';
    for (final duplicate in [
      '$phase,$phase',
      '"phase":"runningW0",$phase',
      r'"\u0070hase":"firstFuturePromisePending",' + phase,
    ]) {
      expect(
          () =>
              _codec.decodeOwnedOpening(genuine.replaceFirst(phase, duplicate)),
          throwsA(isA<SaveLoadException>()));
    }
    const emptyHistory = '"completedSeasons":[]';
    expect(
        () => _codec.decodeOwnedOpening(
            genuine.replaceFirst(emptyHistory, '$emptyHistory,$emptyHistory')),
        throwsA(isA<SaveLoadException>()));
    final envelope = _map(jsonDecode(genuine));
    final checksum = jsonEncode(envelope['checksum']);
    expect(
        () => _codec.decodeOwnedOpening(genuine.replaceFirst(
            '"checksum":$checksum',
            '"checksum":$checksum,"checksum":$checksum')),
        throwsA(isA<SaveLoadException>()));
  });

  test('owned scanner preserves unchanged embedded legacy JSON-string decoding',
      () {
    final encoded = _change(genuine, (p) {
      p['worldSave'] = (p['worldSave'] as String).replaceFirst(
          '"completedSeasons":1', '"completedSeasons":1,"completedSeasons":1');
    });
    final decoded = _codec.decodeOwnedOpening(encoded);
    expect(_codec.encodeOwnedOpening(decoded), genuine);
  });

  group('isolated single-writer manual store', () {
    late Directory temporary;
    late File target;
    final store = M65OwnedFirstFutureOpeningFileStore();

    setUp(() {
      temporary = Directory.systemTemp.createTempSync('m102-owned-store-');
      target = File('${temporary.path}/opening.fbs.json');
    });
    tearDown(() => temporary.deleteSync(recursive: true));

    Future<M65OwnedFirstFutureOpeningState> load(
            {String? career, String? club, String? president}) =>
        store.load(target,
            expectedCareerInstanceId: career ?? state.careerInstanceId,
            expectedClubId: club ?? state.controlledClubId,
            expectedPlayerPresidentId: president ?? state.playerPresidentId);

    test('invalid prepared witness fails before any file publication',
        () async {
      final sentinel = File('${temporary.path}/unrelated.txt')
        ..writeAsStringSync('preserve me');
      final bad = _codec.decodeOwnedOpening(
          _change(genuine, (p) => p['preparedOpeningDigest'] = '0' * 64));
      await expectLater(store.save(target, bad),
          throwsA(_failure(SaveLoadFailure.invalidPayload)));
      expect(target.existsSync(), isFalse);
      expect(sentinel.readAsStringSync(), 'preserve me');
      expect(temporary.listSync().map((f) => f.path).toList(), [sentinel.path]);
    });

    test('manual save/load preserves the exact genuine unanswered checkpoint',
        () async {
      await store.save(target, state);
      expect(target.readAsStringSync(), genuine);
      final loaded = await load();
      expect(_codec.encodeOwnedOpening(loaded), genuine);
      expect(temporary.listSync().whereType<File>().length, 1);
    });

    test(
        'identical canonical checkpoint is a no-op preserving existing raw bytes',
        () async {
      final pretty =
          const JsonEncoder.withIndent('  ').convert(jsonDecode(genuine));
      target.writeAsStringSync(pretty);
      await store.save(target, state);
      expect(target.readAsStringSync(), pretty);
      expect(_codec.encodeOwnedOpening(await load()), genuine);
      expect(temporary.listSync().whereType<File>().length, 1);
    });

    test('foreign expected identities fail without modifying the file',
        () async {
      await store.save(target, state);
      for (final request in [
        () => load(career: 'f' * 32),
        () => load(club: 't2_01'),
        () => load(president: 'foreign-president'),
      ]) {
        await expectLater(request(), throwsA(anything));
      }
      expect(target.readAsStringSync(), genuine);
    });

    test(
        'legacy, corrupt and unsupported existing targets are never overwritten',
        () async {
      final unsupported = _map(jsonDecode(genuine))..['saveVersion'] = 3;
      for (final bytes in [
        _legacyFixture(),
        '{truncated',
        _signed(unsupported)
      ]) {
        target.writeAsStringSync(bytes);
        await expectLater(store.save(target, state), throwsA(anything));
        expect(target.readAsStringSync(), bytes);
        expect(temporary.listSync().whereType<File>().length, 1);
      }
    });

    test('foreign genuine career target cannot be replaced', () async {
      final foreign = createGenuineOpening(clubId: 't2_01');
      target.writeAsStringSync(foreign);
      await expectLater(store.save(target, state), throwsA(anything));
      expect(target.readAsStringSync(), foreign);
    });

    test(
        'same career with different validated value bytes is refused unchanged',
        () async {
      // A tampered NEGATIVE wire fixture, not a second genuine producer.
      final different = _change(genuine, (p) {
        final manager = _map((_map(p['manager'])['managers'] as List).first);
        manager['name'] = '${manager['name']} alternate value';
      });
      expect(_codec.decodeOwnedOpening(different).careerInstanceId,
          state.careerInstanceId);
      target.writeAsStringSync(different);
      await expectLater(store.save(target, state),
          throwsA(_failure(SaveLoadFailure.invalidPayload)));
      expect(target.readAsStringSync(), different);
    });

    test('same career with different unsupported bytes cannot be overwritten',
        () async {
      final different =
          _change(genuine, (p) => p['preparedOpeningDigest'] = '0' * 64);
      target.writeAsStringSync(different);
      await expectLater(store.save(target, state), throwsA(anything));
      expect(target.readAsStringSync(), different);
    });
  });
}
