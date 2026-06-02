import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:isaac_tuna/core/constants/tuning_profiles.dart';
import 'package:isaac_tuna/presentation/settings/settings_screen.dart';
import 'package:isaac_tuna/providers/pitch_provider.dart';

// ---------------------------------------------------------------------------
// Helper: crea la app de test con viewport alto para mostrar todos los perfiles
// ---------------------------------------------------------------------------

Widget _buildSettingsApp() {
  return ProviderScope(
    overrides: [
      activeTuningProfileProvider
          .overrideWith((ref) => TuningProfiles.standard),
    ],
    child: const MaterialApp(
      home: SettingsScreen(),
    ),
  );
}

/// Configura el viewport a 800×1400 para que todos los ítems del ListView
/// queden dentro del área visible sin necesidad de scroll.
void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
}

void main() {
  group('SettingsScreen', () {
    // -----------------------------------------------------------------------
    // Lista de perfiles
    // -----------------------------------------------------------------------

    group('lista de perfiles', () {
      testWidgets('muestra los 10 perfiles predefinidos', (tester) async {
        _setTallViewport(tester);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_buildSettingsApp());
        await tester.pump();

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

        for (final name in expectedNames) {
          expect(
            find.text(name),
            findsOneWidget,
            reason: 'No se encontró el perfil "$name"',
          );
        }
      });

      testWidgets('cada perfil muestra las notas de sus cuerdas', (tester) async {
        _setTallViewport(tester);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_buildSettingsApp());
        await tester.pump();

        // El perfil Estándar muestra E2 A2 D3 G3 B3 E4
        expect(find.text('E2  A2  D3  G3  B3  E4'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // Marcado del perfil activo
    // -----------------------------------------------------------------------

    group('marcado del perfil activo', () {
      testWidgets('el perfil activo tiene ícono de verificación', (tester) async {
        await tester.pumpWidget(_buildSettingsApp());
        await tester.pump();

        // El ícono check_circle marca el perfil activo
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('los demás perfiles visibles tienen ícono de radio no seleccionado',
          (tester) async {
        _setTallViewport(tester);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_buildSettingsApp());
        await tester.pump();

        // Con viewport alto los 10 perfiles son visibles: 1 check + 9 radio
        expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(9));
      });
    });

    // -----------------------------------------------------------------------
    // Selección de perfil
    // -----------------------------------------------------------------------

    group('selección de perfil', () {
      testWidgets('al seleccionar "Drop D" actualiza el estado del provider',
          (tester) async {
        // Usar ProviderContainer directamente para leer el estado tras la navegación
        final container = ProviderContainer(
          overrides: [
            activeTuningProfileProvider
                .overrideWith((ref) => TuningProfiles.standard),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );
        await tester.pump();

        // Estado inicial
        expect(container.read(activeTuningProfileProvider).name, equals('Estándar'));

        // Seleccionar "Drop D"
        await tester.tap(find.text('Drop D'));
        await tester.pump();

        // El provider se actualiza inmediatamente (antes de que Navigator.pop se resuelva)
        expect(container.read(activeTuningProfileProvider).name, equals('Drop D'));
      });

      testWidgets('al seleccionar un perfil navega de regreso (Navigator.pop)',
          (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeTuningProfileProvider
                  .overrideWith((ref) => TuningProfiles.standard),
            ],
            child: MaterialApp(
              home: const Scaffold(body: Text('Pantalla anterior')),
              routes: {
                '/settings': (_) => const SettingsScreen(),
              },
            ),
          ),
        );

        // Navegar a SettingsScreen
        final context = tester.element(find.text('Pantalla anterior'));
        Navigator.pushNamed(context, '/settings');
        await tester.pumpAndSettle();

        // SettingsScreen está visible
        expect(find.text('Estándar'), findsOneWidget);

        // Seleccionar un perfil → navega atrás
        await tester.tap(find.text('Open G'));
        await tester.pumpAndSettle();

        // Regresamos a la pantalla anterior
        expect(find.text('Pantalla anterior'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // AppBar
    // -----------------------------------------------------------------------

    group('AppBar', () {
      testWidgets('muestra el título "Afinación"', (tester) async {
        await tester.pumpWidget(_buildSettingsApp());
        await tester.pump();

        expect(find.text('Afinación'), findsOneWidget);
      });

      testWidgets('botón de regreso está presente', (tester) async {
        await tester.pumpWidget(_buildSettingsApp());
        await tester.pump();

        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });
    });
  });
}
