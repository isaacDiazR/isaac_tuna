import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audio_repository_impl.dart';
import '../domain/models/audio_capture_error.dart';
import '../domain/repositories/audio_repository.dart';

/// Provee la instancia concreta de [AudioRepository].
///
/// Usa [AudioRepositoryImpl] como implementación. Al destruirse el provider
/// (p. ej. al salir del scope), se llama a [AudioRepositoryImpl.dispose]
/// para liberar el micrófono y los recursos asociados.
final audioRepositoryProvider = Provider<AudioRepository>((ref) {
  final repo = AudioRepositoryImpl();

  // Liberar recursos cuando el provider sea destruido.
  ref.onDispose(() => repo.dispose());

  return repo;
});

/// Expone el stream de buffers PCM normalizados del [AudioRepository].
///
/// Cada evento es un [List<double>] de exactamente 4 096 muestras
/// (valores en [−1.0, 1.0]).
///
/// Llama a [AudioRepository.startCapture] al inicializarse para solicitar
/// el permiso de micrófono y arrancar la grabación. Si el permiso es
/// denegado, el error se propaga vía [audioErrorProvider] y este stream
/// no emite ningún buffer (requisitos 1.1, 6.1).
final audioStreamProvider = StreamProvider<List<double>>((ref) async* {
  final repo = ref.watch(audioRepositoryProvider);
  await repo.startCapture(); // solicita permiso e inicia el grabador
  yield* repo.audioStream;
});

/// Expone el stream de errores de captura del [AudioRepository].
///
/// Cada evento es un [AudioCaptureError] que describe el tipo de fallo
/// y un mensaje legible.
///
/// Requisito 1.2 / 1.6: errores de permiso y del sistema se propagan aquí.
final audioErrorProvider = StreamProvider<AudioCaptureError>((ref) {
  final repo = ref.watch(audioRepositoryProvider);
  return repo.errorStream;
});
