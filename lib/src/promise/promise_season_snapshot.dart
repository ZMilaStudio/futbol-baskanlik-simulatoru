import 'president_promise.dart';
import 'promise_context.dart';
import 'promise_resolution.dart';

class PromiseSeasonSnapshot {
  const PromiseSeasonSnapshot({
    required this.context,
    required this.promise,
    required this.outcome,
    required this.resolution,
  });

  final PresidentPromiseContext context;
  final PresidentPromise promise;
  final PresidentPromiseOutcome outcome;
  final PromiseResolution resolution;

  String get signature =>
      '${context.signature}|${promise.signature}|${outcome.signature}|'
      '${resolution.signature}';
}
