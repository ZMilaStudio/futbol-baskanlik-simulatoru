import 'dart:convert';

import '../core/money.dart';
import '../core/simulation_config.dart';
import '../crisis/facility_sponsor_crisis_runtime_composition.dart';
import '../crisis/player_president_facility_control.dart';
import '../election/president_management_profile.dart';
import '../fan/fan_state.dart';
import '../league/club.dart';
import '../media/media_state.dart';
import '../save/save_checksum.dart';
import '../save/save_load_exception.dart';
import '../world/world_league.dart';
import 'sponsor_system.dart';

class PlayerSponsorOfferChoice {
  const PlayerSponsorOfferChoice({required this.offerId});

  final String offerId;

  void validate() {
    if (offerId.isEmpty) {
      throw ArgumentError('offerId cannot be empty.');
    }
  }

  String get signature => offerId;
}

class PlayerSponsorDecisionContext {
  PlayerSponsorDecisionContext({
    required this.seasonIndex,
    required this.clubId,
    required this.presidentId,
    required this.managementProfile,
    required this.leaguePosition,
    required this.fanTrust,
    required this.mediaCredibility,
    required Iterable<SponsorOffer> offers,
    required this.aiChoice,
  }) : offers = List.unmodifiable(offers);

  final int seasonIndex;
  final String clubId;
  final String presidentId;
  final PresidentManagementProfile managementProfile;
  final int leaguePosition;
  final int fanTrust;
  final int mediaCredibility;
  final List<SponsorOffer> offers;
  final SponsorOffer aiChoice;

  String get signature =>
      '$seasonIndex:$clubId:$presidentId:position=$leaguePosition:'
      'fan=$fanTrust:media=$mediaCredibility:ai=${aiChoice.id}:'
      'offers=${offers.map((offer) => offer.signature).join('|')}';
}

abstract class PlayerSponsorDecisionProvider {
  const PlayerSponsorDecisionProvider();

  PlayerSponsorOfferChoice choose(PlayerSponsorDecisionContext context);
}

class PlayerPresidentSponsorRuntimeDecision {
  const PlayerPresidentSponsorRuntimeDecision({
    required this.context,
    required this.choice,
    required this.selectedOffer,
  });

  final PlayerSponsorDecisionContext context;
  final PlayerSponsorOfferChoice choice;
  final SponsorOffer selectedOffer;

  int get seasonIndex => context.seasonIndex;
  String get clubId => context.clubId;
  String get presidentId => context.presidentId;
  SponsorOffer get aiChoice => context.aiChoice;
  bool get changedFromAi => selectedOffer.id != aiChoice.id;

  String get signature =>
      '${context.signature}:choice=${choice.signature}:'
      'selected=${selectedOffer.signature}';
}

class PlayerPresidentSponsorControlCheckpoint {
  PlayerPresidentSponsorControlCheckpoint({required this.control}) {
    validate();
  }

  final PlayerPresidentFacilityControlCheckpoint control;

  int get nextSeasonIndex => control.nextSeasonIndex;
  int get completedSeasons => control.completedSeasons;
  String get controlledClubId => control.controlledClubId;

  void validate() => control.validate();

  String get signature => 'sponsor-control:${control.signature}';
}

class PlayerPresidentSponsorControlSaveCodec {
  const PlayerPresidentSponsorControlSaveCodec({
    this.controlCodec = const PlayerPresidentFacilityControlSaveCodec(),
  });

  static const String format = 'zmila-fbs-player-president-sponsor-control';
  static const int currentSaveVersion = 1;

  final PlayerPresidentFacilityControlSaveCodec controlCodec;

  String encode(PlayerPresidentSponsorControlCheckpoint checkpoint) {
    checkpoint.validate();
    final payload = <String, Object?>{
      'controlSave': controlCodec.encode(checkpoint.control),
    };
    final checksum = SaveChecksum.forPayload(
      saveVersion: currentSaveVersion,
      payload: payload,
    );
    return SaveChecksum.canonicalJson({
      'format': format,
      'saveVersion': currentSaveVersion,
      'payload': payload,
      'checksum': checksum,
    });
  }

  PlayerPresidentSponsorControlCheckpoint decode(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.malformedJson,
        'Player-president sponsor save is not valid JSON: ${error.message}',
      );
    }
    if (decoded is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Player-president sponsor save envelope must be a map.',
      );
    }
    final envelope = Map<String, Object?>.from(decoded);
    if (envelope['format'] != format) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidEnvelope,
        'Unknown player-president sponsor save format.',
      );
    }
    final version = envelope['saveVersion'];
    if (version is! int || version < 0 || version > currentSaveVersion) {
      throw SaveLoadException(
        SaveLoadFailure.unsupportedVersion,
        'Unsupported player-president sponsor save version $version.',
      );
    }
    final payload = envelope['payload'];
    final checksum = envelope['checksum'];
    if (checksum is! String ||
        checksum != SaveChecksum.forPayload(saveVersion: version, payload: payload)) {
      throw const SaveLoadException(
        SaveLoadFailure.checksumMismatch,
        'Player-president sponsor save checksum mismatch.',
      );
    }
    if (version != 1 || payload is! Map) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Player-president sponsor save payload is invalid.',
      );
    }
    final map = Map<String, Object?>.from(payload);
    final controlSave = map['controlSave'];
    if (controlSave is! String) {
      throw const SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Player-president sponsor control payload is invalid.',
      );
    }
    try {
      return PlayerPresidentSponsorControlCheckpoint(
        control: controlCodec.decode(controlSave),
      );
    } on SaveLoadException {
      rethrow;
    } catch (error) {
      throw SaveLoadException(
        SaveLoadFailure.invalidPayload,
        'Invalid player-president sponsor payload: $error',
      );
    }
  }
}

