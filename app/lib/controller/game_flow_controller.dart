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

  /// Sends one player choice through the authoritative M76/M73 submit path.
  ///
  /// A failed validation never advances [_currentStep]. The loading flag is
  /// presentation-only and prevents a second UI submit while this call runs.
  void submitChoice(Object choice) {
    if (_loading) return;

    final session = _session;
    final current = _currentStep;
    if (session == null ||
        current is! PlayerPresidentInteractiveDecisionPending) {
      _errorMessage = 'Şu anda yanıtlanabilecek bir başkanlık kararı yok.';
      notifyListeners();
      return;
    }

    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final next = session.submit(
        request: current.request,
        choice: choice,
      );
      _currentStep = next;
    } catch (_) {
      _errorMessage =
          'Karar gönderilemedi. Mevcut karar değişmeden bırakıldı.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
