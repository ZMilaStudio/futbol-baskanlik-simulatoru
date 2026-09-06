import 'dart:convert';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/src/save/facility_runtime_checkpoint.dart';
import 'package:futbol_baskanlik_m0/src/save/facility_runtime_save_codec.dart';
import 'package:test/test.dart';

void main() {
  test('M34 migrates synthetic v0 facility save to v1', () {
    final world = const FictionalWorldFactory().build();
    final checkpoint = const WorldCareerEngine()
        .simulateWithCheckpoint(
          clubs: world.clubs,
          leagues: world.leagues,
          config: SimulationConfig(careerSeed: 20260903),
          seasonCount: 2,
        )
        .checkpoint;
    final facility = FacilityRuntimeCheckpoint.initial(checkpoint);
    const codec = FacilityRuntimeSaveCodec();
    final current = jsonDecode(codec.encode(facility)) as Map<String, dynamic>;
    final payload = current['payload'] as Map<String, dynamic>;
    final legacyPayload = <String, Object?>{
      'world': payload['worldSave'],
      'facilities': payload['academyFacilities'],
      'spentMinorUnits': payload['totalInvestmentSpentMinorUnits'],
    };
    final legacy = SaveChecksum.canonicalJson({
      'format': FacilityRuntimeSaveCodec.format,
      'saveVersion': 0,
      'payload': legacyPayload,
      'checksum': SaveChecksum.forPayload(saveVersion: 0, payload: legacyPayload),
    });

    final migrated = codec.decode(legacy);
    expect(migrated.signature, facility.signature);
    final reencoded = jsonDecode(codec.encode(migrated)) as Map<String, dynamic>;
    expect(reencoded['saveVersion'], FacilityRuntimeSaveCodec.currentSaveVersion);
  });
}
