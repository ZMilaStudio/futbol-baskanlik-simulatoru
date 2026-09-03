import 'club.dart';
import 'fixture.dart';

class FixtureGenerator {
  const FixtureGenerator();

  List<Fixture> generateDoubleRoundRobin({
    required List<Club> clubs,
    required int seasonIndex,
  }) {
    if (clubs.length < 2 || clubs.length.isOdd) {
      throw ArgumentError('M0 requires an even number of at least 2 clubs.');
    }

    final rotation = List<Club>.from(clubs);
    final firstHalf = <Fixture>[];
    final rounds = clubs.length - 1;
    var fixtureCounter = 0;

    for (var round = 0; round < rounds; round++) {
      for (var i = 0; i < clubs.length ~/ 2; i++) {
        var home = rotation[i];
        var away = rotation[clubs.length - 1 - i];
        if (i == 0 && round.isOdd) {
          final temp = home;
          home = away;
          away = temp;
        }
        firstHalf.add(
          Fixture(
            id: 'S${seasonIndex}_F${fixtureCounter++}',
            seasonIndex: seasonIndex,
            round: round + 1,
            homeClubId: home.id,
            awayClubId: away.id,
          ),
        );
      }

      final last = rotation.removeLast();
      rotation.insert(1, last);
    }

    final secondHalf = <Fixture>[];
    for (final source in firstHalf) {
      secondHalf.add(
        Fixture(
          id: 'S${seasonIndex}_F${fixtureCounter++}',
          seasonIndex: seasonIndex,
          round: source.round + rounds,
          homeClubId: source.awayClubId,
          awayClubId: source.homeClubId,
        ),
      );
    }

    return [...firstHalf, ...secondHalf];
  }
}
