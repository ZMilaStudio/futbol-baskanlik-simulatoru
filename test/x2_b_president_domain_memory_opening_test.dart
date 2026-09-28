import 'dart:convert';
import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:test/test.dart';

const _config = SimulationConfig(careerSeed: 20260903);
const _memory = PresidentDomainMemoryOpeningInitializer();

class _CustomPresidentGenerator extends PresidentProfileGenerator {
  const _CustomPresidentGenerator();

  @override
  PresidentProfile generateInitial({
    required String clubId,
    required int careerSeed,
    required int simulationVersion,
  }) => PresidentProfile(id: 'custom_$clubId', name: 'Custom $clubId');
}

void main() {
  final world = const FictionalWorldFactory().build();
  final opening = const PresidentOpeningStateInitializer().prepareWorld(
    clubs: world.clubs,
    leagues: world.leagues,
    config: _config,
    controlledClubId: 't1_01',
  );

  test('X2-B real 48-club opening preserves exact frozen order and first president', () {
    final memory = _memory.prepare(opening: opening);
    final frozen = jsonDecode(
      File('test/fixtures/x2_a0_president_opening_baseline.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final rows = frozen['rows'] as List<dynamic>;

    expect(memory.clubs, hasLength(48));
    expect(memory.orderedClubIds, frozen['orderedClubIds']);
    expect(memory.clubs.map((club) => club.president.id).toList(),
        rows.map((row) => (row as Map<String, dynamic>)['presidentId']).toList());
    expect(memory.controlledClubId, frozen['controlledClubId']);
    expect(memory.controlledPresidentId, frozen['controlledPresidentId']);
    expect(memory.controlledPresidentId, 'president_t1_01_initial');
    expect(memory.controlledClub, same(opening.controlledClub));
    expect(memory.byClubId['t1_01'], same(opening.byClubId['t1_01']));
    expect(memory.clubs, same(opening.clubs));
    expect(memory.byClubId, same(opening.byClubId));
    expect(memory.opening, same(opening));
    print('X2B_X2A_48_CLUB_IDENTITY_PARITY=PASS');
  });

  test('X2-B zero completed history is a real pristine opening, not missing data', () {
    final memory = _memory.prepare(opening: opening);
    final summary = memory.summary;
    expect(memory.completedSeasons, 0);
    expect(memory.seasonIndex, 0);
    expect(memory.completedElectionTerms, 0);
    expect(memory.seasonsIntoCurrentTerm, 0);
    expect(memory.electionInterval, opening.electionInterval);
    expect(memory.firstElectionSeasonIndex, opening.firstElectionSeasonIndex);
    expect(memory.rawHistorySeasons, 2);
    expect(summary.fanSnapshots, 0);
    expect(summary.fanReasons, 0);
    expect(summary.mediaStatements, 0);
    expect(summary.mediaContradictions, 0);
    expect(summary.promisesFulfilled, 0);
    expect(summary.promisesPartial, 0);
    expect(summary.promisesBroken, 0);
    expect(summary.totalPromises, 0);
    expect(memory.recentFan, isEmpty);
    expect(memory.recentMedia, isEmpty);
    expect(memory.resolvedCurrentTermPromises, isEmpty);
    // This means no completed-season *resolved* promise history, not a
    // prohibition on future promises or pending M73 decisions.
    print('X2B_ZERO_HISTORY_OPENING=PASS');
  });

  test('X2-B repeat is deterministic and all exposed collections are immutable', () {
    final first = _memory.prepare(opening: opening);
    final second = _memory.prepare(opening: opening);
    final longerWindow = _memory.prepare(opening: opening, rawHistorySeasons: 3);
    expect(first.signature, second.signature);
    expect(first.signature, isNot(longerWindow.signature));
    expect(first.opening, same(second.opening));
    expect(first.clubs.first, same(opening.clubs.first));
    expect(first.summary.signature, const PresidentOpeningHistorySummary().signature);
    expect(() => first.clubs.clear(), throwsUnsupportedError);
    expect(() => first.byClubId.clear(), throwsUnsupportedError);
    expect(() => first.orderedClubIds.clear(), throwsUnsupportedError);
    expect(() => first.recentFan.clear(), throwsUnsupportedError);
    expect(() => first.recentMedia.clear(), throwsUnsupportedError);
    expect(() => first.resolvedCurrentTermPromises.clear(), throwsUnsupportedError);
    print('X2B_DETERMINISTIC_IMMUTABLE_OPENING=PASS');
  });

  test('X2-B supports small X2-A fixture and preserves injected custom identity', () {
    const club = Club(id: 'mini', name: 'Mini FC', strength: 60);
    final league = WorldLeague(tier: LeagueTier.second, clubIds: ['mini']);
    final customSource = const PresidentOpeningStateInitializer(
      presidentGenerator: _CustomPresidentGenerator(),
    ).prepareWorld(
      clubs: [club],
      leagues: [league],
      config: _config,
      controlledClubId: 'mini',
      electionInterval: 5,
    );
    final customMemory = _memory.prepare(opening: customSource);
    expect(customMemory.clubs, hasLength(1));
    expect(customMemory.orderedClubIds, ['mini']);
    expect(customMemory.controlledPresidentId, 'custom_mini');
    expect(customMemory.controlledClub, same(customSource.controlledClub));
    expect(customMemory.controlledClub!.tenure.president,
        same(customSource.controlledClub!.president));
    expect(customMemory.firstElectionSeasonIndex, 4);
    expect(customMemory.completedSeasons, 0);
    print('X2B_CUSTOM_SOURCE_IDENTITY_PARITY=PASS');
  });

  test('X2-B rejects invalid window, missing owner and non-new-game source', () {
    expect(() => _memory.prepare(opening: opening, rawHistorySeasons: 0),
        throwsArgumentError);
    expect(() => _memory.prepare(opening: opening, rawHistorySeasons: -1),
        throwsArgumentError);
    final unowned = const PresidentOpeningStateInitializer().prepareWorld(
      clubs: world.clubs,
      leagues: world.leagues,
      config: _config,
    );
    expect(() => _memory.prepare(opening: unowned), throwsStateError);
    final later = const PresidentOpeningStateInitializer().prepareWorld(
      clubs: world.clubs,
      leagues: world.leagues,
      config: _config.copyWith(seasonIndex: 1),
      controlledClubId: 't1_01',
    );
    expect(() => _memory.prepare(opening: later), throwsStateError);
    expect(() => const PresidentOpeningStateInitializer().prepareWorld(
      clubs: [world.clubs.first],
      leagues: world.leagues,
      config: _config,
      controlledClubId: 't1_01',
    ), throwsStateError);
    print('X2B_INVALID_INPUT_FAIL_CLOSED=PASS');
  });

  test('X2-B cannot be a fake report, runtime or completed-memory checkpoint', () {
    final memory = _memory.prepare(opening: opening);
    final Object observation = memory;
    expect(observation, isNot(isA<PresidentDomainMemoryCheckpoint>()));
    expect(observation, isNot(isA<PresidentRuntimeCheckpoint>()));
    expect(observation, isNot(isA<PresidentReputationCareerReport>()));
    expect(memory.completedSeasons, 0);
    expect(memory.recentFan, isEmpty);
    expect(memory.recentMedia, isEmpty);
    expect(memory.resolvedCurrentTermPromises, isEmpty);
    print('X2B_NO_SYNTHETIC_CHECKPOINT_OR_REPORT=PASS');
  });

  test('X2-B leaves real completed-M65 memory and frozen v1 bytes unchanged', () {
    final frozen = utf8.decode(gzip.decode(base64Decode(
      File('test/fixtures/m3b_m65_v1.json.gz.b64').readAsStringSync().trim(),
    )));
    const m65Codec = PlayerPresidentTicketPricingRuntimeSaveCodec();
    const domainCodec = PresidentDomainMemorySaveCodec();
    final completed = m65Codec.decode(frozen);
    final completedMemory = completed.runtime.runtime.domain;
    final oldSignature = completedMemory.signature;
    final oldDomainBytes = domainCodec.encode(completedMemory);
    final zeroMemory = _memory.prepare(opening: opening);

    expect(completed.completedSeasons, 1);
    expect(completedMemory.completedSeasons, 1);
    expect(completedMemory.summary.fanSnapshots, greaterThan(0));
    expect(completedMemory.recentFan, isNotEmpty);
    expect(completedMemory.recentMedia, isNotEmpty);
    expect(zeroMemory.completedSeasons, 0);
    expect(zeroMemory.recentFan, isEmpty);
    expect(zeroMemory.recentMedia, isEmpty);
    expect(completedMemory.signature, oldSignature);
    expect(domainCodec.encode(completedMemory), oldDomainBytes);
    expect(domainCodec.decode(oldDomainBytes).signature, oldSignature);
    expect(m65Codec.encode(completed), frozen);
    print('X2B_REAL_COMPLETED_M65_ISOLATION=PASS');
  });
}
