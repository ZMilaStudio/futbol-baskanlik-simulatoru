import 'package:flutter/material.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';

/// Presentation-only rendering of an authoritative M90 runtime resolution.
///
/// Every displayed consequence is read from the public core result. This widget
/// does not calculate simulation effects and does not persist presentation
/// state.
class DecisionResolutionPanel extends StatelessWidget {
  const DecisionResolutionPanel({
    super.key,
    required this.resolution,
    required this.busy,
    this.onContinue,
  });

  final PlayerPresidentInteractiveDecisionResolution resolution;
  final bool busy;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('decision-resolution-panel'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 42,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          'Karar uygulandı',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _kindLabel(resolution.kind),
          key: const Key('decision-resolution-kind'),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Text(
          _choiceLabel(resolution.consequence),
          key: const Key('decision-resolution-choice'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _resultLabel(resolution.consequence),
          key: const Key('decision-resolution-result'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const Key('decision-resolution-continue-button'),
          onPressed: busy ? null : onContinue,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Devam Et'),
        ),
      ],
    );
  }
}

String _choiceLabel(PlayerPresidentInteractiveDecisionConsequence consequence) {
  if (consequence is PlayerPresidentFacilityInvestmentConsequence) {
    final choice = consequence.decision.requestedChoice;
    if (choice == null) {
      throw StateError('Player facility resolution is missing requested choice.');
    }
    return 'Seçim: akademi ${choice.academyUpgrades}, antrenman '
        '${choice.trainingGroundUpgrades}, stadyum ${choice.stadiumUpgrades}';
  }
  if (consequence is PlayerPresidentSponsorConsequence) {
    return 'Seçim: ${consequence.decision.selectedOffer.sponsorName}';
  }
  if (consequence is PlayerPresidentCrisisConsequence) {
    return 'Seçim: ${_humanize(consequence.decision.selectedDecision.action.name)}';
  }
  if (consequence is PlayerPresidentManagerReviewConsequence) {
    return consequence.retained
        ? 'Seçim: teknik direktörle devam et'
        : 'Seçim: teknik direktör değişikliği';
  }
  if (consequence is PlayerPresidentManagerReplacementConsequence) {
    final manager = consequence.decision.selectedManager;
    return 'Seçim: ${manager?.name ?? consequence.assignment.managerId}';
  }
  if (consequence is PlayerPresidentPromiseConsequence) {
    return 'Seçim: ${_humanize(consequence.promise.type.name)}';
  }
  if (consequence is PlayerPresidentMediaStatementConsequence) {
    return 'Seçim: ${_humanize(consequence.statement.stance.name)}';
  }
  if (consequence is PlayerPresidentTransferStrategyConsequence) {
    final profile = consequence.effectiveProfile;
    return 'Seçim: finans ${profile.financialDiscipline}, risk '
        '${profile.riskAppetite}, transfer ${profile.transferAmbition}, '
        'altyapı ${profile.youthOrientation}';
  }
  if (consequence is PlayerPresidentTicketPricingConsequence) {
    return 'Seçim: ${_humanize(consequence.decision.choice.tier.name)}';
  }
  throw StateError(
    'Unsupported decision consequence ${consequence.runtimeType}.',
  );
}

