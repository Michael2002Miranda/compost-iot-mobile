/// Persistencia local del dispositivo.
///
/// Guarda la sesión, la configuración y una copia de la última información
/// recibida para que la aplicación siga mostrando datos cuando no hay Internet
/// (por ejemplo, si Render está en arranque en frío o la vivienda perdió la red).
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AlmacenLocal {
  SharedPreferences? _prefs;

  static const _claveToken = 'token';
  static const _claveUsuario = 'usuario';
  static const _claveApi = 'api_base_url';
  static const _claveCompostera = 'compostera_activa';
  static const _claveUltima = 'cache_ultima';
  static const _claveComposteras = 'cache_composteras';
  static const _claveAlertas = 'cache_alertas';
  static const _claveSerie = 'cache_serie';
  static const _claveComparacion = 'cache_comparacion';
  static const _clavePpfmLocal = 'local_ppfm';
  static const _claveCfcLocal = 'local_cfc';

  Future<void> iniciar() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // Sin almacenamiento disponible la app funciona, pero no recuerda la sesión.
      _prefs = null;
    }
  }

  String? leer(String clave) => _prefs?.getString(clave);

  Future<void> escribir(String clave, String? valor) async {
    try {
      if (valor == null) {
        await _prefs?.remove(clave);
      } else {
        await _prefs?.setString(clave, valor);
      }
    } catch (_) {
      // Se ignora: el dato se mantiene en memoria durante la sesión.
    }
  }

  // --- Sesión -------------------------------------------------------------
  String? get token => leer(_claveToken);
  Future<void> guardarToken(String? token) => escribir(_claveToken, token);

  Map<String, dynamic>? get usuario {
    final texto = leer(_claveUsuario);
    if (texto == null) return null;
    try {
      return jsonDecode(texto) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> guardarUsuario(Map<String, dynamic>? datos) =>
      escribir(_claveUsuario, datos == null ? null : jsonEncode(datos));

  // --- Configuración ------------------------------------------------------
  String? get apiBaseUrl => leer(_claveApi);
  Future<void> guardarApiBaseUrl(String? url) => escribir(_claveApi, url);

  int? get composteraActivaId {
    final texto = leer(_claveCompostera);
    return texto == null ? null : int.tryParse(texto);
  }

  Future<void> guardarComposteraActiva(int? id) =>
      escribir(_claveCompostera, id?.toString());

  // --- Caché de datos -----------------------------------------------------
  Map<String, dynamic>? leerJson(String clave) {
    final texto = leer(clave);
    if (texto == null) return null;
    try {
      final decodificado = jsonDecode(texto);
      return decodificado is Map<String, dynamic> ? decodificado : null;
    } catch (_) {
      return null;
    }
  }

  List<dynamic> leerLista(String clave) {
    final texto = leer(clave);
    if (texto == null) return const [];
    try {
      final decodificado = jsonDecode(texto);
      return decodificado is List ? decodificado : const [];
    } catch (_) {
      return const [];
    }
  }

  Future<void> guardarJson(String clave, Object? valor) =>
      escribir(clave, valor == null ? null : jsonEncode(valor));

  Future<void> guardarCacheUltima(Map<String, dynamic>? json) => guardarJson(_claveUltima, json);
  Map<String, dynamic>? get cacheUltima => leerJson(_claveUltima);

  Future<void> guardarCacheComposteras(List<Map<String, dynamic>> lista) =>
      guardarJson(_claveComposteras, lista);
  List<dynamic> get cacheComposteras => leerLista(_claveComposteras);

  Future<void> guardarCacheAlertas(List<Map<String, dynamic>> lista) =>
      guardarJson(_claveAlertas, lista);
  List<dynamic> get cacheAlertas => leerLista(_claveAlertas);

  Future<void> guardarCacheSerie(List<Map<String, dynamic>> lista) =>
      guardarJson(_claveSerie, lista);
  List<dynamic> get cacheSerie => leerLista(_claveSerie);

  Future<void> guardarCacheComparacion(Map<String, dynamic>? json) =>
      guardarJson(_claveComparacion, json);
  Map<String, dynamic>? get cacheComparacion => leerJson(_claveComparacion);

  // --- Registros capturados en el dispositivo -----------------------------
  // Se guardan localmente y se sincronizan al servidor cuando hay conexión.
  List<dynamic> get registrosPpfmLocales => leerLista(_clavePpfmLocal);
  Future<void> guardarRegistrosPpfmLocales(List<dynamic> lista) =>
      guardarJson(_clavePpfmLocal, lista);

  List<dynamic> get registrosCfcLocales => leerLista(_claveCfcLocal);
  Future<void> guardarRegistrosCfcLocales(List<dynamic> lista) =>
      guardarJson(_claveCfcLocal, lista);

  // --- Limpieza -----------------------------------------------------------
  Future<void> limpiarSesion() async {
    await guardarToken(null);
    await guardarUsuario(null);
    await guardarComposteraActiva(null);
    await escribir(_claveUltima, null);
    await escribir(_claveComposteras, null);
    await escribir(_claveAlertas, null);
    await escribir(_claveSerie, null);
    await escribir(_claveComparacion, null);
  }
}
