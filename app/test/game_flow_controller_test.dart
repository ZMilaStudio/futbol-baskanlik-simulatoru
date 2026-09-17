import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/controller/game_flow_controller.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';

void main() {
  late FictionalWorldSetup world;
  late GameFlowController controller;

  setUp(() {
    world = const FictionalWorldFactory().build();
    controller = GameFlowController(
      world: world,
      config: const SimulationConfig(careerSeed: 20260903),
    );
  });

  tearDown(() {
    controller.dispose();
  });

  test('starts a real new-game application session for a canonical Club', () {
    final club = world.clubs.first;

    controller.startNewGame(club);

    expect(controller.errorMessage, isNull);
    expect(controller.loading, isFalse);
    expect(controller.selectedClub, same(club));
    expect(
      controller.session,
      isA<PlayerPresidentInteractiveDecisionApplicationSession>(),
    );
    expect(controller.session!.isNewGame, isTrue);
  });

  test('advances the application session to an authoritative boundary', () {
    controller.startNewGame(world.clubs.first);

    final step = controller.currentStep;
    expect(step, isNotNull);
    expect(
      step,
      anyOf(
        isA<PlayerPresidentInteractiveDecisionPending>(),
        isA<PlayerPresidentInteractiveSessionCompleted>(),
      ),
    );

    if (step is PlayerPresidentInteractiveDecisionPending) {
      expect(controller.session!.pendingDecision, same(step.request));
    } else {
      expect(controller.session!.completed, same(step));
    }
  });

  test('keeps authoritative references without a copied persisted state', () {
    final club = world.clubs.first;
    controller.startNewGame(club);

    expect(controller.selectedClub, same(club));
    expect(controller.session!.checkpointOrNull, isNull);
    expect(controller.currentStep, isA<PlayerPresidentInteractiveSessionStep>());
  });

  test('surfaces a presentation-safe error instead of a fake pending state', () {
    const unknownClub = Club(
      id: 'not-in-canonical-world',
      name: 'Unknown Club',
      strength: 50,
    );

    controller.startNewGame(unknownClub);

    expect(controller.session, isNull);
    expect(controller.currentStep, isNull);
    expect(controller.errorMessage, isNotNull);
  });
}
