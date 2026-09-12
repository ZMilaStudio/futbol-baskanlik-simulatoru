import '../core/money.dart';
import '../core/stable_hash.dart';
import '../election/president_management_profile.dart';
import '../fan/fan_state.dart';
import '../league/club.dart';
import '../media/media_state.dart';

enum SponsorBonusTarget {
  topHalf,
  topSix,
  topFour,
  champion,
}

extension SponsorBonusTargetRule on SponsorBonusTarget {
  int get maxPosition => switch (this) {
        SponsorBonusTarget.topHalf => 8,
        SponsorBonusTarget.topSix => 6,
        SponsorBonusTarget.topFour => 4,
        SponsorBonusTarget.champion => 1,
      };
}

class SponsorOffer {
  const SponsorOffer({
    required this.id,
    required this.sponsorName,
    required this.clubId,
    required this.annualGuaranteed,
    required this.performanceBonus,
    required this.termSeasons,
    required this.bonusTarget,
  });

  final String id;
  final String sponsorName;
  final String clubId;
  final Money annualGuaranteed;
  final Money performanceBonus;
  final int termSeasons;
  final SponsorBonusTarget bonusTarget;

  Money get maxAnnualRevenue => annualGuaranteed + performanceBonus;

  String get signature =>
      '$id:$sponsorName:$clubId:${annualGuaranteed.minorUnits}:'
      '${performanceBonus.minorUnits}:$termSeasons:${bonusTarget.name}';
}

class SponsorContract {
  const SponsorContract({
    required this.offer,
    required this.startSeasonIndex,
    required this.acceptedByPresidentId,
  });

  final SponsorOffer offer;
  final int startSeasonIndex;
  final String acceptedByPresidentId;

  int get endSeasonExclusive => startSeasonIndex + offer.termSeasons;

  bool isActiveAt(int seasonIndex) =>
      seasonIndex >= startSeasonIndex && seasonIndex < endSeasonExclusive;

  String get signature =>
      '${offer.signature}:start=$startSeasonIndex:end=$endSeasonExclusive:'
      'president=$acceptedByPresidentId';
}

class SponsorRuntimeCheckpoint {
  SponsorRuntimeCheckpoint({
    required this.nextSeasonIndex,
    required Iterable<SponsorContract> activeContracts,
    required this.totalRevenuePaid,
  }) : activeContracts = List.unmodifiable(activeContracts) {
    validate();
  }

  final int nextSeasonIndex;
  final List<SponsorContract> activeContracts;
  final Money totalRevenuePaid;

  void validate() {
    if (nextSeasonIndex < 0) {
      throw StateError('Sponsor next season index cannot be negative.');
    }
    if (totalRevenuePaid.isNegative) {
      throw StateError('Sponsor total revenue cannot be negative.');
    }
    final ids = <String>{};
    for (final contract in activeContracts) {
      if (!contract.isActiveAt(nextSeasonIndex)) {
        throw StateError(
          'Inactive sponsor contract retained for ${contract.offer.clubId}.',
        );
      }
      if (!ids.add(contract.offer.clubId)) {
        throw StateError(
          'Multiple active sponsor contracts for ${contract.offer.clubId}.',
        );
      }
    }
  }

  String get signature {
    final contracts = [...activeContracts]
      ..sort((a, b) => a.offer.clubId.compareTo(b.offer.clubId));
    return '$nextSeasonIndex|${totalRevenuePaid.minorUnits}|'
        '${contracts.map((contract) => contract.signature).join(';')}';
  }
}

class SponsorSeasonResolution {
  SponsorSeasonResolution({
    required this.seasonIndex,
    required Iterable<SponsorContract> contracts,
    required Map<String, Money> revenueByClub,
    required this.checkpoint,
  })  : contracts = List.unmodifiable(contracts),
        revenueByClub = Map.unmodifiable(revenueByClub);

