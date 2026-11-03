import 'package:flutter_test/flutter_test.dart';
import 'package:compost_iot_mobile/main.dart';

void main() {
  testWidgets('Carga inicial de la app de monitoreo', (WidgetTester tester) async {
    // Renderizar la aplicación de compostaje
    await tester.pumpWidget(const CompostApp());

    // Verificar que encuentra el título principal en pantalla
    expect(find.text('Estado del Compostador'), findsOneWidget);
  });
}