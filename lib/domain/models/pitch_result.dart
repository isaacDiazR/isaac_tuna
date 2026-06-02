import 'tuning_state.dart';

/// Resultado del análisis de tono producido por [AnalyzePitchUseCase].
///
/// Cuando [tuningState] es [TuningState.silent], todos los campos opcionales
/// son null. Usa [PitchResult.silent] como valor por defecto.
///
/// Implementa [operator ==] y [hashCode] para que Riverpod evite
/// reconstrucciones innecesarias cuando el valor no cambia.
class PitchResult {
  /// Nombre de la nota detectada (p. ej. "E", "C#"). Null si silent.
  final String? noteName;

  /// Octava MIDI estándar (C4 = Do central). Null si silent.
  final int? octave;

  /// Frecuencia detectada en Hz. Null si silent.
  final double? frequencyHz;

  /// Desviación en cents respecto a la nota más cercana, acotada a [−50, +50].
  /// Null si silent.
  final double? cents;

  /// Estado de afinación: flat / inTune / sharp / silent.
  final TuningState tuningState;

  /// Índice 1-based de la cuerda sugerida del perfil activo (1–6).
  /// Null si [tuningState] es [TuningState.silent].
  final int? suggestedString;

  const PitchResult({
    this.noteName,
    this.octave,
    this.frequencyHz,
    this.cents,
    required this.tuningState,
    this.suggestedString,
  });

  /// Valor constante que representa el estado silent (sin señal detectada).
  static const PitchResult silent = PitchResult(tuningState: TuningState.silent);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PitchResult) return false;
    return noteName == other.noteName &&
        octave == other.octave &&
        frequencyHz == other.frequencyHz &&
        cents == other.cents &&
        tuningState == other.tuningState &&
        suggestedString == other.suggestedString;
  }

  @override
  int get hashCode => Object.hash(
        noteName,
        octave,
        frequencyHz,
        cents,
        tuningState,
        suggestedString,
      );

  @override
  String toString() {
    if (tuningState == TuningState.silent) return 'PitchResult.silent';
    return 'PitchResult('
        'note: $noteName$octave, '
        'hz: $frequencyHz, '
        'cents: $cents, '
        'state: $tuningState, '
        'string: $suggestedString)';
  }
}
