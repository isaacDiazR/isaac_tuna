import 'package:flutter/material.dart';

import '../../../domain/models/pitch_result.dart';
import '../../../domain/models/tuning_state.dart';

/// Indicador de color según el estado de afinación.
///
/// - [TuningState.flat]   → azul  (#2196F3)
/// - [TuningState.inTune] → verde (#4CAF50)
/// - [TuningState.sharp]  → ámbar (#FFC107)
/// - [TuningState.silent] → sin color de estado (transparente)
///
/// Requisitos: 4.4, 4.5, 4.6
class TuningStateIndicator extends StatelessWidget {
  final PitchResult pitchResult;

  const TuningStateIndicator({super.key, required this.pitchResult});

  Color? _colorForState(TuningState state) {
    switch (state) {
      case TuningState.flat:
        return const Color(0xFF2196F3); // Azul
      case TuningState.inTune:
        return const Color(0xFF4CAF50); // Verde
      case TuningState.sharp:
        return const Color(0xFFFFC107); // Ámbar
      case TuningState.silent:
        return null; // Sin color de estado
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForState(pitchResult.tuningState);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? Colors.transparent,
        border: Border.all(
          color: color != null ? color.withValues(alpha: 0.5) : Colors.white24,
          width: 1.5,
        ),
      ),
    );
  }
}
