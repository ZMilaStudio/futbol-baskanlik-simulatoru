import 'package:flutter/foundation.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';

/// Transient Flutter lifecycle coordinator for one interactive new game.
///
/// The controller keeps references to authoritative core/application objects
/// only. It does not serialize, copy, or persist gameplay state.
class GameFlowController extends ChangeNotifier {
  GameFlowController({
    required this.world,
    required this.config,
  });

  final FictionalWorldSetup world;
  final SimulationConfig config;

  Club? _selectedClub;
  PlayerPresidentInteractiveDecisionApplicationSession? _session;
  PlayerPresidentInteractiveSessionStep? _currentStep;
  bool _loading = false;
  String? _errorMessage;

  Club? get selectedClub => _selectedClub;
  PlayerPresidentInteractiveDecisionApplicationSession? get session => _session;
  PlayerPresidentInteractiveSessionStep? get currentStep => _currentStep;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  void startNewGame(Club club) {
    if (_loading) return;

    _selectedClub = club;
    _session = null;
    _currentStep = null;
    _errorMessage = null;
    _loading = true;
    notifyListeners();

    try {
      final session = PlayerPresidentInteractiveDecisionApplicationSession.start(
        clubs: world.clubs,
        leagues: world.leagues,
        config: config,
        controlledClubId: club.id,
        seasonCount: 1,
        electionInterval: 4,
        hasFutureSeasonAfterReport: true,
      );
      final step = session.advance();

      _session = session;
      _currentStep = step;
    } catch (_) {
      _session = null;
      _currentStep = null;
      _errorMessage =
          'Oyun oturumu başlatılamadı. Lütfen geri dönüp tekrar deneyin.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
