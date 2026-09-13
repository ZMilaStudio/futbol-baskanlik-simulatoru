import 'dart:math' as math;

import '../election/player_president_tenure_control_gate.dart';
import '../election/president_management_profile.dart';
import '../fan/fan_state.dart';
import '../league/club.dart';
import 'stadium_facility.dart';

enum MatchdayTicketPriceTier {
  supporterFriendly,
  balanced,
  premium,
}

class MatchdayTicketPricingChoice {
  const MatchdayTicketPricingChoice(this.tier);

  final MatchdayTicketPriceTier tier;

  String get signature => tier.name;
}

class MatchdayTicketPricingOutcome {
  const MatchdayTicketPricingOutcome({
    required this.tier,
    required this.base,
    required this.demandMultiplierBps,
    required this.priceMultiplierBps,
    required this.adjustedDemand,
    required this.attendance,
    required this.occupancyBps,
    required this.ticketYieldBps,
    required this.revenueMultiplierBps,
  });

  final MatchdayTicketPriceTier tier;
  final StadiumAttendanceProfile base;
  final int demandMultiplierBps;
  final int priceMultiplierBps;
  final int adjustedDemand;
  final int attendance;
  final int occupancyBps;
  final int ticketYieldBps;
  final int revenueMultiplierBps;

  bool get preservesLegacyExactly =>
      tier == MatchdayTicketPriceTier.balanced &&
      adjustedDemand == base.demand &&
      attendance == base.attendance &&
      occupancyBps == base.occupancyBps &&
      ticketYieldBps == base.ticketYieldBps &&
      revenueMultiplierBps == base.revenueMultiplierBps;

  String get signature =>
      '${tier.name}:demand=$adjustedDemand:attendance=$attendance:'
      'occupancy=$occupancyBps:yield=$ticketYieldBps:'
      'revenue=$revenueMultiplierBps';
}

/// M64 keeps the existing M40/M41 balanced-price path byte-for-byte in terms
/// of attendance inputs and revenue multiplier, while exposing two bounded
/// commercial alternatives for a club president.
class MatchdayTicketPricingPolicy {
  const MatchdayTicketPricingPolicy();

  int demandMultiplierBps(MatchdayTicketPriceTier tier) => switch (tier) {
        MatchdayTicketPriceTier.supporterFriendly => 11000,
        MatchdayTicketPriceTier.balanced => 10000,
        MatchdayTicketPriceTier.premium => 8600,
      };

  int priceMultiplierBps(MatchdayTicketPriceTier tier) => switch (tier) {
        MatchdayTicketPriceTier.supporterFriendly => 9000,
        MatchdayTicketPriceTier.balanced => 10000,
        MatchdayTicketPriceTier.premium => 12000,
      };

  MatchdayTicketPricingOutcome apply({
    required StadiumAttendanceProfile base,
    required MatchdayTicketPriceTier tier,
  }) {
    if (tier == MatchdayTicketPriceTier.balanced) {
      return MatchdayTicketPricingOutcome(
        tier: tier,
        base: base,
        demandMultiplierBps: 10000,
        priceMultiplierBps: 10000,
        adjustedDemand: base.demand,
        attendance: base.attendance,
        occupancyBps: base.occupancyBps,
        ticketYieldBps: base.ticketYieldBps,
        revenueMultiplierBps: base.revenueMultiplierBps,
      );
    }

    final demandBps = demandMultiplierBps(tier);
    final priceBps = priceMultiplierBps(tier);
    final adjustedDemand = ((base.demand * demandBps) ~/ 10000)
        .clamp(8000, 50000)
        .toInt();
    final attendance = math.min(base.capacity, adjustedDemand);
    final occupancyBps = (attendance * 10000) ~/ base.capacity;
    final ticketYieldBps = (base.ticketYieldBps * priceBps) ~/ 10000;
    final revenueMultiplierBps = ((base.revenueMultiplierBps *
                attendance *
                priceBps) ~/
            (math.max(1, base.attendance) * 10000))
        .clamp(6500, 16000)
        .toInt();

    return MatchdayTicketPricingOutcome(
      tier: tier,
      base: base,
      demandMultiplierBps: demandBps,
      priceMultiplierBps: priceBps,
      adjustedDemand: adjustedDemand,
      attendance: attendance,
      occupancyBps: occupancyBps,
      ticketYieldBps: ticketYieldBps,
      revenueMultiplierBps: revenueMultiplierBps,
    );
  }
}

