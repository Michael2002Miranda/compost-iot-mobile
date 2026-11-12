import 'package:flutter/material.dart';

import '../app_state.dart';
import 'alertas_page.dart';
import 'dashboard_page.dart';
import 'historial_page.dart';
import 'mas_page.dart';
import 'registros_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.estado});

  final AppState estado;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _indice = 0;

  void _cambiar(int indice) {
    setState(() => _indice = indice);
    if (indice == 1) {
      widget.estado.cargarHistorial();
    }
    if (indice == 2) {
      widget.estado.refrescarPanel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = widget.estado.alertasPendientes();

    return Scaffold(
      body: IndexedStack(
        index: _indice,
        children: [
          DashboardPage(
            estado: widget.estado,
            onVerAlertas: () => _cambiar(2),
            onVerRegistros: () => _cambiar(3),
          ),
          HistorialPage(estado: widget.estado),
          AlertasPage(estado: widget.estado),
          RegistrosPage(estado: widget.estado),
          MasPage(estado: widget.estado),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: _cambiar,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendientes > 0,
              label: Text('$pendientes'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pendientes > 0,
              label: Text('$pendientes'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Alertas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Registros',
          ),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'Más',
          ),
        ],
      ),
    );
  }
}
