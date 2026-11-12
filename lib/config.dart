/// Configuración de la aplicación.
///
/// La URL de la API se puede cambiar en tiempo de ejecución desde
/// «Más → Ajustes» (queda guardada en el dispositivo) o al compilar:
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
class AppConfig {
  static const String apiPorDefecto = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://compost-iot-backend.onrender.com',
  );

  /// Intervalo de actualización del panel cuando la app está en primer plano.
  static const Duration intervaloPolling = Duration(seconds: 5);

  static const String nombreApp = 'Compost IoT';
  static const String version = '2.0.0';
}
