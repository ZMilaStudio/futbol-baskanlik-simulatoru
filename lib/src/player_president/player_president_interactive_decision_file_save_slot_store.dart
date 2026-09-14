import 'dart:io';

import 'player_president_interactive_decision_application_session.dart';
import 'player_president_interactive_decision_persistence_bundle.dart';

/// File-backed application save-slot adapter for M76 interactive sessions.
///
/// M77 does not create a new game-state or save-format authority. Each slot
/// stores the exact M75 persistence bundle produced from the M76 application
/// session. M65 therefore remains the only persisted game-state authority.
class PlayerPresidentInteractiveDecisionFileSaveSlotStore {
  PlayerPresidentInteractiveDecisionFileSaveSlotStore({
    required Directory rootDirectory,
    this.bundleCodec =
        const PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec(),
  }) : rootDirectory = rootDirectory.absolute;

  static final RegExp _validSlotId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');
  static const String _extension = '.fbs.json';
  static const String _temporarySuffix = '.tmp';
  static const String _backupSuffix = '.bak';

  final Directory rootDirectory;
  final PlayerPresidentInteractiveDecisionPersistenceBundleSaveCodec
      bundleCodec;

  void save(
    String slotId,
    PlayerPresidentInteractiveDecisionApplicationSession session,
  ) {
    _validateSlotId(slotId);
    rootDirectory.createSync(recursive: true);
    _recoverInterruptedCommit(slotId);

    final target = _targetFile(slotId);
    final temporary = _temporaryFile(slotId);
    final backup = _backupFile(slotId);
    final encoded = bundleCodec.encode(session.persistenceBundle);

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

  PlayerPresidentInteractiveDecisionApplicationSession? load(String slotId) {
    _validateSlotId(slotId);
    if (!rootDirectory.existsSync()) {
      return null;
    }
    _recoverInterruptedCommit(slotId);
    final target = _targetFile(slotId);
    if (!target.existsSync()) {
      return null;
    }
    return PlayerPresidentInteractiveDecisionApplicationSession.restoreEncoded(
      encodedBundle: target.readAsStringSync(),
      bundleCodec: bundleCodec,
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

  File _targetFile(String slotId) =>
      File('${rootDirectory.path}${Platform.pathSeparator}$slotId$_extension');

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
