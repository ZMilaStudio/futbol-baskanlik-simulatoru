// Genuine public producer / independent OS process acceptance worker.
// Oracle JSON is observation evidence only, never a restore authority input.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_owned_season_application.dart';
import 'package:futbol_baskanlik_m0/player_president_owned_first_future_opening_persistence.dart';
import 'package:futbol_baskanlik_m0/player_president_durable_first_future_opening_application.dart';
import 'package:futbol_baskanlik_m0/src/player_president/player_president_interactive_decision_session.dart';

import 'owned_career_driver.dart' show playOwnedSeason, enterNextOwnedSeason;

PlayerPresidentOwnedSeasonApplication createGenuineOpeningApplication({
  String clubId = 't1_01',
  int electionInterval = 100,
  int seed = 20260903,
  SimulationConfig? config,
}) {
  final world = const FictionalWorldFactory().build();
  final app = PlayerPresidentOwnedSeasonApplication.start(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config ?? SimulationConfig(careerSeed: seed),
    controlledClubId: clubId,
    electionInterval: electionInterval,
  );
  final completed = app.closeSeason(expected: playOwnedSeason(app));
  enterNextOwnedSeason(app, completed);
  if ((app.currentStep as PlayerPresidentOwnedSeasonPromisePending)
          .seasonIndex !=
      1) {
    throw StateError('Genuine producer did not enter first future season.');
  }
  return app;
}

String createGenuineOpening({
  String clubId = 't1_01',
  int electionInterval = 100,
  int seed = 20260903,
}) {
  final app = createGenuineOpeningApplication(
    clubId: clubId,
    electionInterval: electionInterval,
    seed: seed,
  );
  return app.captureFirstFutureOpening(
      expectedPending:
          app.currentStep as PlayerPresidentOwnedSeasonPromisePending);
}

Map<String, Object?> weeklyFacts(WeeklyWorldFixtureSnapshot snapshot) => {
      'seasonIndex': snapshot.seasonIndex,
      'nextRound': snapshot.nextRound,
      'totalRounds': snapshot.totalRounds,
      'completedMatchCount': snapshot.completedMatchCount,
      'fixtures': [
        for (final entry in snapshot.fixtures)
          {
            'tier': entry.tier.level,
            'id': entry.fixture.id,
            'seasonIndex': entry.fixture.seasonIndex,
            'round': entry.fixture.round,
            'homeClubId': entry.fixture.homeClubId,
            'awayClubId': entry.fixture.awayClubId,
            'result': entry.fixture.result == null
                ? null
                : {
                    'homeGoals': entry.fixture.result!.homeGoals,
                    'awayGoals': entry.fixture.result!.awayGoals,
                    'homeExpectedGoals':
                        entry.fixture.result!.homeExpectedGoals,
                    'awayExpectedGoals':
                        entry.fixture.result!.awayExpectedGoals,
                    'matchSeed': entry.fixture.result!.matchSeed,
                  },
          }
      ],
      'tables': {
        for (final e in snapshot.tables.entries)
          '${e.key.level}': [for (final row in e.value) row.toJson()]
      },
    };

Map<String, Object?> promiseFacts(PresidentPromise p) => {
      'id': p.id,
      'clubId': p.clubId,
      'seasonIndex': p.seasonIndex,
      'type': p.type.name,
      'targetLeaguePosition': p.targetLeaguePosition,
      'targetDebtReductionBps': p.targetDebtReductionBps,
    };

Map<String, Object?> consequenceFacts(PlayerPresidentPromiseConsequence c) => {
      'kind': c.kind.name,
      'controlledClubId': c.controlledClubId,
      'context': {
        'clubId': c.context.context.clubId,
        'seasonIndex': c.context.context.seasonIndex,
        'tier': c.context.context.tier.level,
        'leagueSize': c.context.context.leagueSize,
        'expectedPosition': c.context.context.expectedPosition,
        'openingCashMinorUnits': c.context.context.openingCash.minorUnits,
        'openingDebtMinorUnits': c.context.context.openingDebt.minorUnits,
      },
      'aiPromise': promiseFacts(c.context.aiPromise),
      'allowedTypes': c.context.allowedTypes.map((e) => e.name).toList(),
      'promise': promiseFacts(c.promise),
    };

Map<String, dynamic> savedPayload(String encoded) =>
    (jsonDecode(encoded) as Map<String, dynamic>)['payload']
        as Map<String, dynamic>;

Future<void> _barrier(String label) async {
  stdout.writeln('CUT:$label');
  await stdout.flush();
  await stdin
      .first; // Parent kills this real process after the acknowledged cut.
}

