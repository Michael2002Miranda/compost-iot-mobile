import 'package:flutter/material.dart';

import '../app_state.dart';
import '../modelos.dart';
import 'tema.dart';
import 'widgets.dart';

class AlertasPage extends StatefulWidget {
  const AlertasPage({super.key, required this.estado});

  final AppState estado;

  @override
  State<AlertasPage> createState() => _AlertasPageState();
}

class _AlertasPageState extends State<AlertasPage> {
  bool _soloPendientes = false;

  static const _iconos = {
    'temperatura': Icons.thermostat,
    'humedad': Icons.water_drop,
    'ph': Icons.science,
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.estado,
      builder: (context, _) {
        final todas = widget.estado.alertas;
        final lista = _soloPendientes ? todas.where((a) => !a.atendida).toList() : todas;
        final pendientes = todas.where((a) => !a.atendida).length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Alertas'),
            actions: [
              IconButton(
                tooltip: 'Actualizar',
                icon: const Icon(Icons.refresh),
                onPressed: () => widget.estado.refrescarPanel(),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('Todas (${todas.length})'),
                      selected: !_soloPendientes,
                      onSelected: (_) => setState(() => _soloPendientes = false),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Pendientes ($pendientes)'),
                      selected: _soloPendientes,
                      onSelected: (_) => setState(() => _soloPendientes = true),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => widget.estado.refrescarPanel(),
                  child: lista.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 60),
                            MensajeVacio(
                              icono: Icons.check_circle_outline,
                              titulo: 'Sin alertas',
                              mensaje: 'Los parámetros se mantienen dentro de los rangos establecidos.',
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: lista.length,
                          itemBuilder: (context, indice) => _tarjeta(lista[indice]),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tarjeta(Alerta alerta) {
    final color = Tema.colorSeveridad(alerta.severidad);
    final valor = alerta.valor;
    final unidad = alerta.parametro == 'ph' ? '' : (alerta.parametro == 'temperatura' ? '°C' : '%');

    return Opacity(
      opacity: alerta.atendida ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_iconos[alerta.parametro] ?? Icons.warning, size: 18, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      alerta.parametro == 'temperatura'
                          ? 'Temperatura ${valor == null ? '' : (valor > 65 ? 'alta' : 'fuera de rango')}'
                          : '${_titulo(alerta.parametro)} fuera de rango',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: color),
                    ),
                  ),
                  if (valor != null)
                    Text(
                      '${numero(valor)} $unidad'.trim(),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                alerta.mensaje,
                style: const TextStyle(fontSize: 12.5, height: 1.35),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    fechaHora(alerta.fechaHora),
                    style: const TextStyle(fontSize: 11, color: Tema.textoSecundario),
                  ),
                  const Spacer(),
                  if (alerta.atendida)
                    const Text(
                      'Atendida',
                      style: TextStyle(fontSize: 11.5, color: Tema.textoSecundario),
                    )
                  else
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => widget.estado.atenderAlerta(alerta),
                      child: const Text('Marcar atendida', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _titulo(String parametro) {
    switch (parametro) {
      case 'temperatura':
        return 'Temperatura';
      case 'humedad':
        return 'Humedad';
      default:
        return 'pH';
    }
  }
}
