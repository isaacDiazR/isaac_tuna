# IsaacTuna 🎸

Afinador cromático para guitarra desarrollado en Flutter. Escucha el audio del micrófono en tiempo real, detecta la frecuencia de la nota tocada y muestra qué tan afinada está la cuerda.

## Funcionalidades

- Detección de tono en tiempo real mediante el algoritmo MPM (McLeod Pitch Method)
- Indicador visual de afinación: bemol, afinada o sostenida (en cents)
- Sugerencia automática de la cuerda más cercana al tono detectado
- 10 perfiles de afinación predefinidos: Estándar, Drop D, Open G, Open D, Open E, Open A, DADGAD, Drop C, Eb y D Full Step Down
- Procesamiento de audio en isolate secundario para no bloquear la UI
- Soporte para Android e iOS

## Tecnologías

| Tecnología | Uso |
|---|---|
| Flutter / Dart | Framework principal |
| `record ^5.0.0` | Captura de audio PCM desde el micrófono |
| `pitch_detector_dart ^0.0.7` | Detección de frecuencia (algoritmo MPM) |
| `flutter_riverpod ^2.0.0` | Gestión de estado reactivo |
| `permission_handler ^11.0.0` | Solicitud de permisos de micrófono en runtime |
| `dart:isolate` / `compute` | Análisis de pitch fuera del hilo principal |

## Arquitectura

Sigue Clean Architecture con tres capas:

```
lib/
├── core/          # Constantes, utilidades y tema
├── domain/        # Modelos, repositorios abstractos y casos de uso
├── data/          # Implementación concreta de captura de audio
├── presentation/  # UI (pantalla del afinador y ajustes)
└── providers/     # Providers de Riverpod
```

## Cómo ejecutar

```bash
flutter pub get
flutter run
```

Se requiere un dispositivo físico o emulador con acceso a micrófono.
