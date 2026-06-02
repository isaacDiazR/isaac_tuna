import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:record/record.dart';

import '../core/constants/audio_constants.dart';
import '../core/utils/permission_manager.dart';
import '../domain/models/audio_capture_error.dart';
import '../domain/repositories/audio_repository.dart';

/// Implementación concreta de [AudioRepository] usando el paquete `record`.
///
/// Captura audio PCM int16 desde el micrófono, convierte las muestras a
/// [List<double>] normalizado (dividiendo por 32 768.0) y emite buffers de
/// exactamente [AudioConstants.bufferSize] muestras al [audioStream].
///
/// También escucha [AppLifecycleState] para reanudar la captura automáticamente
/// cuando la app regresa al primer plano (requisito 1.5).
class AudioRepositoryImpl extends WidgetsBindingObserver
    implements AudioRepository {
  // ---------------------------------------------------------------------------
  // Campos privados
  // ---------------------------------------------------------------------------

  final AudioRecorder _recorder;

  /// Gestiona la solicitud del permiso de micrófono (requisito 6.1).
  final PermissionManager _permissionManager;

  /// Controlador del stream de buffers PCM normalizados.
  StreamController<List<double>>? _controller;

  /// Controlador del stream de errores de captura.
  final StreamController<AudioCaptureError> _errorController =
      StreamController<AudioCaptureError>.broadcast();

  /// Acumulador de muestras pendientes de emitir.
  final List<double> _sampleBuffer = [];

  /// Suscripción al stream de bytes crudos del grabador.
  StreamSubscription<Uint8List>? _recorderSubscription;

  /// Indica si la captura está activa (o debería estarlo).
  bool _isCapturing = false;

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  AudioRepositoryImpl({AudioRecorder? recorder, PermissionManager? permissionManager})
      : _recorder = recorder ?? AudioRecorder(),
        _permissionManager = permissionManager ?? const PermissionManager() {
    WidgetsBinding.instance.addObserver(this);
  }

  // ---------------------------------------------------------------------------
  // AudioRepository — streams públicos
  // ---------------------------------------------------------------------------

  @override
  Stream<List<double>> get audioStream {
    _controller ??= StreamController<List<double>>.broadcast();
    return _controller!.stream;
  }

  @override
  Stream<AudioCaptureError> get errorStream => _errorController.stream;

  // ---------------------------------------------------------------------------
  // AudioRepository — startCapture
  // ---------------------------------------------------------------------------

  @override
  Future<void> startCapture() async {
    // Verificar/solicitar permiso de micrófono mediante PermissionManager
    // (requisito 6.1).
    final granted = await _permissionManager.requestMicrophonePermission();

    if (!granted) {
      _errorController.add(
        const AudioCaptureError(
          type: AudioErrorType.permissionDenied,
          message:
              'El permiso de micrófono fue denegado. '
              'Habilítalo en los ajustes del sistema para usar el afinador.',
        ),
      );
      return;
    }

    await _startRecording();
  }

  // ---------------------------------------------------------------------------
  // AudioRepository — stopCapture
  // ---------------------------------------------------------------------------

  @override
  Future<void> stopCapture() async {
    _isCapturing = false;
    await _stopRecording();
  }

  // ---------------------------------------------------------------------------
  // AppLifecycleObserver — reanudación automática (requisito 1.5)
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isCapturing) {
      // La app volvió al primer plano; reanudar captura.
      _startRecording();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // La app pasó a segundo plano; detener captura y liberar micrófono
      // (requisito 1.4), pero mantener _isCapturing = true para reanudar.
      _stopRecording();
    }
  }

  // ---------------------------------------------------------------------------
  // Métodos internos
  // ---------------------------------------------------------------------------

  /// Inicia la grabación en modo stream y conecta el procesamiento de bytes.
  Future<void> _startRecording() async {
    // Evitar iniciar si ya hay una grabación activa.
    if (await _recorder.isRecording()) return;

    // Recrear el StreamController si fue cerrado previamente.
    if (_controller == null || _controller!.isClosed) {
      _controller = StreamController<List<double>>.broadcast();
    }

    _sampleBuffer.clear();

    try {
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: AudioConstants.sampleRate, // 44 100 Hz
        numChannels: 1,
      );

      final rawStream = await _recorder.startStream(config);
      _isCapturing = true;

      _recorderSubscription = rawStream.listen(
        _onAudioChunk,
        onError: _onRecorderError,
        cancelOnError: false,
      );
    } catch (e) {
      _isCapturing = false;
      debugPrint('[AudioRepository] Error al iniciar captura: $e');
      _errorController.add(
        AudioCaptureError(
          type: AudioErrorType.systemError,
          message: 'Error al iniciar la captura de audio: $e',
        ),
      );
    }
  }

  /// Detiene la grabación y cancela la suscripción al stream de bytes.
  ///
  /// El [_controller] NO se cierra aquí: mantenerlo vivo permite que
  /// [audioStream] (y el `yield*` de [audioStreamProvider]) sobreviva el
  /// ciclo pause → resume sin que Riverpod pierda la suscripción al stream.
  Future<void> _stopRecording() async {
    await _recorderSubscription?.cancel();
    _recorderSubscription = null;

    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {
      // Ignorar errores al detener; el recurso ya puede estar liberado.
    }

    _sampleBuffer.clear();
  }

  /// Procesa un chunk de bytes PCM int16 recibido del grabador.
  ///
  /// Convierte los bytes a muestras [double] normalizadas y las acumula hasta
  /// tener exactamente [AudioConstants.bufferSize] muestras, momento en que
  /// emite el buffer al [audioStream] (requisito 1.3 / 10.2).
  void _onAudioChunk(Uint8List bytes) {
    if (_controller == null || _controller!.isClosed) return;
    // PCM int16 little-endian: 2 bytes por muestra.
    final byteData = ByteData.sublistView(bytes);
    final sampleCount = bytes.length ~/ 2;

    for (int i = 0; i < sampleCount; i++) {
      final int16 = byteData.getInt16(i * 2, Endian.little);
      _sampleBuffer.add(int16 / 32768.0);

      if (_sampleBuffer.length == AudioConstants.bufferSize) {
        // Emitir una copia inmutable del buffer acumulado.
        final buffer = List<double>.unmodifiable(_sampleBuffer);
        _controller?.add(buffer);
        _sampleBuffer.clear();
      }
    }
  }

  /// Maneja errores emitidos por el stream del grabador (requisito 1.6).
  void _onRecorderError(Object error, StackTrace stackTrace) {
    _isCapturing = false;
    _errorController.add(
      AudioCaptureError(
        type: AudioErrorType.systemError,
        message: 'Error del sistema de audio: $error',
      ),
    );
    // Detener la captura hasta que se solicite reinicio explícito.
    _stopRecording();
  }

  // ---------------------------------------------------------------------------
  // Limpieza de recursos
  // ---------------------------------------------------------------------------

  /// Libera todos los recursos asociados a esta instancia.
  ///
  /// Debe llamarse cuando el repositorio ya no sea necesario (p. ej. al
  /// destruir el provider de Riverpod).
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _isCapturing = false;
    await _stopRecording();
    // Cerrar el controller aquí (y no en _stopRecording) para no matar el
    // yield* de audioStreamProvider durante pause/resume.
    await _controller?.close();
    _controller = null;
    await _errorController.close();
    await _recorder.dispose();
  }
}
