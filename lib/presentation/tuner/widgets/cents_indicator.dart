import 'package:flutter/material.dart';

import '../../../domain/models/pitch_result.dart';
import '../../../domain/models/tuning_state.dart';

/// Indicador visual de desviación en cents (rango −50 a +50).
///
/// Anima la posición del indicador con duración máxima de 100 ms usando
/// [TweenAnimationBuilder]. Sin efectos de rebote ni elasticidad.
///
/// Muestra posición neutra (0) cuando [tuningState] es [TuningState.silent].
///
/// Requisitos: 4.3, 8.3
class CentsIndicator extends StatelessWidget {
  final PitchResult pitchResult;

  const CentsIndicator({super.key, required this.pitchResult});

  @override
  Widget build(BuildContext context) {
    final isSilent = pitchResult.tuningState == TuningState.silent;
    final double targetCents =
        (isSilent || pitchResult.cents == null) ? 0.0 : pitchResult.cents!;

    // Normalizar cents al rango [0, 1] donde 0.5 = centro (0 cents)
    final double normalizedTarget = (targetCents + 50.0) / 100.0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: normalizedTarget),
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear, // Sin rebote ni elasticidad
      builder: (context, value, child) {
        return _CentsIndicatorBar(normalizedPosition: value, cents: targetCents);
      },
    );
  }
}

class _CentsIndicatorBar extends StatelessWidget {
  final double normalizedPosition; // 0.0 = −50 cents, 0.5 = 0 cents, 1.0 = +50 cents
  final double cents;

  const _CentsIndicatorBar({
    required this.normalizedPosition,
    required this.cents,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double barWidth = constraints.maxWidth;
        const double indicatorWidth = 4.0;
        const double barHeight = 8.0;
        const double indicatorHeight = 24.0;

        // Posición del indicador en píxeles
        final double indicatorLeft =
            (normalizedPosition * barWidth) - (indicatorWidth / 2);

        return SizedBox(
          height: indicatorHeight + 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Barra de fondo
              Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Marca central (0 cents)
              Center(
                child: Container(
                  width: 2,
                  height: indicatorHeight,
                  color: Colors.white24,
                ),
              ),
              // Marcas de −25 y +25 cents
              Positioned(
                left: barWidth * 0.25 - 1,
                child: Container(
                  width: 1,
                  height: barHeight,
                  color: Colors.white12,
                ),
              ),
              Positioned(
                left: barWidth * 0.75 - 1,
                child: Container(
                  width: 1,
                  height: barHeight,
                  color: Colors.white12,
                ),
              ),
              // Indicador animado
              Positioned(
                left: indicatorLeft.clamp(0.0, barWidth - indicatorWidth),
                child: Container(
                  width: indicatorWidth,
                  height: indicatorHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
