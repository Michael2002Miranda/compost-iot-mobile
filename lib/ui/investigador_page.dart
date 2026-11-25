import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api.dart';
import '../app_state.dart';
import '../modelos.dart';
import 'tema.dart';
import 'widgets.dart';

/// Panel del investigador: las composteras de todos los participantes.
class InvestigadorPage extends StatefulWidget {
  const InvestigadorPage({super.key, required this.estado});

  final AppState estado;

  @override
  State<InvestigadorPage> createState() => _InvestigadorPageState();
}

class _InvestigadorPageState extends State<InvestigadorPage> {
  String _filtro = 'todos';

  @override
  void initState() {
    super.initState();
    widget.estado.cargarEstudio();
  }

  int _entero(String clave) {
    final valor = widget.estado.resumenEstudio?[clave];
    return (valor as num?)?.toInt() ?? 0;
  }

  double? _promedioPpfm() {
    final ppfm = widget.estado.resumenEstudio?['ppfm'];
    if (ppfm is! Map) return null;
    return (ppfm['promedio'] as num?)?.toDouble();
  }

  int _maduros() {
    final cfc = widget.estado.resumenEstudio?['cfc'];
    if (cfc is! Map) return 0;
    return (cfc['maduros'] as num?)?.toInt() ?? 0;
  }

