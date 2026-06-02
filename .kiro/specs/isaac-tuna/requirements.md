# Documento de Requisitos — IsaacTuna

## Introduction

IsaacTuna es una aplicación móvil de afinador cromático para guitarristas, desarrollada en Flutter para Android e iOS. Captura audio del micrófono en tiempo real, detecta la frecuencia fundamental mediante el algoritmo MPM (McLeod Pitch Method) y guía al usuario visualmente hacia la afinación correcta. La interfaz sigue un lenguaje visual minimalista con fondo oscuro, tipografía limpia y animaciones exclusivamente funcionales.

---

## Glosario

- **App**: La aplicación IsaacTuna en su conjunto.
- **AudioRepository**: Componente de la capa de datos responsable de capturar el stream de audio PCM desde el micrófono del dispositivo.
- **PitchDetector**: Motor de análisis de tono que implementa el algoritmo MPM; recibe un buffer PCM y devuelve frecuencia y confianza.
- **AnalyzePitchUseCase**: Caso de uso de la capa de dominio que orquesta la detección de tono y produce un `PitchResult`.
- **PitchResult**: Entidad de dominio que contiene la nota detectada, la octava, la frecuencia en Hz, la desviación en cents y el estado de afinación.
- **TunerScreen**: Pantalla principal de la aplicación que muestra el estado de afinación en tiempo real.
- **SettingsScreen**: Pantalla de selección de afinación.
- **TuningProfile**: Entidad que representa una afinación (nombre + lista de notas por cuerda).
- **CentsIndicator**: Widget que representa la desviación de afinación en una escala de −50 a +50 cents.
- **TuningStateIndicator**: Widget que muestra el color de estado de afinación (azul/verde/ámbar) según el `TuningState`.
- **PermissionManager**: Componente responsable de solicitar y gestionar el permiso de micrófono.
- **PitchProvider**: Proveedor Riverpod que expone el estado reactivo del `PitchResult` actual.
- **AudioProvider**: Proveedor Riverpod que expone el stream de buffers PCM.
- **Confidence**: Índice de probabilidad (0.0–1.0) que devuelve el `PitchDetector` indicando la fiabilidad del resultado.
- **Cents**: Unidad de medida de desviación musical; 100 cents = 1 semitono. Rango relevante: −50 a +50.
- **TuningState**: Enumeración que representa el estado de afinación: `flat` (demasiado bajo), `inTune` (afinado), `sharp` (demasiado alto), `silent` (sin señal).

---

## Requirements

### Requirement 1: Captura de Audio en Tiempo Real

**User Story:** Como guitarrista, quiero que la app capture el audio del micrófono de forma continua, para que pueda detectar la nota que estoy tocando sin interrupciones.

#### Criterios de Aceptación

1. WHEN el usuario concede el permiso de micrófono y abre la `TunerScreen`, THE `AudioRepository` SHALL iniciar la captura de audio con una frecuencia de muestreo de 44 100 Hz.
2. IF el permiso de micrófono no ha sido concedido cuando se intenta iniciar la captura, THEN THE `AudioRepository` SHALL permanecer inactivo y emitir un evento de error al `AudioProvider` indicando que el permiso es requerido.
3. WHILE la `TunerScreen` está activa, THE `AudioRepository` SHALL entregar buffers PCM de al menos 4 096 muestras al `AudioProvider` con un intervalo máximo de 200 ms entre entregas consecutivas.
4. WHEN la `TunerScreen` se cierra o la app pasa a segundo plano, THE `AudioRepository` SHALL detener la captura de audio y liberar los recursos del micrófono de modo que una captura posterior pueda iniciarse sin error.
5. WHEN la app regresa al primer plano con la `TunerScreen` activa y el permiso de micrófono concedido, THE `AudioRepository` SHALL reanudar la captura de audio automáticamente.
6. IF la captura de audio falla por un error del sistema, THEN THE `AudioRepository` SHALL emitir un evento de error al `AudioProvider` que incluya el tipo de fallo y una descripción legible, y SHALL detener la captura hasta que se solicite reinicio explícito.

---

### Requirement 2: Detección de Tono

**User Story:** Como guitarrista, quiero que la app detecte la frecuencia fundamental de la nota que toco, para que pueda saber qué nota estoy produciendo.

#### Criterios de Aceptación

