import '../core/seeded_rng.dart';
import '../core/stable_hash.dart';
import 'manager.dart';
import 'manager_profile.dart';

class ManagerPoolGenerator {
  const ManagerPoolGenerator();

  static const _firstNames = [
    'Aras',
    'Bora',
    'Cemil',
    'Deniz',
    'Eren',
    'Fikret',
    'Giray',
    'Hakan',
    'Ilgaz',
    'Koray',
    'Levent',
    'Mert',
    'Nadir',
    'Orhan',
    'Poyraz',
    'Rasim',
    'Selim',
    'Taylan',
    'Umut',
    'Yalın',
  ];

  static const _lastNames = [
    'Arel',
    'Berkay',
    'Candan',
    'Duru',
    'Ergin',
    'Gürel',
    'Işık',
    'Koral',
    'Meriç',
    'Ongun',
    'Özer',
    'Sayar',
    'Taner',
    'Ural',
    'Yalçın',
    'Zeren',
    'Akın',
    'Bayar',
    'Çetin',
    'Durukan',
    'Erdem',
    'Gökay',
    'Karaca',
    'Sarpel',
  ];

  List<Manager> generate({
    required int careerSeed,
    required int simulationVersion,
    int count = 96,
  }) {
    if (count < 48) {
      throw ArgumentError.value(
        count,
        'count',
        'Manager pool must contain at least 48 managers.',
      );
    }

    final managers = <Manager>[];
    for (var index = 0; index < count; index++) {
      final seed = StableHash.combine32([
        careerSeed,
        simulationVersion,
        StableHash.string32('manager_$index'),
      ]);
      final rng = SeededRng(seed);
      final profile = ManagerProfile.values[
        (rng.nextDouble() * ManagerProfile.values.length).floor(),
      ];
      final startAge = _range(rng, 34, 52);
      final retirementAge = _range(rng, 66, 73);

      var reputation = _range(rng, 45, 84);
      var coaching = _range(rng, 50, 86);
      var youth = _range(rng, 45, 88);
      var manManagement = _range(rng, 45, 88);
      var boardCooperation = _range(rng, 40, 90);
      var budgetDemand = _range(rng, 30, 88);

      switch (profile) {
        case ManagerProfile.balanced:
          coaching += 3;
          boardCooperation += 5;
        case ManagerProfile.youthDeveloper:
          youth += 12;
          budgetDemand -= 6;
        case ManagerProfile.budgetBuilder:
          boardCooperation += 8;
          budgetDemand -= 18;
        case ManagerProfile.starManager:
          reputation += 12;
          coaching += 8;
          budgetDemand += 14;
        case ManagerProfile.resultsFirst:
          coaching += 10;
          manManagement += 5;
          boardCooperation -= 4;
      }

      managers.add(
        Manager(
          id: 'manager_${index.toString().padLeft(3, '0')}',
          name:
              '${_firstNames[index % _firstNames.length]} ${_lastNames[(index * 7) % _lastNames.length]}',
          profile: profile,
          startAge: startAge,
          retirementAge: retirementAge,
          reputation: reputation.clamp(35, 95),
          coaching: coaching.clamp(35, 95),
          youthDevelopment: youth.clamp(35, 95),
          manManagement: manManagement.clamp(35, 95),
          boardCooperation: boardCooperation.clamp(25, 95),
          budgetDemand: budgetDemand.clamp(15, 95),
        ),
      );
    }

    return List.unmodifiable(managers);
  }

  int _range(SeededRng rng, int min, int max) {
    return min + (rng.nextDouble() * (max - min + 1)).floor();
  }
}
