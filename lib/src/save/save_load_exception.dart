enum SaveLoadFailure {
  malformedJson,
  invalidEnvelope,
  checksumMismatch,
  unsupportedVersion,
  migrationFailed,
  invalidPayload,
}

class SaveLoadException implements Exception {
  const SaveLoadException(this.failure, this.message);

  final SaveLoadFailure failure;
  final String message;

  @override
  String toString() => 'SaveLoadException(${failure.name}): $message';
}
