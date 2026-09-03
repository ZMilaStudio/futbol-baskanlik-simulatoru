import '../league/club.dart';
import 'league_tier.dart';
import 'world_league.dart';

class FictionalWorldSetup {
  FictionalWorldSetup({
    required Iterable<Club> clubs,
    required Iterable<WorldLeague> leagues,
  })  : clubs = List.unmodifiable(clubs),
        leagues = List.unmodifiable(leagues);

  final List<Club> clubs;
  final List<WorldLeague> leagues;
}

class FictionalWorldFactory {
  const FictionalWorldFactory();

  static const List<String> _firstTierNames = [
    'Kuzey Yıldızı SK',
    'Vadişehir FK',
    'Demirkent',
    'Mavi Liman',
    'Çınarova',
    'Ufukşehir',
    'Gölhisar',
    'Hisar Birliği',
    'Poyrazkent',
    'Sedef Liman',
    'Yelkovan',
    'Koruşehir',
    'Altın Vadi',
    'Ayazkent',
    'Irmak Birliği',
    'Dorukova',
  ];

  static const List<String> _secondTierNames = [
    'Güneşyaka',
    'Kervankent',
    'Mercanşehir',
    'Ova Yıldızı',
    'Kartalova',
    'Çelikyaka',
    'Pınarkent',
    'Göksu Birliği',
    'Yamaçşehir',
    'Işıkova',
    'Ilgazkent',
    'Tuna Birliği',
    'Akasya Liman',
    'Bozkır Yıldızı',
    'Kızılvadi',
    'Rüzgarhisar',
  ];

  static const List<String> _thirdTierNames = [
    'Esengöl',
    'Yeşil Koru',
    'Körfez Yıldızı',
    'Adaşehir',
    'Şafakova',
    'Sarnıçkent',
    'Çamlıvadi',
    'Günbatımı SK',
    'Harmanova',
    'Lodoskent',
    'Boğazova',
    'Ardıçkent',
    'Derya Birliği',
    'Taşlıyaka',
    'Gölgeşehir',
    'Yalıova Birliği',
  ];

  FictionalWorldSetup build() {
    final first = _clubsForTier(
      tier: LeagueTier.first,
      names: _firstTierNames,
      strongest: 81.5,
      step: 0.82,
    );
    final second = _clubsForTier(
      tier: LeagueTier.second,
      names: _secondTierNames,
      strongest: 70.5,
      step: 0.78,
    );
    final third = _clubsForTier(
      tier: LeagueTier.third,
      names: _thirdTierNames,
      strongest: 60.5,
      step: 0.72,
    );
    final clubs = <Club>[...first, ...second, ...third];
    final leagues = [
      WorldLeague(
        tier: LeagueTier.first,
        clubIds: first.map((club) => club.id),
      ),
      WorldLeague(
        tier: LeagueTier.second,
        clubIds: second.map((club) => club.id),
      ),
      WorldLeague(
        tier: LeagueTier.third,
        clubIds: third.map((club) => club.id),
      ),
    ];
    return FictionalWorldSetup(clubs: clubs, leagues: leagues);
  }

  List<Club> _clubsForTier({
    required LeagueTier tier,
    required List<String> names,
    required double strongest,
    required double step,
  }) {
    return List.generate(names.length, (index) {
      final id = 't${tier.level}_${(index + 1).toString().padLeft(2, '0')}';
      return Club(
        id: id,
        name: names[index],
        strength: strongest - index * step,
      );
    }, growable: false);
  }
}