class PlayerPresidentSponsorControlCareerResult {
  PlayerPresidentSponsorControlCareerResult({
    required this.checkpoint,
    required this.source,
    required Iterable<PlayerPresidentSponsorRuntimeDecision> sponsorDecisions,
  }) : sponsorDecisions = List.unmodifiable(sponsorDecisions);

  final PlayerPresidentSponsorControlCheckpoint checkpoint;
  final PlayerPresidentFacilityControlCareerResult source;
  final List<PlayerPresidentSponsorRuntimeDecision> sponsorDecisions;

  List<PlayerPresidentFacilityControlSeasonBoundary> get boundaries =>
      source.boundaries;

  String get signature =>
      'sponsor=${sponsorDecisions.map((item) => item.signature).join('||')}:'
      'source=${source.signature}:final=${checkpoint.signature}';
}

/// M50 adds explicit player control over sponsor selection for the controlled
/// club while preserving the exact M49 path everywhere else.
///
/// A player decision is requested only when the controlled club needs a new
/// sponsor contract. Active multi-season contracts remain binding. The player
/// chooses one of the exact deterministic offers already generated by M42;
/// all other clubs continue to use PresidentSponsorDecisionPolicy unchanged.
class PlayerPresidentSponsorControlCareerEngine {
  const PlayerPresidentSponsorControlCareerEngine({
    this.sponsorProvider,
    this.facilityProvider,
    this.offerEngine = const SponsorOfferEngine(),
    this.aiSponsorPolicy = const PresidentSponsorDecisionPolicy(),
  });

  final PlayerSponsorDecisionProvider? sponsorProvider;
  final PlayerFacilityInvestmentDecisionProvider? facilityProvider;
  final SponsorOfferEngine offerEngine;
  final PresidentSponsorDecisionPolicy aiSponsorPolicy;

  PlayerPresidentSponsorControlCareerResult simulateWithCheckpoint({
    required List<Club> clubs,
    required List<WorldLeague> leagues,
    required SimulationConfig config,
    required String controlledClubId,
    int seasonCount = 20,
    int electionInterval = 4,
    bool hasFutureSeasonAfterReport = false,
  }) {
    final decisions = <PlayerPresidentSponsorRuntimeDecision>[];
    final engine = _sourceEngine(
      controlledClubId: controlledClubId,
      decisions: decisions,
    );
    final source = engine.simulateWithCheckpoint(
      clubs: clubs,
      leagues: leagues,
      config: config,
      controlledClubId: controlledClubId,
      seasonCount: seasonCount,
      electionInterval: electionInterval,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
    );
    return PlayerPresidentSponsorControlCareerResult(
      checkpoint: PlayerPresidentSponsorControlCheckpoint(
        control: source.checkpoint,
      ),
      source: source,
      sponsorDecisions: decisions,
    );
  }

  PlayerPresidentSponsorControlCareerResult resume({
    required PlayerPresidentSponsorControlCheckpoint checkpoint,
    required int seasonCount,
    bool hasFutureSeasonAfterReport = false,
  }) {
    checkpoint.validate();
    final decisions = <PlayerPresidentSponsorRuntimeDecision>[];
    final engine = _sourceEngine(
      controlledClubId: checkpoint.controlledClubId,
      decisions: decisions,
    );
    final source = engine.resume(
      checkpoint: checkpoint.control,
      seasonCount: seasonCount,
      hasFutureSeasonAfterReport: hasFutureSeasonAfterReport,
    );
    return PlayerPresidentSponsorControlCareerResult(
      checkpoint: PlayerPresidentSponsorControlCheckpoint(
        control: source.checkpoint,
      ),
      source: source,
      sponsorDecisions: decisions,
    );
  }

  PlayerPresidentFacilityControlCareerEngine _sourceEngine({
    required String controlledClubId,
    required List<PlayerPresidentSponsorRuntimeDecision> decisions,
  }) {
    final SponsorSystemEngine sponsorSystem;
    if (sponsorProvider == null) {
      sponsorSystem = SponsorSystemEngine(
        offerEngine: offerEngine,
        decisionPolicy: aiSponsorPolicy,
      );
    } else {
      sponsorSystem = _PlayerPresidentSponsorSystemEngine(
        controlledClubId: controlledClubId,
        provider: sponsorProvider!,
        decisions: decisions,
        offerEngine: offerEngine,
        decisionPolicy: aiSponsorPolicy,
      );
    }
    return PlayerPresidentFacilityControlCareerEngine(
      runtime: FacilitySponsorCrisisRuntimeCareerEngine(
        sponsorSystem: sponsorSystem,
      ),
      control: PlayerPresidentFacilityControlRuntimeEngine(
        provider: facilityProvider,
      ),
    );
  }
}

