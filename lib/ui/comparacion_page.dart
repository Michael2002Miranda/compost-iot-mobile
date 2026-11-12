import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../modelos.dart';
import 'tema.dart';
import 'widgets.dart';

/// Comparación de la posprueba entre el grupo control (GC) y el experimental (GE).
class ComparacionPage extends StatefulWidget {
  const ComparacionPage({super.key, required this.estado});

  final AppState estado;

  @override
  State<ComparacionPage> createState() => _ComparacionPageState();
}

class _ComparacionPageState extends State<ComparacionPage> {
  @override
  void initState() {
    super.initState();
    widget.estado.cargarComparacion();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.estado,
      builder: (context, _) {
        final gc = widget.estado.grupoControl ?? const ResumenGrupo();
        final ge = widget.estado.grupoExperimental ?? const ResumenGrupo();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Comparación GC / GE'),
            actions: [
              IconButton(
                tooltip: 'Exportar comparación',
                icon: const Icon(Icons.ios_share),
                onPressed: () => _exportar(gc, ge),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              const Text(
                'Promedios de la posprueba por grupo. Estos valores alimentan la '
                'contrastación de las hipótesis específicas.',
                style: TextStyle(fontSize: 12.5, color: Tema.textoSecundario, height: 1.4),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _resumen('GC', 'Grupo control', gc, const Color(0xFF6B7A6E))),
                  const SizedBox(width: 10),
                  Expanded(child: _resumen('GE', 'Experimental', ge, Tema.verde)),
                ],
              ),
              const SizedBox(height: 18),
              const SeccionTitulo(texto: 'Detalle por indicador'),
              _tabla(gc, ge),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _exportar(gc, ge),
                icon: const Icon(Icons.download),
                label: const Text('Exportar comparación (CSV)'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _resumen(String codigo, String nombre, ResumenGrupo grupo, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  codigo,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nombre,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${grupo.lecturas}',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color),
          ),
          const Text('lecturas registradas', style: TextStyle(fontSize: 10.5, color: Tema.textoSecundario)),
          const SizedBox(height: 8),
          Text(
            'Temperatura: ${_v(grupo.temperaturaPromedio, '°C')}',
            style: const TextStyle(fontSize: 11.5),
          ),
          Text(
            'Humedad: ${_v(grupo.humedadPromedio, '%')}',
            style: const TextStyle(fontSize: 11.5),
          ),
          Text(
            'pH: ${_v(grupo.phPromedio, '')}',
            style: const TextStyle(fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _tabla(ResumenGrupo gc, ResumenGrupo ge) {
    final filas = <(String, String, String)>[
      ('Lecturas', '${gc.lecturas}', '${ge.lecturas}'),
      ('Temperatura promedio', _v(gc.temperaturaPromedio, '°C'), _v(ge.temperaturaPromedio, '°C')),
      ('Temperatura máxima', _v(gc.temperaturaMaxima, '°C'), _v(ge.temperaturaMaxima, '°C')),
      ('Humedad promedio', _v(gc.humedadPromedio, '%'), _v(ge.humedadPromedio, '%')),
      ('pH promedio', _v(gc.phPromedio, ''), _v(ge.phPromedio, '')),
      ('Precisión promedio (PPFM)', _v(gc.precisionPromedio, '%'), _v(ge.precisionPromedio, '%')),
      ('Puntaje CFC promedio', _v(gc.puntajeCfcPromedio, '/8'), _v(ge.puntajeCfcPromedio, '/8')),
      ('Compost maduro', _madurez(gc), _madurez(ge)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECE7)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Tema.verdeClaro,
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 5, child: Text('Indicador', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                Expanded(flex: 3, child: Text('GC', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                Expanded(flex: 3, child: Text('GE', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          ...filas.asMap().entries.map((entrada) {
            final (titulo, gcValor, geValor) = entrada.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: const Color(0xFFEDF2EE), width: entrada.key == 0 ? 0 : 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(flex: 5, child: Text(titulo, style: const TextStyle(fontSize: 12))),
                  Expanded(
                    flex: 3,
                    child: Text(gcValor,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(geValor,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Tema.verdeOscuro)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _v(double? valor, String unidad) =>
      valor == null ? '—' : '${numero(valor, decimales: 2)} $unidad'.trim();

  String _madurez(ResumenGrupo grupo) {
    if (grupo.registrosCfc == 0) return '—';
    final porcentaje = grupo.porcentajeMadurez ?? 0;
    return '${grupo.maduros}/${grupo.registrosCfc} (${porcentaje.toStringAsFixed(0)} %)';
  }

  Future<void> _exportar(ResumenGrupo gc, ResumenGrupo ge) async {
    final lineas = <String>[
      'grupo,lecturas,temperatura_promedio,temperatura_maxima,humedad_promedio,ph_promedio,precision_promedio,puntaje_cfc_promedio,registros_cfc,maduros',
      [
        'GC',
        '${gc.lecturas}',
        gc.temperaturaPromedio ?? '',
        gc.temperaturaMaxima ?? '',
        gc.humedadPromedio ?? '',
        gc.phPromedio ?? '',
        gc.precisionPromedio ?? '',
        gc.puntajeCfcPromedio ?? '',
        '${gc.registrosCfc}',
        '${gc.maduros}',
      ].join(','),
      [
        'GE',
        '${ge.lecturas}',
        ge.temperaturaPromedio ?? '',
        ge.temperaturaMaxima ?? '',
        ge.humedadPromedio ?? '',
        ge.phPromedio ?? '',
        ge.precisionPromedio ?? '',
        ge.puntajeCfcPromedio ?? '',
        '${ge.registrosCfc}',
        '${ge.maduros}',
      ].join(','),
    ];
    final csv = lineas.join('\r\n');

    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comparación copiada al portapapeles en formato CSV.')),
    );
  }
}
