import 'dart:math' as math;

import '../core/money.dart';
import '../player/player.dart';

class WageModel {
  const WageModel();

  Money annualWage(Player player) {
    final abilityHundredths = (player.ability * 100).round();
    final potentialHundredths = (player.potential * 100).round();

    final abilityPremium =
        math.max(0, abilityHundredths - 4500) * 280;
    final potentialPremium = player.age <= 23
        ? math.max(0, potentialHundredths - abilityHundredths) * 80
        : 0;

    final baseUnits = 120000 + abilityPremium + potentialPremium;
    final ageMultiplierBps = switch (player.age) {
      <= 20 => 7500,
      <= 23 => 9000,
      <= 30 => 11000,
      <= 32 => 10000,
      _ => 8500,
    };

    return Money.fromUnits((baseUnits * ageMultiplierBps) ~/ 10000);
  }

  Money annualSquadWages(Iterable<Player> players) {
    var total = Money.zero;
    for (final player in players) {
      total += annualWage(player);
    }
    return total;
  }
}
