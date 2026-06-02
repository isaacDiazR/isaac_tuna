import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isaac_tuna/core/utils/note_converter.dart';

void main() {
  group('NoteConverter', () {
    group('frequencyToSemitones', () {
      test('A4 (440 Hz) retorna semitono 0', () {
        expect(NoteConverter.frequencyToSemitones(440.0), equals(0));
      });

      test('A5 (880 Hz) retorna semitono 12', () {
        expect(NoteConverter.frequencyToSemitones(880.0), equals(12));
      });

      test('A3 (220 Hz) retorna semitono -12', () {
        expect(NoteConverter.frequencyToSemitones(220.0), equals(-12));
      });

      test('E4 (≈329.63 Hz) retorna semitono -5', () {
        expect(NoteConverter.frequencyToSemitones(329.63), equals(-5));
      });

      test('E2 (≈82.41 Hz) retorna semitono -29', () {
        expect(NoteConverter.frequencyToSemitones(82.41), equals(-29));
      });
    });

    group('semitonesToNoteName', () {
      test('semitono 0 es A (A4)', () {
        expect(NoteConverter.semitonesToNoteName(0), equals('A'));
      });

      test('semitono -9 es C (C4 = Do central)', () {
        expect(NoteConverter.semitonesToNoteName(-9), equals('C'));
      });

      test('semitono -5 es E', () {
        expect(NoteConverter.semitonesToNoteName(-5), equals('E'));
      });

      test('semitono 3 es C (C5)', () {
        expect(NoteConverter.semitonesToNoteName(3), equals('C'));
      });

      test('semitono -8 es C# (C#4)', () {
        expect(NoteConverter.semitonesToNoteName(-8), equals('C#'));
      });
    });

    group('semitonesToOctave', () {
      test('A4 (semitono 0) es octava 4', () {
        expect(NoteConverter.semitonesToOctave(0), equals(4));
      });

      test('C4 (semitono -9) es octava 4', () {
        expect(NoteConverter.semitonesToOctave(-9), equals(4));
      });

      test('E2 (semitono -29) es octava 2', () {
        expect(NoteConverter.semitonesToOctave(-29), equals(2));
      });

      test('A5 (semitono 12) es octava 5', () {
        expect(NoteConverter.semitonesToOctave(12), equals(5));
      });
    });

    group('frequencyToCents', () {
      test('misma frecuencia retorna 0 cents', () {
        expect(NoteConverter.frequencyToCents(440.0, 440.0), equals(0.0));
      });

      test('frecuencia 15 cents por encima retorna ≈+15', () {
        final targetHz = 440.0;
        final sharpHz = targetHz * pow(2.0, 15.0 / 1200.0);
        expect(
          NoteConverter.frequencyToCents(sharpHz, targetHz),
          closeTo(15.0, 0.01),
        );
      });

      test('frecuencia 15 cents por debajo retorna ≈-15', () {
        final targetHz = 440.0;
        final flatHz = targetHz * pow(2.0, -15.0 / 1200.0);
        expect(
          NoteConverter.frequencyToCents(flatHz, targetHz),
          closeTo(-15.0, 0.01),
        );
      });

      test('resultado acotado a +50 en el límite superior', () {
        // Frecuencia muy por encima del objetivo → debe devolverse exactamente +50
        final cents = NoteConverter.frequencyToCents(600.0, 440.0);
        expect(cents, equals(50.0));
      });

      test('resultado acotado a -50 en el límite inferior', () {
        // Frecuencia muy por debajo del objetivo → debe devolverse exactamente -50
        final cents = NoteConverter.frequencyToCents(300.0, 440.0);
        expect(cents, equals(-50.0));
      });
    });

    group('propiedad de ida y vuelta (round-trip)', () {
      test('frecuencias estándar de guitarra se reconstruyen con <0.5 Hz de error', () {
        // Notas reales de la afinación estándar
        const frequencies = [82.41, 110.0, 146.83, 196.0, 246.94, 329.63, 440.0, 880.0];

        for (final f in frequencies) {
          final semitones = NoteConverter.frequencyToSemitones(f);
          final targetHz = NoteConverter.semitonesToFrequency(semitones);
          final cents = NoteConverter.frequencyToCents(f, targetHz);
          final reconstructed = targetHz * pow(2.0, cents / 1200.0);

          expect(
            (f - reconstructed).abs(),
            lessThan(0.5),
            reason: 'Round-trip falló para $f Hz (reconstruido: $reconstructed Hz)',
          );
        }
      });

      test('frecuencias ligeramente desafinadas también se reconstruyen bien', () {
        // Frecuencias que están ligeramente entre notas
        const frequencies = [83.0, 111.5, 148.0, 200.0, 250.0, 335.0];

        for (final f in frequencies) {
          final semitones = NoteConverter.frequencyToSemitones(f);
          final targetHz = NoteConverter.semitonesToFrequency(semitones);
          final cents = NoteConverter.frequencyToCents(f, targetHz);
          final reconstructed = targetHz * pow(2.0, cents / 1200.0);

          expect(
            (f - reconstructed).abs(),
            lessThan(0.5),
            reason: 'Round-trip falló para $f Hz',
          );
        }
      });
    });
  });
}
