import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/composition/app_composition.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_service.dart';

void main() {
  test('AppComposition supports an injected application-private directory', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'fbs-m89-composition-',
    );

    try {
      final composition = AppComposition.withSaveDirectory(tempDirectory);

      expect(composition.world.clubs, hasLength(48));
      expect(
        composition.saveDirectory.path,
        tempDirectory.absolute.path,
      );
      expect(
        composition.saveSlots,
        isA<PlayerPresidentInteractiveDecisionMixedFileSaveSlotService>(),
      );
    } finally {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    }
  });
}
