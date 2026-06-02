import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:isaac_tuna/main.dart';

void main() {
  testWidgets('IsaacTunaApp arranca sin errores', (WidgetTester tester) async {
    // La app real necesita hardware de micrófono, por eso la envolvemos
    // en ProviderScope y verificamos solo que el árbol se construye.
    await tester.pumpWidget(
      const ProviderScope(
        child: IsaacTunaApp(),
      ),
    );

    // El widget raíz debe existir
    expect(find.byType(IsaacTunaApp), findsOneWidget);
    // El MaterialApp debe estar presente
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
