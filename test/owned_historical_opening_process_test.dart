import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:futbol_baskanlik_m0/src/save/save_checksum.dart';
import 'package:test/test.dart';

const _worker = 'test/support/owned_historical_opening_worker.dart';

Future<ProcessResult> _run(List<String> arguments) =>
    Process.run(Platform.resolvedExecutable, ['run', _worker, ...arguments],
        workingDirectory: Directory.current.path);

void _success(ProcessResult result) {
  expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
}

Future<void> _killAt(File target, String cut) async {
  final process = await Process.start(
      Platform.resolvedExecutable, ['run', _worker, 'cut', target.path, cut],
      workingDirectory: Directory.current.path);
  final marker = Completer<void>();
  final output = <String>[];
  final errors = process.stderr.transform(utf8.decoder).join();
  final lines = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
    output.add(line);
    if (line == 'CUT:$cut' && !marker.isCompleted) marker.complete();
  });
  final exited = process.exitCode.then((code) {
    if (!marker.isCompleted)
      marker.completeError(
          StateError('Worker exited before cut $cut: $code; $output'));
    return code;
  });
  try {
    await marker.future.timeout(const Duration(seconds: 90));
    expect(process.kill(ProcessSignal.sigkill), isTrue);
    expect(await exited, isNot(0));
    await errors;
  } finally {
    process.kill(ProcessSignal.sigkill);
    await process.exitCode;
    await lines.cancel();
  }
}

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('fbs-owned-opening-process-');
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('A exits before independent B; full genuine primitive W0/W1 parity',
      () async {
    final save = File('${root.path}/career.json');
    final oracle = File('${root.path}/oracle.json');
    final a = await _run(['produce', save.path, oracle.path]);
    _success(a);
    // Process.run has awaited exit AND drained pipes; no live A heap remains.
    expect(await Directory('/proc/${a.pid}').exists(), isFalse);
    final b = await _run(['restore', save.path, oracle.path]);
    _success(b);
    expect(b.stdout, contains('FULL PRIMITIVE PARITY'));
    final evidence = jsonDecode((b.stdout as String).trim()) as Map;
    expect(evidence['matches'], 24);
    final canonical = jsonDecode(await oracle.readAsString()) as Map;
    expect((canonical['accepted'] as Map)['acceptedPromises'], hasLength(48));
    final prepared = (canonical['opening'] as Map)['prepared'] as Map;
    expect(prepared.containsKey('managerSetup'), isFalse);
    expect((prepared['world'] as Map)['players'], hasLength(864));
    expect((prepared['world'] as Map)['finance'], hasLength(48));
    expect(((prepared['initialContracts'] as Map)['activeContracts']),
        hasLength(864));
    expect(((prepared['initialContracts'] as Map)['initialEvents']),
        hasLength(864));
    expect((prepared['presidency'] as Map)['completedElectionTerms'], 0);
    expect(
        ((prepared['presidency'] as Map)['domainSummary']
            as Map)['completedSeasons'],
        0);
    expect(prepared['promiseContexts'], hasLength(48));
    expect((prepared['w0'] as Map)['fixtures'], hasLength(720));
    // A second sequential independent restore is legal under G1a manual saves.
    final c = await _run(['restore', save.path, oracle.path]);
    _success(c);
    print(
        'OS process proof: A=${a.pid} exit=${a.exitCode}; B=${b.pid} exit=${b.exitCode}; C=${c.pid} exit=${c.exitCode}; full primitive parity.');
  }, timeout: const Timeout(Duration(minutes: 3)));

  for (final cut in [
    'before-save',
    'during-write',
    'after-flush',
    'after-rename',
    'after-choice',
    'after-ack',
    'after-w1'
  ]) {
    test('real SIGKILL at $cut preserves the exact manual-save boundary',
        () async {
      final save = File('${root.path}/career.json');
      await _killAt(save, cut);
      final published = [
        'after-rename',
        'after-choice',
        'after-ack',
        'after-w1'
      ].contains(cut);
      expect(await save.exists(), published);
      final result =
          await _run([published ? 'restore-only' : 'load-absent', save.path]);
      _success(result);
      expect(result.stdout,
          contains(published ? 'RESTORED_PENDING_AND_W1' : 'ABSENT:'));
      if (cut == 'during-write' || cut == 'after-flush') {
        expect(
            await root.list().where((f) => f.path.contains('.tmp-')).length, 1);
        expect(await save.exists(), isFalse); // Orphan is never promoted.
      }
    }, timeout: const Timeout(Duration(minutes: 3)));
  }

  test(
      'failed detached restore in B publishes nothing; fresh C still restores original',
      () async {
    final save = File('${root.path}/career.json');
    final oracle = File('${root.path}/oracle.json');
    _success(await _run(['produce', save.path, oracle.path]));
    final before = await save.readAsBytes();
    final altered =
        jsonDecode(await save.readAsString()) as Map<String, dynamic>;
    final payload = altered['payload'] as Map<String, dynamic>;
    payload['preparedOpeningDigest'] = '0' * 64;
    altered['checksum'] =
        SaveChecksum.forPayload(saveVersion: 3, payload: payload);
    final invalid = File('${root.path}/invalid.json');
    await invalid.writeAsString(jsonEncode(altered));
    final b = await _run(['restore-only', invalid.path]);
    expect(b.exitCode, isNot(0));
    expect(b.stdout, isNot(contains('FULL PRIMITIVE PARITY')));
    expect(b.stdout, isNot(contains('RESTORED_PENDING_AND_W1')));
    expect(await invalid.readAsString(), jsonEncode(altered));
    expect(await save.readAsBytes(), before);
    _success(await _run(['restore', save.path, oracle.path]));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
