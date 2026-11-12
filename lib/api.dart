/// Cliente HTTP de la API de monitoreo.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'modelos.dart';

class ApiException implements Exception {
  ApiException(this.mensaje, {this.codigo});

  final String mensaje;
  final int? codigo;

  bool get esSinConexion => codigo == null;

  @override
  String toString() => mensaje;
}

class ApiCliente {
  ApiCliente({required this.baseUrl, this.token});

  String baseUrl;
  String? token;

  static const Duration _tiempoNormal = Duration(seconds: 30);
  static const Duration _tiempoArranque = Duration(seconds: 75);

  Uri _uri(String ruta, [Map<String, dynamic>? params]) {
    final limpia = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$limpia$ruta');
    if (params == null || params.isEmpty) return uri;
    return uri.replace(
      queryParameters: params.map((clave, valor) => MapEntry(clave, '$valor')),
    );
  }

  Map<String, String> get _cabeceras => {
        'Content-Type': 'application/json; charset=utf-8',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> _enviar(
    String metodo,
    String ruta, {
    Map<String, dynamic>? cuerpo,
    Map<String, dynamic>? params,
    Duration? tiempo,
  }) async {
    try {
      final uri = _uri(ruta, params);
      late http.Response respuesta;

      switch (metodo) {
        case 'GET':
          respuesta = await http.get(uri, headers: _cabeceras).timeout(tiempo ?? _tiempoNormal);
          break;
        case 'POST':
          respuesta = await http
              .post(uri, headers: _cabeceras, body: jsonEncode(cuerpo ?? {}))
              .timeout(tiempo ?? _tiempoNormal);
          break;
        case 'PATCH':
          respuesta = await http
              .patch(uri, headers: _cabeceras, body: jsonEncode(cuerpo ?? {}))
              .timeout(tiempo ?? _tiempoNormal);
          break;
        default:
          throw ApiException('Método no soportado: $metodo');
      }

      return _procesar(respuesta);
    } on TimeoutException {
      throw ApiException('El servidor tardó demasiado en responder. Intente de nuevo.');
    } on http.ClientException {
      throw ApiException('No se pudo conectar con el servidor. Revise su conexión a Internet.');
    } on FormatException {
      throw ApiException('El servidor devolvió una respuesta inesperada.');
    }
  }

  Map<String, dynamic> _procesar(http.Response respuesta) {
    final texto = utf8.decode(respuesta.bodyBytes);
    Map<String, dynamic> cuerpo = {};
    if (texto.isNotEmpty) {
      try {
        final decodificado = jsonDecode(texto);
        if (decodificado is Map<String, dynamic>) cuerpo = decodificado;
      } catch (_) {
        // Respuesta no JSON: se informa el código HTTP.
      }
    }

    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      return cuerpo;
    }

    var mensaje = cuerpo['mensaje']?.toString() ?? 'Error ${respuesta.statusCode}';
    final detalles = cuerpo['detalles'];
    if (detalles is List && detalles.isNotEmpty) {
      final campos = detalles
          .map((d) => d is Map ? '${d['campo']}: ${d['mensaje']}' : '$d')
          .join(' · ');
      mensaje = '$mensaje — $campos';
    }

    // 404 con `status: empty` no es un error de sesión: es "sin datos".
    if (respuesta.statusCode == 404 && cuerpo['status'] == 'empty') {
      throw ApiException('sin-datos', codigo: 404);
    }

    throw ApiException(mensaje, codigo: respuesta.statusCode);
  }

  // --- Cuentas ------------------------------------------------------------
  Future<({String token, Usuario usuario})> login(String email, String password) async {
    final cuerpo = await _enviar(
      'POST',
      '/api/auth/login',
      cuerpo: {'email': email, 'password': password},
      tiempo: _tiempoArranque,
    );
    return (
      token: '${cuerpo['token']}',
      usuario: Usuario.fromJson(cuerpo['usuario'] as Map<String, dynamic>? ?? {}),
    );
  }

  Future<({String token, Usuario usuario})> registrar(String nombre, String email, String password) async {
    final cuerpo = await _enviar(
      'POST',
      '/api/auth/registro',
      cuerpo: {'nombre': nombre, 'email': email, 'password': password},
      tiempo: _tiempoArranque,
    );
    return (
      token: '${cuerpo['token']}',
      usuario: Usuario.fromJson(cuerpo['usuario'] as Map<String, dynamic>? ?? {}),
    );
  }

  Future<Usuario> perfil() async {
    final cuerpo = await _enviar('GET', '/api/auth/perfil');
    return Usuario.fromJson(cuerpo['usuario'] as Map<String, dynamic>? ?? {});
  }