1. WHEN el `AudioProvider` entrega un buffer PCM, THE `AnalyzePitchUseCase` SHALL invocar al `PitchDetector` con dicho buffer y producir un `PitchResult`.
2. WHEN el `PitchDetector` devuelve un resultado con `Confidence` igual o superior a 0.90, THE `AnalyzePitchUseCase` SHALL incluir la frecuencia detectada en el `PitchResult` con los campos nota, octava, Hz y cents calculados.
3. IF el `PitchDetector` devuelve un resultado con `Confidence` inferior a 0.90, THEN THE `AnalyzePitchUseCase` SHALL producir un `PitchResult` con `TuningState` igual a `silent` y los campos nota, octava, Hz y cents con valor nulo.
4. THE `AnalyzePitchUseCase` SHALL convertir la frecuencia en Hz a la nota musical más cercana usando temperamento igual con La4 = 440 Hz como referencia, donde "más cercana" se define como la nota con menor desviación absoluta en cents.
5. THE `AnalyzePitchUseCase` SHALL calcular la desviación en cents respecto a la nota más cercana del temperamento igual, con el resultado acotado al rango [−50, +50].
6. THE `AnalyzePitchUseCase` SHALL producir, para toda frecuencia válida en el rango de 60 Hz a 1 400 Hz, un `PitchResult` con nota, octava, Hz y cents tal que al reconstruir la frecuencia desde la nota y los cents el error sea menor a 0.5 Hz.
7. IF la frecuencia detectada está fuera del rango de 60 Hz a 1 400 Hz, THEN THE `AnalyzePitchUseCase` SHALL producir un `PitchResult` con `TuningState` igual a `silent`.

---

### Requirement 3: Clasificación del Estado de Afinación

**User Story:** Como guitarrista, quiero saber visualmente si la nota está baja, afinada o alta, para que pueda ajustar la cuerda en la dirección correcta.

#### Criterios de Aceptación

1. IF la desviación calculada es estrictamente menor a −10 cents, THEN THE `AnalyzePitchUseCase` SHALL asignar `TuningState` igual a `flat` en el `PitchResult`.
2. IF la desviación calculada está entre −10 cents y +10 cents (ambos inclusive), THEN THE `AnalyzePitchUseCase` SHALL asignar `TuningState` igual a `inTune` en el `PitchResult`.
3. IF la desviación calculada es estrictamente mayor a +10 cents, THEN THE `AnalyzePitchUseCase` SHALL asignar `TuningState` igual a `sharp` en el `PitchResult`.
4. IF el `PitchDetector` devuelve un resultado con `Confidence` inferior a 0.90, THEN THE `AnalyzePitchUseCase` SHALL asignar `TuningState` igual a `silent` en el `PitchResult`, ignorando cualquier regla de clasificación basada en desviación de cents.

---

### Requirement 4: Pantalla Principal del Afinador

**User Story:** Como guitarrista, quiero ver en una sola pantalla la nota detectada, la frecuencia, la desviación en cents y el estado de afinación, para que pueda afinar mi guitarra de forma eficiente.

#### Criterios de Aceptación

1. WHILE la `TunerScreen` está activa y el `PitchProvider` emite un `PitchResult` con `TuningState` distinto de `silent`, THE `TunerScreen` SHALL mostrar la nota detectada con su octava en notación científica (p. ej. "E2", "A4").
2. WHILE la `TunerScreen` está activa y el `PitchProvider` emite un `PitchResult` con `TuningState` distinto de `silent`, THE `TunerScreen` SHALL mostrar la frecuencia en Hz con dos decimales de precisión.
3. WHILE la `TunerScreen` está activa y el `PitchProvider` emite un `PitchResult` con `TuningState` distinto de `silent`, THE `CentsIndicator` SHALL actualizar su posición visual en un tiempo máximo de 100 ms tras recibir el nuevo `PitchResult`, sin animaciones decorativas adicionales.
4. WHEN el `PitchResult` tiene `TuningState` igual a `flat`, THE `TuningStateIndicator` SHALL aplicar el color azul.
5. WHEN el `PitchResult` tiene `TuningState` igual a `inTune`, THE `TuningStateIndicator` SHALL aplicar el color verde.
6. WHEN el `PitchResult` tiene `TuningState` igual a `sharp`, THE `TuningStateIndicator` SHALL aplicar el color ámbar.
7. WHEN el `PitchResult` tiene `TuningState` igual a `silent`, THE `TunerScreen` SHALL mostrar el placeholder "–" en los campos de nota, octava, Hz y cents, sin valores numéricos activos.
8. WHILE la `TunerScreen` está activa y el `PitchResult` tiene `TuningState` distinto de `silent`, THE `TunerScreen` SHALL mostrar la cuerda sugerida de la `TuningProfile` activa cuya nota objetivo tiene la menor distancia en cents absolutos respecto a la frecuencia detectada.
9. WHEN el `PitchResult` tiene `TuningState` igual a `silent`, THE `TunerScreen` SHALL no mostrar ninguna cuerda sugerida.

---

### Requirement 5: Selección de Afinación

