import 'package:flutter/material.dart';

import '../clasificacion.dart';

/// Paleta y estilos de la aplicación.
class Tema {
  static const Color verde = Color(0xFF2E7D32);
  static const Color verdeOscuro = Color(0xFF1B5E20);
  static const Color verdeClaro = Color(0xFFE8F5E9);
  static const Color crema = Color(0xFFF7F6EF);
  static const Color texto = Color(0xFF1F2A22);
  static const Color textoSecundario = Color(0xFF6B7A6E);

  static ThemeData construir() {
    final esquema = ColorScheme.fromSeed(
      seedColor: verde,
      brightness: Brightness.light,
    ).copyWith(
      primary: verde,
      secondary: const Color(0xFF8D6E63),
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: crema,
      appBarTheme: const AppBarTheme(
        backgroundColor: verde,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDCE5DD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDCE5DD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: verde, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: verde,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: verdeClaro,
        height: 66,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (estados) => IconThemeData(
            color: estados.contains(WidgetState.selected) ? verde : textoSecundario,
            size: 24,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: texto,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Color colorEstado(EstadoParametro estado) {
    switch (estado) {
      case EstadoParametro.optimo:
        return const Color(0xFF2E7D32);
      case EstadoParametro.advertencia:
        return const Color(0xFFEF6C00);
      case EstadoParametro.critico:
        return const Color(0xFFC62828);
    }
  }

  static Color colorSeveridad(String severidad) {
    switch (severidad) {
      case 'critica':
        return const Color(0xFFC62828);
      case 'advertencia':
        return const Color(0xFFEF6C00);
      default:
        return const Color(0xFF1565C0);
    }
  }

  static Color colorFase(String codigo) {
    switch (codigo) {
      case 'termofila':
        return const Color(0xFFC62828);
      case 'mesofila_activa':
        return const Color(0xFFEF6C00);
      case 'mesofila':
        return const Color(0xFF2E7D32);
      case 'enfriamiento':
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFF6D4C41);
    }
  }
}