  // --- Composteras --------------------------------------------------------
  Future<List<Compostera>> composteras() async {
    final cuerpo = await _enviar('GET', '/api/composteras');
    final lista = (cuerpo['data'] as List?) ?? const [];
    return lista.map((e) => Compostera.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Compostera> crearCompostera({
    required String nombre,
    required String grupo,
    String? ubicacion,
  }) async {
    final cuerpo = await _enviar('POST', '/api/composteras', cuerpo: {
      'nombre': nombre,
      'grupo': grupo,
      if (ubicacion != null && ubicacion.isNotEmpty) 'ubicacion': ubicacion,
    });
    return Compostera.fromJson(cuerpo['data'] as Map<String, dynamic>? ?? {});
  }

  // --- Mediciones ---------------------------------------------------------
  Future<Medicion?> ultima({int? compostera}) async {
    try {
      final cuerpo = await _enviar('GET', '/api/mediciones/ultima',
          params: {if (compostera != null) 'compostera': compostera});
      return Medicion.fromJson(cuerpo['data'] as Map<String, dynamic>? ?? {});
    } on ApiException catch (error) {
      if (error.mensaje == 'sin-datos') return null;
      rethrow;
    }
  }

  Future<List<Medicion>> mediciones({
    int? compostera,
    DateTime? desde,
    DateTime? hasta,
    int limite = 200,
  }) async {
    final cuerpo = await _enviar('GET', '/api/mediciones', params: {
      'limit': limite,
      if (compostera != null) 'compostera': compostera,
      if (desde != null) 'desde': desde.toUtc().toIso8601String(),
      if (hasta != null) 'hasta': hasta.toUtc().toIso8601String(),
    });
    final lista = (cuerpo['data'] as List?) ?? const [];
    return lista.map((e) => Medicion.fromJson(e as Map<String, dynamic>)).toList();
  }

  // --- Alertas ------------------------------------------------------------
  Future<List<Alerta>> alertas({String estado = 'todas'}) async {
    final cuerpo = await _enviar('GET', '/api/alertas', params: {'estado': estado});
    final lista = (cuerpo['data'] as List?) ?? const [];
    return lista.map((e) => Alerta.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> marcarAlerta(int id, {bool atendida = true}) async {
    await _enviar('PATCH', '/api/alertas/$id', cuerpo: {'atendida': atendida});
  }

  // --- Indicadores --------------------------------------------------------
  Future<RegistroPpfm> crearPpfm({
    required int idCompostera,
    required String parametro,
    required double valorMedido,
    required double valorReferencia,
    String? observaciones,
  }) async {
    final cuerpo = await _enviar('POST', '/api/registros/ppfm', cuerpo: {
      'id_compostera': idCompostera,
      'parametro': parametro,
      'valor_medido': valorMedido,
      'valor_referencia': valorReferencia,
      if (observaciones != null && observaciones.isNotEmpty) 'observaciones': observaciones,
    });
    return RegistroPpfm.fromJson(cuerpo['data'] as Map<String, dynamic>? ?? {});
  }

  Future<List<RegistroPpfm>> listarPpfm({int? compostera}) async {
    final cuerpo = await _enviar('GET', '/api/registros/ppfm',
        params: {if (compostera != null) 'compostera': compostera});
    final lista = (cuerpo['data'] as List?) ?? const [];
    return lista.map((e) => RegistroPpfm.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RegistroCfc> crearCfc({
    required int idCompostera,
    required String color,
    required String aroma,
    required String textura,
    required String humedad,
    String? observaciones,
  }) async {
    final cuerpo = await _enviar('POST', '/api/registros/cfc', cuerpo: {
      'id_compostera': idCompostera,
      'color': color,
      'aroma': aroma,
      'textura': textura,
      'humedad': humedad,
      if (observaciones != null && observaciones.isNotEmpty) 'observaciones': observaciones,
    });
    return RegistroCfc.fromJson(cuerpo['data'] as Map<String, dynamic>? ?? {});
  }

  Future<List<RegistroCfc>> listarCfc({int? compostera}) async {
    final cuerpo = await _enviar('GET', '/api/registros/cfc',
        params: {if (compostera != null) 'compostera': compostera});
    final lista = (cuerpo['data'] as List?) ?? const [];
    return lista.map((e) => RegistroCfc.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<({ResumenGrupo gc, ResumenGrupo ge})> comparacion() async {
    final cuerpo = await _enviar('GET', '/api/comparacion');
    final grupos = (cuerpo['grupos'] as Map?) ?? const {};
    final gc = (grupos['GC'] as Map?) ?? const {};
    final ge = (grupos['GE'] as Map?) ?? const {};

    return (
      gc: ResumenGrupo.fromJson(
        (gc['pfc'] as Map?)?.cast<String, dynamic>(),
        (gc['ppfm'] as Map?)?.cast<String, dynamic>(),
        (gc['cfc'] as Map?)?.cast<String, dynamic>(),
      ),
      ge: ResumenGrupo.fromJson(
        (ge['pfc'] as Map?)?.cast<String, dynamic>(),
        (ge['ppfm'] as Map?)?.cast<String, dynamic>(),
        (ge['cfc'] as Map?)?.cast<String, dynamic>(),
      ),
    );
  }

  Future<Map<String, dynamic>> resumen() => _enviar('GET', '/api/resumen');

  // --- Usabilidad y funcionalidad ----------------------------------------
  Future<double> enviarSus(List<int> respuestas, {String? evaluador}) async {
    final cuerpo = await _enviar('POST', '/api/evaluaciones/sus', cuerpo: {
      'respuestas': respuestas,
      if (evaluador != null) 'evaluador': evaluador,
    });
    return (cuerpo['puntaje'] as num?)?.toDouble() ?? 0;
  }

  Future<void> registrarPrueba(String caso, {bool aprobado = true, String? observacion}) async {
    await _enviar('POST', '/api/pruebas/funcionalidad', cuerpo: {
      'caso': caso,
      'aprobado': aprobado,
      if (observacion != null) 'observacion': observacion,
    });
  }
}

