part of '../player_president/player_president_interactive_decision_application_session.dart';

/// Explicit manual storage for the one supported owned M65 opening.
///
/// G1a: callers must ensure a single writer and non-overlapping live owners.
/// Check-and-rename is NOT a concurrent no-clobber/lease/fencing guarantee.
/// This store does not participate in the legacy mobile slot namespace.
final class M65OwnedFirstFutureOpeningFileStore {
  const M65OwnedFirstFutureOpeningFileStore();

  static const _codec = PlayerPresidentTicketPricingRuntimeSaveCodec();

  Future<void> save(File target, M65OwnedFirstFutureOpeningState state) async {
    // Validation, including actual pure preparation/context/digest, precedes IO.
    final encoded = _codec.encodeOwnedOpening(state);
    _validateRuntime(encoded);
    if (await target.exists()) {
      await _requireIdenticalTarget(target, state, encoded);
      return;
    }
    // Parent existence is explicit; no namespace/catalog is silently created.
    final random = Random.secure();
    File temporary;
    do {
      final nonce = List.generate(
              16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
          .join();
      temporary = File('${target.path}.tmp-$nonce');
    } while (await temporary.exists());
    try {
      await temporary.writeAsString(encoded, flush: true);
      // Defensive recheck preserves a newly observed target under G1a. This is
      // still not atomic no-replace when competing writers violate G1a.
      if (await target.exists()) {
        await _requireIdenticalTarget(target, state, encoded);
        return;
      }
      await temporary.rename(target.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<M65OwnedFirstFutureOpeningState> load(
    File target, {
    required String expectedCareerInstanceId,
    required String expectedClubId,
    required String expectedPlayerPresidentId,
  }) async {
    // Only the explicit target is read. Orphan temporary files are ignored.
    final encoded = await target.readAsString();
    final state = _codec.decodeOwnedOpening(encoded);
    if (state.careerInstanceId != expectedCareerInstanceId ||
        state.controlledClubId != expectedClubId ||
        state.playerPresidentId != expectedPlayerPresidentId) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Owned opening identity does not match the requested career.',
      );
    }
    _validateRuntime(encoded);
    return state;
  }

  Future<void> _requireIdenticalTarget(
    File target,
    M65OwnedFirstFutureOpeningState state,
    String encoded,
  ) async {
    // No write on idempotence or refusal; retain original whitespace/raw bytes.
    final existing = _codec.decodeOwnedOpening(await target.readAsString());
    if (existing.careerInstanceId != state.careerInstanceId ||
        _codec.encodeOwnedOpening(existing) != encoded) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Existing file is a different owned opening; replacement is refused.',
      );
    }
  }

  static void _validateRuntime(String encoded) {
    PlayerPresidentDurableFirstFutureOpeningApplication._validateEncodedOnly(
        encoded);
  }
}
