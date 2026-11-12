import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../clasificacion.dart';
import '../modelos.dart';
import 'grafico.dart';
import 'tema.dart';
import 'widgets.dart';

class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key, required this.estado});

  final AppState estado;

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  String _parametro = 'temperatura';
  int _dias = 1;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    await widget.estado.cargarHistorial(
      desde: DateTime.now().subtract(Duration(days: _dias)),
    );
    if (mounted) setState(() => _cargando = false);
  }

  double _valor(Medicion m) {
    switch (_parametro) {
      case 'temperatura':
        return m.temperatura;
      case 'humedad':
        return m.humedad;
      default:
        return m.ph;
    }
  }

  Color get _color {
    switch (_parametro) {
      case 'temperatura':
        return const Color(0xFFEF6C00);
      case 'humedad':
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFF7B1FA2);
    }
  }

  String get _unidad => _parametro == 'temperatura' ? '°C' : (_parametro == 'humedad' ? '%' : '');

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.estado,
      builder: (context, _) {
        final serie = widget.estado.serie;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Historial'),
            actions: [
              IconButton(
                tooltip: 'Exportar CSV',
                icon: const Icon(Icons.ios_share),
                onPressed: serie.isEmpty ? null : _exportar,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _cargar,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'temperatura', label: Text('Temperatura')),
                    ButtonSegment(value: 'humedad', label: Text('Humedad')),
                    ButtonSegment(value: 'ph', label: Text('pH')),
                  ],
                  selected: {_parametro},
                  onSelectionChanged: (seleccion) {
                    setState(() => _parametro = seleccion.first);
                  },
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [1, 7, 30]
                      .map((dias) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(dias == 1 ? '24 h' : '$dias días'),
                              selected: _dias == dias,
                              onSelected: (_) {
                                setState(() => _dias = dias);
                                _cargar();
                              },
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              Icon(Icons.show_chart, size: 18, color: _color),
                              const SizedBox(width: 6),
                              Text(
                                _tituloParametro,
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              if (_cargando)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        GraficoLinea(datos: serie, parametro: _parametro, color: _color),
                        const SizedBox(height: 6),
                        const Text(
                          'La banda verde indica el rango óptimo definido en el informe.',
                          style: TextStyle(fontSize: 10.5, color: Tema.textoSecundario),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (serie.isNotEmpty) _estadisticas(serie),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: serie.isEmpty ? null : _exportar,
                  icon: const Icon(Icons.download),
                  label: const Text('Exportar CSV para el análisis'),
                ),
                const SizedBox(height: 8),
                Text(
                  serie.isEmpty
                      ? 'Aún no hay registros en este período.'
                      : '${serie.length} lecturas · desde ${fechaCorta(serie.first.fechaHora)} hasta ${fechaCorta(serie.last.fechaHora)}',
                  style: const TextStyle(fontSize: 11.5, color: Tema.textoSecundario),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String get _tituloParametro {
    switch (_parametro) {
      case 'temperatura':
        return 'Temperatura (°C)';
      case 'humedad':
        return 'Humedad (%)';
      default:
        return 'pH';
    }
  }

  Widget _estadisticas(List<Medicion> serie) {
    final valores = serie.map(_valor).toList();
    final minimo = valores.reduce((a, b) => a < b ? a : b);
    final maximo = valores.reduce((a, b) => a > b ? a : b);
    final promedio = valores.reduce((a, b) => a + b) / valores.length;

    Widget dato(String titulo, String valor) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6ECE7)),
          ),
          child: Column(
            children: [
              Text(
                titulo,
                style: const TextStyle(fontSize: 11, color: Tema.textoSecundario),
              ),
              const SizedBox(height: 3),
              Text(
                valor,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _color),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        dato('Mínimo', '${numero(minimo)} $_unidad'.trim()),
        dato('Promedio', '${numero(promedio)} $_unidad'.trim()),
        dato('Máximo', '${numero(maximo)} $_unidad'.trim()),
      ],
    );
  }

  Future<void> _exportar() async {
    final serie = widget.estado.serie;
    if (serie.isEmpty) return;

    final lineas = <String>['fecha,temperatura,humedad,ph,grupo'];
    for (final m in serie) {
      lineas.add([
        m.fechaHora.toIso8601String(),
        m.temperatura.toStringAsFixed(2),
        m.humedad.toStringAsFixed(2),
        m.ph.toStringAsFixed(2),
        m.grupo ?? widget.estado.activa?.grupo ?? '',
      ].join(','));
    }
    final csv = lineas.join('\r\n');

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Exportar datos'),
        content: SizedBox(
          width: double.maxFinite,
          height: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${serie.length} lecturas listas para el análisis estadístico.',
                style: const TextStyle(fontSize: 12.5, color: Tema.textoSecundario),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6F3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      csv,
                      style: const TextStyle(fontSize: 9.5, fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (contexto.mounted) Navigator.of(contexto).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('CSV copiado. Pégalo en Excel o Google Sheets.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copiar CSV'),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta del parámetro usada también en las alertas.
String nombreParametro(String parametro) => definiciones[parametro]?.etiqueta ?? parametro;

String unidadParametro(String parametro) => definiciones[parametro]?.unidad ?? '';

