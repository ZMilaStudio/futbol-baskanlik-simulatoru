import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_service.dart';
import 'package:path_provider/path_provider.dart';

/// M89 application composition root.
///
/// This object only owns dependency wiring. It does not wrap M87 behavior,
/// duplicate simulation state, or create another persistence authority.
class AppComposition {
  AppComposition._({
    required this.world,
    required this.simulationConfig,
    required this.saveDirectory,
    required this.saveSlots,
  });

  final FictionalWorldSetup world;
  final SimulationConfig simulationConfig;
  final Directory saveDirectory;
  final PlayerPresidentInteractiveDecisionMixedFileSaveSlotService saveSlots;

  static Future<AppComposition> create() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final saveDirectory = Directory(
      '${supportDirectory.path}${Platform.pathSeparator}save_slots',
    );
    return AppComposition.withSaveDirectory(saveDirectory);
  }

  factory AppComposition.withSaveDirectory(Directory saveDirectory) {
    final world = const FictionalWorldFactory().build();
    const simulationConfig = SimulationConfig(careerSeed: 20260903);
    final absoluteSaveDirectory = saveDirectory.absolute;
    final saveSlots =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotService(
      rootDirectory: absoluteSaveDirectory,
      clubs: world.clubs,
      leagues: world.leagues,
    );

    return AppComposition._(
      world: world,
      simulationConfig: simulationConfig,
      saveDirectory: absoluteSaveDirectory,
      saveSlots: saveSlots,
    );
  }
}
