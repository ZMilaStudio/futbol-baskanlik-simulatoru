import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  const engine = CrisisDecisionEngine();
  const clubId = 't1_01';

  PresidentManagementProfile profile({
    required String id,
    required int finance,
    required int risk,
    required int transfer,
    required int patience,
  }) =>
      PresidentManagementProfile(
        presidentId: id,
        archetype: PresidentManagementArchetype.balanced,
        financialDiscipline: finance,
        riskAppetite: risk,
        transferAmbition: transfer,
        youthOrientation: 60,
        managerPatience: patience,
      );

  CrisisContext context({
    required int cashMillions,
    required int debtMillions,
    required int fanTrust,
    required int mediaCredibility,
    required PresidentManagementProfile president,
    int seasonIndex = 4,
  }) =>
      CrisisContext(
        clubId: clubId,
        seasonIndex: seasonIndex,
        finance: ClubFinanceState(
          clubId: clubId,
          cash: Money.fromUnits(cashMillions * 1000000),
          debt: Money.fromUnits(debtMillions * 1000000),
        ),
        fan: FanState.initial(clubId, trust: fanTrust),
        media: MediaState(clubId: clubId, credibility: mediaCredibility),
        president: president,
      );

  final prudentContext = context(
    cashMillions: 10,
    debtMillions: 90,
    fanTrust: 80,
    mediaCredibility: 80,
    president: profile(
      id: 'prudent',
      finance: 90,
      risk: 20,
      transfer: 40,
      patience: 80,
    ),
  );
  final boldContext = context(
    cashMillions: 10,
    debtMillions: 90,
    fanTrust: 80,
    mediaCredibility: 80,
    president: profile(
      id: 'bold',
      finance: 20,
      risk: 90,
      transfer: 85,
      patience: 30,
    ),
  );
  final prudent = engine.evaluate(prudentContext)!;
  final bold = engine.evaluate(boldContext)!;
  if (prudent.scenario.type != CrisisType.liquiditySqueeze ||
      bold.scenario.type != CrisisType.liquiditySqueeze ||
      prudent.decision.action != CrisisAction.austerityPlan ||
      bold.decision.action != CrisisAction.bridgeSpending) {
    throw StateError('M43 president crisis decisions did not diverge.');
  }
  if (prudent.finance.debt != prudentContext.finance.debt ||
      bold.finance.debt != boldContext.finance.debt) {
    throw StateError('M43 created hidden debt.');
  }

  final supporter = engine.evaluate(
    context(
      cashMillions: 50,
      debtMillions: 10,
      fanTrust: 20,
      mediaCredibility: 75,
      president: profile(
        id: 'supporter',
        finance: 50,
        risk: 85,
        transfer: 90,
        patience: 30,
      ),
    ),
  )!;
  final media = engine.evaluate(
    context(
      cashMillions: 70,
      debtMillions: 10,
      fanTrust: 75,
      mediaCredibility: 15,
      president: profile(
        id: 'media',
        finance: 85,
        risk: 20,
        transfer: 50,
        patience: 80,
      ),
    ),
  )!;
  if (supporter.scenario.type != CrisisType.supporterUnrest ||
      media.scenario.type != CrisisType.mediaBacklash) {
    throw StateError('M43 crisis pressure selection failed.');
  }

  final rebuilt = CrisisContext(
    clubId: prudentContext.clubId,
    seasonIndex: prudentContext.seasonIndex,
    finance: ClubFinanceState(
      clubId: prudentContext.finance.clubId,
      cash: Money.fromMinorUnits(prudentContext.finance.cash.minorUnits),
      debt: Money.fromMinorUnits(prudentContext.finance.debt.minorUnits),
    ),
    fan: FanState(
      clubId: prudentContext.fan.clubId,
      sportingTrust: prudentContext.fan.sportingTrust,
      financialTrust: prudentContext.fan.financialTrust,
      transferTrust: prudentContext.fan.transferTrust,
      identityTrust: prudentContext.fan.identityTrust,
    ),
    media: MediaState(
      clubId: prudentContext.media.clubId,
      credibility: prudentContext.media.credibility,
    ),
    president: prudentContext.president,
  );
  final resumed = engine.evaluate(rebuilt)!;
  if (resumed.signature != prudent.signature) {
    throw StateError('M43 stateless save/resume parity failed.');
  }

  print('M43_CRISIS prudent=${prudent.decision.action.name}');
  print('M43_CRISIS bold=${bold.decision.action.name}');
  print(
    'M43_CRISIS supporter=${supporter.decision.action.name} '
    'fan=${supporter.fan.overallTrust}',
  );
  print(
    'M43_CRISIS media=${media.decision.action.name} '
    'credibility=${media.media.credibility}',
  );
  print('M43_CRISIS debtPreserved=${prudent.finance.debt == prudentContext.finance.debt}');
  print('M43_CRISIS saveResumeMatch=${resumed.signature == prudent.signature}');
  print('M43_CRISIS PASS');
}
