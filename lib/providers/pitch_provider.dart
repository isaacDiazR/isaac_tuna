import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';

import '../core/constants/audio_constants.dart';
import '../core/constants/tuning_profiles.dart';
import '../domain/models/pitch_result.dart';
import '../domain/models/tuning_profile.dart';
import '../domain/usecases/analyze_pitch_usecase.dart';
import 'audio_provider.dart';

// ---------------------------------------------------------------------------
// Perfil de afinación activo
// ---------------------------------------------------------------------------

/// Perfil de afinación actualmente seleccionado por el usuario.
///
/// Inicializado con el perfil Estándar (E2 A2 D3 G3 B3 E4).
/// La [SettingsScreen] actualiza este provider al seleccionar un perfil.
///
/// Requisito 5.3: al seleccionar un perfil se actualiza de forma inmediata.
final activeTuningProfileProvider = StateProvider<TuningProfile>((ref) {
  return TuningProfiles.standard;
});

// ---------------------------------------------------------------------------
// Caso de uso
// ---------------------------------------------------------------------------

/// Provee la instancia de [AnalyzePitchUseCase] configurada con el perfil activo.
///
/// Se reconstruye automáticamente cuando [activeTuningProfileProvider] cambia,
/// garantizando que el análisis siempre use el perfil seleccionado.
///
/// Requisito 9.1: la capa de dominio no depende de Flutter.
final analyzePitchUseCaseProvider = Provider<AnalyzePitchUseCase>((ref) {
  final profile = ref.watch(activeTuningProfileProvider);

  final detector = PitchDetector(
    audioSampleRate: AudioConstants.sampleRate.toDouble(),
    bufferSize: AudioConstants.bufferSize,
  );

  return AnalyzePitchUseCase(
    detector: detector,
    profile: profile,
  );
});

// ---------------------------------------------------------------------------
// Cómputo en background isolate
// ---------------------------------------------------------------------------

/// Argumentos serializables para el isolate de análisis de pitch.
///
/// Contiene todo lo necesario para reconstruir el análisis sin referencias
/// al estado del hilo principal.
class _IsolateInput {
  final List<double> buffer;
  final TuningProfile profile;

  const _IsolateInput({required this.buffer, required this.profile});
}

/// Ejecuta el análisis completo de pitch en un isolate secundario.
///
/// Al ejecutarse fuera del hilo principal, el algoritmo YIN (O(N²)) no bloquea
/// la UI. El [PitchDetector] se crea dentro del isolate porque no es
/// transferible entre isolates (contiene el buffer interno _yinBuffer).
///
/// Debe ser una función de nivel superior para que [compute] pueda usarla.
Future<PitchResult> _analyzePitchInBackground(_IsolateInput input) async {
  final detector = PitchDetector(
    audioSampleRate: AudioConstants.sampleRate.toDouble(),
    bufferSize: input.buffer.length,
  );
  final useCase = AnalyzePitchUseCase(
    detector: detector,
    profile: input.profile,
  );
  return useCase.analyze(input.buffer);
}

// ---------------------------------------------------------------------------
// PitchNotifier
// ---------------------------------------------------------------------------

/// Notifier que mantiene el [PitchResult] más reciente.
///
/// Recibe buffers PCM a través de [processBuffer] y actualiza el estado
/// únicamente cuando el resultado difiere del estado actual, evitando
/// reconstrucciones innecesarias en la UI (requisito 9.4).
class PitchNotifier extends StateNotifier<PitchResult> {
  /// Perfil activo requerido para construir el análisis dentro del isolate.
  final TuningProfile _profile;

  PitchNotifier(TuningProfile profile) : _profile = profile, super(PitchResult.silent);

  /// Analiza [buffer] PCM en un isolate secundario y actualiza el estado
  /// si el resultado difiere del actual.
  ///
  /// Usar [compute] desplaza el algoritmo YIN (O(N²), ~4 M operaciones
  /// por buffer) fuera del hilo principal, eliminando el jank en la UI.
  ///
  /// Si el procesamiento supera 200 ms, descarta el resultado y conserva
  /// el último [PitchResult] válido (requisito 10.1).
  Future<void> processBuffer(List<double> buffer) async {
    final stopwatch = Stopwatch()..start();

    final PitchResult result;
    try {
      result = await compute(
        _analyzePitchInBackground,
        _IsolateInput(buffer: buffer, profile: _profile),
      );
    } catch (e) {
      debugPrint('[PitchNotifier] Error en análisis de pitch: $e');
      return;
    }

    stopwatch.stop();

    if (stopwatch.elapsedMilliseconds > 200) {
      debugPrint(
        '[PitchNotifier] Buffer descartado: procesamiento tardó '
        '${stopwatch.elapsedMilliseconds} ms (límite: 200 ms)',
      );
      return;
    }

    if (result != state) {
      state = result;
    }
  }
}

// ---------------------------------------------------------------------------
// pitchProvider
// ---------------------------------------------------------------------------

/// Expone el [PitchResult] más reciente como estado reactivo.
///
/// La [TunerScreen] observa este provider y se reconstruye únicamente cuando
/// el [PitchResult] cambia (requisito 9.4).
///
/// La conexión con [audioStreamProvider] se realiza mediante [ref.listen]
/// dentro del provider: cada buffer emitido por el stream de audio es
/// procesado automáticamente por [PitchNotifier.processBuffer].
///
/// Requisitos: 1.3, 9.4.
final pitchProvider =
    StateNotifierProvider<PitchNotifier, PitchResult>((ref) {
  final profile = ref.watch(activeTuningProfileProvider);

  final notifier = PitchNotifier(profile);

  ref.listen<AsyncValue<List<double>>>(
    audioStreamProvider,
    (_, next) {
      next.whenData((buffer) => notifier.processBuffer(buffer));
    },
  );

  return notifier;
});
