/// Estado global de la aplicación.
///
/// Mantiene la sesión, las composteras del usuario, la última lectura, el
/// historial y las alertas. Las pantallas se suscriben con `ListenableBuilder`.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'almacen.dart';
import 'api.dart';
import 'clasificacion.dart';
import 'config.dart';
import 'modelos.dart';

class AppState extends ChangeNotifier {
  AppState(this.almacen);

  final AlmacenLocal almacen;

  late ApiCliente api;

  // Sesión
  bool inicializando = true;
  Usuario? usuario;
  String? errorSesion;

  // Datos
  bool cargando = false;
  bool sinConexion = false;
  DateTime? actualizado;
  List<Compostera> composteras = [];
  Compostera? activa;
  Medicion? ultima;
  Clasificacion? clasificacion;
  List<Alerta> alertas = [];
  List<Medicion> serie = [];
  ResumenGrupo? grupoControl;
  ResumenGrupo? grupoExperimental;

  int alertasPendientes() => alertas.where((a) => !a.atendida).length;

  bool get haySesion => usuario != null;
  int get diasDeProceso {
    // Se cuenta desde la primera lectura; si aún no hay datos, desde el alta.
    final inicio = activa?.primeraLectura ?? activa?.creadaEn;
    if (inicio == null) return 1;
    final dias = DateTime.now().difference(inicio).inDays + 1;
    return dias < 1 ? 1 : dias;
  }

  Timer? _timer;
  bool _actualizando = false;
  bool _vivo = true;

  @override
  void dispose() {
    _vivo = false;
    _timer?.cancel();
    super.dispose();
  }

