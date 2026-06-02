# Diseño Técnico — IsaacTuna

## Overview

IsaacTuna es un afinador cromático para guitarra desarrollado en Flutter. Su propósito central es capturar audio del micrófono en tiempo real, detectar la frecuencia fundamental de la nota tocada mediante el algoritmo MPM (McLeod Pitch Method) y presentar al guitarrista una retroalimentación visual inmediata sobre el estado de afinación.

La aplicación opera en dos pantallas: la pantalla principal del afinador (`TunerScreen`) y la pantalla de selección de afinación (`SettingsScreen`). El flujo de datos es unidireccional: el micrófono alimenta un stream de buffers PCM que atraviesa la capa de dominio para producir un `PitchResult`, el cual es expuesto reactivamente a la UI mediante Riverpod.

### Decisiones de diseño clave

- **MPM sobre FFT**: El algoritmo MPM (implementado por `pitch_detector_dart`) es superior a la FFT simple para señales monofónicas como cuerdas de guitarra, ya que trabaja en el dominio del tiempo y es más robusto ante armónicos fuertes.
- **Umbral de confianza 0.90**: Filtra lecturas espurias en silencio o con ruido ambiental, evitando que la UI muestre valores inestables.
- **Buffer de 4 096 muestras a 44 100 Hz**: Produce una latencia de análisis de ~93 ms, adecuada para uso en vivo y dentro del límite de 200 ms exigido por el requisito 10.
- **Clean Architecture**: Separa estrictamente dominio, datos y presentación, permitiendo testear la lógica de conversión Hz→nota en Dart puro sin dependencias de Flutter.
- **Riverpod**: Gestión de estado reactiva que garantiza que la `TunerScreen` solo se reconstruye cuando el `PitchResult` cambia.

---

## Architecture

La arquitectura sigue el patrón **Clean Architecture** con cuatro capas principales y una capa de composición:

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION                         │
│   TunerScreen  ·  TunerController  ·  SettingsScreen    │
│   Widgets: CentsIndicator, TuningStateIndicator, etc.   │
└────────────────────────┬────────────────────────────────┘
                         │ observa
┌────────────────────────▼────────────────────────────────┐
│                     PROVIDERS                           │
│          PitchProvider  ·  AudioProvider                │
└──────────┬─────────────────────────────┬────────────────┘
           │ usa                         │ usa
