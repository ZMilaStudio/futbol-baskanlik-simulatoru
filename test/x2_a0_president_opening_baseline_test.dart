import 'dart:convert';
import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/sponsor_runtime_integration.dart';
import 'package:test/test.dart';

// X2-A0 only: capture the EXISTING production rules before extraction.
// This source SHA is the reviewed production main, NOT the PR merge ref.
const _sourceMainSha = '647ba661e5397115fc14532920a1922cf4bfff14';
const _config = SimulationConfig(careerSeed: 20260903);
const _controlledClubId = 't1_01';
const _electionInterval = 4;
const _fixturePath = 'test/fixtures/x2_a0_president_opening_baseline.json';

Map<String, Object?> _row(String clubId) {
  final president = const PresidentProfileGenerator().generateInitial(
    clubId: clubId,
    careerSeed: _config.careerSeed,
    simulationVersion: _config.simulationVersion,
  );
  final management = const PresidentManagementProfileGenerator().generate(
    president: president,
    careerSeed: _config.careerSeed,
    simulationVersion: _config.simulationVersion,
  );
  final tenure = PresidentTenureState.initial(
    clubId: clubId,
    president: president,
    startedSeasonIndex: _config.seasonIndex,
  );
  final fan = FanState.initial(clubId);
  final media = MediaState(clubId: clubId, credibility: 65);
  return <String, Object?>{
    'clubId': clubId,
    'presidentId': president.id,
    'presidentName': president.name,
    'presidentSignature': president.signature,
    'managementPresidentId': management.presidentId,
    'managementArchetype': management.archetype.name,
    'managementTraits': management.traits,
    'managementSignature': management.signature,
    'tenureNumber': tenure.tenureNumber,
    'startedSeasonIndex': tenure.startedSeasonIndex,
    'reelectionsWon': tenure.reelectionsWon,
    'tenureSignature': tenure.signature,
    'fanValues': <int>[
      fan.sportingTrust,
      fan.financialTrust,
      fan.transferTrust,
      fan.identityTrust,
      fan.overallTrust,
    ],
    'fanSignature': fan.signature,
    'mediaCredibility': media.credibility,
    'mediaSignature': media.signature,
  };
}

