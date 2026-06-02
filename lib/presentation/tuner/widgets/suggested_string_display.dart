import 'package:flutter/material.dart';

import '../../../domain/models/pitch_result.dart';
import '../../../domain/models/tuning_state.dart';

/// Muestra el número de cuerda sugerida (1–6) cuando [tuningState] no es silent.
///
/// No muestra nada cuando [tuningState] es [TuningState.silent].
///
/// Requisitos: 4.8, 4.9
class SuggestedStringDisplay extends StatelessWidget {
  final PitchResult pitchResult;

  const SuggestedStringDisplay({super.key, required this.pitchResult});

  @override
  Widget build(BuildContext context) {
    final isSilent = pitchResult.tuningState == TuningState.silent;

    if (isSilent || pitchResult.suggestedString == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Cuerda',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white54,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${pitchResult.suggestedString}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
