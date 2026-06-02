# Plan de Implementación — IsaacTuna

## Grafo de Dependencias de Tareas

```
Tarea 1 (Proyecto base)
   └── Tarea 2 (core/constants)
         └── Tarea 3 (core/utils: NoteConverter + CentsCalculator)
               └── Tarea 4 (domain/models)
                     └── Tarea 5 (domain/repositories + AudioCaptureError)
                           ├── Tarea 6 (domain/usecases: AnalyzePitchUseCase)
                           │     └── Tarea 8 (providers)
                           │           ├── Tarea 9 (presentation/tuner)
                           │           └── Tarea 10 (presentation/settings)
                           └── Tarea 7 (data: AudioRepositoryImpl)
                                 └── Tarea 8 (providers)

Tarea 11 (Permisos de plataforma) — paralela a Tarea 7
Tarea 12 (Pruebas unitarias) — depende de Tareas 3, 4, 6
Tarea 13 (Pruebas de integración / widget) — depende de Tareas 8, 9, 10
Tarea 14 (Diseño visual y tema) — depende de Tarea 9
Tarea 15 (Rendimiento y descarte de buffers) — depende de Tareas 7, 8
```

---

## Tasks

- [x] 1. Inicializar el proyecto Flutter y configurar dependencias
  - Crear el proyecto Flutter con soporte para Android (API 21+) e iOS (13+).
  - Agregar al `pubspec.yaml` las dependencias exactas:
    - `pitch_detector_dart: ^0.0.7`
    - `record: ^5.0.0` (o la versión estable más reciente compatible)
    - `permission_handler: ^11.0.0`
    - `flutter_riverpod: ^2.0.0`
  - Crear la estructura de directorios vacía:
    `lib/core/constants/`, `lib/core/utils/`, `lib/data/`, `lib/domain/models/`, `lib/domain/repositories/`, `lib/domain/usecases/`, `lib/presentation/tuner/widgets/`, `lib/presentation/settings/`, `lib/providers/`
  - Ejecutar `flutter pub get` y verificar que no hay conflictos de versiones.
  - _Requisitos: 9.1, 9.2_

- [x] 2. Implementar constantes globales de audio y perfiles de afinación
  - Crear `lib/core/constants/audio_constants.dart` con la clase `AudioConstants`:
    - `sampleRate = 44100`
    - `bufferSize = 4096`
    - `confidenceThreshold = 0.90`
    - `minFrequency = 60.0`
    - `maxFrequency = 1400.0`
    - `referenceA4 = 440.0`
    - `tuningThresholdCents = 10`
  - Crear `lib/core/constants/tuning_profiles.dart` con los 10 perfiles predefinidos como constantes estáticas de tipo `TuningProfile` (ver Tarea 4 para el modelo; usar `late` o factory si el modelo aún no existe, o definir los datos como `Map` y convertir en Tarea 4):
    - Estándar: E2 A2 D3 G3 B3 E4
    - Drop D: D2 A2 D3 G3 B3 E4
    - Open G: D2 G2 D3 G3 B3 D4
    - Open D: D2 A2 D3 F#3 A3 D4
    - Open E: E2 B2 E3 G#3 B3 E4
    - Open A: E2 A2 E3 A3 C#4 E4
    - DADGAD: D2 A2 D3 G3 A3 D4
    - Drop C: C2 G2 C3 F3 A3 D4
    - Eb: Eb2 Ab2 Db3 Gb3 Bb3 Eb4
    - D Full Step Down: D2 G2 C3 F3 A3 D4
  - Las frecuencias de cada cuerda deben calcularse con temperamento igual (La4 = 440 Hz): `f = 440 × 2^(semitones/12)`.
  - _Requisitos: 5.1_

