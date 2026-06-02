import 'package:permission_handler/permission_handler.dart';

/// Gestiona la solicitud y verificación del permiso de micrófono.
///
/// Encapsula la lógica de [permission_handler] para que [AudioRepositoryImpl]
/// no dependa directamente del paquete externo, facilitando el testing.
///
/// Requisitos: 6.1–6.5
class PermissionManager {
  const PermissionManager();

  /// Solicita el permiso de micrófono si aún no ha sido concedido.
  ///
  /// Retorna `true` si el permiso está concedido tras la solicitud.
  /// Retorna `false` si fue denegado (incluyendo denegación permanente).
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.status;

    if (status.isGranted) return true;

    // Solicitar al sistema operativo si no está concedido.
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  /// Retorna `true` si el permiso fue denegado de forma permanente
  /// (Android: "No preguntar de nuevo"; iOS: denegado explícitamente).
  Future<bool> isPermanentlyDenied() async {
    final status = await Permission.microphone.status;
    return status.isPermanentlyDenied;
  }

  /// Retorna el [PermissionStatus] actual del permiso de micrófono.
  Future<PermissionStatus> currentStatus() async {
    return Permission.microphone.status;
  }

  /// Abre los ajustes del sistema para que el usuario pueda habilitar
  /// el permiso manualmente (requisito 6.3).
  Future<bool> openSettings() => openAppSettings();
}
