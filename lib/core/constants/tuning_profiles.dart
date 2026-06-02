import 'dart:math' as math;

import '../../domain/models/tuning_profile.dart';

// ---------------------------------------------------------------------------
// Frecuencias precalculadas con temperamento igual: f = 440 × 2^(semitones/12)
// Semitonos relativos a La4 (semitone 0 = A4 = 440 Hz).
// ---------------------------------------------------------------------------

double _freq(int semitones) => 440.0 * math.pow(2.0, semitones / 12.0);

// Notas usadas en los perfiles (semitonos desde A4):
//   C2  = -33   D2  = -31   Eb2 = -30   E2  = -29
//   G2  = -26   Ab2 = -25   A2  = -24   B2  = -22
//   C3  = -21   Db3 = -20   D3  = -19   E3  = -17
//   F3  = -16   F#3 = -15   Gb3 = -15   G3  = -14
//   G#3 = -13   A3  = -12   Bb3 = -11   B3  = -10
//   C#4 = -8    D4  = -7    Eb4 = -6    E4  = -5

/// Clase que expone los 10 perfiles de afinación predefinidos como miembros
/// estáticos de tipo [TuningProfile].
///
/// Las frecuencias están calculadas con temperamento igual (La4 = 440 Hz).
/// El índice 0 de [TuningProfile.strings] corresponde a la cuerda más
/// grave (6ª cuerda).
///
/// Sin dependencias de Flutter — solo Dart puro.
class TuningProfiles {
  TuningProfiles._();

  // -------------------------------------------------------------------------
  // 1. Estándar — E2 A2 D3 G3 B3 E4
  // -------------------------------------------------------------------------
  static final TuningProfile standard = TuningProfile(
    name: 'Estándar',
    strings: [
      TuningString(noteName: 'E', octave: 2, frequencyHz: _freq(-29)), // E2  ≈  82.41 Hz
      TuningString(noteName: 'A', octave: 2, frequencyHz: _freq(-24)), // A2  = 110.00 Hz
      TuningString(noteName: 'D', octave: 3, frequencyHz: _freq(-19)), // D3  ≈ 146.83 Hz
      TuningString(noteName: 'G', octave: 3, frequencyHz: _freq(-14)), // G3  ≈ 196.00 Hz
      TuningString(noteName: 'B', octave: 3, frequencyHz: _freq(-10)), // B3  ≈ 246.94 Hz
      TuningString(noteName: 'E', octave: 4, frequencyHz: _freq(-5)),  // E4  ≈ 329.63 Hz
    ],
  );

  // -------------------------------------------------------------------------
  // 2. Drop D — D2 A2 D3 G3 B3 E4
  // -------------------------------------------------------------------------
  static final TuningProfile dropD = TuningProfile(
    name: 'Drop D',
    strings: [
      TuningString(noteName: 'D', octave: 2, frequencyHz: _freq(-31)), // D2  ≈  73.42 Hz
      TuningString(noteName: 'A', octave: 2, frequencyHz: _freq(-24)), // A2  = 110.00 Hz
      TuningString(noteName: 'D', octave: 3, frequencyHz: _freq(-19)), // D3  ≈ 146.83 Hz
      TuningString(noteName: 'G', octave: 3, frequencyHz: _freq(-14)), // G3  ≈ 196.00 Hz
      TuningString(noteName: 'B', octave: 3, frequencyHz: _freq(-10)), // B3  ≈ 246.94 Hz
      TuningString(noteName: 'E', octave: 4, frequencyHz: _freq(-5)),  // E4  ≈ 329.63 Hz
    ],
  );

  // -------------------------------------------------------------------------
  // 3. Open G — D2 G2 D3 G3 B3 D4
  // -------------------------------------------------------------------------
  static final TuningProfile openG = TuningProfile(
    name: 'Open G',
    strings: [
      TuningString(noteName: 'D', octave: 2, frequencyHz: _freq(-31)), // D2  ≈  73.42 Hz
      TuningString(noteName: 'G', octave: 2, frequencyHz: _freq(-26)), // G2  ≈  98.00 Hz
      TuningString(noteName: 'D', octave: 3, frequencyHz: _freq(-19)), // D3  ≈ 146.83 Hz
      TuningString(noteName: 'G', octave: 3, frequencyHz: _freq(-14)), // G3  ≈ 196.00 Hz
      TuningString(noteName: 'B', octave: 3, frequencyHz: _freq(-10)), // B3  ≈ 246.94 Hz
      TuningString(noteName: 'D', octave: 4, frequencyHz: _freq(-7)),  // D4  ≈ 293.66 Hz
    ],
  );