class _PlayerPresidentSponsorSystemEngine extends SponsorSystemEngine {
  _PlayerPresidentSponsorSystemEngine({
    required this.controlledClubId,
    required this.provider,
    required this.decisions,
    required super.offerEngine,
    required super.decisionPolicy,
  });

  final String controlledClubId;
  final PlayerSponsorDecisionProvider provider;
  final List<PlayerPresidentSponsorRuntimeDecision> decisions;

  @override
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
    final existing = existingContracts.toList(growable: false);
    final baseline = super.resolveSeason(
      seasonIndex: seasonIndex,
      clubs: clubs,
      leaguePositions: leaguePositions,
      presidentProfilesByClub: presidentProfilesByClub,
      careerSeed: careerSeed,
      simulationVersion: simulationVersion,
      fanStatesByClub: fanStatesByClub,
      mediaStatesByClub: mediaStatesByClub,
      existingContracts: existing,
      totalRevenuePaid: totalRevenuePaid,
    );

    final controlledClub =
        clubs.where((club) => club.id == controlledClubId).firstOrNull;
    if (controlledClub == null) {
      return baseline;
    }
    final hasActiveContract = existing.any(
      (contract) =>
          contract.offer.clubId == controlledClubId &&
          contract.isActiveAt(seasonIndex),
    );
    if (hasActiveContract) {
      return baseline;
    }

    final profile = presidentProfilesByClub[controlledClubId];
    if (profile == null) {
      throw StateError(
        'Missing president sponsor profile for $controlledClubId.',
      );
    }
    final fanState = fanStatesByClub[controlledClubId];
    final mediaState = mediaStatesByClub[controlledClubId];
    final offers = offerEngine.generateOffers(
      club: controlledClub,
      seasonIndex: seasonIndex,
      careerSeed: careerSeed,
      simulationVersion: simulationVersion,
      fanTrust: fanState?.overallTrust ?? 60,
      mediaCredibility: mediaState?.credibility ?? 70,
    );
    final aiChoice = decisionPolicy.choose(offers: offers, profile: profile);
    final context = PlayerSponsorDecisionContext(
      seasonIndex: seasonIndex,
      clubId: controlledClubId,
      presidentId: profile.presidentId,
      managementProfile: profile,
      leaguePosition: leaguePositions[controlledClubId] ?? 16,
      fanTrust: fanState?.overallTrust ?? 60,
      mediaCredibility: mediaState?.credibility ?? 70,
      offers: offers,
      aiChoice: aiChoice,
    );
    final choice = provider.choose(context)..validate();
    final selectedMatches =
        offers.where((offer) => offer.id == choice.offerId).toList(growable: false);
    if (selectedMatches.length != 1) {
      throw ArgumentError.value(
        choice.offerId,
        'offerId',
        'Player sponsor choice must select one generated offer.',
      );
    }
    final selected = selectedMatches.single;
    final contract = SponsorContract(
      offer: selected,
      startSeasonIndex: seasonIndex,
      acceptedByPresidentId: profile.presidentId,
    );

    var revenue = selected.annualGuaranteed;
    final position = leaguePositions[controlledClubId] ?? 16;
    if (position <= selected.bonusTarget.maxPosition) {
      revenue += selected.performanceBonus;
    }
    final baselineRevenue = baseline.revenueByClub[controlledClubId];
    if (baselineRevenue == null) {
      throw StateError(
        'Missing baseline sponsor revenue for $controlledClubId.',
      );
    }

    final contracts = baseline.contracts
        .map((item) => item.offer.clubId == controlledClubId ? contract : item)
        .toList(growable: false);
    final revenueByClub = Map<String, Money>.from(baseline.revenueByClub)
      ..[controlledClubId] = revenue;
    final nextSeason = seasonIndex + 1;
    final activeNext = baseline.checkpoint.activeContracts
        .where((item) => item.offer.clubId != controlledClubId)
        .toList(growable: true);
    if (contract.isActiveAt(nextSeason)) {
      activeNext.add(contract);
    }
    final checkpoint = SponsorRuntimeCheckpoint(
      nextSeasonIndex: baseline.checkpoint.nextSeasonIndex,
      activeContracts: activeNext,
      totalRevenuePaid:
          baseline.checkpoint.totalRevenuePaid + revenue - baselineRevenue,
    );
    decisions.add(
      PlayerPresidentSponsorRuntimeDecision(
        context: context,
        choice: choice,
        selectedOffer: selected,
      ),
    );
    return SponsorSeasonResolution(
      seasonIndex: seasonIndex,
      contracts: contracts,
      revenueByClub: revenueByClub,
      checkpoint: checkpoint,
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
