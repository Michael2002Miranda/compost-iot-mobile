import 'package:flutter/material.dart';

import '../app_state.dart';
import '../api.dart';
import '../clasificacion.dart';
import '../modelos.dart';
import 'tema.dart';
import 'widgets.dart';

/// Ficha de observación del indicador PPFM.
///
///   PPFM (%) = 100 − (|VM − VR| / VR) × 100
class PpfmPage extends StatefulWidget {
  const PpfmPage({super.key, required this.estado});

  final AppState estado;

  @override
  State<PpfmPage> createState() => _PpfmPageState();
}

class _PpfmPageState extends State<PpfmPage> {
  String _parametro = 'temperatura';
  final _medido = TextEditingController();
  final _referencia = TextEditingController();
  final _observaciones = TextEditingController();

  bool _guardando = false;
  bool _cargando = true;
  List<RegistroPpfm> _registros = [];

  @override
  void initState() {
    super.initState();
    _precargarMedido();
    _medido.addListener(_recalcular);
    _referencia.addListener(_recalcular);
    _cargarRegistros();
  }

  @override
  void dispose() {
    _medido.dispose();
    _referencia.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  void _precargarMedido() {
    final ultima = widget.estado.ultima;
    if (ultima == null) return;
    final valor = switch (_parametro) {
      'temperatura' => ultima.temperatura,
      'humedad' => ultima.humedad,
      _ => ultima.ph,
    };
    _medido.text = numero(valor);
  }

  double? get _vm => double.tryParse(_medido.text.replaceAll(',', '.'));
  double? get _vr => double.tryParse(_referencia.text.replaceAll(',', '.'));

  double? get _precision {
    final vm = _vm;
    final vr = _vr;
    if (vm == null || vr == null || vr == 0) return null;
    return calcularPrecision(vm, vr);
  }

  void _recalcular() => setState(() {});

  Future<void> _cargarRegistros() async {
    try {
      final remotos = await widget.estado.api.listarPpfm(compostera: widget.estado.activa?.id);
      if (!mounted) return;
      setState(() {
        _registros = remotos;
        _cargando = false;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _registros = widget.estado.almacen.registrosPpfmLocales
            .map((e) => RegistroPpfm.fromJson(e as Map<String, dynamic>))
            .toList();
        _cargando = false;
      });
    }
  }

  Future<void> _guardar() async {
    final vm = _vm;
    final vr = _vr;
    if (vm == null || vr == null) return;

    setState(() => _guardando = true);
    final error = await widget.estado.guardarPpfm(
      parametro: _parametro,
      valorMedido: vm,
      valorReferencia: vr,
      observaciones: _observaciones.text.trim(),
    );
    if (!mounted) return;

    setState(() {
      _guardando = false;
      _registros = [
        RegistroPpfm(
          parametro: _parametro,
          valorMedido: vm,
          valorReferencia: vr,
          precision: calcularPrecision(vm, vr),
          fecha: DateTime.now(),
          idCompostera: widget.estado.activa?.id ?? 1,
        ),
        ..._registros,
      ];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? 'Registro de precisión guardado.'
              : 'Sin conexión: el registro quedó guardado en el dispositivo.',
        ),
      ),
    );
    _referencia.clear();
    _observaciones.clear();
  }

  @override
  Widget build(BuildContext context) {
    final prec = _precision;

    return Scaffold(
      appBar: AppBar(title: const Text('Precisión (PPFM)')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const Text(
            'Compare la lectura del sensor (VM) con el instrumento patrón calibrado (VR).',
            style: TextStyle(fontSize: 12.5, color: Tema.textoSecundario),
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'temperatura', label: Text('Temp.')),
              ButtonSegment(value: 'humedad', label: Text('Humedad')),
              ButtonSegment(value: 'ph', label: Text('pH')),
            ],
            selected: {_parametro},
            showSelectedIcon: false,
            onSelectionChanged: (seleccion) {
              setState(() {
                _parametro = seleccion.first;
                _medido.clear();
                _precargarMedido();
              });
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _medido,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Valor medido (VM)',
                    suffixText: _unidad,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _referencia,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Valor patrón (VR)',
                    suffixText: _unidad,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: prec == null
                  ? const Color(0xFFF3F6F3)
                  : (prec >= 95 ? Tema.verdeClaro : const Color(0xFFFFF3E0)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: prec == null
                    ? const Color(0xFFE0E6E1)
                    : (prec >= 95 ? Tema.verde : const Color(0xFFFFCC80)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.percent,
                  color: prec == null
                      ? Tema.textoSecundario
                      : (prec >= 95 ? Tema.verde : const Color(0xFFEF6C00)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Precisión calculada', style: TextStyle(fontSize: 12)),
                      Text(
                        prec == null ? '—' : '${prec.toStringAsFixed(2)} %',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: prec == null
                              ? Tema.textoSecundario
                              : (prec >= 95 ? Tema.verde : const Color(0xFFEF6C00)),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '100 − (|VM − VR| / VR) × 100',
                  style: const TextStyle(fontSize: 9.5, color: Tema.textoSecundario),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _observaciones,
            decoration: const InputDecoration(labelText: 'Observaciones (opcional)'),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: (_guardando || prec == null) ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Guardar registro'),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Registros de precisión',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
              ),
              if (_registros.isNotEmpty)
                Chip(
                  label: Text(
                    'Prom. ${(_registros.map((r) => r.precision).reduce((a, b) => a + b) / _registros.length).toStringAsFixed(2)} %',
                    style: const TextStyle(fontSize: 11),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_cargando)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_registros.isEmpty)
            const MensajeVacio(
              icono: Icons.my_location,
              titulo: 'Sin registros de precisión',
              mensaje: 'Registre al menos una comparación por parámetro para el análisis.',
            )
          else
            ..._registros.take(12).map((r) => _fila(r)),
        ],
      ),
    );
  }

  String get _unidad => switch (_parametro) {
        'temperatura' => '°C',
        'humedad' => '%',
        _ => '',
      };

  Widget _fila(RegistroPpfm r) {
    final color = r.precision >= 95 ? Tema.verde : const Color(0xFFEF6C00);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6ECE7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreParametro(r.parametro),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  'VM ${numero(r.valorMedido)} · VR ${numero(r.valorReferencia)} · ${fechaHora(r.fecha)}',
                  style: const TextStyle(fontSize: 10.5, color: Tema.textoSecundario),
                ),
              ],
            ),
          ),
          Text(
            '${r.precision.toStringAsFixed(2)} %',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
