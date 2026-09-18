import 'package:flutter/foundation.dart';
import 'package:futbol_baskanlik_m0/futbol_baskanlik_m0.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_application_session.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_binding.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_catalog.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_mixed_file_save_slot_service.dart';
import 'package:futbol_baskanlik_m0/player_president_interactive_decision_session.dart';

import '../persistence/slot_id_generator.dart';

/// Transient Flutter lifecycle coordinator for one interactive player-president
/// session.
///
/// The controller keeps references to authoritative core/application objects
/// only. It never serializes gameplay state or implements persistence routing.
class GameFlowController extends ChangeNotifier {
  GameFlowController({
    required this.world,
    required this.config,
    required this.saveSlots,
    SlotIdFactory slotIdFactory = createCareerSlotId,
  }) : _slotIdFactory = slotIdFactory;

  final FictionalWorldSetup world;
  final SimulationConfig config;
  final PlayerPresidentInteractiveDecisionMixedFileSaveSlotService saveSlots;
  final SlotIdFactory _slotIdFactory;

  Club? _selectedClub;
  PlayerPresidentInteractiveDecisionApplicationSession? _session;
  PlayerPresidentInteractiveSessionStep? _currentStep;
  PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding? _binding;
  PlayerPresidentInteractiveDecisionMixedSaveSlotSummary? _saveSummary;
  bool _loading = false;
  bool _persistenceBusy = false;
  String? _errorMessage;
  String? _persistenceError;
  String? _persistenceMessage;

  Club? get selectedClub => _selectedClub;
  PlayerPresidentInteractiveDecisionApplicationSession? get session => _session;
  PlayerPresidentInteractiveSessionStep? get currentStep => _currentStep;
  PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding? get binding =>
      _binding;
  PlayerPresidentInteractiveDecisionMixedSaveSlotSummary? get saveSummary =>
      _saveSummary;
  bool get loading => _loading;
  bool get persistenceBusy => _persistenceBusy;
  String? get errorMessage => _errorMessage;
  String? get persistenceError => _persistenceError;
  String? get persistenceMessage => _persistenceMessage;

