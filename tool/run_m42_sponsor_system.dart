import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  const version = 1;
  final world = const FictionalWorldFactory().build();
  const system = SponsorSystemEngine();
  const codec = SponsorRuntimeSaveCodec();
  const policy = PresidentSponsorDecisionPolicy();
  const offerEngine = SponsorOfferEngine();

  PresidentManagementProfile profileFor(String clubId, int index) =>
      PresidentManagementProfile(
        presidentId: 'pres-$clubId',
        archetype: PresidentManagementArchetype.balanced,
        financialDiscipline: index.isEven ? 82 : 38,
        riskAppetite: index.isEven ? 32 : 82,
        transferAmbition: 60,
        youthOrientation: 60,
        managerPatience: 60,
      );

  final profiles = <String, PresidentManagementProfile>{};
  final fans = <String, FanState>{};
  final media = <String, MediaState>{};
  final positions = <String, int>{};
  for (var i = 0; i < world.clubs.length; i++) {
    final club = world.clubs[i];
    profiles[club.id] = profileFor(club.id, i);
    fans[club.id] = FanState.initial(club.id, trust: 45 + (i % 36));
    media[club.id] = MediaState(clubId: club.id, credibility: 50 + (i % 31));
    positions[club.id] = (i % 16) + 1;
  }

  final first = system.resolveSeason(
    seasonIndex: 0,
    clubs: world.clubs,
    leaguePositions: positions,
    presidentProfilesByClub: profiles,
    fanStatesByClub: fans,
    mediaStatesByClub: media,
    careerSeed: seed,
    simulationVersion: version,
  );
  if (first.contracts.length != world.clubs.length ||
      first.revenueByClub.length != world.clubs.length) {
    throw StateError('M42 did not resolve sponsor state for every club.');
  }

  final target = world.clubs.first;
  final offers = offerEngine.generateOffers(
    club: target,
    seasonIndex: 0,
    careerSeed: seed,
    simulationVersion: version,
  );
  final prudent = policy.choose(
    offers: offers,
    profile: PresidentManagementProfile(
      presidentId: 'prudent',
      archetype: PresidentManagementArchetype.prudentBuilder,
      financialDiscipline: 90,
      riskAppetite: 20,
      transferAmbition: 50,
      youthOrientation: 50,
      managerPatience: 70,
    ),
  );
  final bold = policy.choose(
    offers: offers,
    profile: PresidentManagementProfile(
      presidentId: 'bold',
      archetype: PresidentManagementArchetype.ambitiousSpender,
      financialDiscipline: 20,
      riskAppetite: 90,
      transferAmbition: 85,
      youthOrientation: 40,
      managerPatience: 35,
    ),
  );
  if (prudent.id == bold.id || prudent.termSeasons <= bold.termSeasons) {
    throw StateError('M42 president sponsor preferences did not diverge.');
  }

  final loaded = codec.decode(codec.encode(first.checkpoint));
  final nextPositions = <String, int>{
    for (var i = 0; i < world.clubs.length; i++)
      world.clubs[i].id: ((i + 3) % 16) + 1,
  };
  final direct = system.resolveSeason(
    seasonIndex: first.checkpoint.nextSeasonIndex,
    clubs: world.clubs,
    leaguePositions: nextPositions,
    presidentProfilesByClub: profiles,
    fanStatesByClub: fans,
    mediaStatesByClub: media,
    careerSeed: seed,
    simulationVersion: version,
    existingContracts: first.checkpoint.activeContracts,
    totalRevenuePaid: first.checkpoint.totalRevenuePaid,
  );
  final resumed = system.resolveSeason(
    seasonIndex: loaded.nextSeasonIndex,
    clubs: world.clubs,
    leaguePositions: nextPositions,
    presidentProfilesByClub: profiles,
    fanStatesByClub: fans,
    mediaStatesByClub: media,
    careerSeed: seed,
    simulationVersion: version,
    existingContracts: loaded.activeContracts,
    totalRevenuePaid: loaded.totalRevenuePaid,
  );
  if (direct.signature != resumed.signature) {
    throw StateError('M42 sponsor save/resume parity failed.');
  }

  final row = StandingRow(clubId: target.id);
  final report = SeasonReport(
    seasonIndex: 0,
    seed: seed,
    championClubId: target.id,
    table: [row],
    fixtures: const [],
    homeWins: 0,
    draws: 0,
    awayWins: 0,
    totalGoals: 0,
  );
  const economy = BasicEconomyEngine();
  final openings = economy.initialStates(
    clubs: [target],
    careerSeed: seed,
    simulationVersion: version,
  );
  final legacy = economy.simulateSeason(
    clubs: [target],
    players: const [],
    seasonReport: report,
    openingStates: openings,
  ).single;
  final realSponsorRevenue = first.revenueByClub[target.id]!;
  final sponsored = economy.simulateSeason(
    clubs: [target],
    players: const [],
    seasonReport: report,
    openingStates: openings,
    sponsorRevenueByClub: {target.id: realSponsorRevenue},
  ).single;
  if (sponsored.sponsorRevenue != realSponsorRevenue ||
      sponsored.sponsorRevenue == legacy.sponsorRevenue) {
    throw StateError('M42 sponsor revenue did not reach real economy.');
  }

  print('M42_SPONSOR target=${target.id}');
  print('M42_SPONSOR contracts=${first.contracts.length}');
  print('M42_SPONSOR prudent=${prudent.id}:${prudent.termSeasons}');
  print('M42_SPONSOR bold=${bold.id}:${bold.termSeasons}');
  print(
    'M42_SPONSOR targetRevenue=${realSponsorRevenue.millions.toStringAsFixed(2)}M '
    'legacy=${legacy.sponsorRevenue.millions.toStringAsFixed(2)}M',
  );
  print('M42_SPONSOR saveResumeMatch=${direct.signature == resumed.signature}');
  print('M42_SPONSOR PASS');
}
