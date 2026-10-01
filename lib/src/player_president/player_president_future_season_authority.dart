import '../contract/player_contract.dart';
import '../core/simulation_config.dart';
import '../finance/club_finance_state.dart';
import '../league/club.dart';
import '../manager/manager_career_controller.dart';
import '../player/player.dart';
import '../player/team_strength_calculator.dart';
import '../promise/promise_context.dart';
import '../promise/promise_opening_context_builder.dart';
import '../season/weekly_world_fixture_result_core.dart';
import '../transfer/loan_agreement.dart';
import '../transfer/transfer_installment.dart';
import '../world/world_league.dart';

part 'player_president_future_preseason_boundary.dart';

/// Requirements, NOT proof that a B2 post-offseason producer ran. Public data
/// constructors never grant production authority. B3-B must supply a genuine
/// owner-bound capability; AR-A deliberately does not implement that producer.
final class FutureOpeningSourceRequirements {
  FutureOpeningSourceRequirements({
    required this.owner,
    required this.sourceRevision,
    required this.provenance,
    required this.config,
    required Iterable<Club> baseClubs,
    required Iterable<Player> postOffseasonPlayers,
    required Iterable<ClubFinanceState> openingFinance,
    required Iterable<WorldLeague> nextLeagues,
    required this.contractTransferOpening,
  })  : baseClubs = List.unmodifiable(baseClubs),
        postOffseasonPlayers = List.unmodifiable(postOffseasonPlayers),
        openingFinance = List.unmodifiable(openingFinance),
        nextLeagues = List.unmodifiable(nextLeagues);

  final Object owner, sourceRevision, provenance;
  final SimulationConfig config;
  int get targetSeason => config.seasonIndex;
  final List<Club> baseClubs;
  final List<Player> postOffseasonPlayers;
  final List<ClubFinanceState> openingFinance;
  final List<WorldLeague> nextLeagues;
  final FutureContractTransferOpeningRequirements contractTransferOpening;
}

/// Required opening contract/transfer receipt shape; not a receipt producer.
final class FutureContractTransferOpeningRequirements {
  FutureContractTransferOpeningRequirements({
    required this.owner,
    required this.sourceRevision,
    required this.provenance,
    required this.targetSeason,
    required Iterable<PlayerContract> contracts,
    required Iterable<LoanAgreement> activeLoans,
    required Iterable<TransferInstallmentObligation> installments,
  })  : contracts = List.unmodifiable(contracts),
        activeLoans = List.unmodifiable(activeLoans),
        installments = List.unmodifiable(installments);

  final Object owner, sourceRevision, provenance;
  final int targetSeason;
  final List<PlayerContract> contracts;
  final List<LoanAgreement> activeLoans;
  final List<TransferInstallmentObligation> installments;
}

/// No concrete capability or minting API exists in AR-A. External callers
/// cannot implement this sealed type. B3-B integration must establish provenance
/// before adding an internal producer; arbitrary state and M65 are not substitutes.
sealed class FutureOpeningSourceCapability {
  FutureOpeningSourceRequirements get source;
}

/// Detached preparation result, never a completed season/application publication.
/// A fixture result explicitly remains non-authoritative.
final class FutureSeasonOpeningCandidate {
  FutureSeasonOpeningCandidate._({
    required this.source,
    required this.isAuthoritative,
    required this.managerAuthority,
    required this.w0,
    required this.promiseContexts,
  });

  final FutureOpeningSourceRequirements source;
  final bool isAuthoritative;
  final ManagerSeasonAuthority managerAuthority;
  List<Club> get effectiveClubs => managerAuthority.effectiveClubs;
  final WeeklyWorldFixtureSnapshot w0;
  final List<PresidentPromiseContext> promiseContexts;

  /// Initial appointment is neither retain/replace nor historical evaluation.
  bool get isInitialManagerAppointment => true;
}
