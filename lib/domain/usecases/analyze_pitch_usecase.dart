import 'package:pitch_detector_dart/pitch_detector.dart';

import '../../core/constants/audio_constants.dart';
import '../../core/utils/cents_calculator.dart';
import '../../core/utils/note_converter.dart';
import '../models/pitch_result.dart';
import '../models/tuning_profile.dart';
import '../models/tuning_state.dart';

/// Caso de uso que analiza un buffer PCM y produce un [PitchResult].
///
/// Orquesta la detección de tono ([PitchDetector]), la conversión Hz → nota
/// ([NoteConverter]) y la clasificación del estado de afinación.
///
/// No importa nada de `package:flutter/...`.
class AnalyzePitchUseCase {
  final PitchDetector _detector;
  final TuningProfile _profile;

  /// Crea el caso de uso con el [detector] MPM y el [profile] de afinación activo.
  AnalyzePitchUseCase({
    required PitchDetector detector,
    required TuningProfile profile,
  })  : _detector = detector,
        _profile = profile;

  /// Analiza [buffer] PCM normalizado y retorna un [PitchResult].
  ///
  /// Pasos:
  /// 1. Invoca [PitchDetector.getPitchFromFloatBuffer] para obtener pitch y probability.
  /// 2. Si `probability < AudioConstants.confidenceThreshold` → [PitchResult.silent].
  /// 3. Si `pitch <= 0`, `pitch < AudioConstants.minFrequency` o
  ///    `pitch > AudioConstants.maxFrequency` → [PitchResult.silent].
  /// 4. Calcula semitonos, nombre de nota, octava y frecuencia objetivo.
  /// 5. Calcula desviación en cents.
  /// 6. Clasifica [TuningState] según umbral de ±10 cents.
  /// 7. Determina la cuerda sugerida (1-based) del perfil activo.
  /// 8. Retorna [PitchResult] completo.
  Future<PitchResult> analyze(List<double> buffer) async {
    final result = await _detector.getPitchFromFloatBuffer(buffer);

    // Paso 2: filtrar por confianza
    if (result.probability < AudioConstants.confidenceThreshold) {
      return PitchResult.silent;
    }

    final double pitch = result.pitch;

    // Paso 3: filtrar por rango de frecuencia válido
    if (pitch <= 0 ||
        pitch < AudioConstants.minFrequency ||
        pitch > AudioConstants.maxFrequency) {
      return PitchResult.silent;
    }

    // Paso 4: convertir Hz → semitonos, nombre de nota, octava, frecuencia objetivo
    final int semitones = NoteConverter.frequencyToSemitones(pitch);
    final String noteName = NoteConverter.semitonesToNoteName(semitones);
    final int octave = NoteConverter.semitonesToOctave(semitones);
    final double targetHz = NoteConverter.semitonesToFrequency(semitones);

    // Paso 5: calcular desviación en cents
    final double cents = NoteConverter.frequencyToCents(pitch, targetHz);

    // Paso 6: clasificar TuningState
    final TuningState tuningState;
    if (cents < -AudioConstants.tuningThresholdCents) {
      tuningState = TuningState.flat;
    } else if (cents > AudioConstants.tuningThresholdCents) {
      tuningState = TuningState.sharp;
    } else {
      tuningState = TuningState.inTune;
    }

    // Paso 7: determinar cuerda sugerida (1-based)
    final List<double> stringFrequencies =
        _profile.strings.map((s) => s.frequencyHz).toList();
    final int closestIndex =
        CentsCalculator.closestStringIndex(pitch, stringFrequencies);
    final int suggestedString = closestIndex + 1; // convertir a 1-based

    // Paso 8: retornar PitchResult completo
    return PitchResult(
      noteName: noteName,
      octave: octave,
      frequencyHz: pitch,
      cents: cents,
      tuningState: tuningState,
      suggestedString: suggestedString,
    );
  }
}