  void startNewGame(Club club) {
    if (_loading || _persistenceBusy) return;

    _selectedClub = club;
    _session = null;
    _currentStep = null;
    _binding = null;
    _saveSummary = null;
    _errorMessage = null;
    _persistenceError = null;
    _persistenceMessage = null;
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

  /// Adopts the exact typed slot already opened through M88.
  ///
  /// The controlled club comes from M83/M87 metadata and must resolve to the
  /// canonical world. The application session itself remains authoritative.
  bool loadBoundSave(
    PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding binding,
  ) {
    if (_loading || _persistenceBusy) return false;

    _loading = true;
    _errorMessage = null;
    _persistenceError = null;
    _persistenceMessage = null;
    notifyListeners();

    var loaded = false;
    try {
      final summary = binding.inspect();
      if (summary == null) {
        throw StateError('The bound mixed save slot no longer exists.');
      }
      final club = _clubById(summary.controlledClubId);
      if (club == null) {
        throw StateError(
          'Controlled club ${summary.controlledClubId} is not canonical.',
        );
      }

      final session = binding.session;
      final step = session.advance();

      _selectedClub = club;
      _session = session;
      _currentStep = step;
      _binding = binding;
      _saveSummary = summary;
      loaded = true;
    } catch (_) {
      _selectedClub = null;
      _session = null;
      _currentStep = null;
      _binding = null;
      _saveSummary = null;
      _errorMessage =
          'Kayıt açılamadı. Kayıt dosyası artık mevcut olmayabilir.';
    } finally {
      _loading = false;
      notifyListeners();
    }
    return loaded;
  }

  /// Sends one player choice through the authoritative M76/M73 submit path.
  ///
  /// A failed validation never advances [_currentStep]. The loading flag is
  /// presentation-only and prevents a second UI submit while this call runs.
  void submitChoice(Object choice) {
    if (_loading || _persistenceBusy) return;

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

  /// Hands an authoritative Completed result to the existing checkpoint
  /// application lifecycle.
  ///
  /// The new session is created only through M79's public resume contract.
  /// Any previous M88 binding remains the identity of the old slot and is
  /// deliberately detached after a successful handoff. The old slot stays on
  /// disk; the next checkpoint-origin session will make its first save via M87.
  bool continueToNextSeason() {
    if (_loading || _persistenceBusy) return false;

    final currentSession = _session;
    final currentStep = _currentStep;
    if (currentSession == null ||
        currentStep is! PlayerPresidentInteractiveSessionCompleted) {
      _errorMessage = 'Sonraki sezona geçmek için sezon tamamlanmış olmalı.';
      notifyListeners();
      return false;
    }

    _loading = true;
    _errorMessage = null;
    _persistenceError = null;
    _persistenceMessage = null;
    notifyListeners();

    var continued = false;
    try {
      final checkpoint = currentStep.result.checkpoint;
      final club = _clubById(checkpoint.controlledClubId);
      if (club == null) {
        throw StateError(
          'Controlled club ${checkpoint.controlledClubId} is not canonical.',
        );
      }

      final nextSession =
          PlayerPresidentInteractiveDecisionApplicationSession.resume(
        checkpoint: checkpoint,
        resumeConfig: currentSession.resumeConfig,
      );
      final nextStep = nextSession.advance();

      _selectedClub = club;
      _session = nextSession;
      _currentStep = nextStep;

      // A binding owns one exact typed slot + one exact loaded session. The
      // resumed checkpoint-origin session is a new authoritative session and
      // must not inherit the previous slot identity implicitly.
      _binding = null;
      _saveSummary = null;
      continued = true;
    } catch (_) {
      // Keep the previous Completed session/step/binding untouched.
      _errorMessage =
          'Sonraki sezon başlatılamadı. Tamamlanan sezon korunuyor.';
    } finally {
      _loading = false;
      notifyListeners();
    }
    return continued;
  }

  /// Persists the authoritative application session.
  ///
  /// Fresh sessions route only through M87. Once the first slot exists it is
  /// reopened through M88 so every later write uses saveBack() against the
  /// exact typed source + slot id.
  bool saveCurrent() {
    if (_loading || _persistenceBusy) return false;

    final session = _session;
    if (session == null) {
      _persistenceError = 'Kaydedilecek aktif bir kariyer yok.';
      _persistenceMessage = null;
      notifyListeners();
      return false;
    }

    _persistenceBusy = true;
    _persistenceError = null;
    _persistenceMessage = null;
    notifyListeners();

    var saved = false;
    try {
      final existingBinding = _binding;
      if (existingBinding != null) {
        existingBinding.saveBack();
        final summary = existingBinding.inspect();
        if (summary == null) {
          throw StateError('Saved binding disappeared after saveBack().');
        }
        _saveSummary = summary;
        _persistenceMessage = 'Kayıt güncellendi.';
        saved = true;
      } else {
        final slotId = _slotIdFactory();
        final source = saveSlots.save(slotId: slotId, session: session);
        final summary = saveSlots.inspect(source: source, slotId: slotId);
        if (summary == null) {
          throw StateError('M87 save completed without catalog metadata.');
        }
        final binding =
            PlayerPresidentInteractiveDecisionMixedFileSaveSlotBinding
                .openSummary(
          service: saveSlots,
          summary: summary,
        );
        if (binding == null) {
          throw StateError('Saved mixed slot could not be reopened by M88.');
        }
        final club = _clubById(summary.controlledClubId);
        if (club == null) {
          throw StateError(
            'Controlled club ${summary.controlledClubId} is not canonical.',
          );
        }

        // M88 can only bind an existing typed slot. Re-adopt the authoritative
        // session loaded by that binding after the first M87 save.
        _binding = binding;
        _saveSummary = summary;
        _session = binding.session;
        _currentStep = binding.session.advance();
        _selectedClub = club;
        _persistenceMessage = 'Oyun kaydedildi.';
        saved = true;
      }
    } catch (_) {
      _persistenceError = 'Kayıt işlemi tamamlanamadı.';
      _persistenceMessage = null;
    } finally {
      _persistenceBusy = false;
      notifyListeners();
    }
    return saved;
  }

  Club? _clubById(String id) {
    for (final club in world.clubs) {
      if (club.id == id) return club;
    }
    return null;
  }
}
