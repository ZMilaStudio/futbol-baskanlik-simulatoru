part of '../facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';

/// M65 authority for an untouched historical opening, without manager history.
/// This immutable value never grants process-local runtime ownership.
final class M65OwnedHistoricalOpeningState {
  M65OwnedHistoricalOpeningState._({
    required Iterable<Club> sourceClubs,
    required Iterable<WorldLeague> sourceLeagues,
    required SimulationConfig config,
    required this.controlledClubId,
    required this.expectedPlayerPresidentId,
    required this.electionInterval,
    required this.careerInstanceId,
    required this.origin,
    required this.phase,
    required this.runtimeProfile,
    required this.decisionId,
    required this.contextSignature,
    required this.preparedOpeningDigest,
  })  : sourceClubs = List<Club>.unmodifiable(sourceClubs.map((club) => Club(
              id: club.id,
              name: club.name,
              strength: club.strength,
            ))),
        config = SimulationConfig(
          careerSeed: config.careerSeed,
          simulationVersion: config.simulationVersion,
          seasonIndex: config.seasonIndex,
          homeAdvantageRating: config.homeAdvantageRating,
          baseHomeGoals: config.baseHomeGoals,
          baseAwayGoals: config.baseAwayGoals,
          ratingScale: config.ratingScale,
          minExpectedGoals: config.minExpectedGoals,
          maxExpectedGoals: config.maxExpectedGoals,
        ),
        sourceLeagues = List<WorldLeague>.unmodifiable(
          sourceLeagues.map((league) => WorldLeague(
                tier: league.tier,
                clubIds: league.clubIds,
              )),
        ) {
    validate();
  }

  factory M65OwnedHistoricalOpeningState.fromGenuineCapture(
    OwnedHistoricalOpeningCapture capture,
  ) =>
      M65OwnedHistoricalOpeningState._(
        sourceClubs: capture.sourceClubs,
        sourceLeagues: capture.sourceLeagues,
        config: capture.config,
        controlledClubId: capture.controlledClubId,
        expectedPlayerPresidentId: capture.expectedPlayerPresidentId,
        electionInterval: capture.electionInterval,
        careerInstanceId: capture.careerInstanceId,
        origin: capture.origin,
        phase: capture.phase,
        runtimeProfile: capture.runtimeProfile,
        decisionId: capture.decisionId,
        contextSignature: capture.contextSignature,
        preparedOpeningDigest: capture.preparedOpeningDigest,
      );

  final List<Club> sourceClubs;
  final List<WorldLeague> sourceLeagues;
  final SimulationConfig config;
  final String controlledClubId, expectedPlayerPresidentId;
  final int electionInterval;
  final String careerInstanceId, origin, phase, runtimeProfile;
  final String decisionId, contextSignature, preparedOpeningDigest;
  int get seasonIndex => 0;
  bool get historicalManagerAuthorityAvailable => false;

  /// Validates value authority only; genuine preparation is checked at ingress.
  void validate() {
    if (origin != 'historicalBasicX1' ||
        phase != 'historicalPromisePending' ||
        runtimeProfile != 'canonicalHistoricalOpeningV1' ||
        config.seasonIndex != 0 ||
        config.simulationVersion <= 0 ||
        electionInterval <= 0 ||
        controlledClubId.isEmpty ||
        expectedPlayerPresidentId.isEmpty ||
        contextSignature.isEmpty ||
        !RegExp(r'^[0-9a-f]{32}$').hasMatch(careerInstanceId) ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(preparedOpeningDigest)) {
      throw ArgumentError('Unsupported historical opening phase or identity.');
    }
    final parameters = [
      config.homeAdvantageRating,
      config.baseHomeGoals,
      config.baseAwayGoals,
      config.ratingScale,
      config.minExpectedGoals,
      config.maxExpectedGoals,
    ];
    if (parameters.any((value) => !value.isFinite) ||
        config.ratingScale <= 0 ||
        config.minExpectedGoals <= 0 ||
        config.maxExpectedGoals < config.minExpectedGoals) {
      throw ArgumentError('Invalid historical opening simulation parameters.');
    }
    final clubIds = sourceClubs.map((club) => club.id).toSet();
    if (sourceClubs.length != 48 ||
        clubIds.length != 48 ||
        !clubIds.contains(controlledClubId) ||
        sourceClubs.any((club) =>
            club.id.isEmpty ||
            club.name.isEmpty ||
            !club.strength.isFinite ||
            club.strength < 40 ||
            club.strength > 100)) {
      throw ArgumentError('Historical opening requires 48 valid source clubs.');
    }
    final covered = <String>{};
    final tiers = <int>{};
    if (sourceLeagues.length != 3) {
      throw ArgumentError('Historical opening requires three source leagues.');
    }
    for (final league in sourceLeagues) {
      if (!tiers.add(league.tier.level) ||
          league.clubIds.length != 16 ||
          league.clubIds.toSet().length != 16) {
        throw ArgumentError('Invalid historical league tier or membership.');
      }
      for (final clubId in league.clubIds) {
        if (!clubIds.contains(clubId) || !covered.add(clubId)) {
          throw ArgumentError('Historical club coverage must be exact.');
        }
      }
    }
    if (covered.length != 48 || !tiers.containsAll([1, 2, 3])) {
      throw ArgumentError('Incomplete historical league coverage.');
    }
    final expected = sha256
        .convert(utf8.encode(SaveChecksum.canonicalJson({
          'careerInstanceId': careerInstanceId,
          'clubId': controlledClubId,
          'playerPresidentId': expectedPlayerPresidentId,
          'seasonIndex': 0,
          'phase': phase,
          'kind': 'promise',
          'contextSignature': contextSignature,
        })))
        .toString();
    if (decisionId != expected) {
      throw ArgumentError('Historical promise stable identity mismatch.');
    }
  }
}
