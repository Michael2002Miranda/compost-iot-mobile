/// Clasificación de los parámetros fisicoquímicos (indicador PFC) y cálculo de la
/// precisión (indicador PPFM).
///
/// Los umbrales son los mismos que aplica el backend en
/// `src/domain/clasificacion.js`. Se replican aquí para que la aplicación pueda
/// clasificar una lectura guardada sin conexión y para que la pantalla responda
/// de inmediato, sin esperar al servidor.
library;

import 'modelos.dart';

enum EstadoParametro { optimo, advertencia, critico }

extension EtiquetaEstado on EstadoParametro {
  String get nombre {
    switch (this) {
      case EstadoParametro.optimo:
        return 'Óptimo';
      case EstadoParametro.advertencia:
        return 'Atención';
      case EstadoParametro.critico:
        return 'Crítico';
    }
  }

  int get peso {
    switch (this) {
      case EstadoParametro.optimo:
        return 0;
      case EstadoParametro.advertencia:
        return 1;
      case EstadoParametro.critico:
        return 2;
    }
  }
}

class Tramo {
  const Tramo(this.hasta, this.estado, this.etiqueta, this.mensaje);
  final double hasta;
  final EstadoParametro estado;
  final String etiqueta;
  final String mensaje;
}

class DefinicionParametro {
  const DefinicionParametro(this.etiqueta, this.unidad, this.tramos);
  final String etiqueta;
  final String unidad;
  final List<Tramo> tramos;
}

const Map<String, DefinicionParametro> definiciones = {
  'temperatura': DefinicionParametro('Temperatura', '°C', [
    Tramo(15, EstadoParametro.critico, 'Baja', 'Temperatura muy baja: la actividad microbiana se detiene.'),
    Tramo(20, EstadoParametro.advertencia, 'Fría', 'Temperatura por debajo del rango mesófilo.'),
    Tramo(45, EstadoParametro.optimo, 'Mesófila', 'Rango mesófilo: descomposición activa.'),
    Tramo(65, EstadoParametro.optimo, 'Termófila', 'Rango termófilo: higienización del material.'),
    Tramo(70, EstadoParametro.advertencia, 'Alta', 'Supera el umbral termófilo: riesgo de pérdida de nitrógeno.'),
    Tramo(double.infinity, EstadoParametro.critico, 'Excesiva', 'Temperatura crítica: riesgo de combustión espontánea.'),
  ]),
  'humedad': DefinicionParametro('Humedad', '%', [
    Tramo(40, EstadoParametro.critico, 'Muy seca', 'Compost demasiado seco: la descomposición se frena.'),
    Tramo(50, EstadoParametro.advertencia, 'Baja', 'Humedad por debajo del rango recomendado.'),
    Tramo(70, EstadoParametro.optimo, 'Óptima', 'Humedad adecuada para el proceso.'),
    Tramo(80, EstadoParametro.advertencia, 'Alta', 'Exceso de humedad: riesgo de anaerobiosis.'),
    Tramo(double.infinity, EstadoParametro.critico, 'Encharcada', 'Humedad crítica: el material se compacta y genera lixiviados.'),
  ]),
  'ph': DefinicionParametro('pH', '', [
    Tramo(5.0, EstadoParametro.critico, 'Muy ácido', 'pH crítico: fermentación ácida.'),
    Tramo(6.0, EstadoParametro.advertencia, 'Ácido', 'Fase de acidificación; vigilar la aireación.'),
    Tramo(8.5, EstadoParametro.optimo, 'Neutro', 'pH dentro del rango recomendado.'),
    Tramo(9.0, EstadoParametro.advertencia, 'Alcalino', 'pH alcalino: posible pérdida de nitrógeno por amoniaco.'),
    Tramo(double.infinity, EstadoParametro.critico, 'Muy alcalino', 'pH crítico: revisar la mezcla y la aireación.'),
  ]),
};

class ParametroClasificado {
  const ParametroClasificado({
    required this.parametro,
    required this.valor,
    required this.estado,
    required this.etiqueta,
    required this.mensaje,
    required this.rango,
    required this.unidad,
  });

  final String parametro;
  final double valor;
  final EstadoParametro estado;
  final String etiqueta;
  final String mensaje;
  final String rango;
  final String unidad;

  String get nombre => definiciones[parametro]?.etiqueta ?? parametro;
}

ParametroClasificado clasificarParametro(String parametro, double valor) {
  final definicion = definiciones[parametro];
  if (definicion == null) {
    throw ArgumentError('Parámetro desconocido: $parametro');
  }

  var indice = definicion.tramos.indexWhere((t) => valor < t.hasta);
  if (indice < 0) indice = definicion.tramos.length - 1;
  final tramo = definicion.tramos[indice];
  final inferior = indice == 0 ? 0.0 : definicion.tramos[indice - 1].hasta;

  return ParametroClasificado(
    parametro: parametro,
    valor: valor,
    estado: tramo.estado,
    etiqueta: tramo.etiqueta,
    mensaje: tramo.mensaje,
    rango: '${_formato(inferior)} – ${tramo.hasta == double.infinity ? '∞' : _formato(tramo.hasta)}',
    unidad: definicion.unidad,
  );
}

