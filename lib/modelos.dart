/// Modelos de datos de la aplicación.
///
/// Se mantienen sin dependencias externas: cada clase sabe convertirse desde y
/// hacia JSON, que es lo que devuelve la API y lo que se guarda en el dispositivo.
library;

double _numero(dynamic valor) {
  if (valor is num) return valor.toDouble();
  return double.tryParse('${valor ?? ''}'.replaceAll(',', '.')) ?? 0;
}

double? _numeroOpcional(dynamic valor) {
  if (valor == null) return null;
  if (valor is num) return valor.toDouble();
  return double.tryParse('$valor');
}

DateTime _fecha(dynamic valor) {
  if (valor is DateTime) return valor;
  return DateTime.tryParse('${valor ?? ''}')?.toLocal() ?? DateTime.now();
}

DateTime? _fechaOpcional(dynamic valor) {
  if (valor == null) return null;
  return DateTime.tryParse('$valor')?.toLocal();
}

class Usuario {
  const Usuario({required this.id, required this.nombre, required this.email});

  final int id;
  final String nombre;
  final String email;

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: (json['id'] as num?)?.toInt() ?? 0,
        nombre: '${json['nombre'] ?? ''}',
        email: '${json['email'] ?? ''}',
      );

  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre, 'email': email};
}

class Compostera {
  const Compostera({
    required this.id,
    required this.nombre,
    required this.grupo,
    this.ubicacion,
    this.codigo,
    this.lecturas = 0,
    this.ultimaLectura,
    this.creadaEn,
  });

  final int id;
  final String nombre;

  /// `GC` = grupo control, `GE` = grupo experimental.
  final String grupo;
  final String? ubicacion;

  /// Código que envía el ESP32 en cada lectura.
  final String? codigo;
  final int lecturas;
  final DateTime? ultimaLectura;
  final DateTime? creadaEn;

  bool get esExperimental => grupo == 'GE';

  factory Compostera.fromJson(Map<String, dynamic> json) => Compostera(
        id: (json['id'] as num?)?.toInt() ?? 0,
        nombre: '${json['nombre'] ?? 'Compostera'}',
        grupo: '${json['grupo'] ?? 'GE'}'.toUpperCase(),
        ubicacion: json['ubicacion']?.toString(),
        codigo: json['codigo']?.toString(),
        lecturas: (json['lecturas'] as num?)?.toInt() ?? 0,
        ultimaLectura: _fechaOpcional(json['ultima_lectura'] ?? json['ultima']),
        creadaEn: _fechaOpcional(json['creada_en']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'grupo': grupo,
        'ubicacion': ubicacion,
        'codigo': codigo,
        'lecturas': lecturas,
        'ultima_lectura': ultimaLectura?.toIso8601String(),
        'creada_en': creadaEn?.toIso8601String(),
      };
}

class Medicion {
  const Medicion({
    this.id,
    required this.idCompostera,
    required this.temperatura,
    required this.humedad,
    required this.ph,
    required this.fechaHora,
    this.phSimulado = false,
    this.grupo,
  });

  final int? id;
  final int idCompostera;
  final double temperatura;
  final double humedad;
  final double ph;
  final DateTime fechaHora;

  /// El prototipo todavía no tiene sensor de pH: el firmware envía un valor
  /// simulado y la app lo advierte para no presentarlo como medición real.
  final bool phSimulado;
  final String? grupo;

  factory Medicion.fromJson(Map<String, dynamic> json) => Medicion(
        id: (json['id'] as num?)?.toInt(),
        idCompostera: (json['id_compostera'] as num?)?.toInt() ?? 1,
        temperatura: _numero(json['temperatura']),
        humedad: _numero(json['humedad']),
        ph: _numero(json['ph']),
        fechaHora: _fecha(json['fecha_hora']),
        phSimulado: json['ph_simulado'] == true,
        grupo: json['grupo']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'id_compostera': idCompostera,
        'temperatura': temperatura,
        'humedad': humedad,
        'ph': ph,
        'fecha_hora': fechaHora.toIso8601String(),
        'ph_simulado': phSimulado,
        'grupo': grupo,
      };
}

class Alerta {
  const Alerta({
    required this.id,
    required this.parametro,
    required this.severidad,
    required this.mensaje,
    required this.fechaHora,
    this.valor,
    this.atendida = false,
    this.compostera,
  });

  final int id;
  final String parametro;
  final String severidad; // info | advertencia | critica
  final String mensaje;
  final DateTime fechaHora;
  final double? valor;
  final bool atendida;
  final String? compostera;

  bool get esCritica => severidad == 'critica';

