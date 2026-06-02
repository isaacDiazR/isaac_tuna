import '../models/audio_capture_error.dart';

/// Interfaz abstracta del repositorio de captura de audio.
///
/// Define el contrato que debe cumplir cualquier implementación concreta
/// de captura de audio, sin depender de ningún paquete de plataforma.
abstract class AudioRepository {
  /// Stream de buffers PCM normalizados (valores en [−1.0, 1.0]).
  ///
  /// Cada evento contiene exactamente [AudioConstants.bufferSize] muestras.
  Stream<List<double>> get audioStream;

  /// Inicia la captura de audio desde el micrófono.
  ///
  /// Lanza un error al [errorStream] si el permiso fue denegado o si
  /// el dispositivo de audio no está disponible.
  Future<void> startCapture();

  /// Detiene la captura de audio y libera los recursos asociados.
  Future<void> stopCapture();

  /// Stream de errores ocurridos durante la captura de audio.
  Stream<AudioCaptureError> get errorStream;
}
