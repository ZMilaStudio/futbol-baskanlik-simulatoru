import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_facility_control.dart';
import 'package:futbol_baskanlik_m0/player_president_sponsor_control.dart';

void main(List<String> args) {
  final seed = args.isEmpty ? 20260903 : int.parse(args.first);
  final config = SimulationConfig(careerSeed: seed);
  final world = const FictionalWorldFactory().build();
  const controlled = 't1_02';
  const m49 = PlayerPresidentFacilityControlCareerEngine();
  const codec = PlayerPresidentSponsorControlSaveCodec();

  final baseline = m49.simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 2,
  );
  final neutral = const PlayerPresidentSponsorControlCareerEngine()
      .simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 2,
  );
  final neutralM49Parity =
      neutral.checkpoint.control.signature == baseline.checkpoint.signature &&
          neutral.source.signature == baseline.signature;

  const engine = PlayerPresidentSponsorControlCareerEngine(
    sponsorProvider: _BoldProvider(),
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

  final firstDecision = direct.sponsorDecisions.first;
  final playerBoundary = direct.boundaries.first.source.sponsor;
  final neutralByClub = {
    for (final contract in neutral.boundaries.first.source.sponsor.contracts)
      contract.offer.clubId: contract.signature,
  };
  final playerByClub = {
    for (final contract in playerBoundary.contracts)
      contract.offer.clubId: contract.signature,
  };
  final aiParityCount = world.clubs
      .where((club) => club.id != controlled)
      .where((club) => playerByClub[club.id] == neutralByClub[club.id])
      .length;
  final finance = playerBoundary.report.sourceReport.advancedTransferReport
      .worldReport.seasons.single.finances
      .firstWhere((item) => item.clubId == controlled);
  final sponsorRevenueWired =
      finance.sponsorRevenue == playerBoundary.revenueByClub[controlled];

  final stable = const PlayerPresidentSponsorControlCareerEngine(
    sponsorProvider: _StableProvider(),
  ).simulateWithCheckpoint(
    clubs: world.clubs,
    leagues: world.leagues,
    config: config,
    controlledClubId: controlled,
    seasonCount: 1,
    hasFutureSeasonAfterReport: true,
  );
  final stableEncoded = codec.encode(stable.checkpoint);
  final stableLoaded = codec.decode(stableEncoded);
  final controlledContractPersisted = stableLoaded
      .control.runtime.runtime.sponsor.activeContracts
      .any((contract) => contract.offer.clubId == controlled &&
          contract.offer.id.endsWith('-stable'));

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
  final finalCheckpointMatch =
      codec.encode(second.checkpoint) == codec.encode(direct.checkpoint);
  final boundaryMatch =
      [...first.boundaries, ...second.boundaries]
              .map((item) => item.signature)
              .join('||') ==
          direct.boundaries.map((item) => item.signature).join('||');
  final decisionMatch =
      [...first.sponsorDecisions, ...second.sponsorDecisions]
              .map((item) => item.signature)
              .join('||') ==
          direct.sponsorDecisions.map((item) => item.signature).join('||');
  final controlledClubPersisted = loaded.controlledClubId == controlled &&
      second.checkpoint.controlledClubId == controlled;
  final playerSponsorWindows = direct.sponsorDecisions.length;

  if (!neutralM49Parity) {
    throw StateError('M50 no-provider path must preserve M49 exactly.');
  }
  if (firstDecision.clubId != controlled ||
      !firstDecision.selectedOffer.id.endsWith('-bold')) {
    throw StateError('M50 player must select the requested controlled-club offer.');
  }
  if (aiParityCount != world.clubs.length - 1) {
    throw StateError('M50 must preserve AI sponsor choices for the other 47 clubs.');
  }
  if (!sponsorRevenueWired) {
    throw StateError('M50 selected sponsor revenue must reach the real economy row.');
  }
  if (!controlledContractPersisted || !controlledClubPersisted) {
    throw StateError('M50 controlled sponsor state must persist through save/load.');
  }
  if (!finalCheckpointMatch || !boundaryMatch || !decisionMatch) {
    throw StateError('M50 save/resume parity failed.');
  }
  if (playerSponsorWindows != 4) {
    throw StateError('M50 one-season bold contracts must create four player windows.');
  }

  print('M50_PLAYER_SPONSOR_CONTROL_PASS');
  print('seed=$seed');
  print('controlledClub=$controlled');
  print('aiParityCount=$aiParityCount');
  print('playerSponsorWindows=$playerSponsorWindows');
  print('aiChoice=${firstDecision.aiChoice.id}');
  print('playerChoice=${firstDecision.selectedOffer.id}');
  print('sponsorRevenue=${finance.sponsorRevenue.minorUnits}');
  print('neutralM49Parity=$neutralM49Parity');
  print('sponsorRevenueWired=$sponsorRevenueWired');
  print('controlledContractPersisted=$controlledContractPersisted');
  print('controlledClubPersisted=$controlledClubPersisted');
  print('finalCheckpointMatch=$finalCheckpointMatch');
  print('boundaryMatch=$boundaryMatch');
  print('decisionMatch=$decisionMatch');
  print('saveBytes=${encoded.length}');
}

class _BoldProvider extends PlayerSponsorDecisionProvider {
  const _BoldProvider();

  @override
  PlayerSponsorOfferChoice choose(PlayerSponsorDecisionContext context) {
    final offer = context.offers.firstWhere((item) => item.id.endsWith('-bold'));
    return PlayerSponsorOfferChoice(offerId: offer.id);
  }
}

class _StableProvider extends PlayerSponsorDecisionProvider {
  const _StableProvider();

  @override
  PlayerSponsorOfferChoice choose(PlayerSponsorDecisionContext context) {
    final offer = context.offers.firstWhere((item) => item.id.endsWith('-stable'));
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