  final int seasonIndex;
  final List<SponsorContract> contracts;
  final Map<String, Money> revenueByClub;
  final SponsorRuntimeCheckpoint checkpoint;

  Money get totalRevenue => revenueByClub.values.fold(
        Money.zero,
        (sum, value) => sum + value,
      );

  String get signature {
    final ids = revenueByClub.keys.toList()..sort();
    return '$seasonIndex|${contracts.map((c) => c.signature).join(';')}|'
        '${ids.map((id) => '$id:${revenueByClub[id]!.minorUnits}').join(';')}|'
        '${checkpoint.signature}';
  }
}

class SponsorOfferEngine {
  const SponsorOfferEngine();

  static const List<String> _names = [
    'Nova Enerji',
    'Mira Teknoloji',
    'Kuzey Finans',
    'Pera Lojistik',
    'Atlas Mobilite',
    'Luna Gida',
    'Vera Yapı',
    'Rota Dijital',
    'Ahenk Sigorta',
    'Doruk Telekom',
  ];

  List<SponsorOffer> generateOffers({
    required Club club,
    required int seasonIndex,
    required int careerSeed,
    required int simulationVersion,
    int fanTrust = 60,
    int mediaCredibility = 70,
  }) {
    final trust = fanTrust.clamp(0, 100).toInt();
    final credibility = mediaCredibility.clamp(0, 100).toInt();
    final contextMultiplierBps =
        (6800 + trust * 30 + credibility * 20).clamp(7000, 12000).toInt();
    final strengthDeltaHundredths =
        (((club.strength - 55) * 100).round()).clamp(0, 4000).toInt();
    final base = Money.fromUnits(3000000 + strengthDeltaHundredths * 2500)
        .scaleBasisPoints(contextMultiplierBps);

    final variants = <({
      int guaranteeBps,
      int bonusBps,
      int term,
      SponsorBonusTarget target,
      String label,
    })>[
      (
        guaranteeBps: 10500,
        bonusBps: 800,
        term: 3,
        target: SponsorBonusTarget.topHalf,
        label: 'stable',
      ),
      (
        guaranteeBps: 10000,
        bonusBps: 2200,
        term: 2,
        target: SponsorBonusTarget.topSix,
        label: 'balanced',
      ),
      (
        guaranteeBps: 9000,
        bonusBps: 5000,
        term: 1,
        target: SponsorBonusTarget.topFour,
        label: 'bold',
      ),
    ];

    return List.unmodifiable(
      List.generate(variants.length, (index) {
        final variant = variants[index];
        final hash = StableHash.combine32([
          careerSeed,
          simulationVersion,
          seasonIndex,
          StableHash.string32(club.id),
          StableHash.string32(variant.label),
        ]);
        final name = _names[hash.abs() % _names.length];
        return SponsorOffer(
          id: '${club.id}-s$seasonIndex-${variant.label}',
          sponsorName: name,
          clubId: club.id,
          annualGuaranteed: base.scaleBasisPoints(variant.guaranteeBps),
          performanceBonus: base.scaleBasisPoints(variant.bonusBps),
          termSeasons: variant.term,
          bonusTarget: variant.target,
        );
      }),
    );
  }
}

class PresidentSponsorDecisionPolicy {
  const PresidentSponsorDecisionPolicy();

  SponsorOffer choose({
    required List<SponsorOffer> offers,
    required PresidentManagementProfile profile,
  }) {
    if (offers.isEmpty) {
      throw ArgumentError.value(offers, 'offers', 'Must not be empty.');
    }
    SponsorOffer best = offers.first;
    var bestScore = _score(best, profile);
    for (final offer in offers.skip(1)) {
      final score = _score(offer, profile);
      if (score > bestScore ||
          (score == bestScore && offer.id.compareTo(best.id) < 0)) {
        best = offer;
        bestScore = score;
      }
    }
    return best;
  }

