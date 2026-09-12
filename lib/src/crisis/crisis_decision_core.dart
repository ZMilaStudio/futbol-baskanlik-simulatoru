import '../core/money.dart';
import '../election/president_management_profile.dart';
import '../fan/fan_state.dart';
import '../finance/club_finance_state.dart';
import '../media/media_state.dart';

enum CrisisType {
  liquiditySqueeze,
  supporterUnrest,
  mediaBacklash,
}

enum CrisisAction {
  austerityPlan,
  bridgeSpending,
  balancedRecovery,
  ambitionReset,
  listeningTour,
  supporterReassurance,
  transparentBriefing,
  confrontNarrative,
  measuredMediaResponse,
}

class CrisisContext {
  const CrisisContext({
    required this.clubId,
    required this.seasonIndex,
    required this.finance,
    required this.fan,
    required this.media,
    required this.president,
  });

  final String clubId;
  final int seasonIndex;
  final ClubFinanceState finance;
  final FanState fan;
  final MediaState media;
  final PresidentManagementProfile president;

  String get signature =>
      '$clubId:$seasonIndex:${finance.signature}:${fan.signature}:'
      '${media.signature}:${president.signature}';
}

class CrisisScenario {
  const CrisisScenario({
    required this.type,
    required this.severity,
  });

  final CrisisType type;
  final int severity;

  String get signature => '${type.name}:$severity';
}

class CrisisEffect {
  const CrisisEffect({
    required this.cashDelta,
    required this.fanTrustDelta,
    required this.mediaCredibilityDelta,
  });

  final Money cashDelta;
  final int fanTrustDelta;
  final int mediaCredibilityDelta;

  String get signature =>
      '${cashDelta.minorUnits}:$fanTrustDelta:$mediaCredibilityDelta';
}

class CrisisDecision {
  const CrisisDecision({
    required this.action,
    required this.effect,
  });

  final CrisisAction action;
  final CrisisEffect effect;

  String get signature => '${action.name}:${effect.signature}';
}

class CrisisResolution {
  const CrisisResolution({
    required this.scenario,
    required this.decision,
    required this.finance,
    required this.fan,
    required this.media,
  });

  final CrisisScenario scenario;
  final CrisisDecision decision;
  final ClubFinanceState finance;
  final FanState fan;
  final MediaState media;

  String get signature =>
      '${scenario.signature}:${decision.signature}:${finance.signature}:'
      '${fan.signature}:${media.signature}';
}

class CrisisDecisionEngine {
  const CrisisDecisionEngine({this.activationThreshold = 35});

  final int activationThreshold;

  CrisisScenario? detect(CrisisContext context) {
    _validate(context);
    final cash = context.finance.cash.minorUnits;
    final debt = context.finance.debt.minorUnits;
    final total = cash + debt;
    final liquidityPressure = total <= 0 ? 0 : ((debt * 100) ~/ total).clamp(0, 100);
    final supporterPressure = (100 - context.fan.overallTrust).clamp(0, 100);
    final mediaPressure = (100 - context.media.credibility).clamp(0, 100);

    var type = CrisisType.liquiditySqueeze;
    var severity = liquidityPressure;
    if (supporterPressure > severity) {
      type = CrisisType.supporterUnrest;
      severity = supporterPressure;
    }
    if (mediaPressure > severity) {
      type = CrisisType.mediaBacklash;
      severity = mediaPressure;
    }

    if (severity < activationThreshold) {
      return null;
    }
    return CrisisScenario(type: type, severity: severity);
  }

  CrisisDecision choose({
    required CrisisScenario scenario,
    required PresidentManagementProfile president,
  }) {
    return switch (scenario.type) {
      CrisisType.liquiditySqueeze => _liquidityDecision(president),
      CrisisType.supporterUnrest => _supporterDecision(president),
      CrisisType.mediaBacklash => _mediaDecision(president),
    };
  }

  CrisisResolution? evaluate(CrisisContext context) {
    final scenario = detect(context);
    if (scenario == null) {
      return null;
    }
    final decision = choose(scenario: scenario, president: context.president);
    return _apply(context: context, scenario: scenario, decision: decision);
  }

