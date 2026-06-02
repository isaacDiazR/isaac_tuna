/// Tipo de error de captura de audio.
enum AudioErrorType {
  /// El permiso de micrófono fue denegado por el usuario.
  permissionDenied,

  /// Error interno del sistema de audio.
  systemError,

  /// El dispositivo de audio no está disponible.
  deviceUnavailable,
}

/// Representa un error ocurrido durante la captura de audio.
///
/// [type] indica la categoría del error.
/// [message] contiene una descripción legible del fallo.
class AudioCaptureError {
  final AudioErrorType type;
  final String message;

  const AudioCaptureError({
    required this.type,
    required this.message,
  });

  @override
  String toString() => 'AudioCaptureError(type: $type, message: $message)';
}