class PresidentMatchdayTicketPricingPolicy {
  const PresidentMatchdayTicketPricingPolicy();

  MatchdayTicketPricingChoice choose({
    required PresidentManagementProfile profile,
    required int fanTrust,
    required StadiumAttendanceProfile base,
  }) {
    if (fanTrust <= 45 || base.occupancyBps <= 6500) {
      return const MatchdayTicketPricingChoice(
        MatchdayTicketPriceTier.supporterFriendly,
      );
    }
    if (fanTrust >= 72 &&
        base.occupancyBps >= 9000 &&
        profile.financialDiscipline >= 65) {
      return const MatchdayTicketPricingChoice(
        MatchdayTicketPriceTier.premium,
      );
    }
    return const MatchdayTicketPricingChoice(MatchdayTicketPriceTier.balanced);
  }
}

class PlayerPresidentTicketPricingDecisionContext {
  const PlayerPresidentTicketPricingDecisionContext({
    required this.seasonIndex,
    required this.club,
    required this.president,
    required this.stadiumLevel,
    required this.leaguePosition,
    required this.fanTrust,
    required this.baseAttendance,
    required this.aiChoice,
  });

  final int seasonIndex;
  final Club club;
  final PresidentManagementProfile president;
  final int stadiumLevel;
  final int leaguePosition;
  final int fanTrust;
  final StadiumAttendanceProfile baseAttendance;
  final MatchdayTicketPricingChoice aiChoice;

  String get clubId => club.id;
  String get presidentId => president.presidentId;

  String get signature =>
      '$seasonIndex:${club.id}:${president.presidentId}:'
      'level=$stadiumLevel:position=$leaguePosition:fan=$fanTrust:'
      'base=${baseAttendance.attendance}/${baseAttendance.capacity}:'
      'ai=${aiChoice.signature}';
}

abstract class PlayerMatchdayTicketPricingDecisionProvider {
  const PlayerMatchdayTicketPricingDecisionProvider();

  MatchdayTicketPricingChoice choose(
    PlayerPresidentTicketPricingDecisionContext context,
  );
}

class PlayerPresidentTicketPricingDecision {
  const PlayerPresidentTicketPricingDecision({
    required this.context,
    required this.choice,
    required this.providerCalled,
    required this.outcome,
  });

  final PlayerPresidentTicketPricingDecisionContext context;
  final MatchdayTicketPricingChoice choice;
  final bool providerCalled;
  final MatchdayTicketPricingOutcome outcome;

  bool get playerControlled => providerCalled;
  bool get changedFromAi => choice.tier != context.aiChoice.tier;

  String get signature =>
      '${context.signature}:choice=${choice.signature}:'
      'provider=$providerCalled:outcome=${outcome.signature}';
}

class PlayerPresidentTenureGatedTicketPricingResult {
  PlayerPresidentTenureGatedTicketPricingResult({
    required Iterable<PlayerPresidentTicketPricingDecision> decisions,
  }) : decisions = List.unmodifiable(
          decisions.toList(growable: false)
            ..sort((a, b) => a.context.clubId.compareTo(b.context.clubId)),
        );

  final List<PlayerPresidentTicketPricingDecision> decisions;

  PlayerPresidentTicketPricingDecision decisionFor(String clubId) =>
      decisions.firstWhere((item) => item.context.clubId == clubId);

  String get signature =>
      decisions.map((item) => item.signature).join('||');
}

