/// Representa una cuerda individual dentro de un perfil de afinación.
///
/// [noteName] es el nombre de la nota (p. ej. "E", "C#", "Ab").
/// [octave] es la octava MIDI estándar (C4 = Do central).
/// [frequencyHz] es la frecuencia exacta en temperamento igual.
class TuningString {
  final String noteName;
  final int octave;
  final double frequencyHz;

  const TuningString({
    required this.noteName,
    required this.octave,
    required this.frequencyHz,
  });
}

/// Representa un perfil de afinación con nombre y lista de cuerdas.
///
/// [name] es el nombre de la afinación (p. ej. "Estándar", "Drop D").
/// [strings] contiene las 6 cuerdas; el índice 0 corresponde a la cuerda
/// más grave (6ª cuerda).
class TuningProfile {
  final String name;
  final List<TuningString> strings;

  const TuningProfile({
    required this.name,
    required this.strings,
  });
}
