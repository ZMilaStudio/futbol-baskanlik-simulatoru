import 'dart:io';

import '../league/club.dart';
import '../world/world_league.dart';
import 'player_president_interactive_decision_application_session.dart';
import 'player_president_interactive_decision_new_game_bootstrap_snapshot.dart';
import 'player_president_interactive_decision_persistence_bundle.dart';

/// File-backed save-slot adapter for M80 pre-checkpoint new-game bootstrap
/// snapshots.
///
/// M81 deliberately keeps this namespace separate from the M77 checkpoint
/// store. Every slot contains the exact M80 replay-only bootstrap envelope;
/// no partial runtime/world state is persisted and M65 remains the only
/// persisted game-state authority.
class PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore {
  PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore({
    required Directory rootDirectory,
    this.bundleCodec =
        const PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec(),
    this.bootstrapCodec =
        const PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec(),
  }) : rootDirectory = rootDirectory.absolute;

  static final RegExp _validSlotId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');
  static const String _extension = '.fbs.bootstrap.json';
  static const String _temporarySuffix = '.tmp';
  static const String _backupSuffix = '.bak';

  final Directory rootDirectory;
  final PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec
      bundleCodec;
  final PlayerPresidentInteractiveDecisionNewGameBootstrapSnapshotSaveCodec
      bootstrapCodec;

  void save(
    String slotId,
    PlayerPresidentInteractiveDecisionApplicationSession session,
  ) {
    _validateSlotId(slotId);

    // Encode before touching disk so checkpoint-backed sessions fail closed
    // without creating or mutating slot state.
    final encoded = bootstrapCodec.encode(session.newGameBootstrapSnapshot);

    rootDirectory.createSync(recursive: true);
    _recoverInterruptedCommit(slotId);

    final target = _targetFile(slotId);
    final temporary = _temporaryFile(slotId);
    final backup = _backupFile(slotId);

    if (temporary.existsSync()) {
      temporary.deleteSync();
    }
    temporary.writeAsStringSync(encoded, flush: true);

    if (backup.existsSync()) {
      backup.deleteSync();
    }
    if (target.existsSync()) {
      target.renameSync(backup.path);
    }

    try {
      temporary.renameSync(target.path);
      if (backup.existsSync()) {
        backup.deleteSync();
      }
    } catch (_) {
      if (!target.existsSync() && backup.existsSync()) {
        backup.renameSync(target.path);
      }
      rethrow;
    } finally {
      if (temporary.existsSync()) {
        temporary.deleteSync();
      }
    }
  }

  PlayerPresidentInteractiveDecisionApplicationSession? load({
    required String slotId,
    required List<Club> clubs,
    required List<WorldLeague> leagues,
  }) {
    _validateSlotId(slotId);
    if (!rootDirectory.existsSync()) {
      return null;
    }
    _recoverInterruptedCommit(slotId);
    final target = _targetFile(slotId);
    if (!target.existsSync()) {
      return null;
    }
    return PlayerPresidentInteractiveDecisionApplicationSession
        .restoreEncodedNewGameBootstrap(
      clubs: clubs,
      leagues: leagues,
      encodedBootstrap: target.readAsStringSync(),
      bundleCodec: bundleCodec,
      bootstrapCodec: bootstrapCodec,
    );
  }

  bool contains(String slotId) {
    _validateSlotId(slotId);
    if (!rootDirectory.existsSync()) {
      return false;
    }
    return _targetFile(slotId).existsSync() || _backupFile(slotId).existsSync();
  }

  bool delete(String slotId) {
    _validateSlotId(slotId);
    if (!rootDirectory.existsSync()) {
      return false;
    }
    var removed = false;
    for (final file in <File>[
      _targetFile(slotId),
      _temporaryFile(slotId),
      _backupFile(slotId),
    ]) {
      if (file.existsSync()) {
        file.deleteSync();
        removed = true;
      }
    }
    return removed;
  }

  List<String> listSlotIds() {
    if (!rootDirectory.existsSync()) {
      return const <String>[];
    }
    final slotIds = <String>{};
    for (final entity in rootDirectory.listSync(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final name = entity.uri.pathSegments.last;
      final slotId = _slotIdFromFileName(name);
      if (slotId != null) {
        slotIds.add(slotId);
      }
    }
    final sorted = slotIds.toList()..sort();
    return List<String>.unmodifiable(sorted);
  }

  void _recoverInterruptedCommit(String slotId) {
    final target = _targetFile(slotId);
    final backup = _backupFile(slotId);
    if (target.existsSync()) {
      if (backup.existsSync()) {
        backup.deleteSync();
      }
      return;
    }
    if (backup.existsSync()) {
      backup.renameSync(target.path);
    }
  }

  String? _slotIdFromFileName(String name) {
    String? candidate;
    if (name.endsWith(_extension)) {
      candidate = name.substring(0, name.length - _extension.length);
    } else if (name.endsWith('$_extension$_backupSuffix')) {
      candidate = name.substring(
        0,
        name.length - '$_extension$_backupSuffix'.length,
      );
    }
    if (candidate == null || !_validSlotId.hasMatch(candidate)) {
      return null;
    }
    return candidate;
  }

  File _targetFile(String slotId) => File(
        '${rootDirectory.path}${Platform.pathSeparator}$slotId$_extension',
      );

  File _temporaryFile(String slotId) => File(
        '${rootDirectory.path}${Platform.pathSeparator}'
        '$slotId$_extension$_temporarySuffix',
      );

  File _backupFile(String slotId) => File(
        '${rootDirectory.path}${Platform.pathSeparator}'
        '$slotId$_extension$_backupSuffix',
      );

  static void _validateSlotId(String slotId) {
    if (!_validSlotId.hasMatch(slotId)) {
      throw ArgumentError.value(
        slotId,
        'slotId',
        'Expected 1-64 ASCII letters, digits, underscore, or hyphen.',
      );
    }
  }
}
