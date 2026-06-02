import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:isaac_tuna/core/constants/tuning_profiles.dart';
import 'package:isaac_tuna/domain/models/audio_capture_error.dart';
import 'package:isaac_tuna/domain/models/pitch_result.dart';
import 'package:isaac_tuna/domain/models/tuning_state.dart';
import 'package:isaac_tuna/domain/repositories/audio_repository.dart';
import 'package:isaac_tuna/presentation/tuner/tuner_screen.dart';
import 'package:isaac_tuna/providers/audio_provider.dart';
import 'package:isaac_tuna/providers/pitch_provider.dart';

// ---------------------------------------------------------------------------
// Fake del repositorio de audio (streams vacíos, sin hardware)
// ---------------------------------------------------------------------------

class _FakeAudioRepository implements AudioRepository {
  @override
  Stream<List<double>> get audioStream => const Stream.empty();

  @override
  Stream<AudioCaptureError> get errorStream => const Stream.empty();

  @override
  Future<void> startCapture() async {}

  @override
  Future<void> stopCapture() async {}
}

// ---------------------------------------------------------------------------
// PitchNotifier de test que arranca con un PitchResult conocido
// ---------------------------------------------------------------------------

class _FixedPitchNotifier extends PitchNotifier {
  _FixedPitchNotifier(PitchResult initial) : super(TuningProfiles.standard) {
    state = initial;
  }
}

// ---------------------------------------------------------------------------
// Helper: envuelve el widget en MaterialApp + ProviderScope con overrides
// ---------------------------------------------------------------------------

Widget _buildTestApp({required PitchResult pitchResult}) {
  return ProviderScope(
    overrides: [
      audioRepositoryProvider.overrideWithValue(_FakeAudioRepository()),
      pitchProvider.overrideWith(
        (ref) => _FixedPitchNotifier(pitchResult),
      ),
    ],
    child: MaterialApp(
      routes: {
        '/': (_) => const TunerScreen(),
        '/settings': (_) => const Scaffold(body: Text('Settings')),
      },
    ),
  );
}

void main() {
  group('TunerScreen', () {
    // -----------------------------------------------------------------------
    // NoteDisplay
    // -----------------------------------------------------------------------

    group('NoteDisplay', () {
      testWidgets('muestra "E2" cuando noteName="E" y octave=2', (tester) async {
        const result = PitchResult(
          noteName: 'E',
          octave: 2,
          frequencyHz: 82.41,
          cents: 0.0,
          tuningState: TuningState.inTune,
          suggestedString: 1,
        );

        await tester.pumpWidget(_buildTestApp(pitchResult: result));
        await tester.pump();

        expect(find.text('E2'), findsOneWidget);
      });

      testWidgets('muestra "–" cuando tuningState == silent', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(pitchResult: PitchResult.silent),
        );
        await tester.pump();

        // NoteDisplay muestra "–" para silent (hay dos, uno en NoteDisplay y otro en FrequencyDisplay)
        expect(find.text('–'), findsWidgets);
      });
    });

    // -----------------------------------------------------------------------
    // FrequencyDisplay
    // -----------------------------------------------------------------------

    group('FrequencyDisplay', () {
      testWidgets('muestra "329.63 Hz" con 2 decimales', (tester) async {
        const result = PitchResult(
          noteName: 'E',
          octave: 4,
          frequencyHz: 329.63,
          cents: 0.0,
          tuningState: TuningState.inTune,
          suggestedString: 6,
        );

        await tester.pumpWidget(_buildTestApp(pitchResult: result));
        await tester.pump();

        expect(find.text('329.63 Hz'), findsOneWidget);
      });

      testWidgets('muestra "–" para el estado silent', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(pitchResult: PitchResult.silent),
        );
        await tester.pump();

        // FrequencyDisplay muestra "–" para silent
        expect(find.text('–'), findsWidgets);
      });
    });

    // -----------------------------------------------------------------------
    // TuningStateIndicator (colores)
    // -----------------------------------------------------------------------

    group('TuningStateIndicator', () {
      testWidgets('estado flat muestra el widget sin errores', (tester) async {
        const result = PitchResult(
          noteName: 'A',
          octave: 4,
          frequencyHz: 436.0,
          cents: -15.0,
          tuningState: TuningState.flat,
          suggestedString: 2,
        );

        await tester.pumpWidget(_buildTestApp(pitchResult: result));
        await tester.pump();

        // El widget está en pantalla (se verifica que no lanza excepción)
        expect(find.byType(TunerScreen), findsOneWidget);
      });

      testWidgets('estado inTune muestra el widget sin errores', (tester) async {
        const result = PitchResult(
          noteName: 'A',
          octave: 4,
          frequencyHz: 440.0,
          cents: 0.0,
          tuningState: TuningState.inTune,
          suggestedString: 2,
        );

        await tester.pumpWidget(_buildTestApp(pitchResult: result));
        await tester.pump();

        expect(find.byType(TunerScreen), findsOneWidget);
      });

      testWidgets('estado sharp muestra el widget sin errores', (tester) async {
        const result = PitchResult(
          noteName: 'A',
          octave: 4,
          frequencyHz: 444.0,
          cents: 15.0,
          tuningState: TuningState.sharp,
          suggestedString: 2,
        );

        await tester.pumpWidget(_buildTestApp(pitchResult: result));
        await tester.pump();

        expect(find.byType(TunerScreen), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // SuggestedStringDisplay
    // -----------------------------------------------------------------------

    group('SuggestedStringDisplay', () {
      testWidgets('no muestra "Cuerda" cuando tuningState == silent', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(pitchResult: PitchResult.silent),
        );
        await tester.pump();

        expect(find.text('Cuerda'), findsNothing);
      });

      testWidgets('muestra "Cuerda" cuando hay nota detectada', (tester) async {
        const result = PitchResult(
          noteName: 'A',
          octave: 4,
          frequencyHz: 440.0,
          cents: 0.0,
          tuningState: TuningState.inTune,
          suggestedString: 2,
        );

        await tester.pumpWidget(_buildTestApp(pitchResult: result));
        await tester.pump();

        expect(find.text('Cuerda'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // ActiveTuningLabel
    // -----------------------------------------------------------------------

    group('ActiveTuningLabel', () {
      testWidgets('muestra el nombre del perfil activo (Estándar por defecto)',
          (tester) async {
        await tester.pumpWidget(
          _buildTestApp(pitchResult: PitchResult.silent),
        );
        await tester.pump();

        expect(find.text('Estándar'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // Navegación a SettingsScreen
    // -----------------------------------------------------------------------

    group('navegación', () {
      testWidgets('el botón de afinación navega a /settings', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(pitchResult: PitchResult.silent),
        );
        await tester.pump();

        // El icono de ajustes está visible
        expect(find.byIcon(Icons.tune), findsOneWidget);

        await tester.tap(find.byIcon(Icons.tune));
        await tester.pumpAndSettle();

        // Después de navegar, aparece la pantalla de settings de prueba
        expect(find.text('Settings'), findsOneWidget);
      });
    });
  });
}
