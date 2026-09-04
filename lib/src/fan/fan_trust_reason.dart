enum FanTrustDimension {
  sporting,
  financial,
  transfer,
  identity,
}

class FanTrustReason {
  const FanTrustReason({
    required this.dimension,
    required this.code,
    required this.delta,
  });

  final FanTrustDimension dimension;
  final String code;
  final int delta;

  String get signature => '${dimension.name}:$code:$delta';
}
