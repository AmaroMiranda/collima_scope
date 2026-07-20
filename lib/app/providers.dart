import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/local_store.dart';

final appPrefsProvider = Provider<AppPrefs>((ref) => AppPrefs());

/// Modo vermelho (astronomia). Persistido entre sessões.
class RedModeNotifier extends StateNotifier<bool> {
  final AppPrefs _prefs;

  RedModeNotifier(this._prefs) : super(false) {
    _prefs.getRedMode().then((v) => state = v);
  }

  Future<void> toggle() async {
    state = !state;
    await _prefs.setRedMode(state);
  }
}

final redModeProvider = StateNotifierProvider<RedModeNotifier, bool>(
    (ref) => RedModeNotifier(ref.watch(appPrefsProvider)));

/// Aviso de segurança solar (Etapa 0) aceito?
class SafetyNotifier extends StateNotifier<bool?> {
  final AppPrefs _prefs;

  SafetyNotifier(this._prefs) : super(null) {
    _prefs.getSafetyAccepted().then((v) => state = v);
  }

  Future<void> accept() async {
    state = true;
    await _prefs.setSafetyAccepted(true);
  }
}

final safetyAcceptedProvider = StateNotifierProvider<SafetyNotifier, bool?>(
    (ref) => SafetyNotifier(ref.watch(appPrefsProvider)));

// O antigo previewCalibratedProvider (boolean global e permanente) foi
// removido — auditoria P1.3: a verificação da imagem acontece a cada sessão
// e nunca marca nada como "calibrado".
