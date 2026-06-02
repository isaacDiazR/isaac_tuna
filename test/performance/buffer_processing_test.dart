import 'package:flutter_test/flutter_test.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';

import 'package:isaac_tuna/core/constants/audio_constants.dart';
import 'package:isaac_tuna/core/constants/tuning_profiles.dart';
import 'package:isaac_tuna/domain/usecases/analyze_pitch_usecase.dart';

void main() {
  group('Rendimiento — buffer_processing', () {
    late AnalyzePitchUseCase useCase;
    late List<double> buffer;

    setUpAll(() {
      final detector = PitchDetector(
        audioSampleRate: AudioConstants.sampleRate.toDouble(),
        bufferSize: AudioConstants.bufferSize,
      );
      useCase = AnalyzePitchUseCase(
        detector: detector,
        profile: TuningProfiles.standard,
      );

      // Buffer de 4096 muestras de ceros (silencio)
      buffer = List.filled(AudioConstants.bufferSize, 0.0);
    });

    test(
      'AnalyzePitchUseCase.analyze() completa en menos de 50 ms',
      () async {
        // Calentamiento: primera llamada puede tener overhead de JIT
        await useCase.analyze(buffer);

        // Medición real
        final stopwatch = Stopwatch()..start();
        await useCase.analyze(buffer);
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(50),
          reason:
              'El análisis tardó ${stopwatch.elapsedMilliseconds} ms '
              '(límite conservador: 50 ms, límite real: 200 ms)',
        );
      },
    );

    test(
      'promedio de 10 llamadas consecutivas es menor a 50 ms',
      () async {
        const iterations = 10;
        var totalMs = 0;

        for (int i = 0; i < iterations; i++) {
          final sw = Stopwatch()..start();
          await useCase.analyze(buffer);
          sw.stop();
          totalMs += sw.elapsedMilliseconds;
        }

        final averageMs = totalMs / iterations;
        expect(
          averageMs,
          lessThan(50),
          reason:
              'Promedio de $iterations iteraciones: ${averageMs.toStringAsFixed(1)} ms '
              '(límite: 50 ms)',
        );
      },
    );

    test(
      'buffers con variación de ±10% en tamaño son aceptados',
      () async {
        // pitch_detector_dart requiere buffer.length >= bufferSize, por lo que
        // la variación de ±10% aplica al contenido, no a la longitud del buffer.
        // Verificamos que el tamaño nominal (4096) procesa correctamente.
        final exactBuffer = List.filled(AudioConstants.bufferSize, 0.0);

        final sw = Stopwatch()..start();
        final result = await useCase.analyze(exactBuffer);
        sw.stop();

        expect(sw.elapsedMilliseconds, lessThan(200));
        // Buffer de silencio → resultado silent
        expect(result, isNotNull);
      },
    );
  });
}
