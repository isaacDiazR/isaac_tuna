import 'package:flutter/material.dart';

/// Tema visual minimalista oscuro de IsaacTuna.
///
/// - Fondo negro (#000000) — sin modo claro (requisito 8.1)
/// - Tipografía monoespaciada para valores numéricos (requisito 8.2)
/// - Colores de estado: azul (flat), verde (inTune), ámbar (sharp)
/// - Color secundario en blanco con opacidad para etiquetas inactivas
class AppTheme {
  AppTheme._();

  /// Color azul para el estado [TuningState.flat].
  static const Color flatColor = Color(0xFF2196F3);

  /// Color verde para el estado [TuningState.inTune].
  static const Color inTuneColor = Color(0xFF4CAF50);

  /// Color ámbar para el estado [TuningState.sharp].
  static const Color sharpColor = Color(0xFFFFC107);

  /// [ThemeData] oscuro fijo — no responde al tema del sistema.
  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,

    // Fondo negro puro (requisito 8.1)
    scaffoldBackgroundColor: Colors.black,

    colorScheme: const ColorScheme.dark(
      surface: Color(0xFF1A1A1A),
      primary: Colors.white,
      secondary: Colors.white54,
      // Sin modo claro — ignorar MediaQuery.platformBrightness
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white54),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Tipografía: monoespaciada para valores numéricos (requisito 8.2)
    textTheme: const TextTheme(
      // Nota principal: tipografía grande (≥ 2× el tamaño de valores secundarios)
      displayLarge: TextStyle(
        fontSize: 96,
        fontWeight: FontWeight.w300,
        letterSpacing: -2,
        color: Colors.white,
        height: 1.0,
      ),
      // Valores numéricos secundarios (frecuencia, cents)
      bodyLarge: TextStyle(
        fontSize: 24,
        fontFamily: 'monospace',
        fontWeight: FontWeight.w400,
        color: Colors.white70,
        letterSpacing: 0.5,
      ),
      // Etiquetas inactivas (cuerda sugerida, perfil activo)
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.white54,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Ripple y splash sin colores llamativos
    splashColor: Colors.white12,
    highlightColor: Colors.white10,
  );
}
