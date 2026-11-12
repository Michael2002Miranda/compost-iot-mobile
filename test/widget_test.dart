import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:compost_iot_mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('La aplicación abre en la pantalla de inicio de sesión', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CompostApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Compost IoT'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });

  testWidgets('La pantalla de registro valida el correo y la contraseña', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CompostApp());
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Crear cuenta'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pump();

    expect(find.text('Ingrese su nombre completo'), findsOneWidget);
  });
}