  void _avisar() {
    if (_vivo) notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Arranque
  // ---------------------------------------------------------------------------
  Future<void> iniciar() async {
    await almacen.iniciar();
    api = ApiCliente(
      baseUrl: almacen.apiBaseUrl ?? AppConfig.apiPorDefecto,
      token: almacen.token,
    );

    final guardado = almacen.usuario;
    if (guardado != null && api.token != null) {
      usuario = Usuario.fromJson(guardado);
      _cargarDesdeCache();
      inicializando = false;
      // Al reabrir la app con la sesión guardada también debe refrescarse sola.
      _iniciarPolling();
      _avisar();

      // Se valida la sesión en segundo plano; si no hay red se conserva la copia.
      try {
        usuario = await api.perfil();
        await almacen.guardarUsuario(usuario!.toJson());
        await cargarDatos(silencioso: true);
      } on ApiException catch (error) {
        if (error.codigo == 401) {
          await salir();
        } else {
          sinConexion = true;
          _avisar();
        }
      }
    } else {
      inicializando = false;
      _avisar();
    }
  }

  void _cargarDesdeCache() {
    final cacheUltima = almacen.cacheUltima;
    if (cacheUltima != null) {
      ultima = Medicion.fromJson(cacheUltima);
      clasificacion = clasificarMedicion(ultima!);
    }

    final cacheComposteras = almacen.cacheComposteras;
    if (cacheComposteras.isNotEmpty) {
      composteras = cacheComposteras
          .map((e) => Compostera.fromJson(e as Map<String, dynamic>))
          .toList();
      final idGuardado = almacen.composteraActivaId;
      activa = composteras.firstWhere(
        (c) => c.id == idGuardado,
        orElse: () => composteras.first,
      );
    }

    final cacheAlertas = almacen.cacheAlertas;
    if (cacheAlertas.isNotEmpty) {
      alertas = cacheAlertas.map((e) => Alerta.fromJson(e as Map<String, dynamic>)).toList();
    }

    final cacheSerie = almacen.cacheSerie;
    if (cacheSerie.isNotEmpty) {
      serie = cacheSerie.map((e) => Medicion.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  // ---------------------------------------------------------------------------
  // Sesión
  // ---------------------------------------------------------------------------
  Future<String?> entrar(String email, String password) async {
    errorSesion = null;
    try {
      final resultado = await api.login(email.trim(), password);
      api.token = resultado.token;
      usuario = resultado.usuario;
      await almacen.guardarToken(resultado.token);
      await almacen.guardarUsuario(resultado.usuario.toJson());
      await cargarDatos();
      _iniciarPolling();
      _avisar();
      return null;
    } on ApiException catch (error) {
      errorSesion = error.mensaje;
      _avisar();
      return error.mensaje;
    }
  }

  Future<String?> registrar(String nombre, String email, String password) async {
    errorSesion = null;
    try {
      final resultado = await api.registrar(nombre.trim(), email.trim(), password);
      api.token = resultado.token;
      usuario = resultado.usuario;
      await almacen.guardarToken(resultado.token);
      await almacen.guardarUsuario(resultado.usuario.toJson());
      await cargarDatos();
      _avisar();
      return null;
    } on ApiException catch (error) {
      errorSesion = error.mensaje;
      _avisar();
      return error.mensaje;
    }
  }

  Future<void> salir() async {
    _detenerPolling();
    api.token = null;
    usuario = null;
    composteras = [];
    activa = null;
    ultima = null;
    clasificacion = null;
    alertas = [];
    serie = [];
    sinConexion = false;
    await almacen.limpiarSesion();
    _avisar();
  }

  // ---------------------------------------------------------------------------
  // Carga de datos
  // ---------------------------------------------------------------------------
  Future<void> cargarDatos({bool silencioso = false}) async {
    if (usuario == null) return;
    if (!silencioso) {
      cargando = true;
      _avisar();
    }

    try {
      final lista = await api.composteras();
      composteras = lista;

      if (lista.isNotEmpty) {
        final idGuardado = almacen.composteraActivaId;
        activa = lista.firstWhere(
          (c) => c.id == idGuardado,
          orElse: () => lista.first,
        );
        await almacen.guardarComposteraActiva(activa!.id);
      }

      await _refrescarLectura();
      await _refrescarAlertas();
      await almacen.guardarCacheComposteras(lista.map((c) => c.toJson()).toList());

      sinConexion = false;
      actualizado = DateTime.now();
    } on ApiException catch (error) {
      if (error.codigo == 401) {
        await salir();
      } else {
        sinConexion = true;
        errorSesion = error.mensaje;
      }
    } finally {
      cargando = false;
      _avisar();
    }
  }

  Future<void> _refrescarLectura() async {
    if (activa == null) return;
    final lectura = await api.ultima(compostera: activa!.id);
    ultima = lectura;
    clasificacion = lectura == null ? null : clasificarMedicion(lectura);
    if (lectura != null) {
      await almacen.guardarCacheUltima(lectura.toJson());
    }
  }

  Future<void> _refrescarAlertas() async {
    alertas = await api.alertas();
    await almacen.guardarCacheAlertas(alertas.map((a) => a.toJson()).toList());
  }

  /// Actualización periódica del panel (cada 5 s) mientras la app está visible.
  Future<void> refrescarPanel() async {
    if (usuario == null || _actualizando) return;
    _actualizando = true;
    try {
      await _refrescarLectura();
      await _refrescarAlertas();
      sinConexion = false;
      actualizado = DateTime.now();
    } on ApiException catch (error) {
      if (error.codigo == 401) {
        await salir();
      } else {
        sinConexion = true;
      }
    } finally {
      _actualizando = false;
      _avisar();
    }
  }

  void _iniciarPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(AppConfig.intervaloPolling, (_) => refrescarPanel());
  }

  void _detenerPolling() {
    _timer?.cancel();
    _timer = null;
  }

  /// Se llama desde el ciclo de vida: al volver a primer plano se reanuda.
  void reanudar() {
    if (usuario != null) {
      refrescarPanel();
      _iniciarPolling();
    }
  }

  void pausar() => _detenerPolling();

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------
  Future<void> seleccionarCompostera(Compostera compostera) async {
    activa = compostera;
    ultima = null;
    clasificacion = null;
    serie = [];
    await almacen.guardarComposteraActiva(compostera.id);
    _avisar();
    await refrescarPanel();
  }

  Future<Compostera?> crearCompostera({
    required String nombre,
    required String grupo,
    String? ubicacion,
  }) async {
    try {
      final creada = await api.crearCompostera(
        nombre: nombre,
        grupo: grupo,
        ubicacion: ubicacion,
      );
      composteras = [...composteras, creada];
      activa = creada;
      await almacen.guardarComposteraActiva(creada.id);
      await almacen.guardarCacheComposteras(composteras.map((c) => c.toJson()).toList());
      _avisar();
      return creada;
    } on ApiException catch (error) {
      errorSesion = error.mensaje;
      _avisar();
      return null;
    }
  }

  Future<void> cargarHistorial({DateTime? desde, DateTime? hasta}) async {
    if (activa == null) return;
    try {
      serie = await api.mediciones(compostera: activa!.id, desde: desde, hasta: hasta, limite: 300);
      serie.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
      await almacen.guardarCacheSerie(serie.map((m) => m.toJson()).toList());
      _avisar();
    } on ApiException {
      final cache = almacen.cacheSerie;
      if (cache.isNotEmpty) {
        serie = cache.map((e) => Medicion.fromJson(e as Map<String, dynamic>)).toList();
        _avisar();
      }
    }
  }

  Future<void> atenderAlerta(Alerta alerta) async {
    try {
      await api.marcarAlerta(alerta.id);
      alertas = alertas
          .map((a) => a.id == alerta.id
              ? Alerta(
                  id: a.id,
                  parametro: a.parametro,
                  severidad: a.severidad,
                  mensaje: a.mensaje,
                  fechaHora: a.fechaHora,
                  valor: a.valor,
                  atendida: true,
                  compostera: a.compostera,
                )
              : a)
          .toList();
      _avisar();
    } on ApiException catch (error) {
      errorSesion = error.mensaje;
      _avisar();
    }
  }

  Future<String?> guardarPpfm({
    required String parametro,
    required double valorMedido,
    required double valorReferencia,
    String? observaciones,
  }) async {
    final idCompostera = activa?.id ?? 1;
    try {
      await api.crearPpfm(
        idCompostera: idCompostera,
        parametro: parametro,
        valorMedido: valorMedido,
        valorReferencia: valorReferencia,
        observaciones: observaciones,
      );
      return null;
    } on ApiException catch (error) {
      // Sin conexión el registro queda guardado en el dispositivo.
      final locales = almacen.registrosPpfmLocales.toList();
      locales.add(RegistroPpfm(
        parametro: parametro,
        valorMedido: valorMedido,
        valorReferencia: valorReferencia,
        precision: calcularPrecision(valorMedido, valorReferencia),
        fecha: DateTime.now(),
        idCompostera: idCompostera,
        observaciones: observaciones,
      ).toJson());
      await almacen.guardarRegistrosPpfmLocales(locales);
      return error.mensaje;
    }
  }

  Future<String?> guardarCfc({
    required String color,
    required String aroma,
    required String textura,
    required String humedad,
    String? observaciones,
  }) async {
    final idCompostera = activa?.id ?? 1;
    final puntaje = puntajeCfc(color: color, aroma: aroma, textura: textura, humedad: humedad);

    try {
      await api.crearCfc(
        idCompostera: idCompostera,
        color: color,
        aroma: aroma,
        textura: textura,
        humedad: humedad,
        observaciones: observaciones,
      );
      return null;
    } on ApiException catch (error) {
      final locales = almacen.registrosCfcLocales.toList();
      locales.add(RegistroCfc(
        color: color,
        aroma: aroma,
        textura: textura,
        humedad: humedad,
        puntaje: puntaje,
        maduro: esCompostMaduro(puntaje),
        fecha: DateTime.now(),
        idCompostera: idCompostera,
        observaciones: observaciones,
      ).toJson());
      await almacen.guardarRegistrosCfcLocales(locales);
      return error.mensaje;
    }
  }

  Future<void> cargarComparacion() async {
    try {
      final resultado = await api.comparacion();
      grupoControl = resultado.gc;
      grupoExperimental = resultado.ge;
      await almacen.guardarCacheComparacion({
        'gc': _grupoAJson(resultado.gc),
        'ge': _grupoAJson(resultado.ge),
      });
      _avisar();
    } on ApiException {
      final cache = almacen.cacheComparacion;
      if (cache != null) {
        grupoControl = ResumenGrupo.fromJson(
          (cache['gc'] as Map?)?.cast<String, dynamic>(),
          (cache['gc'] as Map?)?.cast<String, dynamic>(),
          (cache['gc'] as Map?)?.cast<String, dynamic>(),
        );
        _avisar();
      }
    }
  }

  Map<String, dynamic> _grupoAJson(ResumenGrupo grupo) => {
        'lecturas': grupo.lecturas,
        'temperatura_promedio': grupo.temperaturaPromedio,
        'humedad_promedio': grupo.humedadPromedio,
        'ph_promedio': grupo.phPromedio,
        'temperatura_maxima': grupo.temperaturaMaxima,
        'precision_promedio': grupo.precisionPromedio,
        'registros': grupo.registrosPrecision,
        'puntaje_promedio': grupo.puntajeCfcPromedio,
        'maduros': grupo.maduros,
      };

  Future<double?> enviarSus(List<int> respuestas) async {
    try {
      return await api.enviarSus(respuestas);
    } on ApiException {
      return null;
    }
  }

  Future<String?> cambiarApi(String url) async {
    final limpia = url.trim();
    if (limpia.isEmpty || !limpia.startsWith('http')) {
      return 'Ingrese una URL válida (debe iniciar con http:// o https://)';
    }
    api.baseUrl = limpia;
    await almacen.guardarApiBaseUrl(limpia);
    await cargarDatos();
    return null;
  }
}
