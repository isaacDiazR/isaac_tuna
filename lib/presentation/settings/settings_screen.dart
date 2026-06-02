import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/tuning_profiles.dart';
import '../../domain/models/tuning_profile.dart';
import '../../providers/pitch_provider.dart';

/// Pantalla de selección de afinación.
///
/// Muestra la lista de los 10 perfiles predefinidos con el nombre y las notas
/// de las 6 cuerdas en notación científica. El perfil activo se marca con un
/// ícono de verificación y un color de acento. Al seleccionar un perfil se
/// actualiza [activeTuningProfileProvider] y se navega de regreso a
/// [TunerScreen] mediante [Navigator.pop].
///
/// Requisitos: 5.1–5.6
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeTuningProfileProvider);
    final profiles = TuningProfiles.all;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Afinación',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white54),
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: profiles.length,
          separatorBuilder: (_, __) => const Divider(
            color: Color(0xFF2A2A2A),
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final profile = profiles[index];
            final isActive = profile.name == activeProfile.name;

            return _TuningProfileTile(
              profile: profile,
              isActive: isActive,
              onTap: () {
                // Actualizar el perfil activo antes de navegar (requisito 5.4:
                // si la navegación falla, el estado ya fue actualizado).
                ref.read(activeTuningProfileProvider.notifier).state = profile;

                // Navegar de regreso a TunerScreen (requisito 5.3).
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }
}

/// Tile individual para un perfil de afinación.
///
/// Muestra el nombre del perfil y las notas de las 6 cuerdas en notación
/// científica. El perfil activo se resalta con color de acento y un ícono
/// de verificación (requisito 5.6).
class _TuningProfileTile extends StatelessWidget {
  const _TuningProfileTile({
    required this.profile,
    required this.isActive,
    required this.onTap,
  });

  final TuningProfile profile;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Color de acento para el perfil activo.
    const accentColor = Color(0xFF4CAF50); // verde — mismo que inTune

    return InkWell(
      onTap: onTap,
      splashColor: accentColor.withAlpha(40),
      highlightColor: accentColor.withAlpha(20),
      child: Container(
        color: isActive ? const Color(0xFF0D1F0D) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Indicador de perfil activo (check) o espacio reservado.
            SizedBox(
              width: 28,
              child: isActive
                  ? const Icon(
                      Icons.check_circle,
                      color: accentColor,
                      size: 20,
                    )
                  : const Icon(
                      Icons.radio_button_unchecked,
                      color: Colors.white24,
                      size: 20,
                    ),
            ),

            const SizedBox(width: 12),

            // Nombre del perfil y notas de las cuerdas.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del perfil.
                  Text(
                    profile.name,
                    style: TextStyle(
                      color: isActive ? accentColor : Colors.white,
                      fontSize: 16,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Notas de las 6 cuerdas en notación científica.
                  // Las cuerdas están ordenadas de más grave (índice 0) a más
                  // aguda (índice 5), que corresponde a la 6ª → 1ª cuerda.
                  Text(
                    _buildStringsLabel(profile),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la etiqueta con las notas de las 6 cuerdas en notación
  /// científica (p. ej. "E2  A2  D3  G3  B3  E4").
  String _buildStringsLabel(TuningProfile profile) {
    return profile.strings
        .map((s) => '${s.noteName}${s.octave}')
        .join('  ');
  }
}