  factory Alerta.fromJson(Map<String, dynamic> json) => Alerta(
        id: (json['id'] as num?)?.toInt() ?? 0,
        parametro: '${json['parametro'] ?? ''}',
        severidad: '${json['severidad'] ?? 'advertencia'}',
        mensaje: '${json['mensaje'] ?? ''}',
        fechaHora: _fecha(json['fecha_hora']),
        valor: _numeroOpcional(json['valor']),
        atendida: json['atendida'] == true,
        compostera: json['compostera_nombre']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'parametro': parametro,
        'severidad': severidad,
        'mensaje': mensaje,
        'fecha_hora': fechaHora.toIso8601String(),
        'valor': valor,
        'atendida': atendida,
        'compostera_nombre': compostera,
      };
}

/// Registro del indicador PPFM (precisión de los parámetros medidos).
class RegistroPpfm {
  const RegistroPpfm({
    required this.parametro,
    required this.valorMedido,
    required this.valorReferencia,
    required this.precision,
    required this.fecha,
    this.idCompostera = 1,
    this.observaciones,
  });

  final String parametro;
  final double valorMedido;
  final double valorReferencia;
  final double precision;
  final DateTime fecha;
  final int idCompostera;
  final String? observaciones;

  factory RegistroPpfm.fromJson(Map<String, dynamic> json) => RegistroPpfm(
        parametro: '${json['parametro'] ?? ''}',
        valorMedido: _numero(json['valor_medido']),
        valorReferencia: _numero(json['valor_referencia']),
        precision: _numero(json['precision']),
        fecha: _fecha(json['fecha']),
        idCompostera: (json['id_compostera'] as num?)?.toInt() ?? 1,
        observaciones: json['observaciones']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'parametro': parametro,
        'valor_medido': valorMedido,
        'valor_referencia': valorReferencia,
        'precision': precision,
        'fecha': fecha.toIso8601String(),
        'id_compostera': idCompostera,
        'observaciones': observaciones,
      };
}

/// Registro del indicador CFC (calidad física del compost).
class RegistroCfc {
  const RegistroCfc({
    required this.color,
    required this.aroma,
    required this.textura,
    required this.humedad,
    required this.puntaje,
    required this.maduro,
    required this.fecha,
    this.idCompostera = 1,
    this.observaciones,
  });

  final String color;
  final String aroma;
  final String textura;
  final String humedad;
  final int puntaje;
  final bool maduro;
  final DateTime fecha;
  final int idCompostera;
  final String? observaciones;

  factory RegistroCfc.fromJson(Map<String, dynamic> json) => RegistroCfc(
        color: '${json['color'] ?? ''}',
        aroma: '${json['aroma'] ?? ''}',
        textura: '${json['textura'] ?? ''}',
        humedad: '${json['humedad'] ?? ''}',
        puntaje: (json['puntaje'] as num?)?.toInt() ?? 0,
        maduro: json['maduro'] == true,
        fecha: _fecha(json['fecha']),
        idCompostera: (json['id_compostera'] as num?)?.toInt() ?? 1,
        observaciones: json['observaciones']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'color': color,
        'aroma': aroma,
        'textura': textura,
        'humedad': humedad,
        'puntaje': puntaje,
        'maduro': maduro,
        'fecha': fecha.toIso8601String(),
        'id_compostera': idCompostera,
        'observaciones': observaciones,
      };
}

/// Resultado agregado de un grupo (GC o GE) para la comparación de la posprueba.
class ResumenGrupo {
  const ResumenGrupo({
    this.lecturas = 0,
    this.temperaturaPromedio,
    this.humedadPromedio,
    this.phPromedio,
    this.temperaturaMaxima,
    this.precisionPromedio,
    this.registrosPrecision = 0,
    this.puntajeCfcPromedio,
    this.registrosCfc = 0,
    this.maduros = 0,
  });

  final int lecturas;
  final double? temperaturaPromedio;
  final double? humedadPromedio;
  final double? phPromedio;
  final double? temperaturaMaxima;
  final double? precisionPromedio;
  final int registrosPrecision;
  final double? puntajeCfcPromedio;
  final int registrosCfc;
  final int maduros;

  double? get porcentajeMadurez =>
      registrosCfc == 0 ? null : (maduros / registrosCfc) * 100;

  factory ResumenGrupo.fromJson(Map<String, dynamic>? pfc, Map<String, dynamic>? ppfm, Map<String, dynamic>? cfc) {
    return ResumenGrupo(
      lecturas: (pfc?['lecturas'] as num?)?.toInt() ?? 0,
      temperaturaPromedio: _numeroOpcional(pfc?['temperatura_promedio']),
      humedadPromedio: _numeroOpcional(pfc?['humedad_promedio']),
      phPromedio: _numeroOpcional(pfc?['ph_promedio']),
      temperaturaMaxima: _numeroOpcional(pfc?['temperatura_maxima']),
      precisionPromedio: _numeroOpcional(ppfm?['precision_promedio']),
      registrosPrecision: (ppfm?['registros'] as num?)?.toInt() ?? 0,
      puntajeCfcPromedio: _numeroOpcional(cfc?['puntaje_promedio']),
      registrosCfc: (cfc?['registros'] as num?)?.toInt() ?? 0,
      maduros: (cfc?['maduros'] as num?)?.toInt() ?? 0,
    );
  }
}
