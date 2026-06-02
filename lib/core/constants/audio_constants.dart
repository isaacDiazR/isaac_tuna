/// Constantes globales de configuración de audio y detección de tono.
///
/// Sin dependencias de Flutter — solo Dart puro.
class AudioConstants {
  AudioConstants._();

  /// Frecuencia de muestreo en Hz.
  static const int sampleRate = 44100;

  /// Tamaño nominal del buffer PCM en muestras (~93 ms a 44 100 Hz).
  static const int bufferSize = 4096;

  /// Umbral mínimo de confianza del detector de tono para considerar un
  /// resultado válido (0.0–1.0).
  ///
  /// El algoritmo YIN genera probabilidades entre 0.80–0.95 en condiciones
  /// normales de guitarra. 0.85 da buen balance entre sensibilidad y
  /// falsos positivos. Sube a 0.90+ para entornos muy silenciosos.
  static const double confidenceThreshold = 0;

  /// Frecuencia mínima detectable en Hz (corresponde aproximadamente a B1).
  static const double minFrequency = 60.0;

  /// Frecuencia máxima detectable en Hz (corresponde aproximadamente a F6).
  static const double maxFrequency = 1400.0;

  /// Frecuencia de referencia de La4 en Hz (temperamento igual estándar).
  static const double referenceA4 = 440.0;

  /// Umbral de afinación en cents para clasificar el estado `inTune`.
  /// Una desviación dentro de ±[tuningThresholdCents] se considera afinada.
  static const int tuningThresholdCents = 10;
}
