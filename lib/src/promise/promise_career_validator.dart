import '../world/league_tier.dart';
import 'president_promise.dart';
import 'promise_career_report.dart';
import 'promise_resolution.dart';

class PromiseCareerValidator {
  const PromiseCareerValidator();

  List<String> validate(PromiseCareerReport report) {
    final issues = <String>[];
    final world = report.advancedTransferReport.worldReport;

    if (report.seasonCount <= 0) {
      issues.add('Promise career must contain at least one season.');
      return issues;
    }

    final expectedSnapshots = world.initialClubCount * report.seasonCount;
    if (report.totalPromises != expectedSnapshots) {
      issues.add(
        'Expected $expectedSnapshots club-season promises, '
        'found ${report.totalPromises}.',
      );
    }

    final ids = <String>{};
    for (final snapshot in report.snapshots) {
      final context = snapshot.context;
      final promise = snapshot.promise;
      final outcome = snapshot.outcome;
      final resolution = snapshot.resolution;

      if (!ids.add(promise.id)) {
        issues.add('Duplicate promise id: ${promise.id}.');
      }
      if (promise.clubId != context.clubId || promise.clubId != outcome.clubId) {
        issues.add('Promise club mismatch for ${promise.id}.');
      }
      if (promise.seasonIndex != context.seasonIndex ||
          promise.seasonIndex != outcome.seasonIndex) {
        issues.add('Promise season mismatch for ${promise.id}.');
      }
      if (outcome.leaguePosition < 1 ||
          outcome.leaguePosition > outcome.leagueSize) {
        issues.add('Invalid league position for ${promise.id}.');
      }
      if (resolution.promise.id != promise.id) {
        issues.add('Resolution promise mismatch for ${promise.id}.');
      }
      if (resolution.score < 0 || resolution.score > 100) {
        issues.add('Invalid resolution score for ${promise.id}.');
      }
      if (resolution.status == PromiseStatus.fulfilled &&
          resolution.score != 100) {
        issues.add('Fulfilled promise must score 100: ${promise.id}.');
      }
      if (resolution.status == PromiseStatus.broken &&
          resolution.score != 0) {
        issues.add('Broken promise must score 0: ${promise.id}.');
      }

      switch (promise.type) {
        case PresidentPromiseType.reduceDebt:
          if (!context.financialStress ||
              promise.targetDebtReductionBps == null) {
            issues.add('Invalid debt-reduction promise context: ${promise.id}.');
          }
          break;
        case PresidentPromiseType.stabilizeFinances:
          if (!context.financialStress) {
            issues.add('Invalid financial-stability context: ${promise.id}.');
          }
          break;
        case PresidentPromiseType.finishTopHalf:
          if (promise.targetLeaguePosition != context.leagueSize ~/ 2) {
            issues.add('Invalid top-half target: ${promise.id}.');
          }
          break;
        case PresidentPromiseType.avoidRelegation:
          if (context.expectedPosition < context.leagueSize - 3) {
            issues.add('Avoid-relegation promise is not context-aware: ${promise.id}.');
          }
          break;
        case PresidentPromiseType.earnPromotion:
          if (context.tier == LeagueTier.first || context.expectedPosition > 5) {
            issues.add('Promotion promise is not context-aware: ${promise.id}.');
          }
          break;
        case PresidentPromiseType.challengeTitle:
          if (context.tier != LeagueTier.first || context.expectedPosition > 3) {
            issues.add('Title promise is not context-aware: ${promise.id}.');
          }
          break;
      }
    }

    if (report.fulfilledPromises == 0) {
      issues.add('No fulfilled promises observed.');
    }
    if (report.partialPromises == 0) {
      issues.add('No partially fulfilled promises observed.');
    }
    if (report.brokenPromises == 0) {
      issues.add('No broken promises observed.');
    }

    return issues;
  }
}
