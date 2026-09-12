import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const version = 1;
  const offerEngine = SponsorOfferEngine();
  const system = SponsorSystemEngine();
  const codec = SponsorRuntimeSaveCodec();
  final world = const FictionalWorldFactory().build();
  final club = world.clubs.first;

  PresidentManagementProfile profile({
    required String id,
    required int finance,
    required int risk,
  }) =>
      PresidentManagementProfile(
        presidentId: id,
        archetype: PresidentManagementArchetype.balanced,
        financialDiscipline: finance,
        riskAppetite: risk,
        transferAmbition: 60,
        youthOrientation: 60,
        managerPatience: 60,
      );

  test('M42 fan and media strength materially improve sponsor offers', () {
    final weak = offerEngine.generateOffers(
      club: club,
      seasonIndex: 0,
      careerSeed: seed,
      simulationVersion: version,
      fanTrust: 20,
      mediaCredibility: 30,
    );
    final strong = offerEngine.generateOffers(
      club: club,
      seasonIndex: 0,
      careerSeed: seed,
      simulationVersion: version,
      fanTrust: 90,
      mediaCredibility: 90,
    );

    expect(strong.length, weak.length);
    for (var i = 0; i < weak.length; i++) {
      expect(strong[i].annualGuaranteed, greaterThan(weak[i].annualGuaranteed));
      expect(strong[i].performanceBonus, greaterThan(weak[i].performanceBonus));
    }
  });

  test('M42 president finance and risk profiles prefer different contracts', () {
    final offers = offerEngine.generateOffers(
      club: club,
      seasonIndex: 0,
      careerSeed: seed,
      simulationVersion: version,
    );
    const policy = PresidentSponsorDecisionPolicy();
    final prudent = policy.choose(
      offers: offers,
      profile: profile(id: 'prudent', finance: 90, risk: 20),
    );
    final bold = policy.choose(
      offers: offers,
      profile: profile(id: 'bold', finance: 20, risk: 90),
    );

    expect(prudent.termSeasons, greaterThan(bold.termSeasons));
    expect(prudent.id, isNot(bold.id));
  });

  test('M42 multi-year contract survives president profile change', () {
    final first = system.resolveSeason(
      seasonIndex: 0,
      clubs: [club],
      leaguePositions: {club.id: 5},
      presidentProfilesByClub: {
        club.id: profile(id: 'p-old', finance: 90, risk: 20),
      },
      careerSeed: seed,
      simulationVersion: version,
    );
    final contract = first.contracts.single;
    expect(contract.offer.termSeasons, greaterThan(1));

    final second = system.resolveSeason(
      seasonIndex: 1,
      clubs: [club],
      leaguePositions: {club.id: 5},
      presidentProfilesByClub: {
        club.id: profile(id: 'p-new', finance: 20, risk: 90),
      },
      careerSeed: seed,
      simulationVersion: version,
      existingContracts: first.checkpoint.activeContracts,
      totalRevenuePaid: first.checkpoint.totalRevenuePaid,
    );

    expect(second.contracts.single.offer.id, contract.offer.id);
    expect(second.contracts.single.acceptedByPresidentId, 'p-old');
  });

  test('M42 sponsor checkpoint round-trips and resumes deterministically', () {
    final first = system.resolveSeason(
      seasonIndex: 0,
      clubs: [club],
      leaguePositions: {club.id: 4},
      presidentProfilesByClub: {
        club.id: profile(id: 'p1', finance: 90, risk: 20),
      },
      careerSeed: seed,
      simulationVersion: version,
    );
    final loaded = codec.decode(codec.encode(first.checkpoint));
    expect(loaded.signature, first.checkpoint.signature);

    final direct = system.resolveSeason(
      seasonIndex: first.checkpoint.nextSeasonIndex,
      clubs: [club],
      leaguePositions: {club.id: 7},
      presidentProfilesByClub: {
        club.id: profile(id: 'p1', finance: 90, risk: 20),
      },
      careerSeed: seed,
      simulationVersion: version,
      existingContracts: first.checkpoint.activeContracts,
      totalRevenuePaid: first.checkpoint.totalRevenuePaid,
    );
    final resumed = system.resolveSeason(
      seasonIndex: loaded.nextSeasonIndex,
      clubs: [club],
      leaguePositions: {club.id: 7},
      presidentProfilesByClub: {
        club.id: profile(id: 'p1', finance: 90, risk: 20),
      },
      careerSeed: seed,
      simulationVersion: version,
      existingContracts: loaded.activeContracts,
      totalRevenuePaid: loaded.totalRevenuePaid,
    );

    expect(resumed.signature, direct.signature);
  });

  test('M42 migrates synthetic v0 sponsor save to v1', () {
    final first = system.resolveSeason(
      seasonIndex: 0,
      clubs: [club],
      leaguePositions: {club.id: 4},
      presidentProfilesByClub: {
        club.id: profile(id: 'p1', finance: 90, risk: 20),
      },
      careerSeed: seed,
      simulationVersion: version,
    );
    final contract = first.checkpoint.activeContracts.single;
    final payload = <String, Object?>{
      'season': first.checkpoint.nextSeasonIndex,
      'totalPaid': first.checkpoint.totalRevenuePaid.minorUnits,
      'contracts': [
        {
          'id': contract.offer.id,
          'sponsorName': contract.offer.sponsorName,
          'clubId': contract.offer.clubId,
          'annualGuaranteedMinorUnits': contract.offer.annualGuaranteed.minorUnits,
          'performanceBonusMinorUnits': contract.offer.performanceBonus.minorUnits,
          'termSeasons': contract.offer.termSeasons,
          'bonusTarget': contract.offer.bonusTarget.name,
          'startSeasonIndex': contract.startSeasonIndex,
          'acceptedByPresidentId': contract.acceptedByPresidentId,
        },
      ],
    };
    final encoded = SaveChecksum.canonicalJson({
      'format': SponsorRuntimeSaveCodec.format,
      'saveVersion': 0,
      'payload': payload,
      'checksum': SaveChecksum.forPayload(saveVersion: 0, payload: payload),
    });

    final migrated = codec.decode(encoded);
    expect(migrated.signature, first.checkpoint.signature);
  });

  test('M42 accepted sponsor revenue flows into real club economy', () {
    final resolution = system.resolveSeason(
      seasonIndex: 0,
      clubs: [club],
      leaguePositions: {club.id: 1},
      presidentProfilesByClub: {
        club.id: profile(id: 'p1', finance: 60, risk: 60),
      },
      fanStatesByClub: {club.id: FanState.initial(club.id, trust: 80)},
      mediaStatesByClub: {club.id: MediaState(clubId: club.id, credibility: 85)},
      careerSeed: seed,
      simulationVersion: version,
    );
    const economy = BasicEconomyEngine();
    final openings = economy.initialStates(
      clubs: [club],
      careerSeed: seed,
      simulationVersion: version,
    );
    final row = StandingRow(clubId: club.id);
    final report = SeasonReport(
      seasonIndex: 0,
      seed: seed,
      championClubId: club.id,
      table: [row],
      fixtures: const [],
      homeWins: 0,
      draws: 0,
      awayWins: 0,
      totalGoals: 0,
    );
    final legacy = economy.simulateSeason(
      clubs: [club],
      players: const [],
      seasonReport: report,
      openingStates: openings,
    ).single;
    final sponsored = economy.simulateSeason(
      clubs: [club],
      players: const [],
      seasonReport: report,
      openingStates: openings,
      sponsorRevenueByClub: resolution.revenueByClub,
    ).single;

    expect(sponsored.sponsorRevenue, resolution.revenueByClub[club.id]);
    expect(sponsored.sponsorRevenue, isNot(legacy.sponsorRevenue));
    expect(
      sponsored.closingCash - legacy.closingCash,
      sponsored.sponsorRevenue - legacy.sponsorRevenue,
    );
  });
}
