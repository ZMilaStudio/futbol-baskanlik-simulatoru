import 'dart:convert';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final world = const FictionalWorldFactory().build();
  final config = SimulationConfig(careerSeed: seed);
  const runtimeEngine = AdvancedRuntimeCareerEngine();
  const compactEngine = CompactAdvancedRuntimeCareerEngine();
  const compactor = AdvancedRuntimeHistoryCompactor();
  const fullCodec = AdvancedWorldSaveCodec();
  const compactCodec = CompactAdvancedWorldSaveCodec();

  final uninterrupted = runtimeEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 20,
  );
  final first = runtimeEngine.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    seasonCount: 8,
  );
  final compactFirst = compactor.compactFull(first.checkpoint);
  final fullSave = fullCodec.encode(first.checkpoint);
  final compactSave = compactCodec.encode(compactFirst);
  final loaded = compactCodec.decode(compactSave);
  final resumed = compactEngine.resume(checkpoint: loaded, seasonCount: 12);
  final compactUninterrupted = compactor.compactFull(uninterrupted.checkpoint);
  final finalSave = compactCodec.encode(resumed.checkpoint);

  final firstMatches = _seasonSignatures(first.report).join() ==
      _seasonSignatures(uninterrupted.report).take(8).join();
  final resumedMatches = _seasonSignatures(resumed.report).join() ==
      _seasonSignatures(uninterrupted.report).skip(8).join();
  final finalCheckpointMatches = finalSave ==
      compactCodec.encode(compactUninterrupted);
  final fullBytes = utf8.encode(fullSave).length;
  final compactBytes = utf8.encode(compactSave).length;
  final finalBytes = utf8.encode(finalSave).length;
  final reductionPercent = (1 - compactBytes / fullBytes) * 100;

  if (!firstMatches || !resumedMatches || !finalCheckpointMatches) {
    throw StateError('M28 deterministic continuation mismatch.');
  }
  if (compactBytes * 100 >= fullBytes * 75 || compactBytes >= 750000) {
    throw StateError('M28 compact save did not meet size guard.');
  }

  print('M28 Save History Compaction / Historical Memory Policy I');
  print('Seed: $seed');
  print('Save version: ${CompactAdvancedWorldSaveCodec.currentSaveVersion}');
  print('Full M27 season-8 save bytes: $fullBytes');
  print('Compact M28 season-8 save bytes: $compactBytes');
  print('Reduction: ${reductionPercent.toStringAsFixed(1)}%');
  print('Compact M28 season-20 save bytes: $finalBytes');
  print('Recent raw history window: ${compactFirst.recentHistoryStartSeasonIndex}..7');
  print('All-time contract events: ${compactFirst.history.contractEventCount}');
  print('Retained contract events: ${compactFirst.runtime.transfer.contractEvents.length}');
  print('All-time loans: ${compactFirst.history.loanCount}');
  print('Retained loan detail: ${compactFirst.runtime.transfer.loanHistory.length}');
  print('All-time manager seasons: ${compactFirst.history.managerSeasonCount}');
  print('Retained manager seasons: ${compactFirst.runtime.manager.seasons.length}');
  print('All-time manager changes: ${compactFirst.history.managerChangeCount}');
  print('Season replay match: $resumedMatches');
  print('Final compact checkpoint match: $finalCheckpointMatches');
}

List<String> _seasonSignatures(WorldCareerReport report) => report.seasons
    .map((season) {
      final leagues = season.leagueResults.map((league) {
        final fixtures = league.report.fixtures.map((fixture) {
          final result = fixture.result!;
          return '${fixture.id}:${result.homeGoals}-${result.awayGoals}:'
              '${result.homeExpectedGoals}:${result.awayExpectedGoals}:'
              '${result.matchSeed}';
        }).join();
        return '${league.tier.name}:${league.report.seasonIndex}:'
            '${league.report.seed}:${league.report.championClubId}:$fixtures';
      }).join('|');
      return '${season.seasonIndex}::$leagues::'
          '${season.transfersAfterSeason.map((deal) => deal.signature).join('|')}::'
          '${season.retiredAfterSeason.map((player) => player.signature).join('|')}::'
          '${season.youthIntakeAfterSeason.map((player) => player.signature).join('|')}::'
          '${season.financeStatesAfterWindow.map((state) => state.signature).join('|')}::'
          '${season.movementsAfterSeason.map((item) => item.signature).join('|')}::'
          '${season.leaguesAfterTransition.map((item) => item.signature).join('|')}';
    })
    .toList(growable: false);