// Only the test worker intercepts file IO; production has no fault hooks.
final class _CutFile implements File {
  _CutFile(this.delegate, this.cut);
  final File delegate;
  final String cut;
  @override
  String get path => delegate.path;
  @override
  Future<bool> exists() => delegate.exists();
  @override
  Future<String> readAsString({Encoding encoding = utf8}) =>
      delegate.readAsString(encoding: encoding);
  @override
  Future<File> delete({bool recursive = false}) =>
      delegate.delete(recursive: recursive).then((_) => this);
  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) async {
    if (path.contains('.tmp-') && cut == 'during-write') {
      await delegate.writeAsString(contents.substring(0, contents.length ~/ 2),
          mode: mode, encoding: encoding, flush: true);
      await _barrier(cut);
    }
    await delegate.writeAsString(contents,
        mode: mode, encoding: encoding, flush: flush);
    if (path.contains('.tmp-') && cut == 'after-flush') await _barrier(cut);
    return this;
  }

  @override
  Future<File> rename(String newPath) async {
    final file = await delegate.rename(newPath);
    if (cut == 'after-rename') await _barrier(cut);
    return file;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> main(List<String> args) async {
  final mode = args[0];
  final target = File(args[1]);
  const codec = PlayerPresidentTicketPricingRuntimeSaveCodec();
  const store = M65OwnedFirstFutureOpeningFileStore();
  if (mode == 'produce' || mode == 'cut') {
    final app = createGenuineOpeningApplication();
    final pending = app.currentStep as PlayerPresidentOwnedSeasonPromisePending;
    final encoded = app.captureFirstFutureOpening(expectedPending: pending);
    final state = codec.decodeOwnedOpening(encoded);
    if (mode == 'cut') {
      final cut = args[2];
      if (cut == 'before-save') await _barrier(cut);
      final originalZone = Zone.current;
      await IOOverrides.runZoned(() async {
        await store.save(File(target.path), state);
      },
          createFile: (path) =>
              _CutFile(originalZone.run(() => File(path)), cut));
      if (cut == 'after-choice' || cut == 'after-ack') {
        final resolved = app.submitPromise(
            expected: pending, choice: PresidentPromiseType.finishTopHalf);
        if (cut == 'after-ack') app.continueAfterPromise(expected: resolved);
        await _barrier(cut);
      }
      throw StateError('Cut did not stop at the requested boundary.');
    }
    await store.save(target, state);
    final loaded = await store.load(target,
        expectedCareerInstanceId: state.careerInstanceId,
        expectedClubId: state.controlledClubId,
        expectedPlayerPresidentId: state.playerPresidentId);
    final opening = app.firstFutureOpeningObservation;
    final resolved = app.submitPromise(
        expected: pending, choice: PresidentPromiseType.finishTopHalf);
    final w0 = app.continueAfterPromise(expected: resolved);
    final w1 = app.advanceRound(expected: w0);
    final oracle = {
      'payload': savedPayload(codec.encodeOwnedOpening(loaded)),
      'opening': opening,
      'accepted': app.firstFutureOpeningObservation,
      'consequence': consequenceFacts(resolved.consequence),
      'w0': weeklyFacts(w0.fixtures),
      'w1': weeklyFacts(w1.fixtures),
    };
    await File(args[2]).writeAsString(jsonEncode(oracle), flush: true);
    stdout.writeln(jsonEncode({
      'mode': mode,
      'pid': pid,
      'career': state.careerInstanceId,
      'decision': state.decisionId,
      'matches': w1.completedMatchCount
    }));
    return;
  }
  if (mode == 'restore' || mode == 'restore-only') {
    final encoded = await target.readAsString();
    final app =
        PlayerPresidentDurableFirstFutureOpeningApplication.restoreEncoded(
            encoded);
    final state = codec.decodeOwnedOpening(encoded);
    if (state.historicalManagerAuthorityAvailable ||
        state.world.completedSeasons != 1 ||
        state.assignments.length != 48 ||
        state.assignments.any((a) => a.appointedSeasonIndex != 1)) {
      throw StateError('Historical/future authority boundary changed.');
    }
    final opening = app.openingObservation;
    final pending = app.currentStep as DurableFirstFuturePromisePending;
    final resolution = app.submitPromise(
        expectedPending: pending, choice: PresidentPromiseType.finishTopHalf);
    final w0 = app.continueAfterPromise(expectedResolution: resolution);
    final w1 = app.advanceFirstRound(expectedW0: w0);
    if (mode == 'restore') {
      // Read oracle only AFTER genuine restore and explicit commands completed.
      final expected = jsonDecode(await File(args[2]).readAsString());
      final actual = {
        'payload': savedPayload(codec.encodeOwnedOpening(state)),
        'opening': opening,
        'accepted': app.openingObservation,
        'consequence': consequenceFacts(resolution.consequence),
        'w0': weeklyFacts(w0.fixtures),
        'w1': weeklyFacts(w1.fixtures),
      };
      _requireExact(expected, actual, r'$');
    }
    app.dispose();
    stdout.writeln(jsonEncode({
      'mode': mode,
      'pid': pid,
      'career': state.careerInstanceId,
      'decision': state.decisionId,
      'matches': w1.fixtures.completedMatchCount,
      'parity': 'FULL PRIMITIVE PARITY'
    }));
    return;
  }
  if (mode == 'load-absent') {
    try {
      await store.load(target,
          expectedCareerInstanceId: 'absent',
          expectedClubId: 't1_01',
          expectedPlayerPresidentId: 'absent');
    } on FileSystemException {
      stdout.writeln('ABSENT: orphan temporary files were not promoted');
      return;
    }
    throw StateError('Unexpected authoritative target.');
  }
  throw ArgumentError.value(mode, 'mode');
}

void _requireExact(Object? a, Object? b, String path) {
  if (a is Map && b is Map) {
    if (a.length != b.length || !a.keys.every(b.containsKey)) {
      throw StateError('Oracle keys differ at $path');
    }
    for (final key in a.keys) {
      _requireExact(a[key], b[key], '$path.$key');
    }
  } else if (a is List && b is List) {
    if (a.length != b.length)
      throw StateError('Oracle length differs at $path');
    for (var i = 0; i < a.length; i++) {
      _requireExact(a[i], b[i], '$path[$i]');
    }
  } else if (a != b ||
      (a is num && b is num && a.runtimeType != b.runtimeType)) {
    throw StateError('Exact oracle differs at $path: $a / $b');
  }
}
