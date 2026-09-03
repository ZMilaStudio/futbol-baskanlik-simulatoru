import '../player/player.dart';
import 'manager.dart';
import 'manager_profile.dart';

class ManagerImpactModel {
  const ManagerImpactModel();

  double calculate({
    required Manager manager,
    required double fitScore,
    required double boardRelationship,
    required List<Player> players,
  }) {
    if (players.isEmpty) {
      throw ArgumentError('Manager impact requires a non-empty squad.');
    }

    final youngShare = players.where((player) => player.age <= 23).length /
        players.length;
    var impact = 0.0;
    impact += (manager.coaching - 68) * 0.035;
    impact += (manager.manManagement - 62) * 0.010;
    impact += (fitScore - 50) * 0.025;
    impact += (boardRelationship - 50) * 0.012;
    impact += youngShare * (manager.youthDevelopment - 60) * 0.010;

    if (manager.profile == ManagerProfile.resultsFirst) {
      impact += 0.15;
    }

    return impact.clamp(-2.5, 2.5).toDouble();
  }
}
