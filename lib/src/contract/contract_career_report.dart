import '../core/money.dart';
import '../player/player.dart';
import '../world/world_career_report.dart';
import 'contract_event.dart';
import 'player_contract.dart';

class ContractCareerReport {
  ContractCareerReport({
    required this.worldReport,
    required Iterable<PlayerContract> activeContracts,
    required Iterable<ContractEvent> events,
  })  : activeContracts = List.unmodifiable(activeContracts),
        events = List.unmodifiable(events);

  final WorldCareerReport worldReport;
  final List<PlayerContract> activeContracts;
  final List<ContractEvent> events;

  int get initialContracts =>
      events.where((event) => event.type == ContractEventType.initial).length;
  int get renewals =>
      events.where((event) => event.type == ContractEventType.renewal).length;
  int get releases =>
      events.where((event) => event.type == ContractEventType.released).length;
  int get youthContracts =>
      events.where((event) => event.type == ContractEventType.youth).length;
  int get freeAgentSignings => events
      .where((event) => event.type == ContractEventType.freeAgentSigning)
      .length;
  int get transferContracts => events
      .where((event) => event.type == ContractEventType.transferContract)
      .length;

  int get finalFreeAgents => worldReport.finalPlayers
      .where((player) => player.clubId == Player.freeAgentClubId)
      .length;

  Money get finalAnnualWageBill => activeContracts.fold(
        Money.zero,
        (sum, contract) => sum + contract.annualWage,
      );

  double get averageFinalAnnualWage {
    if (activeContracts.isEmpty) return 0;
    return finalAnnualWageBill.units / activeContracts.length;
  }

  String get signature {
    final contracts = List<PlayerContract>.of(activeContracts)
      ..sort((a, b) => a.playerId.compareTo(b.playerId));
    final buffer = StringBuffer(worldReport.signature);
    for (final contract in contracts) {
      buffer.write('|contract=${contract.signature}');
    }
    for (final event in events) {
      buffer.write('|contractEvent=${event.signature}');
    }
    return buffer.toString();
  }
}
