import 'package:flutter/material.dart';

import '../clasificacion.dart';

/// Identidad visual de la aplicación.
///
/// Paleta terrosa (papel, oliva, terracota) y tipografía editorial: Lora para
/// títulos y cifras, Karla para el texto. La intención es que se sienta como una
/// libreta de campo y no como una plantilla genérica.
class Tema {
  // --- Paleta -------------------------------------------------------------
  static const Color papel = Color(0xFFF4EFE4);
  static const Color superficie = Color(0xFFFFFCF6);
  static const Color tinta = Color(0xFF2B2925);
  static const Color tintaSuave = Color(0xFF6E6759);
  static const Color oliva = Color(0xFF5A6B47);
  static const Color olivaOscuro = Color(0xFF3C4A30);
  static const Color salvia = Color(0xFFE6E9DA);
  static const Color terracota = Color(0xFFB0563A);
  static const Color terracotaSuave = Color(0xFFF3E2D9);
  static const Color ocre = Color(0xFFC08A2E);
  static const Color ladrillo = Color(0xFFA33B33);
  static const Color borde = Color(0xFFE3DAC7);

  // Nombres anteriores, conservados para no tocar todas las pantallas.
  static const Color verde = oliva;
  static const Color verdeOscuro = olivaOscuro;
  static const Color verdeClaro = salvia;
  static const Color crema = papel;
  static const Color texto = tinta;
  static const Color textoSecundario = tintaSuave;

  static TextStyle serif(double tamano, {Color color = tinta, double peso = 600}) {
    return TextStyle(
      fontFamily: 'Lora',
      fontSize: tamano,
      height: 1.18,
      color: color,
      fontWeight: FontWeight.w600,
      fontVariations: [FontVariation('wght', peso)],
      letterSpacing: -0.2,
    );
  }

  static TextStyle sans(double tamano, {
    Color color = tinta,
    FontWeight peso = FontWeight.w400,
    double altura = 1.45,
    double espaciado = 0,
  }) {
    return TextStyle(
      fontFamily: 'Karla',
      fontSize: tamano,
      height: altura,
      color: color,
      fontWeight: peso,
      letterSpacing: espaciado,
    );
  }

  static ThemeData construir() {
    final esquema = ColorScheme.fromSeed(
      seedColor: oliva,
      brightness: Brightness.light,
    ).copyWith(
      primary: terracota,
      onPrimary: Colors.white,
      secondary: oliva,
      surface: superficie,
      onSurface: tinta,
      error: ladrillo,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: esquema);

    final texto = base.textTheme.apply(
      fontFamily: 'Karla',
      bodyColor: tinta,
      displayColor: tinta,
    ).copyWith(
      displayLarge: serif(40),
      displayMedium: serif(32),
      displaySmall: serif(28),
      headlineLarge: serif(26),
      headlineMedium: serif(23),
      headlineSmall: serif(20),
      titleLarge: serif(18),
      titleMedium: serif(16, peso: 500),
      titleSmall: sans(13, peso: FontWeight.w700, espaciado: 0.4),
      bodyLarge: sans(15.5, altura: 1.5),
      bodyMedium: sans(14, altura: 1.45),
      bodySmall: sans(12, color: tintaSuave),
      labelLarge: sans(14, peso: FontWeight.w700, espaciado: 0.2),
      labelMedium: sans(12, peso: FontWeight.w600, espaciado: 0.3),
      labelSmall: sans(10.5, peso: FontWeight.w700, color: tintaSuave, espaciado: 1.0),
    );

    return base.copyWith(
      textTheme: texto,
      scaffoldBackgroundColor: papel,
      appBarTheme: AppBarTheme(
        backgroundColor: papel,
        foregroundColor: tinta,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: serif(20),
        iconTheme: const IconThemeData(color: tinta),
        shape: const Border(bottom: BorderSide(color: borde)),
      ),
      cardTheme: CardThemeData(
        color: superficie,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borde),
        ),
      ),
      dividerTheme: const DividerThemeData(color: borde, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: superficie,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: sans(13.5, color: tintaSuave),
        hintStyle: sans(13.5, color: tintaSuave),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: terracota, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: terracota,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: sans(15.5, peso: FontWeight.w700, color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tinta,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: borde),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: sans(14.5, peso: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: terracota,
          textStyle: sans(13.5, peso: FontWeight.w700, color: terracota),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: superficie,
        selectedColor: salvia,
        side: const BorderSide(color: borde),
        labelStyle: sans(12.5, peso: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: superficie,
        indicatorColor: salvia,
        height: 68,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.all(
          sans(10.5, peso: FontWeight.w700, espaciado: 0.3),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (estados) => IconThemeData(
            color: estados.contains(WidgetState.selected) ? olivaOscuro : tintaSuave,
            size: 23,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tinta,
        contentTextStyle: sans(13, color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: oliva,
        titleTextStyle: sans(14.5, peso: FontWeight.w600),
        subtitleTextStyle: sans(12, color: tintaSuave),
      ),
    );
  }

  // --- Estados ------------------------------------------------------------
  static Color colorEstado(EstadoParametro estado) {
    switch (estado) {
      case EstadoParametro.optimo:
        return const Color(0xFF4E6B43);
      case EstadoParametro.advertencia:
        return ocre;
      case EstadoParametro.critico:
        return ladrillo;
    }
  }

  static Color colorSeveridad(String severidad) {
    switch (severidad) {
      case 'critica':
        return ladrillo;
      case 'advertencia':
        return ocre;
      default:
        return const Color(0xFF4A6B7C);
    }
  }

  static Color colorFase(String codigo) {
    switch (codigo) {
      case 'termofila':
        return ladrillo;
      case 'mesofila_activa':
        return ocre;
      case 'mesofila':
        return const Color(0xFF4E6B43);
      case 'enfriamiento':
        return const Color(0xFF4A6B7C);
      default:
        return terracota;
    }
  }
}
