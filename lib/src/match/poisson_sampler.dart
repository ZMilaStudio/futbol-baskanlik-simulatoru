import 'dart:math' as math;

import '../core/seeded_rng.dart';

class PoissonSampler {
  const PoissonSampler._();

  static int sample(double lambda, SeededRng rng) {
    final threshold = math.exp(-lambda);
    var product = 1.0;
    var k = 0;
    do {
      k++;
      product *= rng.nextDouble();
    } while (product > threshold);
    return k - 1;
  }
}
