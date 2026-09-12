import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  const engine = CrisisDecisionEngine();
  const clubId = 't1_01';

  PresidentManagementProfile profile({
    required String id,
    int finance = 60,
    int risk = 60,
    int transfer = 60,
    int youth = 60,
    int patience = 60,
  }) =>
      PresidentManagementProfile(
        presidentId: id,
        archetype: PresidentManagementArchetype.balanced,
        financialDiscipline: finance,
        riskAppetite: risk,
        transferAmbition: transfer,
        youthOrientation: youth,
        managerPatience: patience,
      );

  CrisisContext context({
    required int cashMillions,
    required int debtMillions,
    required int fanTrust,
    required int mediaCredibility,
    required PresidentManagementProfile president,
    int seasonIndex = 0,
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

  test('M43 healthy context does not create a crisis', () {
    final result = engine.evaluate(
      context(
        cashMillions: 80,
        debtMillions: 20,
        fanTrust: 70,
        mediaCredibility: 70,
        president: profile(id: 'balanced'),
      ),
    );

    expect(result, isNull);
  });

  test('M43 strongest pressure deterministically selects crisis type', () {
    final liquidity = engine.detect(
      context(
        cashMillions: 10,
        debtMillions: 90,
        fanTrust: 80,
        mediaCredibility: 80,
        president: profile(id: 'p1'),
      ),
    );
    final supporter = engine.detect(
      context(
        cashMillions: 90,
        debtMillions: 10,
        fanTrust: 15,
        mediaCredibility: 70,
        president: profile(id: 'p2'),
      ),
    );
    final media = engine.detect(
      context(
        cashMillions: 90,
        debtMillions: 10,
        fanTrust: 75,
        mediaCredibility: 10,
        president: profile(id: 'p3'),
      ),
    );

    expect(liquidity!.type, CrisisType.liquiditySqueeze);
    expect(supporter!.type, CrisisType.supporterUnrest);
    expect(media!.type, CrisisType.mediaBacklash);
  });

  test('M43 president finance and risk profiles choose different liquidity responses', () {
    final prudent = engine.evaluate(
      context(
        cashMillions: 10,
        debtMillions: 90,
        fanTrust: 80,
        mediaCredibility: 80,
        president: profile(id: 'prudent', finance: 90, risk: 20),
      ),
    )!;
    final bold = engine.evaluate(
      context(
        cashMillions: 10,
        debtMillions: 90,
        fanTrust: 80,
        mediaCredibility: 80,
        president: profile(id: 'bold', finance: 20, risk: 90),
      ),
    )!;

    expect(prudent.decision.action, CrisisAction.austerityPlan);
    expect(bold.decision.action, CrisisAction.bridgeSpending);
    expect(prudent.decision.action, isNot(bold.decision.action));
    expect(prudent.finance.cash, greaterThan(bold.finance.cash));
  });

  test('M43 supporter crisis reacts differently to ambition and patience', () {
    final ambitious = engine.evaluate(
      context(
        cashMillions: 50,
        debtMillions: 10,
        fanTrust: 20,
        mediaCredibility: 75,
        president: profile(
          id: 'ambitious',
          risk: 80,
          transfer: 85,
          patience: 30,
        ),
      ),
    )!;
    final patient = engine.evaluate(
      context(
        cashMillions: 50,
        debtMillions: 10,
        fanTrust: 20,
        mediaCredibility: 75,
        president: profile(
          id: 'patient',
          risk: 30,
          transfer: 40,
          patience: 85,
        ),
      ),
    )!;

    expect(ambitious.decision.action, CrisisAction.ambitionReset);
    expect(patient.decision.action, CrisisAction.listeningTour);
    expect(ambitious.fan.overallTrust, greaterThan(20));
    expect(patient.fan.overallTrust, greaterThan(20));
  });

  test('M43 effects are bounded and never create hidden debt', () {
    final original = context(
      cashMillions: 1,
      debtMillions: 0,
      fanTrust: 20,
      mediaCredibility: 80,
      president: profile(
        id: 'spend',
        risk: 90,
        transfer: 90,
        patience: 20,
      ),
    );
    final result = engine.evaluate(original)!;

    expect(result.finance.cash, Money.zero);
    expect(result.finance.debt, original.finance.debt);
    expect(result.fan.overallTrust, inInclusiveRange(0, 100));
    expect(result.media.credibility, inInclusiveRange(0, 100));
    expect(result.decision.effect.cashDelta, const Money.fromUnits(-1000000));
  });

  test('M43 stateless crisis replay is save-resume deterministic', () {
    final firstContext = context(
      cashMillions: 15,
      debtMillions: 85,
      fanTrust: 45,
      mediaCredibility: 35,
      president: profile(id: 'resume', finance: 82, risk: 25, patience: 75),
      seasonIndex: 6,
    );
    final resumedContext = CrisisContext(
      clubId: firstContext.clubId,
      seasonIndex: firstContext.seasonIndex,
      finance: ClubFinanceState(
        clubId: firstContext.finance.clubId,
        cash: Money.fromMinorUnits(firstContext.finance.cash.minorUnits),
        debt: Money.fromMinorUnits(firstContext.finance.debt.minorUnits),
      ),
      fan: FanState(
        clubId: firstContext.fan.clubId,
        sportingTrust: firstContext.fan.sportingTrust,
        financialTrust: firstContext.fan.financialTrust,
        transferTrust: firstContext.fan.transferTrust,
        identityTrust: firstContext.fan.identityTrust,
      ),
      media: MediaState(
        clubId: firstContext.media.clubId,
        credibility: firstContext.media.credibility,
      ),
      president: firstContext.president,
    );

    final direct = engine.evaluate(firstContext)!;
    final resumed = engine.evaluate(resumedContext)!;

    expect(resumedContext.signature, firstContext.signature);
    expect(resumed.signature, direct.signature);
  });
}
