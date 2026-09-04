import '../core/seeded_rng.dart';
import '../core/stable_hash.dart';

class PresidentProfile {
  const PresidentProfile({required this.id, required this.name});

  final String id;
  final String name;

  String get signature => '$id:$name';
}

class PresidentProfileGenerator {
  const PresidentProfileGenerator();

  static const _firstNames = [
    'Adem',
    'Alper',
    'Arda',
    'Baran',
    'Berk',
    'Cem',
    'Deniz',
    'Efe',
    'Emir',
    'Engin',
    'Erdem',
    'Firat',
    'Hakan',
    'Kerem',
    'Koray',
    'Mert',
    'Murat',
    'Okan',
    'Onur',
    'Selim',
    'Sinan',
    'Tolga',
    'Umut',
    'Yalcin',
  ];

  static const _lastNames = [
    'Aksoy',
    'Aydin',
    'Bayar',
    'Celik',
    'Demir',
    'Dogan',
    'Eren',
    'Guler',
    'Isik',
    'Kara',
    'Kaya',
    'Kilic',
    'Koc',
    'Ozer',
    'Polat',
    'Sahin',
    'Sari',
    'Tekin',
    'Toprak',
    'Turan',
    'Ural',
    'Yaman',
    'Yildiz',
    'Zeren',
  ];

  PresidentProfile generateInitial({
    required String clubId,
    required int careerSeed,
    required int simulationVersion,
  }) =>
      _generate(
        clubId: clubId,
        token: 'initial',
        careerSeed: careerSeed,
        simulationVersion: simulationVersion,
      );

  PresidentProfile generateChallenger({
    required String clubId,
    required int seasonIndex,
    required int electionTermNumber,
    required int careerSeed,
    required int simulationVersion,
  }) =>
      _generate(
        clubId: clubId,
        token: 'challenger_s${seasonIndex}_t$electionTermNumber',
        careerSeed: careerSeed,
        simulationVersion: simulationVersion,
      );

  PresidentProfile _generate({
    required String clubId,
    required String token,
    required int careerSeed,
    required int simulationVersion,
  }) {
    final rng = SeededRng(
      StableHash.combine32([
        careerSeed,
        simulationVersion,
        StableHash.string32(clubId),
        StableHash.string32(token),
        StableHash.string32('president-profile'),
      ]),
    );
    final first = _firstNames[(rng.nextDouble() * _firstNames.length).floor()];
    final last = _lastNames[(rng.nextDouble() * _lastNames.length).floor()];
    return PresidentProfile(
      id: 'president_${clubId}_$token',
      name: '$first $last',
    );
  }
}

class PresidentTenureState {
  const PresidentTenureState({
    required this.clubId,
    required this.president,
    required this.tenureNumber,
    required this.startedSeasonIndex,
    required this.reelectionsWon,
  });

  factory PresidentTenureState.initial({
    required String clubId,
    required PresidentProfile president,
    required int startedSeasonIndex,
  }) =>
      PresidentTenureState(
        clubId: clubId,
        president: president,
        tenureNumber: 1,
        startedSeasonIndex: startedSeasonIndex,
        reelectionsWon: 0,
      );

  final String clubId;
  final PresidentProfile president;
  final int tenureNumber;
  final int startedSeasonIndex;
  final int reelectionsWon;

  PresidentTenureState recordReelection() => PresidentTenureState(
        clubId: clubId,
        president: president,
        tenureNumber: tenureNumber,
        startedSeasonIndex: startedSeasonIndex,
        reelectionsWon: reelectionsWon + 1,
      );

  PresidentTenureState handover({
    required PresidentProfile incoming,
    required int effectiveSeasonIndex,
  }) =>
      PresidentTenureState(
        clubId: clubId,
        president: incoming,
        tenureNumber: tenureNumber + 1,
        startedSeasonIndex: effectiveSeasonIndex,
        reelectionsWon: 0,
      );

  String get signature =>
      '$clubId:${president.signature}:tenure=$tenureNumber:'
      'start=$startedSeasonIndex:reelected=$reelectionsWon';
}

class PresidentTurnoverEvent {
  const PresidentTurnoverEvent({
    required this.clubId,
    required this.electionSeasonIndex,
    required this.effectiveSeasonIndex,
    required this.electionTermNumber,
    required this.outgoing,
    required this.incoming,
    required this.outgoingStartedSeasonIndex,
    required this.outgoingTenureSeasons,
    required this.outgoingReelections,
    required this.electionMargin,
    required this.challengerStrength,
  });

  final String clubId;
  final int electionSeasonIndex;
  final int effectiveSeasonIndex;
  final int electionTermNumber;
  final PresidentProfile outgoing;
  final PresidentProfile incoming;
  final int outgoingStartedSeasonIndex;
  final int outgoingTenureSeasons;
  final int outgoingReelections;
  final int electionMargin;
  final int challengerStrength;

  String get signature =>
      '$clubId:s$electionSeasonIndex>start$effectiveSeasonIndex:'
      'term=$electionTermNumber:${outgoing.signature}>${incoming.signature}:'
      'outStart=$outgoingStartedSeasonIndex:seasons=$outgoingTenureSeasons:'
      'reelected=$outgoingReelections:margin=$electionMargin:'
      'challenger=$challengerStrength';
}
