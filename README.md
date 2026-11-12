# Compost IoT · Aplicación móvil

Aplicación Flutter para monitorear el proceso de compostaje en El Porvenir (2026).
Consume la API del backend, clasifica los parámetros fisicoquímicos (PFC), muestra
alertas, registra la precisión frente al instrumento patrón (PPFM) y la calidad
física del compost (CFC), y exporta los datos para el análisis estadístico.

---

## 1. Ejecutar

```bash
flutter pub get
flutter run                                   # dispositivo o emulador
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
flutter build apk --release                   # APK para el teléfono
flutter build web                             # versión web (demostración)
```

La URL del backend también se puede cambiar desde **Más → Servidor de la API**
sin recompilar.

### Servidor por defecto

`https://compost-iot-backend.onrender.com`

> La capa gratuita de Render suspende la instancia tras 15 minutos de inactividad.
> La primera petición del día puede tardar hasta 60 s. La app espera 75 s en el
> inicio de sesión; si falla, se puede reintentar.

---

## 2. Funcionalidades

| Pantalla | Contenido |
|---|---|
| **Inicio de sesión / registro** | Cuenta por correo y contraseña; la sesión queda guardada |
| **Inicio** | Estado de la compostera, fase del proceso, día de proceso y los tres parámetros con su rango |
| **Historial** | Gráfico por parámetro (24 h / 7 / 30 días), mínimo, promedio y máximo, exportación CSV |
| **Alertas** | Alertas con severidad, acción recomendada y marca de atendida |
| **Registros** | Fichas CFC y PPFM, y comparación de la posprueba GC vs GE |
| **Más** | Composteras, código del dispositivo, usabilidad (SUS), funcionalidad, servidor, sesión |

### Sin conexión

La app guarda la última lectura, el historial y las alertas en el teléfono. Si no hay
red, muestra esos datos con un aviso y los registros de CFC/PPFM quedan guardados en
el dispositivo.

---

## 3. Arquitectura

```
lib/
  main.dart                    arranque, tema y ciclo de vida
  config.dart                  URL de la API e intervalo de refresco
  modelos.dart                 Usuario, Compostera, Medicion, Alerta, registros
  clasificacion.dart           PFC, PPFM, CFC y puntaje SUS (misma regla que el backend)
  api.dart                     cliente HTTP con manejo de errores tipado
  almacen.dart                 persistencia local (shared_preferences)
  app_state.dart               estado global (ChangeNotifier) y polling cada 5 s
  ui/                          pantallas y widgets
    tema.dart                  paleta y estilos
    widgets.dart               tarjetas, chips y estados vacíos
    grafico.dart               gráfico de líneas con CustomPainter (sin dependencias)
```

- **Estado:** `ChangeNotifier` + `ListenableBuilder` (sin gestores externos).
- **Gráficos:** `CustomPainter`, sin paquetes adicionales.
- **Pruebas:** 11 (`flutter test`), incluidas las reglas de clasificación y precisión.

---

## 4. Permisos de Android

`android/app/src/main/AndroidManifest.xml` declara `INTERNET`. Sin ese permiso la app
funciona con `flutter run` (que usa el manifiesto de depuración) pero **no** en el APK
de release.

`usesCleartextTraffic="true"` está habilitado para poder apuntar a un servidor local
por HTTP durante las pruebas de campo.

### Nota sobre dependencias nativas

`shared_preferences` está fijado con `dependency_overrides` a
`shared_preferences_android: 2.4.0` porque la versión 2.5.x incorpora el paquete
`jni`, que compila código nativo con CMake y hace fallar la compilación en equipos
sin NDK. Con esta versión **no se necesita NDK** para generar el APK.

Si en el futuro se actualiza ese plugin, hará falta instalar el NDK:

```powershell
$sdk = "$env:LOCALAPPDATA\Android\sdk"
& "$sdk\cmdline-tools\latest\bin\sdkmanager.bat" --sdk_root="$sdk" --install "ndk;28.2.13676358" "cmake;3.22.1"
```



---

## 5. Flujo completo

1. La persona crea su cuenta.
2. Registra su compostera y elige el grupo del estudio (GE con la app, GC sin la app).
3. La app muestra el **código del dispositivo** (`CMP-XXXX`).
4. Ese código se graba en el firmware del ESP32 (`CODIGO_DISPOSITIVO`).
5. El ESP32 se conecta al WiFi de la vivienda y envía una lectura cada 5 s a la nube.
6. El backend guarda la lectura, la clasifica y genera alertas.
7. La app (en cualquier lugar con Internet) consulta la nube cada 5 s y muestra el estado.

El teléfono **no** necesita estar en la misma red que el ESP32: ambos hablan con el
servidor en Internet.
