typedef SlotIdFactory = String Function();

/// Produces a short technical slot identity accepted by the existing M77/M81
/// validation. It carries no user-facing metadata and is never persisted as a
/// separate authority.
String createCareerSlotId() =>
    'career_${DateTime.now().microsecondsSinceEpoch}';
