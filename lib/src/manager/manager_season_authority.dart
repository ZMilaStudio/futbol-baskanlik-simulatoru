part of 'manager_career_controller.dart';

/// Opaque runtime snapshot of an actual successful manager season setup.
/// Pending inputs are private immutable values, not generated opening data.
final class ManagerSeasonAuthority {
  ManagerSeasonAuthority._(ManagerCareerController source, this.owner,
      this.sourceRevision, this.seasonIndex, this.effectiveClubs)
      : _source = source,
        careerSeed = source.careerSeed,
        simulationVersion = source.simulationVersion,
        initialSeasonIndex = source.initialSeasonIndex,
        managers = List.unmodifiable(source._managers),
        assignments = Map.unmodifiable(source._assignments),
        seasons = List.unmodifiable(source._seasons),
        _pending = Map.unmodifiable(source._pending),
        _poolGenerator = source.poolGenerator,
        _fitModel = source.fitModel,
        _impactModel = source.impactModel,
        _patienceProvider = source.patienceProvider,
        _dismissalPolicy = source.dismissalPolicy;

  final ManagerCareerController _source;
  final Object owner, sourceRevision;
  final int careerSeed, simulationVersion, initialSeasonIndex, seasonIndex;
  final List<Club> effectiveClubs;
  final List<Manager> managers;
  final Map<String, ManagerAssignment> assignments;
  final List<ManagerCareerSeason> seasons;
  final Map<String, _PendingManagerClubSeason> _pending;
  final ManagerPoolGenerator _poolGenerator;
  final ManagerFitModel _fitModel;
  final ManagerImpactModel _impactModel;
  final ManagerPatienceProvider? _patienceProvider;
  final ManagerDismissalPolicy _dismissalPolicy;

  ManagerCareerController forkDetached({
    required Object expectedOwner,
    required Object expectedRevision,
    required int expectedSeason,
  }) =>
      _source.forkSeasonAuthority(
          authority: this,
          owner: expectedOwner,
          sourceRevision: expectedRevision,
          seasonIndex: expectedSeason);

  ManagerCareerController _fork() {
    // Do not use restore: its deliberately empty pending contract is unchanged.
    final fork = ManagerCareerController(
      careerSeed: careerSeed,
      simulationVersion: simulationVersion,
      initialSeasonIndex: initialSeasonIndex,
      poolGenerator: _poolGenerator,
      fitModel: _fitModel,
      impactModel: _impactModel,
      patienceProvider: _patienceProvider,
      dismissalPolicy: _dismissalPolicy,
    );
    fork._initialized = true;
    fork._managers = List.unmodifiable(managers);
    fork._managerById = Map.unmodifiable({for (final m in managers) m.id: m});
    fork._assignments = Map.unmodifiable(assignments);
    fork._seasons.addAll(seasons);
    fork._pending = Map.of(_pending);
    // A fork is not the original capture source and cannot mint that authority.
    return fork;
  }
}
