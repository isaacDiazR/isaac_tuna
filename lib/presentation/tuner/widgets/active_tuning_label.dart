import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/pitch_provider.dart';

/// Muestra el nombre del perfil de afinación activo.
///
/// Observa [activeTuningProfileProvider] para actualizarse automáticamente
/// cuando el usuario cambia el perfil en [SettingsScreen].
///
/// Requisito: 5.5
class ActiveTuningLabel extends ConsumerWidget {
  const ActiveTuningLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeTuningProfileProvider);

    return Text(
      profile.name,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.white54,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