  int _score(SponsorOffer offer, PresidentManagementProfile profile) {
    final guaranteeWeight = 100 + profile.financialDiscipline;
    final bonusWeight = 45 + profile.riskAppetite;
    final durationWeight = profile.financialDiscipline - profile.riskAppetite;
    return offer.annualGuaranteed.minorUnits * guaranteeWeight +
        offer.performanceBonus.minorUnits * bonusWeight +
        offer.termSeasons * durationWeight * 1000000;
  }
}

class SponsorSystemEngine {
  const SponsorSystemEngine({
    this.offerEngine = const SponsorOfferEngine(),
    this.decisionPolicy = const PresidentSponsorDecisionPolicy(),
  });

  final SponsorOfferEngine offerEngine;
  final PresidentSponsorDecisionPolicy decisionPolicy;

  SponsorSeasonResolution resolveSeason({
    required int seasonIndex,
    required List<Club> clubs,
    required Map<String, int> leaguePositions,
    required Map<String, PresidentManagementProfile> presidentProfilesByClub,
    required int careerSeed,
    required int simulationVersion,
    Map<String, FanState> fanStatesByClub = const {},
    Map<String, MediaState> mediaStatesByClub = const {},
    Iterable<SponsorContract> existingContracts = const [],
    Money totalRevenuePaid = Money.zero,
  }) {
    final clubsSorted = [...clubs]..sort((a, b) => a.id.compareTo(b.id));
    final existingByClub = <String, SponsorContract>{};
    for (final contract in existingContracts) {
      if (contract.isActiveAt(seasonIndex)) {
        if (existingByClub.putIfAbsent(contract.offer.clubId, () => contract) !=
            contract) {
          throw StateError(
            'Multiple active sponsor contracts for ${contract.offer.clubId}.',
          );
        }
      }
    }

    final contracts = <SponsorContract>[];
    final revenueByClub = <String, Money>{};
    var seasonRevenue = Money.zero;

    for (final club in clubsSorted) {
      var contract = existingByClub[club.id];
      if (contract == null) {
        final profile = presidentProfilesByClub[club.id];
        if (profile == null) {
          throw StateError('Missing president sponsor profile for ${club.id}.');
        }
        final fanState = fanStatesByClub[club.id];
        if (fanState != null && fanState.clubId != club.id) {
          throw StateError('Fan sponsor context key mismatch for ${club.id}.');
        }
        final mediaState = mediaStatesByClub[club.id];
        if (mediaState != null && mediaState.clubId != club.id) {
          throw StateError('Media sponsor context key mismatch for ${club.id}.');
        }
        final offers = offerEngine.generateOffers(
          club: club,
          seasonIndex: seasonIndex,
          careerSeed: careerSeed,
          simulationVersion: simulationVersion,
          fanTrust: fanState?.overallTrust ?? 60,
          mediaCredibility: mediaState?.credibility ?? 70,
        );
        final accepted = decisionPolicy.choose(offers: offers, profile: profile);
        contract = SponsorContract(
          offer: accepted,
          startSeasonIndex: seasonIndex,
          acceptedByPresidentId: profile.presidentId,
        );
      }
      contracts.add(contract);

      var revenue = contract.offer.annualGuaranteed;
      final position = leaguePositions[club.id] ?? 16;
      if (position <= contract.offer.bonusTarget.maxPosition) {
        revenue += contract.offer.performanceBonus;
      }
      revenueByClub[club.id] = revenue;
      seasonRevenue += revenue;
    }

    final nextSeason = seasonIndex + 1;
    final activeNext = contracts
        .where((contract) => contract.isActiveAt(nextSeason))
        .toList(growable: false);
    final checkpoint = SponsorRuntimeCheckpoint(
      nextSeasonIndex: nextSeason,
      activeContracts: activeNext,
      totalRevenuePaid: totalRevenuePaid + seasonRevenue,
    );

    return SponsorSeasonResolution(
      seasonIndex: seasonIndex,
      contracts: contracts,
      revenueByClub: revenueByClub,
      checkpoint: checkpoint,
    );
  }
}
