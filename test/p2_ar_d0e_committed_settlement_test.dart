import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';

/// TEST FIXTURE / NOT AUTHORITATIVE PRODUCER.
/// Copies the unchanged production package into an isolated test workspace and
/// adds a private fixture part/main. No production body changes; no public mint
/// bypass, fake production source factory or fixture API is added to lib/.
Future<ProcessResult> runD0EContractHarness(String fixture) async {
  final directory =
      await Directory('.ard0e-validation').create(recursive: true);
  final temp = await directory.createTemp('contract-');
  await for (final entity
      in Directory('lib').list(recursive: true, followLinks: false)) {
    if (entity is File) {
      final target = File('${temp.path}/${entity.path}');
      await target.parent.create(recursive: true);
      await entity.copy(target.path);
    }
  }
  await File('pubspec.yaml').copy('${temp.path}/pubspec.yaml');
  if (await File('pubspec.lock').exists())
    await File('pubspec.lock').copy('${temp.path}/pubspec.lock');
  final originalConfig = File('.dart_tool/package_config.json').absolute;
  final config =
      jsonDecode(await originalConfig.readAsString()) as Map<String, dynamic>;
  for (final package in config['packages'] as List<dynamic>) {
    package['rootUri'] = package['name'] == 'futbol_baskanlik_m0'
        ? temp.absolute.uri.toString()
        : originalConfig.uri.resolve(package['rootUri'] as String).toString();
  }
  final packageConfig = File('${temp.path}/.dart_tool/package_config.json');
  await packageConfig.parent.create(recursive: true);
  await packageConfig.writeAsString(jsonEncode(config));
  var entry = await File(
          'lib/src/facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart')
      .readAsString();
  entry =
      "import 'package:test/test.dart';\nimport '../season/season_engine.dart';\nimport '../world/fictional_world_factory.dart';\n$entry";
  entry = entry.replaceFirst(
      "part '../finance/full_m65_runtime_economy_continuation_authority.dart';",
      "part '../finance/full_m65_runtime_economy_continuation_authority.dart';\npart 'contract_fixture.dart';");
  const entryPath =
      'lib/src/facility/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
  await File('${temp.path}/$entryPath')
      .writeAsString('$entry\nvoid main() => runFixtureTests();\n');
  await File('${temp.path}/lib/src/facility/contract_fixture.dart').writeAsString(
      "part of 'player_president_tenure_gated_ticket_pricing_runtime_integration.dart';\n$fixture");
  return Process.run(
      Platform.resolvedExecutable, ['test', '--reporter=expanded', entryPath],
      workingDirectory: temp.absolute.path);
}

void main() {
  test(
      'private contract fixture exercises settlement, NOT future production integration',
      () async {
    final run = await runD0EContractHarness(contractCases);
    // Keep the child test evidence, including its real test count and errors.
    print(run.stdout);
    expect(run.exitCode, 0, reason: '${run.stdout}\n${run.stderr}');
  }, timeout: const Timeout(Duration(minutes: 5)));
}

