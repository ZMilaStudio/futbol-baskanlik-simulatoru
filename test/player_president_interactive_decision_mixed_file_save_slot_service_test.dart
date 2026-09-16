import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_file_save_slot_store.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_service.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_new_game_bootstrap_file_save_slot_store.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_persistence_bundle.dart';
import 'package:futbol_baskanlik_m0/player_president_tenure_gated_ticket_pricing_runtime_integration.dart';
import 'package:futbol_baskanlik_m0/player_president_unified_decision_gateway_runtime.dart';
import 'package:test/test.dart';

void main() {
  const seed = 20260903;
  const config = SimulationConfig(careerSeed: seed);

  late FictionalWorldSetup world;
  late PlayerPresidentTicketPricingRuntimeCheckpoint initial;
  late String controlledClubId;
  late Directory root;

  setUpAll(() {
    world = const FictionalWorldFactory().build();
    controlledClubId = world.clubs.first.id;
    initial = const PlayerPresidentUnifiedDecisionGatewayRuntimeCareerEngine()
        .simulateWithCheckpoint(
      clubs: world.clubs,
      leagues: world.leagues,
      config: config,
      controlledClubId: controlledClubId,
      seasonCount: 1,
      hasFutureSeasonAfterReport: true,
    ).checkpoint;
  });

  setUp(() {
    root = Directory.systemTemp.createTempSync('fbs-m87-');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  PlayerPresidentInteractiveDecisionApplicationSession checkpointSession() =>
      PlayerPresidentInteractiveDecisionApplicationSession.resume(
        checkpoint: initial,
        resumeConfig: const PlayerPresidentInteractiveDecisionResumeConfig(
          seasonCount: 1,
          hasFutureSeasonAfterReport: true,
          crisisActivationThreshold: 0,
          candidateLimit: 5,
        ),
      );

  PlayerPresidentInteractiveDecisionApplicationSession bootstrapSession() =>
      PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: controlledClubId,
        seasonCount: 1,
        electionInterval: 4,
        hasFutureSeasonAfterReport: true,
        crisisActivationThreshold: 0,
        candidateLimit: 5,
      );

  PlayerPresidentInteractiveDecisionMixedFileSaveSlotService withStores({
    required PlayerPresidentInteractiveDecisionFileSaveSlotStore checkpoints,
    required PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore
        bootstraps,
  }) =>
      PlayerPresidentInteractiveDecisionMixedFileSaveSlotService.withStores(
        checkpointStore: checkpoints,
        bootstrapStore: bootstraps,
        clubs: world.clubs,
        leagues: world.leagues,
      );

  test('M87 unifies save list inspect and load over both namespaces', () {
    final checkpoints = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    );
    final bootstraps =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: root,
    );
    final service = withStores(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    );

    expect(
      service.save(slotId: 'shared', session: checkpointSession()),
      PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
    );
    expect(
      service.save(slotId: 'shared', session: bootstrapSession()),
      PlayerPresidentInteractiveDecisionMixedSaveSlotSource.newGameBootstrap,
    );

    final summaries = service.list();
    expect(
      summaries.map((summary) => summary.identity),
      <String>['checkpoint:shared', 'newGameBootstrap:shared'],
    );
    expect(
      service.inspect(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        slotId: 'shared',
      )?.identity,
      'checkpoint:shared',
    );
    expect(
      service.inspect(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap,
        slotId: 'shared',
      )?.identity,
      'newGameBootstrap:shared',
    );
    expect(
      service.loadSummary(summaries.first)?.origin,
      PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint,
    );
    expect(
      service.loadSummary(summaries.last)?.origin,
      PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame,
    );
  });

  test('M87 deleteSummary preserves the same-id sibling namespace', () {
    final checkpoints = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    );
    final bootstraps =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: root,
    );
    final service = withStores(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    );

    service.save(slotId: 'shared', session: checkpointSession());
    service.save(slotId: 'shared', session: bootstrapSession());
    final checkpointSummary = service.inspect(
      source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
      slotId: 'shared',
    )!;

    expect(service.deleteSummary(checkpointSummary), isTrue);
    expect(checkpoints.contains('shared'), isFalse);
    expect(bootstraps.contains('shared'), isTrue);
    expect(
      service.load(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap,
        slotId: 'shared',
      )?.origin,
      PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame,
    );
    expect(
      service.delete(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        slotId: 'missing',
      ),
      isFalse,
    );
  });

  test('M87 root-directory constructor uses the existing physical namespaces', () {
    final service = PlayerPresidentInteractiveDecisionMixedFileSaveSlotService(
      rootDirectory: root,
      clubs: world.clubs,
      leagues: world.leagues,
    );

    service.save(slotId: 'checkpoint', session: checkpointSession());
    service.save(slotId: 'bootstrap', session: bootstrapSession());

    final checkpoints = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    );
    final bootstraps =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: root,
    );
    expect(checkpoints.contains('checkpoint'), isTrue);
    expect(bootstraps.contains('bootstrap'), isTrue);
    expect(checkpoints.contains('bootstrap'), isFalse);
    expect(bootstraps.contains('checkpoint'), isFalse);
    expect(service.list().length, 2);
  });

  test('M87 delegates invalid slot validation without disk mutation', () {
    final checkpoints = PlayerPresidentInteractiveDecisionFileSaveSlotStore(
      rootDirectory: root,
    );
    final bootstraps =
        PlayerPresidentInteractiveDecisionNewGameBootstrapFileSaveSlotStore(
      rootDirectory: root,
    );
    final service = withStores(
      checkpoints: checkpoints,
      bootstraps: bootstraps,
    );

    service.save(slotId: 'keep', session: checkpointSession());
    service.save(slotId: 'keep', session: bootstrapSession());
    final before = root.listSync(followLinks: false).map((e) => e.path).toSet();

    expect(
      () => service.save(
        slotId: '../escape',
        session: checkpointSession(),
      ),
      throwsArgumentError,
    );
    expect(
      () => service.load(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        slotId: '../escape',
      ),
      throwsArgumentError,
    );
    expect(
      () => service.delete(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap,
        slotId: '../escape',
      ),
      throwsArgumentError,
    );

    final after = root.listSync(followLinks: false).map((e) => e.path).toSet();
    expect(after, before);
    expect(checkpoints.contains('keep'), isTrue);
    expect(bootstraps.contains('keep'), isTrue);
  });
}
