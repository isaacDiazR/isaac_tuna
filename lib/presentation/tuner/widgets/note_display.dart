import 'package:flutter/material.dart';

import '../../../domain/models/pitch_result.dart';
import '../../../domain/models/tuning_state.dart';

/// Muestra la nota detectada con su octava en notación científica (p. ej. "E2").
///
/// Cuando [tuningState] es [TuningState.silent], muestra "–".
///
/// Requisitos: 4.1, 4.7, 8.5
class NoteDisplay extends StatelessWidget {
  final PitchResult pitchResult;

  const NoteDisplay({super.key, required this.pitchResult});

  @override
  Widget build(BuildContext context) {
    final isSilent = pitchResult.tuningState == TuningState.silent;

    final String displayText;
    if (isSilent) {
      displayText = '–';
    } else {
      displayText = '${pitchResult.noteName ?? '–'}${pitchResult.octave ?? ''}';
    }

    return Text(
      displayText,
      style: const TextStyle(
        fontSize: 96,
        fontWeight: FontWeight.w300,
        letterSpacing: -2,
        color: Colors.white,
        height: 1.0,
      ),
    );
  }
}
