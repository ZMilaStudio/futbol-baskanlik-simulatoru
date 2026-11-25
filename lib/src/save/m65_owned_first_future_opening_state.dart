part of '../facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';

/// The single M65 value authority for the supported unanswered first opening.
/// Owning this immutable value does not grant a process-local runtime capability.
final class M65OwnedFirstFutureOpeningState {
  M65OwnedFirstFutureOpeningState._({
    required this.world,
    required this.tenureControl,
    required Iterable<Manager> managers,
    required Iterable<ManagerAssignment> assignments,
    required this.transfers,
    required this.facilities,
    required Iterable<PresidentClubRuntimeState> presidentClubs,
    required this.electionInterval,
    required Map<String, List<int>> termPromiseScores,
    required this.careerInstanceId,
    required this.origin,
    required this.phase,
    required this.runtimeProfile,
    required this.decisionId,
    required this.contextSignature,
    required this.preparedOpeningDigest,
  })  : managers = List.unmodifiable(managers),
        assignments = List.unmodifiable(assignments),
        presidentClubs = List.unmodifiable(presidentClubs),
        termPromiseScores = Map.unmodifiable({
          for (final e in termPromiseScores.entries)
            e.key: List<int>.unmodifiable(e.value),
        }) {
    validate();
  }

  factory M65OwnedFirstFutureOpeningState.fromGenuineCapture(
          OwnedFirstFutureOpeningCapture capture) =>
      M65OwnedFirstFutureOpeningState._(
        world: capture.world,
        tenureControl: capture.tenureControl,
        managers: capture.managers,
        assignments: capture.assignments,
        transfers: capture.transfers,
        facilities: capture.facilities,
        presidentClubs: capture.presidentClubs,
        electionInterval: capture.electionInterval,
        termPromiseScores: capture.termPromiseScores,
        careerInstanceId: capture.careerInstanceId,
        origin: capture.origin,
        phase: capture.phase,
        runtimeProfile: capture.runtimeProfile,
        decisionId: capture.decisionId,
        contextSignature: capture.contextSignature,
        preparedOpeningDigest: capture.preparedOpeningDigest,
      );

  final WorldCheckpoint world;
  final PlayerPresidentTenureControlState tenureControl;
  final List<Manager> managers;
  final List<ManagerAssignment> assignments;
  final AdvancedTransferRuntimeState transfers;
  final FacilityPortfolioRuntimeState facilities;
  final List<PresidentClubRuntimeState> presidentClubs;
  final int electionInterval;
  final Map<String, List<int>> termPromiseScores;
  final String careerInstanceId, origin, phase, runtimeProfile;
  final String decisionId, contextSignature, preparedOpeningDigest;
  String get controlledClubId => tenureControl.controlledClubId;
  String get clubId => controlledClubId;
  String get playerPresidentId => tenureControl.playerPresidentId;
  int get seasonIndex => world.nextSeasonIndex;
  bool get historicalManagerAuthorityAvailable => false;

  void validate() {
    world.validate();
    tenureControl.validate();
    if (origin != 'historicalBasicX1ToFirstFuture' ||
        phase != 'firstFuturePromisePending' ||
        runtimeProfile != 'canonicalFirstFutureV1' ||
        world.config.seasonIndex != 0 ||
        world.completedSeasons != 1 ||
        world.nextSeasonIndex != 1 ||
        !tenureControl.active ||
        !RegExp(r'^[0-9a-f]{32}$').hasMatch(careerInstanceId) ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(preparedOpeningDigest) ||
        contextSignature.isEmpty ||
        electionInterval <= 0) {
      throw ArgumentError(
          'Unsupported owned first-future origin, phase or identity.');
    }
    final clubs = world.baseClubs.map((e) => e.id).toSet();
    void coverage(Iterable<String> values) {
      final list = values.toList(growable: false);
      final set = list.toSet();
      if (list.length != 48 ||
          set.length != 48 ||
          set.difference(clubs).isNotEmpty ||
          clubs.difference(set).isNotEmpty) {
        throw ArgumentError(
            'Owned opening must cover exactly every world club.');
      }
    }

    final managerIds = <String>{};
    for (final m in managers) {
      if (m.id.isEmpty ||
          m.name.isEmpty ||
          m.startAge < 0 ||
          m.retirementAge <= m.startAge ||
          !managerIds.add(m.id)) {
        throw ArgumentError('Invalid owned manager pool.');
      }
    }
    coverage(assignments.map((e) => e.clubId));
    final assigned = <String>{};
    for (final a in assignments) {
      if (!managerIds.contains(a.managerId) ||
          !assigned.add(a.managerId) ||
          a.appointedSeasonIndex != 1 ||
          a.completedSeasons != 0 ||
          !a.boardRelationship.isFinite ||
          a.boardRelationship < 0 ||
          a.boardRelationship > 100) {
        throw ArgumentError(
            'Owned manager authority starts at future season one.');
      }
    }
    transfers.validate(world);
    facilities.validateAgainst(clubs);
    coverage(presidentClubs.map((e) => e.clubId));
    for (final p in presidentClubs) {
      p.validate();
    }
    final controlled =
        presidentClubs.singleWhere((e) => e.clubId == controlledClubId);
    if (controlled.tenure.president.id != playerPresidentId) {
      throw ArgumentError('Owned opening incumbent identity mismatch.');
    }
    coverage(termPromiseScores.keys);
    for (final scores in termPromiseScores.values) {
      if (scores.length != 1 % electionInterval ||
          scores.any((v) => v < 0 || v > 100)) {
        throw ArgumentError('Invalid current presidency term score coverage.');
      }
    }
    final expected = sha256
        .convert(utf8.encode(SaveChecksum.canonicalJson({
          'careerInstanceId': careerInstanceId,
          'clubId': controlledClubId,
          'playerPresidentId': playerPresidentId,
          'phase': phase,
          'seasonIndex': 1,
          'kind': 'promise',
          'contextSignature': contextSignature,
        })))
        .toString();
    if (decisionId != expected) {
      throw ArgumentError('Owned promise stable identity mismatch.');
    }
  }
}