/// M64 introduces the first explicit player-president matchday pricing surface.
///
/// The existing stadium + fan-trust attendance model remains authoritative.
/// A balanced ticket choice preserves M40/M41 exactly. The player may override
/// only the controlled club while the persisted M58 tenure ownership is active
/// and the real president id still matches the captured player-president id.
/// Every other club, successor presidencies, and persisted lost states stay on
/// the exact deterministic AI path. The provider is runtime-only and no world,
/// finance, fan, stadium, or president state is mutated by this core layer.
class PlayerPresidentTenureGatedTicketPricingEngine {
  const PlayerPresidentTenureGatedTicketPricingEngine({
    this.playerProvider,
    this.aiPolicy = const PresidentMatchdayTicketPricingPolicy(),
    this.pricingPolicy = const MatchdayTicketPricingPolicy(),
    this.stadiumPolicy = const StadiumInvestmentPolicy(),
  });

  final PlayerMatchdayTicketPricingDecisionProvider? playerProvider;
  final PresidentMatchdayTicketPricingPolicy aiPolicy;
  final MatchdayTicketPricingPolicy pricingPolicy;
  final StadiumInvestmentPolicy stadiumPolicy;

  PlayerPresidentTenureGatedTicketPricingResult resolveSeason({
    required int seasonIndex,
    required List<Club> clubs,
    required Map<String, int> leaguePositionsByClub,
    required Map<String, int> stadiumLevelsByClub,
    required Map<String, FanState> fanStatesByClub,
    required Map<String, PresidentManagementProfile> presidentProfilesByClub,
    required PlayerPresidentTenureControlState tenureControl,
  }) {
    if (seasonIndex < 0) {
      throw ArgumentError.value(seasonIndex, 'seasonIndex');
    }
    tenureControl.validate();
    final clubIds = clubs.map((club) => club.id).toSet();
    if (!clubIds.contains(tenureControl.controlledClubId)) {
      throw ArgumentError(
        'Tenure-controlled club ${tenureControl.controlledClubId} is not in the season.',
      );
    }
    _validateCoverage('league positions', clubIds, leaguePositionsByClub.keys);
    _validateCoverage('stadium levels', clubIds, stadiumLevelsByClub.keys);
    _validateCoverage('fan states', clubIds, fanStatesByClub.keys);
    _validateCoverage('president profiles', clubIds, presidentProfilesByClub.keys);

    final ordered = clubs.toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));
    final decisions = <PlayerPresidentTicketPricingDecision>[];
    for (final club in ordered) {
      final position = leaguePositionsByClub[club.id]!;
      final level = stadiumLevelsByClub[club.id]!;
      final fan = fanStatesByClub[club.id]!;
      final president = presidentProfilesByClub[club.id]!;
      if (fan.clubId != club.id) {
        throw ArgumentError('Fan state club mismatch for ${club.id}.');
      }
      final base = stadiumPolicy.attendanceProfile(
        level: level,
        clubStrength: club.strength,
        leaguePosition: position,
        fanTrust: fan.overallTrust,
      );
      final aiChoice = aiPolicy.choose(
        profile: president,
        fanTrust: fan.overallTrust,
        base: base,
      );
      final context = PlayerPresidentTicketPricingDecisionContext(
        seasonIndex: seasonIndex,
        club: club,
        president: president,
        stadiumLevel: level,
        leaguePosition: position,
        fanTrust: fan.overallTrust,
        baseAttendance: base,
        aiChoice: aiChoice,
      );

      final canDelegate = club.id == tenureControl.controlledClubId &&
          playerProvider != null &&
          tenureControl.active &&
          president.presidentId == tenureControl.playerPresidentId;
      final choice = canDelegate ? playerProvider!.choose(context) : aiChoice;
      decisions.add(
        PlayerPresidentTicketPricingDecision(
          context: context,
          choice: choice,
          providerCalled: canDelegate,
          outcome: pricingPolicy.apply(base: base, tier: choice.tier),
        ),
      );
    }
    return PlayerPresidentTenureGatedTicketPricingResult(decisions: decisions);
  }

  void _validateCoverage(
    String label,
    Set<String> clubIds,
    Iterable<String> candidateIds,
  ) {
    final ids = candidateIds.toSet();
    if (ids.length != clubIds.length ||
        ids.difference(clubIds).isNotEmpty ||
        clubIds.difference(ids).isNotEmpty) {
      throw ArgumentError('$label must cover every season club exactly.');
    }
  }
}
