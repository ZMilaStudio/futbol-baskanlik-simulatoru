enum FanExpectationType {
  none,
  financialDiscipline,
  smartLoanReinforcement,
  strengthenSquad,
  ambitiousReinforcement,
  rebuildAfterRelegation,
  prepareForHigherTier,
  measuredImprovement,
}

class FanExpectation {
  const FanExpectation({
    required this.type,
    required this.reasonCode,
  });

  final FanExpectationType type;
  final String reasonCode;

  String get signature => '${type.name}:$reasonCode';
}
