import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/permission_manager.dart';
import '../../domain/models/audio_capture_error.dart';
import '../../providers/audio_provider.dart';
import '../../providers/pitch_provider.dart';
import 'widgets/active_tuning_label.dart';
import 'widgets/cents_indicator.dart';
import 'widgets/frequency_display.dart';
import 'widgets/note_display.dart';
import 'widgets/suggested_string_display.dart';
import 'widgets/tuning_state_indicator.dart';

/// Pantalla principal del afinador.
///
/// Observa [pitchProvider] y compone todos los sub-widgets de afinación.
/// Incluye un botón de navegación hacia [SettingsScreen].
/// Muestra mensajes de permiso denegado cuando corresponde (requisitos 6.2–6.4).
///
/// Requisitos: 4.1–4.9, 6.2–6.4, 8.2, 8.3, 8.5
class TunerScreen extends ConsumerWidget {
  const TunerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pitchResult = ref.watch(pitchProvider);
    final audioError = ref.watch(audioErrorProvider);

    // Determinar si hay un error activo y su tipo.
    AudioCaptureError? permissionError;
    AudioCaptureError? systemError;
    audioError.whenData((error) {
      if (error.type == AudioErrorType.permissionDenied) {
        permissionError = error;
      } else if (error.type == AudioErrorType.systemError) {
        systemError = error;
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Requisito 6.4: la navegación a SettingsScreen no debe bloquearse
          // aunque el permiso esté denegado.
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white54),
            tooltip: 'Seleccionar afinación',
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: permissionError != null
            ? _PermissionDeniedView(
                permissionManager: const PermissionManager(),
                onRetry: () {
                  // Reintentar la captura tras conceder el permiso.
                  final repo = ref.read(audioRepositoryProvider);
                  repo.startCapture();
                },
              )
            : systemError != null
                ? _SystemErrorView(
                    error: systemError!,
                    onRetry: () {
                      final repo = ref.read(audioRepositoryProvider);
                      repo.startCapture();
                    },
                  )
                : _TunerContent(pitchResult: pitchResult),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget interno: contenido principal del afinador
// ---------------------------------------------------------------------------

class _TunerContent extends StatelessWidget {
  const _TunerContent({required this.pitchResult});

  final dynamic pitchResult;

  @override
  Widget build(BuildContext context) {
    // Patrón "fill or scroll": el Column se centra cuando cabe en pantalla
    // y se vuelve scrollable cuando no (p. ej. modo landscape).
    // Los Spacer no funcionan dentro de SingleChildScrollView, por eso se
    // reemplazaron con SizedBox de tamaño fijo y padding vertical.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 20.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Nombre del perfil activo
                  const ActiveTuningLabel(),

                  const SizedBox(height: 8),

                  // Cuerda sugerida
                  SuggestedStringDisplay(pitchResult: pitchResult),

                  const SizedBox(height: 28),

                  // Nota principal (tipografía grande — al menos 2× el tamaño secundario)
                  NoteDisplay(pitchResult: pitchResult),

                  const SizedBox(height: 8),

                  // Frecuencia en Hz
                  FrequencyDisplay(pitchResult: pitchResult),

                  const SizedBox(height: 28),

                  // Indicador de cents (barra animada)
                  CentsIndicator(pitchResult: pitchResult),

                  const SizedBox(height: 20),

                  // Indicador de estado de afinación (color)
                  TuningStateIndicator(pitchResult: pitchResult),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Widget interno: vista de permiso denegado
// ---------------------------------------------------------------------------

/// Muestra el mensaje apropiado según si el permiso es re-solicitable o
/// fue denegado permanentemente (requisitos 6.2 y 6.3).
class _PermissionDeniedView extends StatefulWidget {
  const _PermissionDeniedView({
    required this.permissionManager,
    required this.onRetry,
  });

  final PermissionManager permissionManager;
  final VoidCallback onRetry;

  @override
  State<_PermissionDeniedView> createState() => _PermissionDeniedViewState();
}

// ---------------------------------------------------------------------------
// Widget interno: vista de error del sistema de audio
// ---------------------------------------------------------------------------

class _SystemErrorView extends StatelessWidget {
  const _SystemErrorView({required this.error, required this.onRetry});

  final AudioCaptureError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.mic_off, color: Colors.orange, size: 56),
          const SizedBox(height: 24),
          const Text(
            'Error al acceder al micrófono.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            error.message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _PermissionDeniedViewState extends State<_PermissionDeniedView> {
  bool _isPermanentlyDenied = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final permanently = await widget.permissionManager.isPermanentlyDenied();
    if (mounted) {
      setState(() {
        _isPermanentlyDenied = permanently;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white24),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.mic_off, color: Colors.white38, size: 56),
          const SizedBox(height: 24),
          if (_isPermanentlyDenied) ...[
            // Requisito 6.3: permiso denegado permanentemente (≤ 200 caracteres)
            const Text(
              'Permiso de micrófono denegado. Ve a Ajustes del sistema y habilita el micrófono para IsaacTuna.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.settings),
              label: const Text('Abrir Ajustes'),
              onPressed: () => widget.permissionManager.openSettings(),
            ),
          ] else ...[
            // Requisito 6.2: permiso denegado re-solicitable (≤ 200 caracteres)
            const Text(
              'IsaacTuna necesita el micrófono para detectar la nota. Concede el permiso para continuar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.mic),
              label: const Text('Solicitar permiso'),
              onPressed: widget.onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
