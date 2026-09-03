import '../core/money.dart';
import '../player/player.dart';

class MarketValueModel {
  const MarketValueModel();

  Money value(
    Player player, {
    int? contractYearsRemaining,
  }) {
    final quality = (player.ability - 45.0).clamp(0.0, 50.0);
    final baseUnits = (quality * quality * 6000).round();

    final ageBps = switch (player.age) {
      <= 20 => 14500,
      <= 23 => 13000,
      <= 27 => 11000,
      <= 30 => 9000,
      <= 33 => 6500,
      _ => 4000,
    };
    final potentialGap =
        (player.potential - player.ability).clamp(0.0, 25.0);
    final potentialBps = 10000 + (potentialGap * 120).round();

    var value = Money.fromUnits(baseUnits < 250000 ? 250000 : baseUnits);
    value = value.scaleBasisPoints(ageBps);
    value = value.scaleBasisPoints(potentialBps);

    if (contractYearsRemaining != null) {
      final contractBps = switch (contractYearsRemaining) {
        <= 0 => 2500,
        1 => 7000,
        2 => 9000,
        3 => 10300,
        4 => 11000,
        _ => 11500,
      };
      value = value.scaleBasisPoints(contractBps);
    }

    return value.max(const Money.fromUnits(250000));
  }
}
