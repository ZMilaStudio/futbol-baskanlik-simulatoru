import 'president_promise.dart';
import 'promise_resolution.dart';

class PromiseMediaCredibilityChange {
  const PromiseMediaCredibilityChange({
    required this.clubId,
    required this.seasonIndex,
    required this.promiseId,
    required this.promiseType,
    required this.status,
    required this.code,
    required this.delta,
    required this.before,
    required this.after,
  });

  final String clubId;
  final int seasonIndex;
  final String promiseId;
  final PresidentPromiseType promiseType;
  final PromiseStatus status;
  final String code;
  final int delta;
  final int before;
  final int after;

  String get signature =>
      '$clubId:$seasonIndex:$promiseId:${promiseType.name}:${status.name}:'
      '$code:$delta:$before>$after';
}
