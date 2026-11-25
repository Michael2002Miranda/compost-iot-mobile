import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'app_state.dart';

/// Inicializa Firebase. Si algo falla (por ejemplo, en la versión web sin
/// service worker) la aplicación sigue funcionando sin notificaciones.
Future<bool> iniciarFirebase() async {
  try {
    await Firebase.initializeApp();
    return true;
  } catch (error) {
    debugPrint('[firebase] no se pudo inicializar: $error');
    return false;
  }
}

/// Registro del teléfono para recibir notificaciones push.
///
/// El backend guarda este token y lo usa para avisar cuando una lectura genera
/// una alerta crítica, aunque la aplicación esté cerrada.
class Notificaciones {
  static bool _configurado = false;

  static Future<void> configurar(AppState estado) async {
    if (kIsWeb) {
      estado.notificacionesEstado = 'No disponible en la versión web';
      return;
    }
    if (_configurado) return;

    try {
      final mensajeria = FirebaseMessaging.instance;

      final permiso = await mensajeria.requestPermission(alert: true, badge: true, sound: true);
      if (permiso.authorizationStatus == AuthorizationStatus.denied) {
        estado.notificacionesEstado = 'Permiso denegado en el teléfono';
        estado.avisarCambio();
        return;
      }

      final token = await mensajeria.getToken();
      if (token == null || token.isEmpty) {
        estado.notificacionesEstado = 'El teléfono no entregó un token';
        estado.avisarCambio();
        return;
      }

      final guardado = await estado.registrarTokenPush(token);
      estado.notificacionesEstado = guardado ? 'Activas' : 'Token no enviado al servidor';
      estado.avisarCambio();

      mensajeria.onTokenRefresh.listen(estado.registrarTokenPush);
      _configurado = guardado;
    } catch (error) {
      debugPrint('[notificaciones] no se pudieron configurar: $error');
      estado.notificacionesEstado = 'Error: ${error.toString().split('\n').first}';
      estado.avisarCambio();
    }
  }
}
