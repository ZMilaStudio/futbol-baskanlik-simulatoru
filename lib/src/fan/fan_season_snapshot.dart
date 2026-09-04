import 'fan_expectation.dart';
import 'fan_season_context.dart';
import 'fan_state.dart';
import 'fan_trust_reason.dart';

class FanSeasonSnapshot {
  FanSeasonSnapshot({
    required this.context,
    required this.expectation,
    required this.state,
    required Iterable<FanTrustReason> reasons,
  }) : reasons = List.unmodifiable(reasons);

  final FanSeasonContext context;
  final FanExpectation expectation;
  final FanState state;
  final List<FanTrustReason> reasons;

  String get signature =>
      '${context.signature}|${expectation.signature}|${state.signature}|'
      '${reasons.map((reason) => reason.signature).join(',')}';
}
