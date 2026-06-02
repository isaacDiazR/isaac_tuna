import 'package:flutter/material.dart';

import '../../../domain/models/pitch_result.dart';
import '../../../domain/models/tuning_state.dart';

/// Muestra la frecuencia detectada con 2 decimales (p. ej. "329.63 Hz").
///
/// Usa tipografía monoespaciada. Cuando [tuningState] es [TuningState.silent],
/// muestra "–".
///
/// Requisitos: 4.2, 4.7, 8.2
class FrequencyDisplay extends StatelessWidget {
  final PitchResult pitchResult;

  const FrequencyDisplay({super.key, required this.pitchResult});

  @override
  Widget build(BuildContext context) {
    final isSilent = pitchResult.tuningState == TuningState.silent;

    final String displayText;
    if (isSilent || pitchResult.frequencyHz == null) {
      displayText = '–';
    } else {
      displayText = '${pitchResult.frequencyHz!.toStringAsFixed(2)} Hz';
    }

    return Text(
      displayText,
      style: const TextStyle(
        fontSize: 24,
        fontFamily: 'monospace',
        fontWeight: FontWeight.w400,
        color: Colors.white70,
        letterSpacing: 0.5,
      ),
    );
  }
}
