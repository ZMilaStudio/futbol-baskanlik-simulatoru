import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const config = SimulationConfig(careerSeed: seed);
  const controlled = 't1_02';
  const m49 = PlayerPresidentFacilityControlCareerEngine();
  const codec = PlayerPresidentSponsorControlSaveCodec();

  test('M50 without a sponsor provider preserves M49 exactly', () {
    final world = const FictionalWorldFactory().build();
    final baseline = m49.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 3,
    );
    final player = const PlayerPresidentSponsorControlCareerEngine()
        .simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 3,
    );

    expect(player.checkpoint.control.signature, baseline.checkpoint.signature);
    expect(player.source.signature, baseline.signature);
    expect(player.sponsorDecisions, isEmpty);
  });

  test('M50 sponsor choice overrides only the controlled club', () {
    final world = const FictionalWorldFactory().build();
    final baseline = m49.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 1,
    );
    final player = const PlayerPresidentSponsorControlCareerEngine(
      sponsorProvider: _NonAiProvider(),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 1,
    );

    expect(player.sponsorDecisions, hasLength(1));
    final decision = player.sponsorDecisions.single;
    expect(decision.clubId, controlled);
    expect(decision.changedFromAi, isTrue);

    final baselineByClub = {
      for (final contract in baseline.boundaries.single.source.sponsor.contracts)
        contract.offer.clubId: contract.signature,
    };
    final playerByClub = {
      for (final contract in player.boundaries.single.source.sponsor.contracts)
        contract.offer.clubId: contract.signature,
    };
    expect(
      playerByClub[controlled],
      contains(decision.selectedOffer.signature),
    );
    for (final club in world.clubs.where((club) => club.id != controlled)) {
      expect(playerByClub[club.id], baselineByClub[club.id]);
    }
  });

  test('M50 selected sponsor terms drive the real economy row', () {
    final world = const FictionalWorldFactory().build();
    final stable = const PlayerPresidentSponsorControlCareerEngine(
      sponsorProvider: _LabelProvider('stable'),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 1,
    );
    final bold = const PlayerPresidentSponsorControlCareerEngine(
      sponsorProvider: _LabelProvider('bold'),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 1,
    );

    final stableDecision = stable.sponsorDecisions.single;
    final boldDecision = bold.sponsorDecisions.single;
    expect(stableDecision.selectedOffer.termSeasons, 3);
    expect(boldDecision.selectedOffer.termSeasons, 1);

    final stableBoundary = stable.boundaries.single.source.sponsor;
    final boldBoundary = bold.boundaries.single.source.sponsor;
    final stableFinance = stableBoundary.report.sourceReport.advancedTransferReport
        .worldReport.seasons.single.finances
        .firstWhere((item) => item.clubId == controlled);
    final boldFinance = boldBoundary.report.sourceReport.advancedTransferReport
        .worldReport.seasons.single.finances
        .firstWhere((item) => item.clubId == controlled);

    expect(
      stableFinance.sponsorRevenue,
      stableBoundary.revenueByClub[controlled],
    );
    expect(
      boldFinance.sponsorRevenue,
      boldBoundary.revenueByClub[controlled],
    );
    expect(stableFinance.sponsorRevenue, isNot(boldFinance.sponsorRevenue));
  });

  test('M50 active multi-year player contract is not reselected', () {
    final world = const FictionalWorldFactory().build();
    final result = const PlayerPresidentSponsorControlCareerEngine(
      sponsorProvider: _LabelProvider('stable'),
    ).simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 3,
    );

    expect(result.sponsorDecisions, hasLength(1));
    final signatures = result.boundaries
        .map(
          (boundary) => boundary.source.sponsor.contracts
              .firstWhere((item) => item.offer.clubId == controlled)
              .signature,
        )
        .toList();
    expect(signatures.toSet(), hasLength(1));
  });

  test('M50 save round trip and 2 plus 2 resume match four seasons', () {
    final world = const FictionalWorldFactory().build();
    const engine = PlayerPresidentSponsorControlCareerEngine(
      sponsorProvider: _LabelProvider('bold'),
      facilityProvider: _AlternatingFacilityProvider(),
    );
    final direct = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 4,
      electionInterval: 2,
    );
    final first = engine.simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlled,
      seasonCount: 2,
      electionInterval: 2,
      hasFutureSeasonAfterReport: true,
    );
    final encoded = codec.encode(first.checkpoint);
    final loaded = codec.decode(encoded);
    final second = engine.resume(
      checkpoint: loaded,
      seasonCount: 2,
    );

    expect(loaded.controlledClubId, controlled);
    expect(codec.encode(loaded), encoded);
    expect(codec.encode(second.checkpoint), codec.encode(direct.checkpoint));
    expect(
      [...first.boundaries, ...second.boundaries]
          .map((item) => item.signature)
          .toList(),
      direct.boundaries.map((item) => item.signature).toList(),
    );
    expect(
      [...first.sponsorDecisions, ...second.sponsorDecisions]
          .map((item) => item.signature)
          .toList(),
      direct.sponsorDecisions.map((item) => item.signature).toList(),
    );
  });
}

class _NonAiProvider extends PlayerSponsorDecisionProvider {
  const _NonAiProvider();

  @override
  PlayerSponsorOfferChoice choose(PlayerSponsorDecisionContext context) {
    final alternative = context.offers.firstWhere(
      (offer) => offer.id != context.aiChoice.id,
    );
    return PlayerSponsorOfferChoice(offerId: alternative.id);
  }
}

class _LabelProvider extends PlayerSponsorDecisionProvider {
  const _LabelProvider(this.label);

  final String label;

  @override
  PlayerSponsorOfferChoice choose(PlayerSponsorDecisionContext context) {
    final offer = context.offers.firstWhere(
      (item) => item.id.endsWith('-$label'),
    );
    return PlayerSponsorOfferChoice(offerId: offer.id);
  }
}

class _AlternatingFacilityProvider
    extends PlayerFacilityInvestmentDecisionProvider {
  const _AlternatingFacilityProvider();

  @override
  PlayerFacilityInvestmentChoice choose(PlayerFacilityInvestmentContext context) {
    if (context.seasonIndex.isEven) {
      return const PlayerFacilityInvestmentChoice(stadiumUpgrades: 1);
    }
    return const PlayerFacilityInvestmentChoice(trainingGroundUpgrades: 1);
  }
}