  int _totalCfc() {
    final cfc = widget.estado.resumenEstudio?['cfc'];
    if (cfc is! Map) return 0;
    return (cfc['total'] as num?)?.toInt() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.estado,
      builder: (context, _) {
        final estudio = widget.estado.estudio;
        final visibles = _filtro == 'todos'
            ? estudio
            : estudio.where((c) => c.grupo == _filtro).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Panel del investigador'),
            actions: [
              IconButton(
                tooltip: 'Actualizar',
                icon: const Icon(Icons.refresh),
                onPressed: () => widget.estado.cargarEstudio(),
              ),
              IconButton(
                tooltip: 'Descargar estudio (CSV)',
                icon: const Icon(Icons.ios_share),
                onPressed: _exportar,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => widget.estado.cargarEstudio(),
            child: widget.estado.cargandoEstudio && estudio.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    children: [
                      _resumen(),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _chip('todos', 'Todas (${estudio.length})'),
                          const SizedBox(width: 8),
                          _chip('GE', 'GE'),
                          const SizedBox(width: 8),
                          _chip('GC', 'GC'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (visibles.isEmpty)
                        const MensajeVacio(
                          icono: Icons.groups_outlined,
                          titulo: 'Sin composteras registradas',
                          mensaje: 'Cuando los participantes registren su compostera aparecerán aquí.',
                        )
                      else
                        ...visibles.map(_tarjeta),
                      const SizedBox(height: 18),
                      ..._fichas(),
                      const SizedBox(height: 18),
                      ..._evaluaciones(),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _exportar,
                        icon: const Icon(Icons.download),
                        label: const Text('Descargar estudio completo (CSV)'),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _chip(String valor, String texto) {
    return ChoiceChip(
      label: Text(texto),
      selected: _filtro == valor,
      onSelected: (_) => setState(() => _filtro = valor),
    );
  }

  Widget _resumen() {
    final ppfm = _promedioPpfm();
    final cfc = _totalCfc();

    return Column(
      children: [
        Row(
          children: [
            _dato('Participantes', '${_entero('usuarios')}', Icons.people_outline, Tema.verde),
            const SizedBox(width: 8),
            _dato('Composteras', '${widget.estado.estudio.length}', Icons.grass, const Color(0xFF6D4C41)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _dato('Lecturas', _compacto(widget.estado.estudio.fold<int>(0, (a, c) => a + c.lecturas)),
                Icons.show_chart, const Color(0xFF1565C0)),
            const SizedBox(width: 8),
            _dato('Alertas', '${_entero('alertas_pendientes')}', Icons.notifications_active_outlined,
                const Color(0xFFC62828)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _dato('Precisión prom.', ppfm == null ? '—' : '${ppfm.toStringAsFixed(1)} %', Icons.my_location,
                const Color(0xFF00695C)),
            const SizedBox(width: 8),
            _dato('Compost maduro', cfc == 0 ? '—' : '${_maduros()} / $cfc', Icons.compost,
                const Color(0xFF33691E)),
          ],
        ),
      ],
    );
  }

  Widget _dato(String titulo, String valor, IconData icono, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6ECE7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              valor,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
            ),
            Text(titulo, style: const TextStyle(fontSize: 10.5, color: Tema.textoSecundario)),
          ],
        ),
      ),
    );
  }

  String _compacto(int valor) {
    if (valor >= 10000) return '${(valor / 1000).toStringAsFixed(1)}k';
    return '$valor';
  }

  // --- Fichas del estudio ---------------------------------------------------
  List<Widget> _fichas() {
    final cfc = widget.estado.fichasCfc;
    final ppfm = widget.estado.fichasPpfm;
    final maduros = cfc.where((r) => r.maduro).length;
    final promedio = ppfm.isEmpty
        ? null
        : ppfm.map((r) => r.precision).reduce((a, b) => a + b) / ppfm.length;

    return [
      const SeccionTitulo(texto: 'Fichas del estudio'),
      _fichaCard(
        titulo: 'Calidad física del compost',
        detalle: '${cfc.length} registros · $maduros marcados como maduros',
        color: const Color(0xFF33691E),
        icono: Icons.compost,
        alExportar: () => _exportarFichas('cfc'),
        ejemplo: cfc.isEmpty
            ? null
            : '${cfc.first.compostera ?? 'Compostera'} · ${fechaCorta(cfc.first.fecha)} · '
                '${cfc.first.puntaje}/8',
      ),
      const SizedBox(height: 8),
      _fichaCard(
        titulo: 'Precisión de los parámetros',
        detalle: ppfm.isEmpty
            ? 'Sin registros todavía'
            : '${ppfm.length} registros · promedio ${promedio!.toStringAsFixed(2)} %',
        color: const Color(0xFF00695C),
        icono: Icons.my_location,
        alExportar: () => _exportarFichas('ppfm'),
        ejemplo: ppfm.isEmpty
            ? null
            : '${ppfm.first.compostera ?? 'Compostera'} · ${fechaCorta(ppfm.first.fecha)} · '
                '${ppfm.first.precision.toStringAsFixed(2)} %',
      ),
    ];
  }

  Widget _fichaCard({
    required String titulo,
    required String detalle,
    required Color color,
    required IconData icono,
    required VoidCallback alExportar,
    String? ejemplo,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECE7)),
      ),
      child: Row(
        children: [
          Icon(icono, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Tema.sans(13.5, peso: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(detalle, style: Tema.sans(11.5, color: Tema.tintaSuave)),
                if (ejemplo != null) ...[
                  const SizedBox(height: 2),
                  Text(ejemplo, style: Tema.sans(10.5, color: color)),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: alExportar,
            child: const Text('CSV', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // --- Evaluaciones ---------------------------------------------------------
  List<Widget> _evaluaciones() {
    final resumen = widget.estado.resumenEvaluaciones ?? const {};
    final sus = widget.estado.evaluacionesSus;
    final pruebas = widget.estado.pruebasFuncionalidad;
    final promedio = (resumen['promedio_sus'] as num?)?.toDouble();
    final aprobadas = (resumen['aprobadas'] as num?)?.toInt() ?? 0;
    final total = (resumen['pruebas'] as num?)?.toInt() ?? pruebas.length;

    return [
      const SeccionTitulo(texto: 'Evaluaciones'),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6ECE7)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _datoEvaluacion(
                    'Usabilidad (SUS)',
                    promedio == null ? '—' : promedio.toStringAsFixed(1),
                    '${sus.length} evaluaciones',
                  ),
                ),
                Expanded(
                  child: _datoEvaluacion(
                    'Funcionalidad',
                    '$aprobadas / $total',
                    'casos aprobados',
                  ),
                ),
              ],
            ),
            if (pruebas.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...pruebas.take(3).map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          p.aprobado ? Icons.check_circle : Icons.cancel,
                          size: 14,
                          color: p.aprobado ? Tema.verde : Tema.ladrillo,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            p.caso,
                            style: Tema.sans(11.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _datoEvaluacion(String titulo, String valor, String detalle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo.toUpperCase(),
          style: Tema.sans(9, color: Tema.tintaSuave, peso: FontWeight.w700, espaciado: 0.8),
        ),
        const SizedBox(height: 2),
        Text(valor, style: Tema.serif(24, color: Tema.olivaOscuro)),
        Text(detalle, style: Tema.sans(10.5, color: Tema.tintaSuave)),
      ],
    );
  }

  Future<void> _exportarFichas(String tipo) async {
    final mensajero = ScaffoldMessenger.of(context);
    try {
      final csv = await widget.estado.descargarFichasCsv(tipo);
      await Clipboard.setData(ClipboardData(text: csv));
      final filas = '\n'.allMatches(csv).length;
      mensajero.showSnackBar(
        SnackBar(content: Text('CSV de $tipo copiado ($filas filas).')),
      );
    } on ApiException catch (error) {
      mensajero.showSnackBar(SnackBar(content: Text(error.mensaje)));
    }
  }

  Widget _tarjeta(ComposteraEstudio c) {
    final color = c.grupo == 'GE' ? Tema.verde : const Color(0xFF6B7A6E);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECE7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                c.grupo,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.nombre,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    c.participante ?? 'Sin participante',
                    style: const TextStyle(fontSize: 11.5, color: Tema.textoSecundario),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        c.tieneEquipo ? Icons.sensors : Icons.sensors_off,
                        size: 12,
                        color: c.tieneEquipo ? Tema.verde : const Color(0xFFEF6C00),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${c.codigo ?? '—'} · ${c.lecturas} lecturas',
                        style: const TextStyle(fontSize: 10.5, color: Tema.textoSecundario),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (valor) => _accion(c, valor),
              itemBuilder: (contexto) => [
                if (c.grupo == 'GE')
                  const PopupMenuItem(value: 'GC', child: Text('Mover al grupo control (GC)'))
                else
                  const PopupMenuItem(value: 'GE', child: Text('Mover al grupo experimental (GE)')),
                const PopupMenuItem(value: 'detalle', child: Text('Ver detalle')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accion(ComposteraEstudio c, String accion) async {
    if (accion == 'detalle') {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: Tema.crema,
        builder: (contexto) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.nombre, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _linea('Participante', c.participante ?? '—'),
              _linea('Correo', c.email ?? '—'),
              _linea('Grupo', c.grupo),
              _linea('Código', c.codigo ?? '—'),
              _linea('Equipo', c.dispositivoId ?? 'sin vincular'),
              _linea('Lecturas', '${c.lecturas}'),
              _linea('Primera lectura', c.primeraLectura == null ? '—' : fechaHora(c.primeraLectura!)),
              _linea('Última lectura', c.ultimaLectura == null ? '—' : fechaHora(c.ultimaLectura!)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
      return;
    }

    final error = await widget.estado.cambiarGrupoEstudio(c.id, accion);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Compostera movida al grupo $accion')),
    );
  }

  Widget _linea(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(titulo, style: const TextStyle(fontSize: 12, color: Tema.textoSecundario)),
          ),
          Expanded(
            child: Text(valor, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportar() async {
    final mensajero = ScaffoldMessenger.of(context);
    mensajero.showSnackBar(
      const SnackBar(content: Text('Preparando el CSV del estudio...')),
    );

    try {
      final csv = await widget.estado.descargarCsvEstudio();
      await Clipboard.setData(ClipboardData(text: csv));
      final filas = '\n'.allMatches(csv).length;
      mensajero.showSnackBar(
        SnackBar(content: Text('CSV copiado ($filas filas). Pégalo en Excel o Google Sheets.')),
      );
    } on ApiException catch (error) {
      mensajero.showSnackBar(SnackBar(content: Text(error.mensaje)));
    }
  }
}
