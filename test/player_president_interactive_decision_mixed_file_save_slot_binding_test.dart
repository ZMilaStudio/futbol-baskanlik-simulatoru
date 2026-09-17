import 'dart:io';

import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_binding.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_service.dart';
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
    root = Directory.systemTemp.createTempSync('fbs-m88-');
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

  PlayerPresidentInteractiveDecisionMixedFileSaveSlotService service() =>
      PlayerPresidentInteractiveDecisionMixedFileSaveSlotService(
        rootDirectory: root,
        clubs: world.clubs,
        leagues: world.leagues,
      );

  test('M88 opens checkpoint and bootstrap summaries with exact typed identity', () {
    final slots = service();
    slots.save(slotId: 'shared', session: checkpointSession());
    slots.save(slotId: 'shared', session: bootstrapSession());

    final summaries = slots.list();
    final checkpoint =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: slots,
      summary: summaries.first,
    );
    final bootstrap =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: slots,
      summary: summaries.last,
    );

    expect(checkpoint, isNotNull);
    expect(checkpoint!.identity, 'checkpoint:shared');
    expect(
      checkpoint.session.origin,
      PlayerPresidentInteractiveDecisionApplicationSessionOrigin.checkpoint,
    );
    expect(bootstrap, isNotNull);
    expect(bootstrap!.identity, 'newGameBootstrap:shared');
    expect(
      bootstrap.session.origin,
      PlayerPresidentInteractiveDecisionApplicationSessionOrigin.newGame,
    );
    expect(checkpoint.identity, isNot(bootstrap.identity));
  });

  test('M88 open by source keeps same-id namespaces as distinct bindings', () {
    final slots = service();
    slots.save(slotId: 'shared', session: checkpointSession());
    slots.save(slotId: 'shared', session: bootstrapSession());

    final checkpoint = PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding
        .open(
      service: slots,
      source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
      slotId: 'shared',
    );
    final bootstrap = PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding
        .open(
      service: slots,
      source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
          .newGameBootstrap,
      slotId: 'shared',
    );

    expect(checkpoint?.identity, 'checkpoint:shared');
    expect(bootstrap?.identity, 'newGameBootstrap:shared');
    expect(checkpoint?.source, isNot(bootstrap?.source));
  });

  test('M88 saveBack persists to the exact bound namespace', () {
    final slots = service();
    slots.save(slotId: 'shared', session: checkpointSession());
    slots.save(slotId: 'shared', session: bootstrapSession());
    final bootstrapBefore = slots.inspect(
      source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
          .newGameBootstrap,
      slotId: 'shared',
    )!;
    final checkpoint = PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding
        .open(
      service: slots,
      source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
      slotId: 'shared',
    )!;

    expect(
      checkpoint.saveBack(),
      PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
    );
    expect(checkpoint.exists, isTrue);
    expect(checkpoint.inspect()?.identity, 'checkpoint:shared');
    expect(
      slots.inspect(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap,
        slotId: 'shared',
      )?.signature,
      bootstrapBefore.signature,
    );
  });

  test('M88 delete removes only the bound source and stale summary reopens null', () {
    final slots = service();
    slots.save(slotId: 'shared', session: checkpointSession());
    slots.save(slotId: 'shared', session: bootstrapSession());
    final checkpointSummary = slots.inspect(
      source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
      slotId: 'shared',
    )!;
    final checkpoint =
        PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
      service: slots,
      summary: checkpointSummary,
    )!;

    expect(checkpoint.delete(), isTrue);
    expect(checkpoint.exists, isFalse);
    expect(
      slots.inspect(
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource
            .newGameBootstrap,
        slotId: 'shared',
      ),
      isNotNull,
    );
    expect(
      PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.openSummary(
        service: slots,
        summary: checkpointSummary,
      ),
      isNull,
    );
  });

  test('M88 missing and invalid opens delegate existing M87 validation', () {
    final slots = service();
    expect(
      PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.open(
        service: slots,
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        slotId: 'missing',
      ),
      isNull,
    );
    expect(
      () => PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding.open(
        service: slots,
        source: PlayerPresidentInteractiveDecisionMixedSaveSlotSource.checkpoint,
        slotId: '../escape',
      ),
      throwsArgumentError,
    );
    expect(root.existsSync(), isFalse);
  });
}