**User Story:** Como guitarrista, quiero seleccionar entre 10 afinaciones predefinidas para guitarra de 6 cuerdas, para que pueda afinar mi guitarra en cualquier configuración que necesite.

#### Criterios de Aceptación

1. THE `App` SHALL incluir los siguientes 10 `TuningProfile` predefinidos con sus frecuencias exactas en temperamento igual: Estándar (E2 A2 D3 G3 B3 E4), Drop D (D2 A2 D3 G3 B3 E4), Open G (D2 G2 D3 G3 B3 D4), Open D (D2 A2 D3 F#3 A3 D4), Open E (E2 B2 E3 G#3 B3 E4), Open A (E2 A2 E3 A3 C#4 E4), DADGAD (D2 A2 D3 G3 A3 D4), Drop C (C2 G2 C3 F3 A3 D4), Eb (Eb2 Ab2 Db3 Gb3 Bb3 Eb4) y D Full Step Down (D2 G2 C3 F3 A3 D4).
2. WHEN el usuario abre la `SettingsScreen`, THE `SettingsScreen` SHALL mostrar la lista completa de los 10 `TuningProfile` con el nombre de cada afinación y las notas de sus 6 cuerdas en notación científica.
3. WHEN el usuario selecciona un `TuningProfile` en la `SettingsScreen`, THE `App` SHALL actualizar el `TuningProfile` activo de forma inmediata y navegar automáticamente de regreso a la `TunerScreen`.
4. IF la navegación automática de regreso a la `TunerScreen` falla tras la selección de un `TuningProfile`, THEN THE `App` SHALL mantener el `TuningProfile` seleccionado activo y permitir al usuario navegar manualmente de regreso.
5. WHILE la `TunerScreen` está activa, THE `TunerScreen` SHALL mostrar el nombre del `TuningProfile` activo en un área de la pantalla dedicada a esa información.
6. THE `SettingsScreen` SHALL marcar visualmente el `TuningProfile` activo con un indicador diferenciado (p. ej. check, resaltado o color de acento) del resto de la lista.

---

### Requirement 6: Gestión de Permisos de Micrófono

**User Story:** Como usuario, quiero que la app solicite el permiso de micrófono de forma clara antes de iniciar la captura, para que pueda entender por qué se necesita y decidir si concederlo.

#### Criterios de Aceptación

1. IF el permiso de micrófono no ha sido concedido cuando la app intenta iniciar la captura de audio, THEN THE `PermissionManager` SHALL solicitar el permiso al sistema operativo antes de que `AudioRepository` inicie la captura.
2. IF el usuario deniega el permiso de micrófono y la plataforma permite volver a solicitarlo, THEN THE `App` SHALL mostrar un mensaje explicativo de no más de 200 caracteres indicando que el permiso es necesario para el funcionamiento del afinador, con una acción para volver a solicitarlo.
3. IF el usuario deniega el permiso de micrófono de forma permanente (Android: "No preguntar de nuevo"), THEN THE `App` SHALL mostrar un mensaje explicativo de no más de 200 caracteres con instrucciones para habilitar el permiso manualmente desde los ajustes del sistema.
4. IF el permiso de micrófono está denegado, desconocido o pendiente, THEN THE `App` SHALL mantener la navegación funcional sin bloquear el acceso a la `SettingsScreen`.
5. WHEN el usuario concede el permiso de micrófono, THE `AudioProvider` SHALL iniciar la captura de audio en un tiempo máximo de 2 segundos tras la concesión del permiso.
6. WHERE la plataforma es Android, THE `App` SHALL declarar el permiso `RECORD_AUDIO` en el manifiesto de la aplicación.
7. WHERE la plataforma es iOS, THE `App` SHALL incluir la clave `NSMicrophoneUsageDescription` con una descripción en el archivo `Info.plist`.

---

### Requirement 7: Conversión de Frecuencia a Nota Musical

**User Story:** Como desarrollador, quiero que la conversión de Hz a nota musical sea precisa y testeable de forma aislada, para que la lógica de dominio sea confiable y mantenible.

#### Criterios de Aceptación

1. THE `AnalyzePitchUseCase` SHALL convertir cualquier frecuencia en Hz a su nota musical más cercana usando la fórmula de temperamento igual: `semitones = round(12 × log2(f / 440))`, con nombres de nota en notación científica con sostenidos (p. ej. C#4, A4) y octavas numeradas según el estándar MIDI (C4 = Do central).
2. THE `AnalyzePitchUseCase` SHALL calcular la desviación en cents usando la fórmula: `cents = 1200 × log2(f / f_target)`, donde `f_target` es la frecuencia exacta de la nota más cercana calculada como `f_target = 440 × 2^(semitones/12)`.
3. THE `AnalyzePitchUseCase` SHALL producir, para toda frecuencia en el rango de 60 Hz a 1 400 Hz, una nota y desviación en cents tal que al reconstruir la frecuencia como `f_reconstructed = f_target × 2^(cents/1200)` el error absoluto `|f - f_reconstructed|` sea menor a 0.5 Hz.
4. THE `AnalyzePitchUseCase` SHALL operar sin dependencias de Flutter ni de paquetes externos, de modo que sea testeable con pruebas unitarias en Dart puro.
5. IF la frecuencia de entrada es igual o menor a 0 Hz, THEN THE `AnalyzePitchUseCase` SHALL retornar un `PitchResult` con `TuningState` igual a `silent` sin realizar ningún cálculo de nota o cents.

---

### Requirement 8: Diseño Visual Minimalista

**User Story:** Como guitarrista, quiero una interfaz limpia y oscura que no distraiga mi atención, para que pueda concentrarme en la afinación durante la práctica o la actuación.

#### Criterios de Aceptación

1. THE `App` SHALL utilizar exclusivamente un tema oscuro con fondo negro o gris carbón; no se implementará modo claro ni se responderá a cambios del tema del sistema operativo.
2. THE `TunerScreen` SHALL mostrar los valores numéricos (Hz, cents) con tipografía monoespaciada o geométrica.
3. WHEN el `PitchProvider` emite un nuevo `PitchResult`, THE `CentsIndicator` SHALL actualizar su posición con una animación de duración máxima de 100 ms; no se aplicarán efectos de rebote, elasticidad ni ninguna otra transición decorativa.
4. THE `App` SHALL utilizar una paleta de colores reducida: blanco exclusivamente para información primaria, un único color de acento que distinga visualmente los tres estados de afinación (`flat`, `inTune`, `sharp`), y un color secundario con luminosidad visualmente inferior a la del blanco para etiquetas y controles inactivos.
5. THE `TunerScreen` SHALL presentar la nota detectada con un tamaño de fuente al menos 2× mayor que el tamaño de fuente de los valores numéricos secundarios (Hz, cents).

---

### Requirement 9: Arquitectura Limpia y Testeable

**User Story:** Como desarrollador, quiero que la app siga una arquitectura en capas con separación estricta de responsabilidades, para que el código sea mantenible, extensible y testeable de forma independiente.

#### Criterios de Aceptación

1. THE `App` SHALL organizar el código en las capas `core`, `data`, `domain`, `presentation` y `providers`, sin dependencias circulares entre capas; la dirección de dependencia permitida es: `presentation` → `domain` ← `data`, con `providers` como capa de composición.
2. THE `domain` layer SHALL contener únicamente código Dart puro sin importaciones de paquetes de Flutter (`package:flutter/...`) ni de librerías de captura de audio (`record`, `permission_handler`).
3. THE `AudioRepository` SHALL exponer una interfaz abstracta (`abstract class` o `abstract interface`) en la capa de dominio, de modo que la implementación concreta en la capa de datos pueda ser sustituida por un mock en pruebas sin modificar el código de dominio.
4. THE `PitchProvider` SHALL exponer el `PitchResult` más reciente como estado reactivo mediante Riverpod, de modo que la `TunerScreen` se reconstruya únicamente cuando el valor del `PitchResult` cambia; los cambios de estado interno del proveedor que no alteren el `PitchResult` no SHALL desencadenar reconstrucciones de la `TunerScreen`.

---

### Requirement 10: Rendimiento y Latencia de Análisis

**User Story:** Como guitarrista, quiero que el afinador responda en menos de 200 ms desde que toco la cuerda, para que la retroalimentación visual sea útil durante la afinación en vivo.

#### Criterios de Aceptación

1. WHILE la `TunerScreen` está activa, THE `App` SHALL procesar cada buffer PCM y actualizar el `PitchResult` en el `PitchProvider` en un tiempo total menor a 200 ms desde la captura del buffer.
2. THE `AudioRepository` SHALL configurar el buffer de captura con un tamaño nominal de 4 096 muestras a 44 100 Hz; variaciones de hasta ±10% en el tamaño del buffer debidas a limitaciones de hardware o drivers son aceptables.
3. IF el procesamiento de un buffer supera los 200 ms, THEN THE `App` SHALL descartar ese buffer y comenzar la captura del siguiente buffer en un tiempo máximo de 93 ms (equivalente a un período de buffer), sin bloquear el stream de audio.
4. WHEN un buffer es descartado por superar el límite de 200 ms, THE `TunerScreen` SHALL retener y mostrar el último `PitchResult` válido hasta que se produzca un nuevo resultado.
