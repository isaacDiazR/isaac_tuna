import 'dart:math';

/// Utilidades de conversión entre frecuencias en Hz y notas musicales.
///
/// Usa temperamento igual con La4 = 440 Hz como referencia.
/// Notación científica con sostenidos (C, C#, D, D#, E, F, F#, G, G#, A, A#, B).
/// Octavas MIDI estándar: C4 = Do central.
class NoteConverter {
  NoteConverter._();

  static const List<String> _noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  /// Convierte una frecuencia en Hz al número de semitonos respecto a A4.
  ///
  /// semitones = round(12 × log2(hz / 440))
  static int frequencyToSemitones(double hz) {
    return (12.0 * log(hz / 440.0) / ln2).round();
  }

  /// Devuelve el nombre de la nota (sin octava) para el número de semitonos dado.
  ///
  /// Semitone 0 = A4, semitone -9 = C4, etc.
  /// Retorna nombres con sostenidos: C, C#, D, D#, E, F, F#, G, G#, A, A#, B.
  static String semitonesToNoteName(int semitones) {
    // A4 es el semitono 0. A4 corresponde al índice 9 en la escala cromática
    // (C=0, C#=1, D=2, D#=3, E=4, F=5, F#=6, G=7, G#=8, A=9, A#=10, B=11).
    final int noteIndex = ((semitones + 9) % 12 + 12) % 12;
    return _noteNames[noteIndex];
  }

  /// Calcula la octava MIDI estándar para el número de semitonos dado.
  ///
  /// C4 = Do central. A4 (semitone 0) está en la octava 4.
  /// La octava cambia en C, por lo que A4 y B4 están en octava 4,
  /// mientras que C4 está en octava 4 y B3 en octava 3.
  static int semitonesToOctave(int semitones) {
    // Calculamos el número de nota MIDI absoluto.
    // A4 = nota MIDI 69. C4 = nota MIDI 60.
    // midiNote = 69 + semitones
    // octave = (midiNote / 12).floor() - 1
    final int midiNote = 69 + semitones;
    return (midiNote / 12).floor() - 1;
  }

  /// Calcula la frecuencia exacta de la nota más cercana al número de semitonos dado.
  ///
  /// f_target = 440 × 2^(semitones / 12)
  static double semitonesToFrequency(int semitones) {
    return 440.0 * pow(2.0, semitones / 12.0);
  }

  /// Calcula la desviación en cents entre [hz] y [targetHz], acotada a [−50, +50].
  ///
  /// cents = 1200 × log2(hz / targetHz)
  static double frequencyToCents(double hz, double targetHz) {
    final double cents = 1200.0 * log(hz / targetHz) / ln2;
    return cents.clamp(-50.0, 50.0);
  }
}