- [x] 3. Implementar utilidades de conversión de frecuencia a nota musical
  - Crear `lib/core/utils/note_converter.dart` con la clase `NoteConverter` (solo Dart puro, sin imports de Flutter):
    - `static int frequencyToSemitones(double hz)` → `round(12 × log2(hz / 440))`
    - `static String semitonesToNoteName(int semitones)` → nombre en notación científica con sostenidos (C, C#, D, D#, E, F, F#, G, G#, A, A#, B)
    - `static int semitonesToOctave(int semitones)` → octava MIDI (C4 = Do central, semitone 0 = A4)
    - `static double semitonesToFrequency(int semitones)` → `440 × 2^(semitones/12)`
    - `static double frequencyToCents(double hz, double targetHz)` → `1200 × log2(hz / targetHz)`, acotado a [−50, +50]
  - Crear `lib/core/utils/cents_calculator.dart` con la clase `CentsCalculator`:
    - `static double centsBetween(double f1, double f2)` → distancia en cents entre dos frecuencias
    - `static int closestStringIndex(double hz, List<double> stringFrequencies)` → índice (0-based) de la cuerda con menor distancia absoluta en cents
  - Verificar que ningún archivo importa `package:flutter/...`.
  - _Requisitos: 2.4, 2.5, 7.1, 7.2, 7.4, 9.2_

- [x] 4. Implementar los modelos de dominio
  - Crear `lib/domain/models/tuning_state.dart`:
    ```dart
    enum TuningState { flat, inTune, sharp, silent }
    ```
  - Crear `lib/domain/models/tuning_profile.dart` con `TuningProfile` y `TuningString`:
    - `TuningProfile`: `name`, `strings` (List<TuningString>, índice 0 = cuerda más grave)
    - `TuningString`: `noteName`, `octave`, `frequencyHz`
    - Ambas clases deben ser `const`-constructibles.
  - Crear `lib/domain/models/pitch_result.dart` con `PitchResult`:
    - Campos: `noteName`, `octave`, `frequencyHz`, `cents`, `tuningState`, `suggestedString` (índice 1–6, null si silent)
    - Constante estática: `PitchResult.silent`
    - Implementar `operator ==` y `hashCode` para evitar reconstrucciones innecesarias en Riverpod.
  - Crear `lib/domain/models/audio_capture_error.dart` con `AudioCaptureError` y `AudioErrorType`:
    ```dart
    enum AudioErrorType { permissionDenied, systemError, deviceUnavailable }
    class AudioCaptureError { final AudioErrorType type; final String message; }
    ```
  - Actualizar `lib/core/constants/tuning_profiles.dart` para usar los modelos reales si se usaron datos temporales en Tarea 2.
  - _Requisitos: 2.2, 2.3, 3.1–3.4, 4.1, 4.7, 9.1_

- [x] 5. Definir la interfaz abstracta del repositorio de audio
  - Crear `lib/domain/repositories/audio_repository.dart` con la clase abstracta `AudioRepository`:
    ```dart
    abstract class AudioRepository {
      Stream<List<double>> get audioStream;
      Future<void> startCapture();
      Future<void> stopCapture();
      Stream<AudioCaptureError> get errorStream;
    }
    ```
  - Verificar que el archivo no importa nada de `package:flutter/...`, `record` ni `permission_handler`.
  - _Requisitos: 1.1–1.6, 9.2, 9.3_

- [x] 6. Implementar el caso de uso AnalyzePitchUseCase
  - Crear `lib/domain/usecases/analyze_pitch_usecase.dart` con la clase `AnalyzePitchUseCase`:
    - Constructor recibe `PitchDetector` (de `pitch_detector_dart`) y `TuningProfile` activo.
    - Método `PitchResult analyze(List<double> buffer)`:
      1. Invocar `_detector.getPitch(buffer)` → `{pitch, probability}`.
      2. Si `probability < AudioConstants.confidenceThreshold` → retornar `PitchResult.silent`.
      3. Si `pitch <= 0` o `pitch < AudioConstants.minFrequency` o `pitch > AudioConstants.maxFrequency` → retornar `PitchResult.silent`.
      4. Calcular `semitones = NoteConverter.frequencyToSemitones(pitch)`.
      5. Calcular `noteName`, `octave`, `targetHz` usando `NoteConverter`.
      6. Calcular `cents = NoteConverter.frequencyToCents(pitch, targetHz)`.
      7. Clasificar `TuningState`:
         - `cents < -10` → `flat`
         - `-10 <= cents <= 10` → `inTune`
         - `cents > 10` → `sharp`
      8. Determinar `suggestedString` (1-based) usando `CentsCalculator.closestStringIndex` sobre las frecuencias del perfil activo.
      9. Retornar `PitchResult` completo.
  - Verificar que el archivo no importa nada de `package:flutter/...`.
  - _Requisitos: 2.1–2.7, 3.1–3.4, 7.1–7.5_

- [x] 7. Implementar AudioRepositoryImpl en la capa de datos
  - Crear `lib/data/audio_repository_impl.dart` con la clase `AudioRepositoryImpl implements AudioRepository`:
    - Usar el paquete `record` (`AudioRecorder`) para captura de audio.
    - Configurar `RecordConfig` con `sampleRate: 44100`, `numChannels: 1`, formato PCM int16.
    - Convertir bytes PCM int16 a `List<double>` normalizado (dividir por 32768.0).
    - Emitir buffers de exactamente `AudioConstants.bufferSize` (4096) muestras al `StreamController<List<double>>`.
    - Implementar `startCapture()`: verificar permiso antes de iniciar; si no hay permiso, emitir `AudioCaptureError(type: AudioErrorType.permissionDenied, ...)` al `errorStream` y no iniciar.
    - Implementar `stopCapture()`: detener `_recorder`, cerrar `_controller`.
    - Capturar excepciones del sistema y emitirlas al `errorStream` como `AudioCaptureError(type: AudioErrorType.systemError, ...)`.
    - Implementar reanudación automática cuando la app regresa al primer plano (escuchar `AppLifecycleState`).
  - _Requisitos: 1.1–1.6, 10.2_

- [x] 8. Implementar los providers de Riverpod
  - Crear `lib/providers/audio_provider.dart`:
    - `audioRepositoryProvider`: `Provider<AudioRepository>` que provee `AudioRepositoryImpl`.
    - `audioStreamProvider`: `StreamProvider<List<double>>` que expone `repo.audioStream`.
    - `audioErrorProvider`: `StreamProvider<AudioCaptureError>` que expone `repo.errorStream`.
  - Crear `lib/providers/pitch_provider.dart`:
    - `activeTuningProfileProvider`: `StateProvider<TuningProfile>` inicializado con el perfil Estándar.
    - `analyzePitchUseCaseProvider`: `Provider<AnalyzePitchUseCase>` que construye el caso de uso con el perfil activo.
    - `PitchNotifier extends StateNotifier<PitchResult>`:
      - Constructor recibe `AnalyzePitchUseCase`.
      - Método `void processBuffer(List<double> buffer)`: llama `_useCase.analyze(buffer)` y actualiza estado solo si `result != state`.
    - `pitchProvider`: `StateNotifierProvider<PitchNotifier, PitchResult>`.
    - Conectar `audioStreamProvider` con `pitchProvider` para que cada buffer sea procesado automáticamente (usar `ref.listen` o un `Provider` intermedio).
  - _Requisitos: 1.3, 9.4_

- [x] 9. Implementar la pantalla principal TunerScreen y sus widgets
  - Crear `lib/presentation/tuner/tuner_screen.dart`:
    - Widget `ConsumerWidget` que observa `pitchProvider`.
    - Componer los sub-widgets: `NoteDisplay`, `FrequencyDisplay`, `CentsIndicator`, `TuningStateIndicator`, `SuggestedStringDisplay`, `ActiveTuningLabel`.
    - Botón/icono de navegación hacia `SettingsScreen`.
  - Crear `lib/presentation/tuner/widgets/note_display.dart`:
    - Muestra `noteName + octave` en notación científica (p. ej. "E2") con tipografía grande (al menos 2× el tamaño de los valores secundarios).
    - Muestra "–" cuando `tuningState == silent`.
  - Crear `lib/presentation/tuner/widgets/frequency_display.dart`:
    - Muestra `frequencyHz` con 2 decimales (p. ej. "329.63 Hz") con tipografía monoespaciada.
    - Muestra "–" cuando `tuningState == silent`.
  - Crear `lib/presentation/tuner/widgets/cents_indicator.dart`:
    - Barra o aguja de −50 a +50 cents.
    - Usar `AnimatedContainer` o `TweenAnimationBuilder` con duración máxima de 100 ms.
    - Sin efectos de rebote, elasticidad ni transiciones decorativas.
    - Muestra posición neutra (0) cuando `tuningState == silent`.
  - Crear `lib/presentation/tuner/widgets/tuning_state_indicator.dart`:
    - Color azul para `flat`, verde para `inTune`, ámbar para `sharp`.
    - Sin color de estado cuando `silent`.
  - Crear `lib/presentation/tuner/widgets/suggested_string_display.dart`:
    - Muestra el número de cuerda sugerida (1–6) cuando `tuningState != silent`.
    - No muestra nada cuando `tuningState == silent`.
  - Crear `lib/presentation/tuner/widgets/active_tuning_label.dart`:
    - Muestra el nombre del perfil activo (observa `activeTuningProfileProvider`).
  - _Requisitos: 4.1–4.9, 8.2, 8.3, 8.5_

- [x] 10. Implementar la pantalla de selección de afinación SettingsScreen
  - Crear `lib/presentation/settings/settings_screen.dart`:
    - Widget `ConsumerWidget` que observa `activeTuningProfileProvider`.
    - Mostrar lista de los 10 perfiles con nombre y notas de las 6 cuerdas en notación científica.
    - Marcar visualmente el perfil activo (check, resaltado o color de acento).
    - Al seleccionar un perfil: actualizar `activeTuningProfileProvider` y navegar de regreso a `TunerScreen` con `Navigator.pop` o `GoRouter`.
    - Si la navegación automática falla, mantener el perfil seleccionado activo (el estado ya fue actualizado antes de navegar).
  - Configurar la navegación en `lib/main.dart` o en un archivo de rutas dedicado.
  - _Requisitos: 5.1–5.6_

- [x] 11. Configurar permisos de plataforma
  - **Android** (`android/app/src/main/AndroidManifest.xml`):
    - Agregar `<uses-permission android:name="android.permission.RECORD_AUDIO" />`.
    - Verificar `minSdkVersion 21` en `android/app/build.gradle`.
  - **iOS** (`ios/Runner/Info.plist`):
    - Agregar la clave `NSMicrophoneUsageDescription` con una descripción en español, p. ej.: `"IsaacTuna necesita acceso al micrófono para detectar la nota que estás tocando."`.
  - Implementar `PermissionManager` en `lib/core/utils/permission_manager.dart` (o en la capa de datos):
    - Método `Future<bool> requestMicrophonePermission()` usando `permission_handler`.
    - Retorna `true` si el permiso fue concedido.
  - Integrar `PermissionManager` en `AudioRepositoryImpl.startCapture()` (ya contemplado en Tarea 7).
  - Implementar la UI de mensajes de permiso denegado en `TunerScreen`:
    - Permiso denegado (re-solicitable): mensaje ≤ 200 caracteres + botón para volver a solicitar.
    - Permiso denegado permanentemente: mensaje ≤ 200 caracteres + instrucciones para ir a ajustes del sistema (`openAppSettings()` de `permission_handler`).
    - El permiso denegado no debe bloquear la navegación a `SettingsScreen`.
  - _Requisitos: 6.1–6.7_

- [x] 12. Escribir pruebas unitarias para la capa de dominio y core
  - Crear `test/core/utils/note_converter_test.dart`:
    - Verificar `frequencyToSemitones(440.0) == 0` (A4).
    - Verificar `frequencyToSemitones(880.0) == 12` (A5).
    - Verificar `semitonesToNoteName(0) == "A"` y octava 4.
    - Verificar `semitonesToNoteName(-9) == "C"` y octava 4 (C4 = Do central).
    - Verificar `frequencyToCents(440.0, 440.0) == 0.0`.
    - Verificar que `frequencyToCents` está acotado a [−50, +50].
    - Propiedad: para toda frecuencia `f` en [60, 1400] Hz, `|f - f_reconstructed| < 0.5 Hz` donde `f_reconstructed = semitonesToFrequency(frequencyToSemitones(f)) * 2^(frequencyToCents(f, semitonesToFrequency(frequencyToSemitones(f)))/1200)`.
  - Crear `test/domain/usecases/analyze_pitch_usecase_test.dart`:
    - Mockear `PitchDetector` para controlar `probability` y `pitch`.
    - Verificar que `probability < 0.90` → `PitchResult.silent`.
    - Verificar que `pitch < 60 Hz` → `PitchResult.silent`.
    - Verificar que `pitch > 1400 Hz` → `PitchResult.silent`.
    - Verificar que `pitch <= 0` → `PitchResult.silent`.
    - Verificar clasificación `TuningState`: cents = −15 → `flat`, cents = 0 → `inTune`, cents = +15 → `sharp`.
    - Verificar que `suggestedString` es 1-based y corresponde a la cuerda más cercana del perfil activo.
  - Crear `test/core/constants/tuning_profiles_test.dart`:
    - Verificar que los 10 perfiles están presentes con los nombres correctos.
    - Verificar que cada perfil tiene exactamente 6 cuerdas.
    - Verificar las frecuencias de las cuerdas del perfil Estándar (E2 ≈ 82.41 Hz, A2 ≈ 110.00 Hz, etc.) con tolerancia de 0.01 Hz.
  - _Requisitos: 2.1–2.7, 3.1–3.4, 7.1–7.5, 9.2, 9.3_

- [x] 13. Escribir pruebas de widget e integración
  - Crear `test/presentation/tuner/tuner_screen_test.dart`:
    - Usar `ProviderScope` con overrides para inyectar un `PitchResult` de prueba.
    - Verificar que `NoteDisplay` muestra "E2" cuando `noteName = "E"`, `octave = 2`.
    - Verificar que `NoteDisplay` muestra "–" cuando `tuningState == silent`.
    - Verificar que `FrequencyDisplay` muestra "329.63 Hz" con 2 decimales.
    - Verificar que `TuningStateIndicator` aplica color azul para `flat`, verde para `inTune`, ámbar para `sharp`.
    - Verificar que `SuggestedStringDisplay` no aparece cuando `tuningState == silent`.
    - Verificar que `ActiveTuningLabel` muestra el nombre del perfil activo.
  - Crear `test/presentation/settings/settings_screen_test.dart`:
    - Verificar que la lista muestra los 10 perfiles.
    - Verificar que el perfil activo está marcado visualmente.
    - Verificar que al seleccionar un perfil se actualiza `activeTuningProfileProvider`.
  - _Requisitos: 4.1–4.9, 5.2–5.6_

- [x] 14. Aplicar el tema visual minimalista oscuro
  - Crear `lib/core/theme/app_theme.dart` con `ThemeData` oscuro:
    - `brightness: Brightness.dark`
    - `scaffoldBackgroundColor`: negro (`#000000`) o gris carbón (`#1A1A1A`).
    - `colorScheme`: sin modo claro; ignorar `MediaQuery.platformBrightness`.
    - Colores de estado: azul (`#2196F3` o similar) para `flat`, verde (`#4CAF50` o similar) para `inTune`, ámbar (`#FFC107` o similar) para `sharp`.
    - Tipografía monoespaciada o geométrica para valores numéricos (p. ej. `RobotoMono` o `SpaceMono`).
    - Color secundario con luminosidad visualmente inferior al blanco para etiquetas inactivas.
  - Aplicar el tema en `lib/main.dart` con `theme: AppTheme.dark` y `themeMode: ThemeMode.dark`.
  - Verificar que `NoteDisplay` usa un `fontSize` al menos 2× mayor que `FrequencyDisplay` y `CentsIndicator`.
  - _Requisitos: 8.1–8.5_

- [x] 15. Implementar gestión de rendimiento y descarte de buffers lentos
  - En `lib/providers/pitch_provider.dart` o en `PitchNotifier`:
    - Medir el tiempo de procesamiento de cada buffer con `Stopwatch`.
    - Si el procesamiento supera 200 ms, descartar el resultado y no actualizar el estado (retener el último `PitchResult` válido).
    - Registrar el descarte en un log de debug (no mostrar al usuario).
  - En `AudioRepositoryImpl`:
    - Verificar que el intervalo entre entregas de buffers no supera 200 ms; si el hardware introduce retrasos, emitir el siguiente buffer disponible sin esperar al anterior.
    - Asegurar que el buffer de captura es de 4096 muestras nominales, aceptando variaciones de ±10%.
  - Crear `test/performance/buffer_processing_test.dart` (prueba de rendimiento básica):
    - Verificar que `AnalyzePitchUseCase.analyze()` completa en menos de 50 ms para un buffer de 4096 muestras (margen conservador respecto al límite de 200 ms).
  - _Requisitos: 10.1–10.4_