┌──────────▼──────────┐       ┌──────────▼──────────────┐
│       DOMAIN        │       │         DATA            │
│  AnalyzePitchUseCase│       │   AudioRepositoryImpl   │
│  PitchResult        │◄──────│   (implementa interfaz) │
│  TuningProfile      │       └─────────────────────────┘
│  AudioRepository    │
│  (interfaz abstracta│
└─────────────────────┘
           │ usa
┌──────────▼──────────┐
│        CORE         │
│  NoteConverter      │
│  CentsCalculator    │
│  AudioConstants     │
│  TuningProfiles     │
└─────────────────────┘
```

### Dirección de dependencias

```
presentation → providers → domain ← data
                                ↑
                              core
```

La capa `domain` no importa nada de Flutter ni de paquetes de captura de audio. La capa `data` implementa las interfaces definidas en `domain`. Los `providers` componen ambas capas y exponen estado reactivo a `presentation`.

### Flujo de datos en tiempo real

```
Micrófono
   │
   ▼
AudioRepositoryImpl
   │  stream de List<double> (PCM normalizado, 4096 muestras)
   ▼
AudioProvider (StreamProvider)
   │
   ▼
AnalyzePitchUseCase
   │  invoca PitchDetector (pitch_detector_dart / MPM)
   │  convierte Hz → nota + cents (NoteConverter)
   │  clasifica TuningState
   ▼
PitchResult
   │
   ▼
PitchProvider (StateNotifierProvider)
   │  notifica solo cuando PitchResult cambia
   ▼
TunerScreen → CentsIndicator, TuningStateIndicator, NoteDisplay
```

---

## Components and Interfaces

### core/constants/audio_constants.dart

Constantes globales de configuración de audio y detección:

```dart
class AudioConstants {
  static const int sampleRate = 44100;
  static const int bufferSize = 4096;
  static const double confidenceThreshold = 0.90;
  static const double minFrequency = 60.0;   // Hz
  static const double maxFrequency = 1400.0; // Hz
  static const double referenceA4 = 440.0;   // Hz
  static const int tuningThresholdCents = 10;
}
```

### core/constants/tuning_profiles.dart

Definición estática de los 10 perfiles de afinación predefinidos. Cada perfil contiene el nombre y las frecuencias exactas de las 6 cuerdas calculadas con temperamento igual (La4 = 440 Hz).

### core/utils/note_converter.dart

Lógica pura de conversión Hz → nota musical. Sin dependencias de Flutter.

```dart
class NoteConverter {
  /// Convierte frecuencia en Hz a número de semitonos respecto a A4.
  /// semitones = round(12 × log2(f / 440))
  static int frequencyToSemitones(double hz);

  /// Devuelve el nombre de la nota en notación científica (p. ej. "C#4", "E2").
  static String semitonesToNoteName(int semitones);

  /// Calcula la octava MIDI estándar (C4 = Do central).
  static int semitonesToOctave(int semitones);

  /// Calcula la frecuencia exacta de la nota más cercana.
  /// f_target = 440 × 2^(semitones/12)
  static double semitonesToFrequency(int semitones);

  /// Calcula desviación en cents acotada a [−50, +50].
  /// cents = 1200 × log2(f / f_target)
  static double frequencyToCents(double hz, double targetHz);
}
```

### core/utils/cents_calculator.dart

Utilidad auxiliar para cálculos de distancia en cents entre dos frecuencias, usada también para determinar la cuerda sugerida.

### domain/models/pitch_result.dart

Entidad central de dominio:

```dart
class PitchResult {
  final String? noteName;      // p. ej. "E", "C#"
  final int? octave;           // p. ej. 2, 4
  final double? frequencyHz;   // frecuencia detectada
  final double? cents;         // desviación en [−50, +50]
  final TuningState tuningState;
  final int? suggestedString;  // índice 1–6 de la cuerda sugerida (null si silent)

  const PitchResult({...});

  /// PitchResult vacío para estado silent.
  static const PitchResult silent = PitchResult(tuningState: TuningState.silent);

  @override
  bool operator ==(Object other); // para evitar reconstrucciones innecesarias en Riverpod
}
```

### domain/models/tuning_state.dart

```dart
enum TuningState { flat, inTune, sharp, silent }
```

### domain/models/tuning_profile.dart

```dart
class TuningProfile {
  final String name;
  final List<TuningString> strings; // 6 cuerdas, índice 0 = cuerda 6ª (más grave)

  const TuningProfile({required this.name, required this.strings});
}

class TuningString {
  final String noteName;  // p. ej. "E"
  final int octave;       // p. ej. 2
  final double frequencyHz;

  const TuningString({...});
}
```

### domain/repositories/audio_repository.dart

Interfaz abstracta en la capa de dominio:

```dart
abstract class AudioRepository {
  /// Stream de buffers PCM normalizados (valores en [−1.0, 1.0]).
  Stream<List<double>> get audioStream;

  /// Inicia la captura de audio.
  Future<void> startCapture();

  /// Detiene la captura y libera recursos.
  Future<void> stopCapture();

  /// Stream de errores de captura.
  Stream<AudioCaptureError> get errorStream;
}
```

### domain/usecases/analyze_pitch_usecase.dart

```dart
class AnalyzePitchUseCase {
  final PitchDetector _detector;   // de pitch_detector_dart
  final TuningProfile _profile;    // perfil activo

  /// Analiza un buffer PCM y produce un PitchResult.
  PitchResult analyze(List<double> buffer);
}
```

Lógica interna:
1. Invoca `_detector.getPitch(buffer)` → `{pitch, probability}`.
2. Si `probability < 0.90` → retorna `PitchResult.silent`.
3. Si `pitch < 60 Hz` o `pitch > 1400 Hz` → retorna `PitchResult.silent`.
4. Calcula semitonos, nombre de nota, octava, frecuencia objetivo y cents.
5. Clasifica `TuningState` según umbral de ±10 cents.
6. Determina cuerda sugerida (menor distancia absoluta en cents respecto a las notas del perfil activo).
7. Retorna `PitchResult` completo.

### data/audio_repository_impl.dart

Implementación concreta usando el paquete `record`:

```dart
class AudioRepositoryImpl implements AudioRepository {
  final AudioRecorder _recorder;
  StreamController<List<double>>? _controller;
  StreamController<AudioCaptureError>? _errorController;

  @override
  Stream<List<double>> get audioStream => _controller!.stream;

  @override
  Future<void> startCapture() async {
    // Configura RecordConfig con sampleRate=44100, numChannels=1
    // Convierte bytes PCM int16 a List<double> normalizado
    // Emite buffers de 4096 muestras
  }

  @override
  Future<void> stopCapture() async {
    await _recorder.stop();
    await _controller?.close();
  }
}
```

### providers/audio_provider.dart

```dart
// StreamProvider que expone el stream de buffers PCM
final audioStreamProvider = StreamProvider<List<double>>((ref) {
  final repo = ref.watch(audioRepositoryProvider);
  return repo.audioStream;
});
```

### providers/pitch_provider.dart

```dart
// StateNotifierProvider que expone el PitchResult más reciente
final pitchProvider = StateNotifierProvider<PitchNotifier, PitchResult>((ref) {
  return PitchNotifier(ref.watch(analyzePitchUseCaseProvider));
});

class PitchNotifier extends StateNotifier<PitchResult> {
  PitchNotifier(this._useCase) : super(PitchResult.silent);

  void processBuffer(List<double> buffer) {
    final result = _useCase.analyze(buffer);
    if (result != state) state = result; // evita reconstrucciones innecesarias
  }
}
```

### presentation/tuner/tuner_screen.dart

Widget principal que observa `pitchProvider` y compone:
- `NoteDisplay` — nota + octava en tipografía grande
- `FrequencyDisplay` — Hz con 2 decimales
- `CentsIndicator` — barra/aguja de −50 a +50 cents
- `TuningStateIndicator` — color de estado (azul/verde/ámbar)
- `SuggestedStringDisplay` — cuerda sugerida del perfil activo
- `ActiveTuningLabel` — nombre del perfil activo

### presentation/tuner/widgets/cents_indicator.dart

Widget que anima la posición del indicador con duración máxima de 100 ms usando `AnimatedContainer` o `TweenAnimationBuilder`. Sin efectos de rebote ni elasticidad.

### presentation/settings/settings_screen.dart

Lista de los 10 perfiles de afinación. Al seleccionar uno, actualiza el proveedor activo y navega de regreso a `TunerScreen`.

---

## Data Models

### PitchResult

| Campo | Tipo | Descripción |
|---|---|---|
| `noteName` | `String?` | Nombre de la nota (p. ej. "E", "C#"). Null si silent. |
| `octave` | `int?` | Octava MIDI (C4 = Do central). Null si silent. |
| `frequencyHz` | `double?` | Frecuencia detectada en Hz. Null si silent. |
| `cents` | `double?` | Desviación en [−50, +50]. Null si silent. |
| `tuningState` | `TuningState` | Estado: flat / inTune / sharp / silent. |
| `suggestedString` | `int?` | Índice 1–6 de la cuerda sugerida. Null si silent. |

### TuningProfile

| Campo | Tipo | Descripción |
|---|---|---|
| `name` | `String` | Nombre de la afinación (p. ej. "Estándar", "Drop D"). |
| `strings` | `List<TuningString>` | Lista de 6 cuerdas, índice 0 = cuerda más grave. |

### TuningString

| Campo | Tipo | Descripción |
|---|---|---|
| `noteName` | `String` | Nombre de la nota (p. ej. "E", "Ab"). |
| `octave` | `int` | Octava de la nota objetivo. |
| `frequencyHz` | `double` | Frecuencia exacta en temperamento igual. |

### AudioCaptureError

| Campo | Tipo | Descripción |
|---|---|---|
| `type` | `AudioErrorType` | Tipo de error: `permissionDenied`, `systemError`, `deviceUnavailable`. |
| `message` | `String` | Descripción legible del error. |

### Perfiles de afinación predefinidos

| Nombre | Cuerda 6 | Cuerda 5 | Cuerda 4 | Cuerda 3 | Cuerda 2 | Cuerda 1 |
|---|---|---|---|---|---|---|
| Estándar | E2 | A2 | D3 | G3 | B3 | E4 |
| Drop D | D2 | A2 | D3 | G3 | B3 | E4 |
| Open G | D2 | G2 | D3 | G3 | B3 | D4 |
| Open D | D2 | A2 | D3 | F#3 | A3 | D4 |
| Open E | E2 | B2 | E3 | G#3 | B3 | E4 |
| Open A | E2 | A2 | E3 | A3 | C#4 | E4 |
| DADGAD | D2 | A2 | D3 | G3 | A3 | D4 |
| Drop C | C2 | G2 | C3 | F3 | A3 | D4 |
| Eb | Eb2 | Ab2 | Db3 | Gb3 | Bb3 | Eb4 |
| D Full Step Down | D2 | G2 | C3 | F3 | A3 | D4 |

