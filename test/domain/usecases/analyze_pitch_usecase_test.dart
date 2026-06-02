import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitch_detector_dart/pitch_detector_result.dart';

import 'package:isaac_tuna/core/constants/audio_constants.dart';
import 'package:isaac_tuna/core/constants/tuning_profiles.dart';
import 'package:isaac_tuna/domain/models/pitch_result.dart';
import 'package:isaac_tuna/domain/models/tuning_state.dart';
import 'package:isaac_tuna/domain/usecases/analyze_pitch_usecase.dart';

// ---------------------------------------------------------------------------
// Fake de PitchDetector para controlar pitch y probability en tests
// ---------------------------------------------------------------------------

class _FakePitchDetector extends PitchDetector {
  double _fakePitch;
  double _fakeProbability;

  _FakePitchDetector({
    required double pitch,
    required double probability,
  })  : _fakePitch = pitch,
        _fakeProbability = probability,
        super(
          audioSampleRate: AudioConstants.sampleRate.toDouble(),
          bufferSize: AudioConstants.bufferSize,
        );

  void setResult({required double pitch, required double probability}) {
    _fakePitch = pitch;
    _fakeProbability = probability;
  }

  @override
  Future<PitchDetectorResult> getPitchFromFloatBuffer(
      List<double> buffer) async {
    return PitchDetectorResult(
      pitch: _fakePitch,
      probability: _fakeProbability,
      pitched: _fakeProbability >= AudioConstants.confidenceThreshold,
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Genera un buffer de 4096 muestras de ceros.
List<double> _silentBuffer() =>
    List.filled(AudioConstants.bufferSize, 0.0);

/// Calcula la frecuencia a N cents por encima/debajo de [baseHz].
double _shiftCents(double baseHz, double cents) =>
    baseHz * math.pow(2.0, cents / 1200.0);

void main() {
  group('AnalyzePitchUseCase', () {
    late _FakePitchDetector detector;
    late AnalyzePitchUseCase useCase;

    setUp(() {
      detector = _FakePitchDetector(pitch: 0.0, probability: 0.0);
      useCase = AnalyzePitchUseCase(
        detector: detector,
        profile: TuningProfiles.standard,
      );
    });

    // -----------------------------------------------------------------------
    // Filtrado por confianza (probability)
    // -----------------------------------------------------------------------

    group('filtrado por confianza', () {
      test('probability < 0.90 → PitchResult.silent', () async {
        detector.setResult(pitch: 440.0, probability: 0.89);
        final result = await useCase.analyze(_silentBuffer());
        expect(result, equals(PitchResult.silent));
        expect(result.tuningState, equals(TuningState.silent));
      });

      test('probability == 0.00 → PitchResult.silent', () async {
        detector.setResult(pitch: 440.0, probability: 0.0);
        final result = await useCase.analyze(_silentBuffer());
        expect(result, equals(PitchResult.silent));
      });

      test('probability == 0.90 (exacto) → no es silent', () async {
        detector.setResult(pitch: 440.0, probability: 0.90);
        final result = await useCase.analyze(_silentBuffer());
        expect(result.tuningState, isNot(equals(TuningState.silent)));
      });
    });

    // -----------------------------------------------------------------------
    // Filtrado por rango de frecuencia
    // -----------------------------------------------------------------------

    group('filtrado por rango de frecuencia', () {
      test('pitch < 60 Hz → PitchResult.silent', () async {
        detector.setResult(pitch: 59.99, probability: 0.95);
        final result = await useCase.analyze(_silentBuffer());
        expect(result, equals(PitchResult.silent));
      });

      test('pitch > 1400 Hz → PitchResult.silent', () async {
        detector.setResult(pitch: 1400.01, probability: 0.95);
        final result = await useCase.analyze(_silentBuffer());
        expect(result, equals(PitchResult.silent));
      });

      test('pitch <= 0 → PitchResult.silent', () async {
        detector.setResult(pitch: 0.0, probability: 0.95);
        final result = await useCase.analyze(_silentBuffer());
        expect(result, equals(PitchResult.silent));
      });

      test('pitch negativo → PitchResult.silent', () async {
        detector.setResult(pitch: -50.0, probability: 0.95);
        final result = await useCase.analyze(_silentBuffer());
        expect(result, equals(PitchResult.silent));
      });

      test('pitch == 440 Hz (válido) → no es silent', () async {
        detector.setResult(pitch: 440.0, probability: 0.95);
        final result = await useCase.analyze(_silentBuffer());
        expect(result.tuningState, isNot(equals(TuningState.silent)));
      });
    });

    // -----------------------------------------------------------------------
    // Clasificación de TuningState
    // -----------------------------------------------------------------------

    group('clasificación de TuningState', () {
      test('cents ≈ -15 → TuningState.flat', () async {
        // A4 afinado -15 cents respecto a La = 440 Hz
        final flatPitch = _shiftCents(440.0, -15.0);
        detector.setResult(pitch: flatPitch, probability: 0.95);
        final result = await useCase.analyze(_silentBuffer());

        expect(result.tuningState, equals(TuningState.flat));
      });

      test('cents ≈ 0 → TuningState.inTune', () async {
        detector.setResult(pitch: 440.0, probability: 0.95);
        final result = await useCase.analyze(_silentBuffer());

        expect(result.tuningState, equals(TuningState.inTune));
        expect(result.cents, closeTo(0.0, 0.5));
      });

      test('cents ≈ +15 → TuningState.sharp', () async {
        final sharpPitch = _shiftCents(440.0, 15.0);
        detector.setResult(pitch: sharpPitch, probability: 0.95);
        final result = await useCase.analyze(_silentBuffer());

        expect(result.tuningState, equals(TuningState.sharp));
      });

      test('cents ≈ -9 (dentro del umbral) → TuningState.inTune', () async {
        // -9 cents está claramente dentro del rango inTune [-10, +10]
        final edgePitch = _shiftCents(440.0, -9.0);
        detector.setResult(pitch: edgePitch, probability: 0.95);
        final result = await useCase.analyze(_silentBuffer());

        expect(result.tuningState, equals(TuningState.inTune));
      });

      test('cents ≈ +9 (dentro del umbral) → TuningState.inTune', () async {
        // +9 cents está claramente dentro del rango inTune [-10, +10]
        final edgePitch = _shiftCents(440.0, 9.0);
        detector.setResult(pitch: edgePitch, probability: 0.95);
        final result = await useCase.analyze(_silentBuffer());

        expect(result.tuningState, equals(TuningState.inTune));
      });
    });

    // -----------------------------------------------------------------------
    // Campos del PitchResult
    // -----------------------------------------------------------------------

    group('campos del PitchResult', () {
      test('nota y octava de A4 son correctas', () async {
        detector.setResult(pitch: 440.0, probability: 0.95);
        final result = await useCase.analyze(_silentBuffer());

        expect(result.noteName, equals('A'));
        expect(result.octave, equals(4));
        expect(result.frequencyHz, closeTo(440.0, 0.01));
      });

      test('nota y octava de E2 son correctas', () async {
        // E2 ≈ 82.41 Hz
        detector.setResult(pitch: 82.41, probability: 0.95);
        final result = await useCase.analyze(_silentBuffer());

        expect(result.noteName, equals('E'));
        expect(result.octave, equals(2));
      });

      test('cents de A4 exacto es 0', () async {
        detector.setResult(pitch: 440.0, probability: 0.95);
        final result = await useCase.analyze(_silentBuffer());
        expect(result.cents, closeTo(0.0, 0.01));
      });
    });

    // -----------------------------------------------------------------------
    // Cuerda sugerida (suggestedString)
    // -----------------------------------------------------------------------

    group('suggestedString', () {
      test('A2 (110 Hz) → suggestedString 2 en afinación Estándar', () async {
        // Estándar: E2(82.41), A2(110.0), D3(146.83), G3(196.0), B3(246.94), E4(329.63)
        detector.setResult(pitch: 110.0, probability: 0.95);
        final result = await useCase.analyze(_silentBuffer());

        expect(result.suggestedString, equals(2)); // índice 1-based
      });

      test('E4 (329.63 Hz) → suggestedString 6 en afinación Estándar', () async {
        detector.setResult(pitch: 329.63, probability: 0.95);
        final result = await useCase.analyze(_silentBuffer());

        expect(result.suggestedString, equals(6));
      });

      test('E2 (82.41 Hz) → suggestedString 1 en afinación Estándar', () async {
        detector.setResult(pitch: 82.41, probability: 0.95);
        final result = await useCase.analyze(_silentBuffer());

        expect(result.suggestedString, equals(1));
      });

      test('suggestedString es null cuando el resultado es silent', () async {
        detector.setResult(pitch: 440.0, probability: 0.0); // low probability → silent
        final result = await useCase.analyze(_silentBuffer());
        expect(result.suggestedString, isNull);
      });
    });

    // -----------------------------------------------------------------------
    // Igualdad de PitchResult (requisito 9.4)
    // -----------------------------------------------------------------------

    group('igualdad de PitchResult', () {
      test('dos resultados con los mismos campos son iguales', () {
        const r1 = PitchResult(
          noteName: 'A',
          octave: 4,
          frequencyHz: 440.0,
          cents: 0.0,
          tuningState: TuningState.inTune,
          suggestedString: 2,
        );
        const r2 = PitchResult(
          noteName: 'A',
          octave: 4,
          frequencyHz: 440.0,
          cents: 0.0,
          tuningState: TuningState.inTune,
          suggestedString: 2,
        );
        expect(r1, equals(r2));
      });

      test('PitchResult.silent es igual a sí mismo', () {
        expect(PitchResult.silent, equals(PitchResult.silent));
      });

      test('resultados con notas distintas no son iguales', () {
        const r1 = PitchResult(
          noteName: 'A',
          octave: 4,
          frequencyHz: 440.0,
          cents: 0.0,
          tuningState: TuningState.inTune,
          suggestedString: 2,
        );
        const r2 = PitchResult(
          noteName: 'E',
          octave: 4,
          frequencyHz: 329.63,
          cents: 0.0,
          tuningState: TuningState.inTune,
          suggestedString: 6,
        );
        expect(r1, isNot(equals(r2)));
      });
    });
  });
}