String _resultLabel(PlayerPresidentInteractiveDecisionConsequence consequence) {
  if (consequence is PlayerPresidentFacilityInvestmentConsequence) {
    final decision = consequence.decision.decision;
    return 'Akademi ${decision.academyBeforeLevel}→'
        '${decision.academyAfterLevel} '
        '(${decision.academyAppliedUpgrades} uygulandı) • '
        'Antrenman ${decision.trainingGroundBeforeLevel}→'
        '${decision.trainingGroundAfterLevel} '
        '(${decision.trainingGroundAppliedUpgrades} uygulandı) • '
        'Stadyum ${decision.stadiumBeforeLevel}→'
        '${decision.stadiumAfterLevel} '
        '(${decision.stadiumAppliedUpgrades} uygulandı) • '
        'Harcama ${decision.spend}';
  }
  if (consequence is PlayerPresidentSponsorConsequence) {
    final offer = consequence.contract.offer;
    return '${offer.sponsorName} sözleşmesi • garanti '
        '${offer.annualGuaranteed} • performans bonusu '
        '${offer.performanceBonus} • süre ${offer.termSeasons} sezon • '
        'hedef ${_humanize(offer.bonusTarget.name)}';
  }
  if (consequence is PlayerPresidentCrisisConsequence) {
    final applied = consequence.decision.resolution.decision;
    return 'Uygulanan aksiyon ${_humanize(applied.action.name)} • '
        'nakit ${applied.effect.cashDelta} • '
        'taraftar ${_signed(applied.effect.fanTrustDelta)} • '
        'medya ${_signed(applied.effect.mediaCredibilityDelta)}';
  }
  if (consequence is PlayerPresidentManagerReviewConsequence) {
    final manager = consequence.context.currentManager.name;
    return consequence.retained
        ? '$manager ile devam etme kararı uygulandı.'
        : '$manager için değişiklik kararı uygulandı; yeni teknik direktör '
            'henüz bu kararda seçilmiş değildir.';
  }
  if (consequence is PlayerPresidentManagerReplacementConsequence) {
    final manager = consequence.decision.selectedManager;
    final reason = consequence.decision.replacementContext?.reason;
    return '${manager?.name ?? consequence.assignment.managerId} göreve '
        'atandı${reason == null ? '' : ' • neden ${_humanize(reason.name)}'}.';
  }
  if (consequence is PlayerPresidentPromiseConsequence) {
    final promise = consequence.promise;
    final targets = <String>[
      if (promise.targetLeaguePosition != null)
        'lig hedefi ${promise.targetLeaguePosition}',
      if (promise.targetDebtReductionBps != null)
        'borç azaltma hedefi ${promise.targetDebtReductionBps} bp',
    ];
    return 'Vaat ${_humanize(promise.type.name)} uygulandı'
        '${targets.isEmpty ? '.' : ' • ${targets.join(' • ')}'}';
  }
  if (consequence is PlayerPresidentMediaStatementConsequence) {
    final statement = consequence.statement;
    return 'Medya açıklaması uygulandı • konu '
        '${_humanize(statement.topic.name)} • tutum '
        '${_humanize(statement.stance.name)} • hedef '
        '${statement.targetManagerId}';
  }
  if (consequence is PlayerPresidentTransferStrategyConsequence) {
    final profile = consequence.effectiveProfile;
    return 'Etkin transfer profili • finans ${profile.financialDiscipline} • '
        'risk ${profile.riskAppetite} • transfer '
        '${profile.transferAmbition} • altyapı ${profile.youthOrientation}';
  }
  if (consequence is PlayerPresidentTicketPricingConsequence) {
    final outcome = consequence.decision.outcome;
    return 'Bilet ${_humanize(outcome.tier.name)} • fiyat '
        '${_bps(outcome.priceMultiplierBps)} • talep '
        '${_bps(outcome.demandMultiplierBps)} • seyirci '
        '${outcome.attendance} • doluluk ${_bps(outcome.occupancyBps)} • '
        'gelir çarpanı ${_bps(outcome.revenueMultiplierBps)}';
  }
  throw StateError(
    'Unsupported decision consequence ${consequence.runtimeType}.',
  );
}

String _kindLabel(PlayerPresidentInteractiveDecisionKind kind) => switch (kind) {
      PlayerPresidentInteractiveDecisionKind.facilityInvestment =>
        'Tesis yatırımı',
      PlayerPresidentInteractiveDecisionKind.sponsor => 'Sponsorluk',
      PlayerPresidentInteractiveDecisionKind.crisis => 'Kriz yönetimi',
      PlayerPresidentInteractiveDecisionKind.managerReview =>
        'Teknik direktör değerlendirmesi',
      PlayerPresidentInteractiveDecisionKind.managerReplacement =>
        'Teknik direktör seçimi',
      PlayerPresidentInteractiveDecisionKind.promise => 'Başkanlık vaadi',
      PlayerPresidentInteractiveDecisionKind.mediaStatement =>
        'Medya açıklaması',
      PlayerPresidentInteractiveDecisionKind.transferStrategy =>
        'Transfer stratejisi',
      PlayerPresidentInteractiveDecisionKind.ticketPricing =>
        'Bilet fiyatlandırma',
    };

String _signed(int value) => value > 0 ? '+$value' : '$value';

String _bps(int value) {
  final percent = value / 100;
  final decimals = value % 100 == 0 ? 0 : 2;
  return '%${percent.toStringAsFixed(decimals)}';
}

String _humanize(String value) {
  final spaced = value.replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  return spaced.replaceAll('_', ' ');
}