  // -------------------------------------------------------------------------
  // 4. Open D — D2 A2 D3 F#3 A3 D4
  // -------------------------------------------------------------------------
  static final TuningProfile openD = TuningProfile(
    name: 'Open D',
    strings: [
      TuningString(noteName: 'D',  octave: 2, frequencyHz: _freq(-31)), // D2  ≈  73.42 Hz
      TuningString(noteName: 'A',  octave: 2, frequencyHz: _freq(-24)), // A2  = 110.00 Hz
      TuningString(noteName: 'D',  octave: 3, frequencyHz: _freq(-19)), // D3  ≈ 146.83 Hz
      TuningString(noteName: 'F#', octave: 3, frequencyHz: _freq(-15)), // F#3 ≈ 185.00 Hz
      TuningString(noteName: 'A',  octave: 3, frequencyHz: _freq(-12)), // A3  = 220.00 Hz
      TuningString(noteName: 'D',  octave: 4, frequencyHz: _freq(-7)),  // D4  ≈ 293.66 Hz
    ],
  );

  // -------------------------------------------------------------------------
  // 5. Open E — E2 B2 E3 G#3 B3 E4
  // -------------------------------------------------------------------------
  static final TuningProfile openE = TuningProfile(
    name: 'Open E',
    strings: [
      TuningString(noteName: 'E',  octave: 2, frequencyHz: _freq(-29)), // E2  ≈  82.41 Hz
      TuningString(noteName: 'B',  octave: 2, frequencyHz: _freq(-22)), // B2  ≈ 123.47 Hz
      TuningString(noteName: 'E',  octave: 3, frequencyHz: _freq(-17)), // E3  ≈ 164.81 Hz
      TuningString(noteName: 'G#', octave: 3, frequencyHz: _freq(-13)), // G#3 ≈ 207.65 Hz
      TuningString(noteName: 'B',  octave: 3, frequencyHz: _freq(-10)), // B3  ≈ 246.94 Hz
      TuningString(noteName: 'E',  octave: 4, frequencyHz: _freq(-5)),  // E4  ≈ 329.63 Hz
    ],
  );

  // -------------------------------------------------------------------------
  // 6. Open A — E2 A2 E3 A3 C#4 E4
  // -------------------------------------------------------------------------
  static final TuningProfile openA = TuningProfile(
    name: 'Open A',
    strings: [
      TuningString(noteName: 'E',  octave: 2, frequencyHz: _freq(-29)), // E2  ≈  82.41 Hz
      TuningString(noteName: 'A',  octave: 2, frequencyHz: _freq(-24)), // A2  = 110.00 Hz
      TuningString(noteName: 'E',  octave: 3, frequencyHz: _freq(-17)), // E3  ≈ 164.81 Hz
      TuningString(noteName: 'A',  octave: 3, frequencyHz: _freq(-12)), // A3  = 220.00 Hz
      TuningString(noteName: 'C#', octave: 4, frequencyHz: _freq(-8)),  // C#4 ≈ 277.18 Hz
      TuningString(noteName: 'E',  octave: 4, frequencyHz: _freq(-5)),  // E4  ≈ 329.63 Hz
    ],
  );

