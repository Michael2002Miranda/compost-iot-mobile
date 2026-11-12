import 'package:flutter_test/flutter_test.dart';

import 'package:compost_iot_mobile/clasificacion.dart';
import 'package:compost_iot_mobile/modelos.dart';

void main() {
  group('PFC · clasificación de parámetros', () {
    test('temperatura: rangos del informe', () {
      expect(clasificarParametro('temperatura', 10).estado, EstadoParametro.critico);
      expect(clasificarParametro('temperatura', 18).estado, EstadoParametro.advertencia);
      expect(clasificarParametro('temperatura', 30).etiqueta, 'Mesófila');
      expect(clasificarParametro('temperatura', 55).etiqueta, 'Termófila');
      expect(clasificarParametro('temperatura', 68).estado, EstadoParametro.advertencia);
      expect(clasificarParametro('temperatura', 72).estado, EstadoParametro.critico);
    });

    test('humedad y pH', () {
      expect(clasificarParametro('humedad', 35).estado, EstadoParametro.critico);
      expect(clasificarParametro('humedad', 60).estado, EstadoParametro.optimo);
      expect(clasificarParametro('humedad', 75).estado, EstadoParametro.advertencia);
      expect(clasificarParametro('humedad', 85).estado, EstadoParametro.critico);

      expect(clasificarParametro('ph', 4.5).estado, EstadoParametro.critico);
      expect(clasificarParametro('ph', 5.5).estado, EstadoParametro.advertencia);
      expect(clasificarParametro('ph', 7.2).estado, EstadoParametro.optimo);
      expect(clasificarParametro('ph', 9.5).estado, EstadoParametro.critico);
    });

    test('los límites pasan al tramo superior', () {
      expect(clasificarParametro('temperatura', 20).etiqueta, 'Mesófila');
      expect(clasificarParametro('temperatura', 45).etiqueta, 'Termófila');
      expect(clasificarParametro('humedad', 40).estado, EstadoParametro.advertencia);
      expect(clasificarParametro('ph', 6.0).estado, EstadoParametro.optimo);
    });
  });

  group('PFC · fase del proceso', () {
    test('se determina por temperatura', () {
      expect(determinarFase(55, 60, 7).codigo, 'termofila');
      expect(determinarFase(38, 60, 7).codigo, 'mesofila_activa');
      expect(determinarFase(28, 60, 7).codigo, 'mesofila');
      expect(determinarFase(22, 60, 7).codigo, 'enfriamiento');
      expect(determinarFase(18, 60, 7).codigo, 'maduracion');
    });

    test('agrega recomendaciones cuando la humedad está fuera de rango', () {
      final fase = determinarFase(55, 30, 7);
      expect(fase.observaciones.any((o) => o.toLowerCase().contains('humedad')), isTrue);
    });
  });

  group('PFC · clasificación completa', () {
    test('el estado general es el peor parámetro', () {
      final medicion = Medicion(
        idCompostera: 1,
        temperatura: 70,
        humedad: 60,
        ph: 7,
        fechaHora: DateTime(2026, 11, 11),
      );
      final resultado = clasificarMedicion(medicion);
      expect(resultado.estado, EstadoParametro.critico);
      expect(resultado.fase.codigo, 'termofila');
      expect(resultado.parametros.length, 3);
      expect(resultado.conAlerta.length, 1);
    });
  });

  group('PPFM · precisión', () {
    test('aplica la fórmula del informe', () {
      expect(calcularPrecision(39.4, 40), 98.5);
      expect(calcularPrecision(60, 60), 100);
      expect(calcularPrecision(0, 10), 0);
    });

    test('el error por exceso y por defecto da la misma precisión', () {
      expect(calcularPrecision(58, 60), calcularPrecision(62, 60));
    });
  });

  group('CFC · calidad física', () {
    test('puntúa de 0 a 8 y exige 7 para considerar maduro', () {
      final optimo = puntajeCfc(
        color: 'marron_oscuro',
        aroma: 'tierra_humeda',
        textura: 'suelta_granulada',
        humedad: 'humedece_sin_gotear',
      );
      expect(optimo, 8);
      expect(esCompostMaduro(optimo), isTrue);

      final intermedio = puntajeCfc(
        color: 'marron_claro',
        aroma: 'neutro',
        textura: 'grumosa',
        humedad: 'seca',
      );
      expect(intermedio, 4);
      expect(esCompostMaduro(intermedio), isFalse);

      expect(
        puntajeCfc(
          color: 'negro_verdoso',
          aroma: 'putrefacto',
          textura: 'compacta_pastosa',
          humedad: 'gotea',
        ),
        0,
      );
    });
  });
}