String _formato(double valor) =>
    valor == valor.roundToDouble() ? valor.toStringAsFixed(0) : valor.toStringAsFixed(1);

class FaseProceso {
  const FaseProceso({
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    this.observaciones = const [],
  });

  final String codigo;
  final String nombre;
  final String descripcion;
  final List<String> observaciones;
}

FaseProceso determinarFase(double temperatura, double humedad, double ph) {
  String codigo;
  String nombre;
  String descripcion;

  if (temperatura >= 45) {
    codigo = 'termofila';
    nombre = 'Fase termófila';
    descripcion = 'El material alcanza temperaturas de higienización; se eliminan patógenos y semillas.';
  } else if (temperatura >= 35) {
    codigo = 'mesofila_activa';
    nombre = 'Fase mesófila activa';
    descripcion = 'Máxima actividad microbiana y consumo de oxígeno.';
  } else if (temperatura >= 25) {
    codigo = 'mesofila';
    nombre = 'Fase mesófila';
    descripcion = 'Descomposición constante de la materia orgánica.';
  } else if (temperatura >= 20) {
    codigo = 'enfriamiento';
    nombre = 'Fase de enfriamiento';
    descripcion = 'El proceso pierde temperatura y se acerca a la estabilización.';
  } else {
    codigo = 'maduracion';
    nombre = 'Maduración';
    descripcion = 'Baja actividad biológica; el compost tiende a estabilizarse.';
  }

  final observaciones = <String>[];
  if (humedad < 40) observaciones.add('La humedad baja puede detener la fase: humedecer y voltear.');
  if (humedad > 80) observaciones.add('El exceso de humedad favorece condiciones anaerobias: voltear y agregar material seco.');
  if (ph < 5.5) observaciones.add('pH ácido: incorporar material rico en carbono y airear.');
  if (ph > 8.5) observaciones.add('pH alcalino: revisar la proporción de restos y la aireación.');

  return FaseProceso(codigo: codigo, nombre: nombre, descripcion: descripcion, observaciones: observaciones);
}

class Clasificacion {
  const Clasificacion({required this.fase, required this.estado, required this.parametros});

  final FaseProceso fase;
  final EstadoParametro estado;
  final List<ParametroClasificado> parametros;

  ParametroClasificado porParametro(String nombre) =>
      parametros.firstWhere((p) => p.parametro == nombre);

  List<ParametroClasificado> get conAlerta =>
      parametros.where((p) => p.estado != EstadoParametro.optimo).toList();
}

Clasificacion clasificarMedicion(Medicion medicion) {
  final parametros = [
    clasificarParametro('temperatura', medicion.temperatura),
    clasificarParametro('humedad', medicion.humedad),
    clasificarParametro('ph', medicion.ph),
  ];

  var peor = EstadoParametro.optimo;
  for (final p in parametros) {
    if (p.estado.peso > peor.peso) peor = p.estado;
  }

  return Clasificacion(
    fase: determinarFase(medicion.temperatura, medicion.humedad, medicion.ph),
    estado: peor,
    parametros: parametros,
  );
}

/// PPFM (%) = 100 − (|VM − VR| / VR) × 100
double calcularPrecision(double valorMedido, double valorReferencia) {
  if (valorReferencia == 0) return 0;
  final errorRelativo = (valorMedido - valorReferencia).abs() / valorReferencia.abs();
  final precision = 100 - errorRelativo * 100;
  return double.parse(precision.clamp(0, 100).toStringAsFixed(2));
}

/// Puntaje de la ficha de calidad física del compost (0 a 8).
int puntajeCfc({
  required String color,
  required String aroma,
  required String textura,
  required String humedad,
}) {
  const colorPuntos = {'marron_oscuro': 2, 'marron_claro': 1, 'negro_verdoso': 0};
  const aromaPuntos = {'tierra_humeda': 2, 'neutro': 1, 'putrefacto': 0};
  const texturaPuntos = {'suelta_granulada': 2, 'grumosa': 1, 'compacta_pastosa': 0};
  const humedadPuntos = {'humedece_sin_gotear': 2, 'seca': 1, 'gotea': 0};

  return (colorPuntos[color] ?? 0) +
      (aromaPuntos[aroma] ?? 0) +
      (texturaPuntos[textura] ?? 0) +
      (humedadPuntos[humedad] ?? 0);
}

bool esCompostMaduro(int puntaje) => puntaje >= 7;

/// Nombre legible de un parámetro (usado en listados y fichas).
String nombreParametro(String parametro) =>
    definiciones[parametro]?.etiqueta ?? parametro;

/// Unidad de medida de un parámetro.
String unidadParametro(String parametro) => definiciones[parametro]?.unidad ?? '';