  CrisisDecision _liquidityDecision(PresidentManagementProfile president) {
    if (president.financialDiscipline >= 70) {
      return const CrisisDecision(
        action: CrisisAction.austerityPlan,
        effect: CrisisEffect(
          cashDelta: Money.fromUnits(2000000),
          fanTrustDelta: -2,
          mediaCredibilityDelta: 2,
        ),
      );
    }
    if (president.riskAppetite >= 70) {
      return const CrisisDecision(
        action: CrisisAction.bridgeSpending,
        effect: CrisisEffect(
          cashDelta: Money.fromUnits(-3000000),
          fanTrustDelta: 3,
          mediaCredibilityDelta: -1,
        ),
      );
    }
    return const CrisisDecision(
      action: CrisisAction.balancedRecovery,
      effect: CrisisEffect(
        cashDelta: Money.fromUnits(500000),
        fanTrustDelta: 0,
        mediaCredibilityDelta: 1,
      ),
    );
  }

  CrisisDecision _supporterDecision(PresidentManagementProfile president) {
    if (president.transferAmbition >= 70 && president.riskAppetite >= 60) {
      return const CrisisDecision(
        action: CrisisAction.ambitionReset,
        effect: CrisisEffect(
          cashDelta: Money.fromUnits(-2000000),
          fanTrustDelta: 5,
          mediaCredibilityDelta: -1,
        ),
      );
    }
    if (president.managerPatience >= 70) {
      return const CrisisDecision(
        action: CrisisAction.listeningTour,
        effect: CrisisEffect(
          cashDelta: Money.fromUnits(-500000),
          fanTrustDelta: 4,
          mediaCredibilityDelta: 2,
        ),
      );
    }
    return const CrisisDecision(
      action: CrisisAction.supporterReassurance,
      effect: CrisisEffect(
        cashDelta: Money.fromUnits(-1000000),
        fanTrustDelta: 3,
        mediaCredibilityDelta: 1,
      ),
    );
  }

  CrisisDecision _mediaDecision(PresidentManagementProfile president) {
    if (president.riskAppetite >= 70) {
      return const CrisisDecision(
        action: CrisisAction.confrontNarrative,
        effect: CrisisEffect(
          cashDelta: Money.zero,
          fanTrustDelta: 1,
          mediaCredibilityDelta: -3,
        ),
      );
    }
    if (president.financialDiscipline >= 65 || president.managerPatience >= 65) {
      return const CrisisDecision(
        action: CrisisAction.transparentBriefing,
        effect: CrisisEffect(
          cashDelta: Money.fromUnits(-200000),
          fanTrustDelta: 1,
          mediaCredibilityDelta: 5,
        ),
      );
    }
    return const CrisisDecision(
      action: CrisisAction.measuredMediaResponse,
      effect: CrisisEffect(
        cashDelta: Money.fromUnits(-100000),
        fanTrustDelta: 0,
        mediaCredibilityDelta: 3,
      ),
    );
  }

  CrisisResolution _apply({
    required CrisisContext context,
    required CrisisScenario scenario,
    required CrisisDecision decision,
  }) {
    final requestedCash = context.finance.cash + decision.effect.cashDelta;
    final nextCash = requestedCash.isNegative ? Money.zero : requestedCash;
    final appliedCashDelta = nextCash - context.finance.cash;
    final nextFan = FanState(
      clubId: context.fan.clubId,
      sportingTrust: _score(context.fan.sportingTrust, decision.effect.fanTrustDelta),
      financialTrust: _score(context.fan.financialTrust, decision.effect.fanTrustDelta),
      transferTrust: _score(context.fan.transferTrust, decision.effect.fanTrustDelta),
      identityTrust: _score(context.fan.identityTrust, decision.effect.fanTrustDelta),
    );
    final nextMedia = context.media.copyWith(
      credibility: _score(
        context.media.credibility,
        decision.effect.mediaCredibilityDelta,
      ),
    );
    final appliedDecision = CrisisDecision(
      action: decision.action,
      effect: CrisisEffect(
        cashDelta: appliedCashDelta,
        fanTrustDelta: nextFan.overallTrust - context.fan.overallTrust,
        mediaCredibilityDelta: nextMedia.credibility - context.media.credibility,
      ),
    );

    return CrisisResolution(
      scenario: scenario,
      decision: appliedDecision,
      finance: ClubFinanceState(
        clubId: context.finance.clubId,
        cash: nextCash,
        debt: context.finance.debt,
      ),
      fan: nextFan,
      media: nextMedia,
    );
  }

  int _score(int current, int delta) => (current + delta).clamp(0, 100).toInt();

  void _validate(CrisisContext context) {
    if (context.seasonIndex < 0) {
      throw ArgumentError.value(context.seasonIndex, 'seasonIndex');
    }
    if (context.finance.clubId != context.clubId ||
        context.fan.clubId != context.clubId ||
        context.media.clubId != context.clubId) {
      throw ArgumentError('Crisis context club ids must match.');
    }
  }
}
