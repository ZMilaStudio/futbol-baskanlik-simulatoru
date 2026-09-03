import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:test/test.dart';

void main() {
  final clubs = List.generate(
    8,
    (i) => Club(id: 'c$i', name: 'Club $i', strength: 60 + i),
  );

  test('8-club double round robin has 56 matches and balanced home/away', () {
    final fixtures = const FixtureGenerator().generateDoubleRoundRobin(
      clubs: clubs,
      seasonIndex: 0,
    );
    expect(fixtures.length, 56);
    for (final club in clubs) {
      expect(fixtures.where((f) => f.homeClubId == club.id).length, 7);
      expect(fixtures.where((f) => f.awayClubId == club.id).length, 7);
    }
    for (var round = 1; round <= 14; round++) {
      final roundFixtures = fixtures.where((f) => f.round == round).toList();
      expect(roundFixtures.length, 4);
      final participants = <String>{};
      for (final f in roundFixtures) {
        participants
          ..add(f.homeClubId)
          ..add(f.awayClubId);
      }
      expect(participants.length, 8);
    }
  });
}
