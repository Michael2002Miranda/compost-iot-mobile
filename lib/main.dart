import 'package:flutter/material.dart';

import 'almacen.dart';
import 'app_state.dart';
import 'ui/home_shell.dart';
import 'ui/login_page.dart';
import 'ui/tema.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CompostApp());
}

class CompostApp extends StatefulWidget {
  const CompostApp({super.key});

  @override
  State<CompostApp> createState() => _CompostAppState();
}

class _CompostAppState extends State<CompostApp> with WidgetsBindingObserver {
  late final AppState _estado;

  @override
  void initState() {
    super.initState();
    _estado = AppState(AlmacenLocal());
    WidgetsBinding.instance.addObserver(this);
    _estado.iniciar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _estado.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _estado.reanudar();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _estado.pausar();
        break;
      case AppLifecycleState.hidden:
        _estado.pausar();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Compost IoT',
      debugShowCheckedModeBanner: false,
      theme: Tema.construir(),
      home: ListenableBuilder(
        listenable: _estado,
        builder: (context, _) {
          if (_estado.inicializando) {
            return const _PantallaCarga();
          }
          if (!_estado.haySesion) {
            return LoginPage(estado: _estado);
          }
          return HomeShell(estado: _estado);
        },
      ),
    );
  }
}

class _PantallaCarga extends StatelessWidget {
  const _PantallaCarga();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco, size: 56, color: Tema.verde),
            SizedBox(height: 16),
            Text(
              'Compost IoT',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Tema.verdeOscuro),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
          ],
        ),
      ),
    );
  }
}