  // -------------------------------------------------------------------------
  // 7. DADGAD — D2 A2 D3 G3 A3 D4
  // -------------------------------------------------------------------------
  static final TuningProfile dadgad = TuningProfile(
    name: 'DADGAD',
    strings: [
      TuningString(noteName: 'D', octave: 2, frequencyHz: _freq(-31)), // D2  ≈  73.42 Hz
      TuningString(noteName: 'A', octave: 2, frequencyHz: _freq(-24)), // A2  = 110.00 Hz
      TuningString(noteName: 'D', octave: 3, frequencyHz: _freq(-19)), // D3  ≈ 146.83 Hz
      TuningString(noteName: 'G', octave: 3, frequencyHz: _freq(-14)), // G3  ≈ 196.00 Hz
      TuningString(noteName: 'A', octave: 3, frequencyHz: _freq(-12)), // A3  = 220.00 Hz
      TuningString(noteName: 'D', octave: 4, frequencyHz: _freq(-7)),  // D4  ≈ 293.66 Hz
    ],
  );

  // -------------------------------------------------------------------------
  // 8. Drop C — C2 G2 C3 F3 A3 D4
  // -------------------------------------------------------------------------
  static final TuningProfile dropC = TuningProfile(
    name: 'Drop C',
    strings: [
      TuningString(noteName: 'C', octave: 2, frequencyHz: _freq(-33)), // C2  ≈  65.41 Hz
      TuningString(noteName: 'G', octave: 2, frequencyHz: _freq(-26)), // G2  ≈  98.00 Hz
      TuningString(noteName: 'C', octave: 3, frequencyHz: _freq(-21)), // C3  ≈ 130.81 Hz
      TuningString(noteName: 'F', octave: 3, frequencyHz: _freq(-16)), // F3  ≈ 174.61 Hz
      TuningString(noteName: 'A', octave: 3, frequencyHz: _freq(-12)), // A3  = 220.00 Hz
      TuningString(noteName: 'D', octave: 4, frequencyHz: _freq(-7)),  // D4  ≈ 293.66 Hz
    ],
  );

  // -------------------------------------------------------------------------
  // 9. Eb — Eb2 Ab2 Db3 Gb3 Bb3 Eb4
  // -------------------------------------------------------------------------
  static final TuningProfile eb = TuningProfile(
    name: 'Eb',
    strings: [
      TuningString(noteName: 'Eb', octave: 2, frequencyHz: _freq(-30)), // Eb2 ≈  77.78 Hz
      TuningString(noteName: 'Ab', octave: 2, frequencyHz: _freq(-25)), // Ab2 ≈ 103.83 Hz
      TuningString(noteName: 'Db', octave: 3, frequencyHz: _freq(-20)), // Db3 ≈ 138.59 Hz
      TuningString(noteName: 'Gb', octave: 3, frequencyHz: _freq(-15)), // Gb3 ≈ 185.00 Hz
      TuningString(noteName: 'Bb', octave: 3, frequencyHz: _freq(-11)), // Bb3 ≈ 233.08 Hz
      TuningString(noteName: 'Eb', octave: 4, frequencyHz: _freq(-6)),  // Eb4 ≈ 311.13 Hz
    ],
  );

  // -------------------------------------------------------------------------
  // 10. D Full Step Down — D2 G2 C3 F3 A3 D4
  // -------------------------------------------------------------------------
  static final TuningProfile dFullStepDown = TuningProfile(
    name: 'D Full Step Down',
    strings: [
      TuningString(noteName: 'D', octave: 2, frequencyHz: _freq(-31)), // D2  ≈  73.42 Hz
      TuningString(noteName: 'G', octave: 2, frequencyHz: _freq(-26)), // G2  ≈  98.00 Hz
      TuningString(noteName: 'C', octave: 3, frequencyHz: _freq(-21)), // C3  ≈ 130.81 Hz
      TuningString(noteName: 'F', octave: 3, frequencyHz: _freq(-16)), // F3  ≈ 174.61 Hz
      TuningString(noteName: 'A', octave: 3, frequencyHz: _freq(-12)), // A3  = 220.00 Hz
      TuningString(noteName: 'D', octave: 4, frequencyHz: _freq(-7)),  // D4  ≈ 293.66 Hz
    ],
  );

  /// Lista ordenada de todos los perfiles predefinidos.
  static final List<TuningProfile> all = [
    standard,
    dropD,
    openG,
    openD,
    openE,
    openA,
    dadgad,
    dropC,
    eb,
    dFullStepDown,
  ];
}
