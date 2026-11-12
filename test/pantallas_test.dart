import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:compost_iot_mobile/almacen.dart';
import 'package:compost_iot_mobile/app_state.dart';
import 'package:compost_iot_mobile/clasificacion.dart';
import 'package:compost_iot_mobile/modelos.dart';
import 'package:compost_iot_mobile/ui/cfc_page.dart';
import 'package:compost_iot_mobile/ui/dashboard_page.dart';
import 'package:compost_iot_mobile/ui/tema.dart';

/// Estado de ejemplo: usuario con una compostera y una lectura en fase termófila.
Future<AppState> estadoDeEjemplo() async {
  SharedPreferences.setMockInitialValues({});
  final estado = AppState(AlmacenLocal());
  await estado.almacen.iniciar();

  final compostera = Compostera(
    id: 1,
    nombre: 'Compostera del patio',
    grupo: 'GE',
    codigo: 'CMP-1234',
    creadaEn: DateTime.now().subtract(const Duration(days: 5)),
  );

  estado.usuario = const Usuario(id: 1, nombre: 'Ana Torres', email: 'ana@upao.edu.pe');
  estado.composteras = [compostera];
  estado.activa = compostera;

  final lectura = Medicion(
    id: 10,
    idCompostera: 1,
    temperatura: 52.3,
    humedad: 61,
    ph: 7.1,
    fechaHora: DateTime.now().subtract(const Duration(seconds: 20)),
  );
  estado.ultima = lectura;
  estado.clasificacion = clasificarMedicion(lectura);
  estado.actualizado = DateTime.now();

  return estado;
}

Widget envolver(Widget hijo) => MaterialApp(theme: Tema.construir(), home: hijo);

/// Pantalla de teléfono para que las listas largas se rendericen completas.
void pantallaDeTelefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('El panel muestra la fase, los tres parámetros y el día de proceso', (tester) async {
    pantallaDeTelefono(tester);
    final estado = await estadoDeEjemplo();

    await tester.pumpWidget(envolver(DashboardPage(
      estado: estado,
      onVerAlertas: () {},
      onVerRegistros: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('Estado del Compostador'), findsOneWidget);
    expect(find.text('Compostera del patio'), findsOneWidget);
    expect(find.text('Fase termófila'), findsOneWidget);
    expect(find.text('Temperatura'), findsOneWidget);
    expect(find.text('Humedad'), findsOneWidget);
    expect(find.text('pH'), findsOneWidget);
    // El valor se dibuja con Text.rich (número + unidad).
    expect(find.textContaining('52.3', findRichText: true), findsOneWidget);
    expect(find.text('Día de proceso'), findsOneWidget);
    expect(find.text('Experimental'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('El panel invita a registrar una compostera cuando no hay ninguna', (tester) async {
    pantallaDeTelefono(tester);
    SharedPreferences.setMockInitialValues({});
    final estado = AppState(AlmacenLocal());
    await estado.almacen.iniciar();
    estado.usuario = const Usuario(id: 1, nombre: 'Ana', email: 'ana@upao.edu.pe');

    await tester.pumpWidget(envolver(DashboardPage(
      estado: estado,
      onVerAlertas: () {},
      onVerRegistros: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes una compostera'), findsOneWidget);
    expect(find.text('Registrar compostera'), findsOneWidget);
  });

  testWidgets('La ficha CFC calcula el puntaje al completar los criterios', (tester) async {
    pantallaDeTelefono(tester);
    final estado = await estadoDeEjemplo();

    await tester.pumpWidget(envolver(CfcPage(estado: estado)));
    await tester.pumpAndSettle();

    expect(find.text('Color'), findsOneWidget);
    expect(find.text('Complete los cuatro criterios'), findsOneWidget);

    await tester.tap(find.text('Marrón oscuro'));
    await tester.pump();
    await tester.tap(find.text('Tierra húmeda'));
    await tester.pump();
    await tester.tap(find.text('Suelta y granulada'));
    await tester.pump();
    await tester.tap(find.text('Humedece sin gotear'));
    await tester.pumpAndSettle();

    expect(find.text('Cumple los criterios de madurez'), findsOneWidget);
    expect(find.text('Puntaje 8 / 8 · se considera maduro con 7 u 8 puntos'), findsOneWidget);
  });
}
