import '../fan/fan_career_validator.dart';
import 'promise_career_validator.dart';
import 'promise_fan_career_report.dart';

class PromiseFanCareerValidator {
  const PromiseFanCareerValidator({
    this.promiseValidator = const PromiseCareerValidator(),
    this.fanValidator = const FanCareerValidator(),
  });

  final PromiseCareerValidator promiseValidator;
  final FanCareerValidator fanValidator;

  List<String> validate(PromiseFanCareerReport report) {
    final issues = <String>[
      ...promiseValidator.validate(report.promiseReport),
      ...fanValidator.validate(report.baselineFanReport),
      ...fanValidator.validate(report.fanReport),
    ];

    final promiseAdvanced = report.promiseReport.advancedTransferReport.signature;
    final baselineAdvanced =
        report.baselineFanReport.advancedTransferReport.signature;
    final fanAdvanced = report.fanReport.advancedTransferReport.signature;
    if (promiseAdvanced != baselineAdvanced || promiseAdvanced != fanAdvanced) {
      issues.add('M12 layers do not share the same advanced-world report.');
    }

    if (report.promiseIdentityReasons != report.promiseReport.totalPromises) {
      issues.add(
        'Promise identity reason coverage mismatch: '
        '${report.promiseIdentityReasons}/${report.promiseReport.totalPromises}.',
      );
    }
    if (report.promiseFinancialReasons != report.promiseReport.financialPromises) {
      issues.add(
        'Promise financial reason coverage mismatch: '
        '${report.promiseFinancialReasons}/${report.promiseReport.financialPromises}.',
      );
    }
    if (report.promiseReasonCount !=
        report.promiseReport.totalPromises + report.promiseReport.financialPromises) {
      issues.add('Unexpected M12 promise reason count.');
    }

    if (report.baselineFanReport.finalStates
        .any((state) => state.identityTrust != 60)) {
      issues.add('M9 baseline identity trust is no longer neutral.');
    }
    if (report.fanReport.finalStates
        .every((state) => state.identityTrust == 60)) {
      issues.add('Promise outcomes did not affect final identity trust.');
    }
    if (report.positivePromiseReasons == 0 || report.negativePromiseReasons == 0) {
      issues.add('Promise fan integration needs both positive and negative reasons.');
    }

    return issues;
  }
}
