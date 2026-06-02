import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:isaac_tuna/core/constants/tuning_profiles.dart';
import 'package:isaac_tuna/domain/models/tuning_profile.dart';

void main() {
  group('TuningProfiles', () {
    group('cantidad de perfiles', () {
      test('TuningProfiles.all contiene exactamente 10 perfiles', () {
        expect(TuningProfiles.all.length, equals(10));
      });

      test('los 10 nombres de perfil son correctos', () {
        final expectedNames = [
          'Estándar',
          'Drop D',
          'Open G',
          'Open D',
          'Open E',
          'Open A',
          'DADGAD',
          'Drop C',
          'Eb',
          'D Full Step Down',
        ];
        final actualNames = TuningProfiles.all.map((p) => p.name).toList();
        expect(actualNames, equals(expectedNames));
      });
    });

    group('cantidad de cuerdas', () {
      test('cada perfil tiene exactamente 6 cuerdas', () {
        for (final profile in TuningProfiles.all) {
          expect(
            profile.strings.length,
            equals(6),
            reason: 'El perfil "${profile.name}" no tiene 6 cuerdas',
          );
        }
      });
    });

    group('frecuencias del perfil Estándar', () {
      late TuningProfile standard;

      setUp(() {
        standard = TuningProfiles.standard;
      });

      double expectedFreq(int semitones) =>
          440.0 * math.pow(2.0, semitones / 12.0);

      test('E2 (cuerda 6) ≈ 82.41 Hz', () {
        expect(
          standard.strings[0].frequencyHz,
          closeTo(82.41, 0.01),
        );
      });

      test('A2 (cuerda 5) = 110.00 Hz', () {
        expect(
          standard.strings[1].frequencyHz,
          closeTo(110.00, 0.01),
        );
      });

      test('D3 (cuerda 4) ≈ 146.83 Hz', () {
        expect(
          standard.strings[2].frequencyHz,
          closeTo(146.83, 0.01),
        );
      });

      test('G3 (cuerda 3) ≈ 196.00 Hz', () {
        expect(
          standard.strings[3].frequencyHz,
          closeTo(196.00, 0.01),
        );
      });

      test('B3 (cuerda 2) ≈ 246.94 Hz', () {
        expect(
          standard.strings[4].frequencyHz,
          closeTo(246.94, 0.01),
        );
      });

      test('E4 (cuerda 1) ≈ 329.63 Hz', () {
        expect(
          standard.strings[5].frequencyHz,
          closeTo(329.63, 0.01),
        );
      });

      test('todas las frecuencias coinciden con la fórmula de temperamento igual', () {
        // Semitonos de E2 A2 D3 G3 B3 E4 respecto a A4
        const semitones = [-29, -24, -19, -14, -10, -5];
        for (int i = 0; i < 6; i++) {
          expect(
            standard.strings[i].frequencyHz,
            closeTo(expectedFreq(semitones[i]), 0.01),
            reason:
                'Cuerda ${i + 1}: frecuencia incorrecta para semitono ${semitones[i]}',
          );
        }
      });
    });

    group('nombres y octavas del perfil Estándar', () {
      test('nombres de nota correctos (E A D G B E)', () {
        final names =
            TuningProfiles.standard.strings.map((s) => s.noteName).toList();
        expect(names, equals(['E', 'A', 'D', 'G', 'B', 'E']));
      });

      test('octavas correctas (2 2 3 3 3 4)', () {
        final octaves =
            TuningProfiles.standard.strings.map((s) => s.octave).toList();
        expect(octaves, equals([2, 2, 3, 3, 3, 4]));
      });
    });

    group('perfiles específicos', () {
      test('Drop D: cuerda 6 es D2 ≈ 73.42 Hz', () {
        expect(
          TuningProfiles.dropD.strings[0].frequencyHz,
          closeTo(73.42, 0.01),
        );
        expect(TuningProfiles.dropD.strings[0].noteName, equals('D'));
        expect(TuningProfiles.dropD.strings[0].octave, equals(2));
      });

      test('Drop C: cuerda 6 es C2 ≈ 65.41 Hz', () {
        expect(
          TuningProfiles.dropC.strings[0].frequencyHz,
          closeTo(65.41, 0.01),
        );
      });

      test('Eb: cuerda 6 es Eb2 ≈ 77.78 Hz', () {
        expect(
          TuningProfiles.eb.strings[0].frequencyHz,
          closeTo(77.78, 0.01),
        );
      });
    });
  });
}