void main() {
  final world = const FictionalWorldFactory().build();
  final clubIds = world.leagues
      .expand((league) => league.clubIds)
      .toList(growable: false);

  test('X2-A0 real 48-club production opening: collect and verify frozen baseline', () {
    expect(_config.seasonIndex, 0);
    expect(_config.simulationVersion, 1);
    expect(world.clubs, hasLength(48));
    expect(world.leagues, hasLength(3));
    expect(world.leagues.map((league) => league.clubIds.length), everyElement(16));
    expect(clubIds, hasLength(48));
    expect(clubIds.toSet(), hasLength(48));
    expect(clubIds, world.clubs.map((club) => club.id).toList());
    expect(clubIds.first, _controlledClubId);
    for (final league in world.leagues) {
      expect(league.clubIds, hasLength(16));
    }

    final rows = clubIds.map(_row).toList(growable: false);
    expect(rows.map((row) => row['presidentId']).toSet(), hasLength(48));
    for (final row in rows) {
      final clubId = row['clubId'] as String;
      expect(row['presidentId'], 'president_${clubId}_initial');
      expect(row['managementPresidentId'], row['presidentId']);
      expect(row['tenureNumber'], 1);
      expect(row['startedSeasonIndex'], 0);
      expect(row['reelectionsWon'], 0);
      expect(row['fanValues'], [60, 60, 60, 60, 60]);
      expect(row['mediaCredibility'], 65);
    }
    final evidence = <String, Object?>{
      'sourceMainSha': _sourceMainSha,
      'careerSeed': _config.careerSeed,
      'simulationVersion': _config.simulationVersion,
      'seasonIndex': _config.seasonIndex,
      'electionInterval': _electionInterval,
      'completedElectionTerms': 0,
      'seasonsIntoCurrentTerm': 0,
      'firstElectionSeasonIndex': _config.seasonIndex + _electionInterval - 1,
      'controlledClubId': _controlledClubId,
      'controlledPresidentId': rows.first['presidentId'],
      'orderedClubIds': clubIds,
      'rows': rows,
    };

    print('X2A0_COLLECTION_SOURCE=$_sourceMainSha');
    print('X2A0_CI_SHA=${Platform.environment['GITHUB_SHA'] ?? 'local'}');
    print('X2A0_HEADER=${jsonEncode({
      'sourceMainSha': _sourceMainSha,
      'careerSeed': _config.careerSeed,
      'simulationVersion': _config.simulationVersion,
      'seasonIndex': _config.seasonIndex,
      'electionInterval': _electionInterval,
      'completedElectionTerms': 0,
      'seasonsIntoCurrentTerm': 0,
      'firstElectionSeasonIndex': _config.seasonIndex + _electionInterval - 1,
      'controlledClubId': _controlledClubId,
      'controlledPresidentId': rows.first['presidentId'],
      'orderedClubIds': clubIds,
    })}');
    for (final row in rows) {
      print('X2A0_ROW=${jsonEncode(row)}');
    }
    for (final sample in ['t1_01', 't2_01', 't3_01']) {
      print('X2A0_SAMPLE=${jsonEncode(rows.singleWhere((row) => row['clubId'] == sample))}');
    }

    final fixture = File(_fixturePath);
    if (fixture.existsSync()) {
      final frozen = jsonDecode(fixture.readAsStringSync());
      expect(evidence, equals(frozen),
          reason: 'Frozen extraction-before-production baseline changed.');
      print('X2A0_FROZEN_BASELINE_VERIFICATION=PASS');
    } else {
      print('X2A0_FROZEN_BASELINE_VERIFICATION=NOT_YET_FROZEN');
    }
  });

  test('X2-A0 old production tenure and reputation initial states match production generator', () {
    final expected = <String, String>{
      for (final id in clubIds) id: (_row(id)['tenureSignature'] as String),
    };
    final tenure = const PresidentTenureCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: _config,
      seasonCount: 1,
      electionInterval: _electionInterval,
    );
    final reputation = const PresidentReputationCareerEngine().simulate(
      clubs: world.clubs,
      leagues: world.leagues,
      config: _config,
      seasonCount: 1,
      electionInterval: _electionInterval,
    );
    expect(tenure.initialStates, hasLength(48));
    expect(reputation.initialTenureStates, hasLength(48));
    for (final state in tenure.initialStates) {
      expect(state.signature, expected[state.clubId]);
    }
    for (final state in reputation.initialTenureStates) {
      expect(state.signature, expected[state.clubId]);
    }
    expect(tenure.initialStates.map((state) => state.clubId).toList(), clubIds);
    expect(reputation.initialTenureStates.map((state) => state.clubId).toList(), clubIds);
    print('X2A0_LEGACY_TENURE_REPUTATION_INITIAL_PARITY=PASS');
  });

  test('X2-A0 sponsor and M65 consume the same real first president identity', () {
    final expectedId = _row(_controlledClubId)['presidentId'];
    final sponsor = const SponsorRuntimeCareerEngine().simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: _config,
      seasonCount: 1,
    );
    final contracts = sponsor.boundaries.single.contracts;
    expect(contracts, hasLength(48));
    for (final contract in contracts) {
      expect(contract.acceptedByPresidentId, _row(contract.offer.clubId)['presidentId']);
    }
    final m65 = const PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine()
        .simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: _config,
      controlledClubId: _controlledClubId,
      seasonCount: 1,
    );
    expect(m65.checkpoint.tenureControl.playerPresidentId, expectedId);
    expect(m65.checkpoint.tenureControl.active, isTrue);
    print('X2A0_SPONSOR_M65_INITIAL_IDENTITY=PASS');
  });

  test('X2-A0 M79 is controlled-club projection, not a 48-club checkpoint', () {
    final app = PlayerPresidentInteractiveDecisionApplicationSession.start(
      clubs: world.clubs,
      leagues: world.leagues,
      config: _config,
      controlledClubId: _controlledClubId,
      seasonCount: 1,
      electionInterval: _electionInterval,
    );
    final dashboard = app.preparedSeasonDashboard;
    final expected = _row(_controlledClubId);
    expect(app.checkpointOrNull, isNull);
    expect(dashboard.controlledClubId, _controlledClubId);
    expect(dashboard.seasonIndex, 0);
    expect(dashboard.presidentTenure.signature, expected['tenureSignature']);
    expect(dashboard.playerControl.playerPresidentId, expected['presidentId']);
    expect(dashboard.playerControl.active, isTrue);
    expect(dashboard.fanOverallTrust, 60);
    print('X2A0_M79_CONTROLLED_PROJECTION=${jsonEncode({
      'controlledClubId': dashboard.controlledClubId,
      'presidentId': dashboard.presidentTenure.president.id,
      'presidentSignature': dashboard.presidentTenure.president.signature,
      'tenureSignature': dashboard.presidentTenure.signature,
      'controlSignature': dashboard.playerControl.signature,
      'fanOverallTrust': dashboard.fanOverallTrust,
      'seasonIndex': dashboard.seasonIndex,
      'isCheckpoint': app.checkpointOrNull != null,
    })}');
  });
}
