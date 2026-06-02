import 'dart:math';

/// Utilidades para calcular distancias en cents entre frecuencias.
///
/// Usada para determinar la cuerda sugerida en el perfil de afinación activo.
class CentsCalculator {
  CentsCalculator._();

  /// Calcula la distancia en cents entre dos frecuencias [f1] y [f2].
  ///
  /// cents = 1200 × log2(f1 / f2)
  /// El resultado puede ser positivo o negativo según si f1 > f2 o f1 < f2.
  static double centsBetween(double f1, double f2) {
    return 1200.0 * log(f1 / f2) / ln2;
  }

  /// Devuelve el índice (0-based) de la cuerda con menor distancia absoluta
  /// en cents respecto a [hz] dentro de [stringFrequencies].
  ///
  /// Si [stringFrequencies] está vacío, lanza [ArgumentError].
  static int closestStringIndex(double hz, List<double> stringFrequencies) {
    if (stringFrequencies.isEmpty) {
      throw ArgumentError('stringFrequencies no puede estar vacío');
    }

    int closestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < stringFrequencies.length; i++) {
      final double distance = centsBetween(hz, stringFrequencies[i]).abs();
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }
}
