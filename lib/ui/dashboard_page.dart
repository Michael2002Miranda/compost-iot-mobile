import 'package:flutter/material.dart';

import '../app_state.dart';
import '../clasificacion.dart';
import 'compostera_page.dart';
import 'tema.dart';
import 'widgets.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.estado,
    required this.onVerAlertas,
    required this.onVerRegistros,
  });

  final AppState estado;
  final VoidCallback onVerAlertas;
  final VoidCallback onVerRegistros;

  static const _iconos = {
    'temperatura': Icons.thermostat,
    'humedad': Icons.water_drop,
    'ph': Icons.science,
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Compost IoT Monitor'),
            actions: [
              IconButton(
                tooltip: 'Actualizar',
                icon: const Icon(Icons.refresh),
                onPressed: () => estado.refrescarPanel(),
              ),
              IconButton(
                tooltip: 'Mis composteras',
                icon: const Icon(Icons.layers_outlined),
                onPressed: () => _elegirCompostera(context),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => estado.cargarDatos(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                if (estado.sinConexion)
                  AvisoSinConexion(
                    texto: estado.actualizado == null
                        ? 'Sin conexión con el servidor. Se muestran los últimos datos guardados.'
                        : 'Sin conexión · última lectura ${haceCuanto(estado.actualizado!)}',
                  ),
                if (estado.activa == null)
                  _sinCompostera(context)
                else ...[
                  _tarjetaEstado(context),
                  const SizedBox(height: 12),
                  if (estado.alertasPendientes() > 0) ...[
                    _tarjetaAlertas(context),
                    const SizedBox(height: 12),
                  ],
                  if (estado.ultima?.phSimulado == true) ...[
                    const _AvisoPhSimulado(),
                    const SizedBox(height: 12),
                  ],
                  _parametros(context),
                  const SizedBox(height: 16),
                  _pie(context),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sinCompostera(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: MensajeVacio(
        icono: Icons.grass,
        titulo: 'Aún no tienes una compostera',
        mensaje: 'Registra tu compostera y vincula el dispositivo ESP32 para empezar a recibir mediciones.',
        accion: FilledButton.icon(
          onPressed: () => _abrirNuevaCompostera(context),
          icon: const Icon(Icons.add),
          label: const Text('Registrar compostera'),
        ),
      ),
    );
  }

  Widget _tarjetaEstado(BuildContext context) {
    final compostera = estado.activa!;
    final clasificacion = estado.clasificacion;
    final fase = clasificacion?.fase;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Tema.verde, Tema.verdeOscuro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Tema.verde.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado del Compostador',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      compostera.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (fase != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    fase.nombre,
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _dato('Día de proceso', '${estado.diasDeProceso}'),
              const SizedBox(width: 18),
              _dato('Grupo', compostera.grupo == 'GE' ? 'Experimental' : 'Control'),
              const SizedBox(width: 18),
              _dato(
                'Estado',
                clasificacion == null ? 'Sin datos' : clasificacion.estado.nombre,
              ),
            ],
          ),
          if (fase != null) ...[
            const SizedBox(height: 12),
            Text(
              fase.descripcion,
              style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dato(String titulo, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(color: Colors.white60, fontSize: 10.5)),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _tarjetaAlertas(BuildContext context) {
    final pendientes = estado.alertasPendientes();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onVerAlertas,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFCC80)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF6C00)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pendientes == 1
                      ? '1 alerta activa en tu compostera'
                      : '$pendientes alertas activas en tu compostera',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A4B00),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF8A4B00)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _parametros(BuildContext context) {
    final clasificacion = estado.clasificacion;

    if (estado.ultima == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: MensajeVacio(
          icono: Icons.sensors_off,
          titulo: 'Esperando la primera lectura',
          mensaje: estado.activa?.codigo == null
              ? 'Cuando el ESP32 envíe datos aparecerán aquí.'
              : 'Configura el ESP32 con el código ${estado.activa!.codigo} y verifica que esté conectado al WiFi.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SeccionTitulo(texto: 'Parámetros fisicoquímicos'),
        ...clasificacion!.parametros.map((p) {
          return TarjetaMetrica(
            icono: _iconos[p.parametro] ?? Icons.sensors,
            color: Tema.colorEstado(p.estado),
            titulo: p.nombre,
            valor: numero(p.valor),
            unidad: p.unidad,
            detalle: '${p.etiqueta} · rango ${p.rango} ${p.unidad}'.trim(),
            colorDetalle: Tema.colorEstado(p.estado),
            onTap: onVerRegistros,
          );
        }),
      ],
    );
  }

  Widget _pie(BuildContext context) {
    final actualizado = estado.actualizado;
    return Row(
      children: [
        Icon(
          estado.sinConexion ? Icons.cloud_off : Icons.cloud_done_outlined,
          size: 15,
          color: Tema.textoSecundario,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            actualizado == null
                ? 'Sin actualizaciones'
                : 'Actualizado ${haceCuanto(actualizado)} · se refresca cada 5 s',
            style: const TextStyle(fontSize: 11.5, color: Tema.textoSecundario),
          ),
        ),
      ],
    );
  }

  Future<void> _elegirCompostera(BuildContext context) async {
    final composteras = estado.composteras;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Tema.crema,
      builder: (contexto) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Mis composteras',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              ...composteras.map((c) {
                final activa = c.id == estado.activa?.id;
                return ListTile(
                  leading: Icon(
                    Icons.grass,
                    color: activa ? Tema.verde : Tema.textoSecundario,
                  ),
                  title: Text(c.nombre),
                  subtitle: Text('Grupo ${c.grupo} · ${c.lecturas} lecturas'),
                  trailing: activa ? const Icon(Icons.check_circle, color: Tema.verde) : null,
                  onTap: () {
                    Navigator.of(contexto).pop();
                    estado.seleccionarCompostera(c);
                  },
                );
              }),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Tema.verde),
                title: const Text('Registrar nueva compostera'),
                onTap: () {
                  Navigator.of(contexto).pop();
                  _abrirNuevaCompostera(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _abrirNuevaCompostera(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ComposteraPage(estado: estado)),
    );
  }
}

class _AvisoPhSimulado extends StatelessWidget {
  const _AvisoPhSimulado();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 17, color: Color(0xFF1565C0)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'El pH mostrado es simulado: el prototipo aún no cuenta con sensor de pH.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF0D47A1)),
            ),
          ),
        ],
      ),
    );
  }
}