const contractCases = r'''
// TEST FIXTURE / NOT AUTHORITATIVE PRODUCER: exists only in this generated
// test library, never in the production source/library/package.
final class _Fixture extends CommittedSeasonSettlementCapability {
  _Fixture(FullM65RuntimeEconomyContinuationAuthority a, List<LeagueSeasonSnapshot> reports,
      {Object? owner, Object? revision, Object? provenance, Object? execution,
      PreparedWorldOpening? opening}) : super._(owner: owner ?? a.owner,
        revision: revision ?? a.revision, provenance: provenance ?? a.provenance,
        executionIdentity: execution ?? a.executionIdentity, completedSource: Object(),
        opening: opening ?? a.opening, reports: reports);
}

FullM65RuntimeEconomyContinuationAuthority _open({BasicEconomyEngine? economy}) {
  final world = const FictionalWorldFactory().build();
  final engine = PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(
      baseWorldEngine: WorldCareerEngine(seasonEngine:_NoSimulation(),
          economyEngine: economy ?? const BasicEconomyEngine()));
  final p = engine.prepareInitial(clubs: world.clubs, leagues: world.leagues,
      config: const SimulationConfig(careerSeed: 42002), controlledClubId: world.clubs.first.id,
      captureManagerAuthority: true);
  return FullM65RuntimeEconomyContinuationAuthority.claim(p, expectedOwner: p.owner,
      expectedRevision: p.revision, expectedProvenance: p.provenance, expectedExecution: p.executionIdentity);
}

List<LeagueSeasonSnapshot> _reports(FullM65RuntimeEconomyContinuationAuthority a) {
  final clubs = {for(final c in a.opening.effectiveClubs) c.id:c};
  return [for(final l in a.opening.leagues) LeagueSeasonSnapshot(tier:l.tier,
      report: const SeasonEngine().simulate(clubs: [for(final id in l.clubIds) clubs[id]!],
        config:a.opening.config.copyWith(seasonIndex:a.opening.seasonIndex)))];
}

class _Failure extends BasicEconomyEngine {
  @override
  List<ClubFinanceSeason> simulateSeason({required List<Club> clubs, required List<Player> players,
    required SeasonReport seasonReport, required List<ClubFinanceState> openingStates,
    int economicScaleBps=10000, int costScaleBps=10000, Map<String,Money>? annualWagesByClub,
    Map<String,Money>? transferInstallmentIncomeByClub, Map<String,Money>? transferInstallmentExpenseByClub,
    Map<String,int> matchdayRevenueMultiplierBpsByClub=const{}, Map<String,Money>? sponsorRevenueByClub}) {
      throw StateError('actual delegate failure');
  }
}

class _NoSimulation extends SeasonEngine {
  @override
  SeasonReport simulate({required List<Club> clubs,required SimulationConfig config}) =>
      throw StateError('Economy execution must not simulate/replay a league.');
}

class _FixedTicket extends PlayerMatchdayTicketPricingDecisionProvider {
  @override
  MatchdayTicketPricingChoice choose(PlayerPresidentTicketPricingDecisionContext c) =>
      const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.premium);
}

class _FinanceProbe extends BasicEconomyEngine {
  final rows = <ClubFinanceSeason>[];
  final wages = <Map<String,Money>?>[];
  final incomes = <Map<String,Money>?>[];
  final expenses = <Map<String,Money>?>[];
  @override
  List<ClubFinanceSeason> simulateSeason({required List<Club> clubs, required List<Player> players,
    required SeasonReport seasonReport, required List<ClubFinanceState> openingStates,
    int economicScaleBps=10000, int costScaleBps=10000, Map<String,Money>? annualWagesByClub,
    Map<String,Money>? transferInstallmentIncomeByClub, Map<String,Money>? transferInstallmentExpenseByClub,
    Map<String,int> matchdayRevenueMultiplierBpsByClub=const{}, Map<String,Money>? sponsorRevenueByClub}) {
    wages.add(annualWagesByClub); incomes.add(transferInstallmentIncomeByClub); expenses.add(transferInstallmentExpenseByClub);
    final result=super.simulateSeason(clubs:clubs,players:players,seasonReport:seasonReport,
      openingStates:openingStates,economicScaleBps:economicScaleBps,costScaleBps:costScaleBps,
      annualWagesByClub:annualWagesByClub,transferInstallmentIncomeByClub:transferInstallmentIncomeByClub,
      transferInstallmentExpenseByClub:transferInstallmentExpenseByClub,
      matchdayRevenueMultiplierBpsByClub:matchdayRevenueMultiplierBpsByClub,sponsorRevenueByClub:sponsorRevenueByClub);
    rows.addAll(result); return result;
  }
}

void runFixtureTests() {
  for(final field in ['owner','revision','provenance','execution']) {
    test('contract rejects foreign $field without attempt', () {
      final a=_open(); final reports=_reports(a);
      final foreign=_Fixture(a,reports, owner:field=='owner'?Object():null,
          revision:field=='revision'?Object():null, provenance:field=='provenance'?Object():null,
          execution:field=='execution'?Object():null);
      expect(()=>a.prepareSettlement(foreign),throwsStateError);
      expect(a.state,RuntimeEconomyState.awaitingCommittedSeason);
      expect(a._pipeline.receipt,isNull); expect(a.contractCount,0);
      expect(a.prepareSettlement(_Fixture(a,reports)),RuntimeEconomyState.awaitingTicketDecision);
    });
  }
  test('raw reports and incomplete coverage do not authorize settlement', () {
    final a=_open(); final reports=_reports(a);
    expect(()=>(a as dynamic).prepareSettlement(reports), throwsA(isA<TypeError>()));
    expect(()=>a.prepareSettlement(_Fixture(a,reports.take(2).toList())),throwsStateError);
    expect(a.state,RuntimeEconomyState.awaitingCommittedSeason);
    expect(a.contractCount,0); expect(a.sponsorProcessedClubCount,0);
  });
  test('exact Pending/choice identity, no AI fallback and actual once-only receipt', () {
    final probe=_FinanceProbe(); final a=_open(economy:probe); final cap=_Fixture(a,_reports(a));
    expect(a.prepareSettlement(cap),RuntimeEconomyState.awaitingTicketDecision);
    final pending=a.pending!; final context=pending.context;
    expect(a.prepareSettlement(cap),RuntimeEconomyState.awaitingTicketDecision);
    expect(a.pending,same(pending));
    expect(a.contractCount,0); expect(a.sponsorProcessedClubCount,0); expect(a.ticketDecisionCount,0);
    expect(()=>a.submitTicket(pending,'premium',expectedRevision:a.revision),throwsStateError);
    expect(()=>a.submitTicket(pending,const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.premium),
        expectedRevision:Object()),throwsStateError);
    final other=_open(); final otherCap=_Fixture(other,_reports(other)); other.prepareSettlement(otherCap);
    expect(()=>a.submitTicket(other.pending!,const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.premium),
        expectedRevision:a.revision),throwsStateError);
    expect(a.pending,same(pending)); expect(a._pipeline.receipt,isNull);
    final choice=const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.premium);
    a.submitTicket(pending,choice,expectedRevision:a.revision);
    a.submitTicket(pending,choice,expectedRevision:a.revision);
    expect(()=>a.submitTicket(pending,const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.balanced),
        expectedRevision:a.revision),throwsStateError);
    expect(()=>a.executeSettlement(expectedCommitted:_Fixture(a,cap.reports)),throwsStateError);
    final result=a.executeSettlement(expectedCommitted:cap);
    expect(a.state,RuntimeEconomyState.settled); expect(a.result,same(result));
    expect(result.committedSource,same(cap)); expect(result.receipt.results.length,48);
    expect(result.receipt.inputs.length,48); expect(a.sponsorProcessedClubCount,48);
    expect(a.ticketDecisionCount,48); expect(a.contractCount,greaterThan(0));
    final input=result.receipt.inputs[pending.controlledClubId]!;
    expect(input.ticket.context,same(context)); expect(input.ticket.choice,same(choice));
    expect(input.ticket.providerCalled,isTrue);
    expect(result.receipt.effectiveClubSource,same(a.managerAuthority));
    expect(probe.wages.length,3); expect(probe.incomes.length,3); expect(probe.expenses.length,3);
    expect(probe.wages.every((w)=>identical(w,probe.wages.first)),isTrue);
    expect(probe.incomes.every((w)=>identical(w,probe.incomes.first)),isTrue);
    expect(probe.expenses.every((w)=>identical(w,probe.expenses.first)),isTrue);
    for(final row in result.receipt.results) {
      expect(probe.rows.singleWhere((r)=>r.clubId==row.clubId),same(row));
      expect(result.receipt.inputs[row.clubId]!.wages,probe.wages.first![row.clubId]);
    }
    result.receipt.verify(expectedOwner:a.owner,expectedRevision:a.revision,
        expectedProvenance:a.provenance,expectedSeason:a.opening.seasonIndex,
        expectedResults:result.receipt.results,expectedEffectiveClubSource:a.managerAuthority);
    final contracts=a.contractCount;
    expect(()=>a.executeSettlement(expectedCommitted:cap),throwsStateError);
    expect(a.contractCount,contracts); expect(a.result,same(result));
    expect(probe.rows.length,48); expect(probe.wages.length,3);
    expect(()=>result.receipt.results.clear(),throwsUnsupportedError);
    expect(()=>result.closingFinanceStates.clear(),throwsUnsupportedError);
    expect(()=>a.submitTicket(pending,choice,expectedRevision:a.revision),throwsStateError);
  });
  test('changed report after Pending rejected before attempt', () {
    final a=_open(); final cap=_Fixture(a,_reports(a)); a.prepareSettlement(cap);
    cap.reports.first.report.table.first.points++;
    expect(()=>a.submitTicket(a.pending!,const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.premium),
        expectedRevision:a.revision),throwsStateError);
    expect(a.state,RuntimeEconomyState.awaitingTicketDecision); expect(a.contractCount,0);
  });
  test('actual failure poisons graph with no publication or retry', () {
    final a=_open(economy:_Failure()); final cap=_Fixture(a,_reports(a)); a.prepareSettlement(cap);
    a.submitTicket(a.pending!,const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.premium),
        expectedRevision:a.revision);
    expect(()=>a.executeSettlement(expectedCommitted:cap),throwsStateError);
    expect(a.state,RuntimeEconomyState.failed); expect(a.result,isNull);
    expect(a._pipeline.receipt,isNull); expect(a.contractCount,greaterThan(0));
    expect(()=>a.executeSettlement(expectedCommitted:cap),throwsStateError);
    expect(()=>a.prepareSettlement(cap),throwsStateError);
  });
  test('value-equal fixture replacement fails identity preservation', () {
    final a=_open(); final cap=_Fixture(a,_reports(a));
    final f=cap.reports.first.report.fixtures.first;
    cap.reports.first.report.fixtures[0]=f.withResult(f.result!);
    expect(()=>a.prepareSettlement(cap),throwsStateError);
    expect(a.state,RuntimeEconomyState.awaitingCommittedSeason); expect(a.contractCount,0);
  });
  test('committed settlement shares actual full-M65 legacy finance values', () {
    final world=const FictionalWorldFactory().build();
    const config=SimulationConfig(careerSeed:42002);
    final legacyEngine=PlayerPresidentTenureGatedTicketPricingRuntimeCareerEngine(playerProvider:_FixedTicket());
    final legacyPrepared=legacyEngine.prepareInitial(clubs:world.clubs,leagues:world.leagues,
        config:config,controlledClubId:world.clubs.first.id);
    final legacy=legacyEngine.executePrepared(legacyPrepared,expectedOwner:legacyPrepared.owner,
        expectedRevision:legacyPrepared.revision,expectedProvenance:legacyPrepared.provenance);
    final a=_open(); final cap=_Fixture(a,_reports(a)); a.prepareSettlement(cap);
    a.submitTicket(a.pending!,const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.premium),expectedRevision:a.revision);
    final settled=a.executeSettlement(expectedCommitted:cap);
    expect(settled.receipt.results.map((r)=>r.signature).toList(),
        legacy.report.seasons.single.finances.map((r)=>r.signature).toList());
    expect(settled.receipt.inputs.values.map((i)=>i.ticket.signature).toList()..sort(),
        legacyPrepared._pricing.decisions.map((d)=>d.signature).toList()..sort());
  });
}
''';
