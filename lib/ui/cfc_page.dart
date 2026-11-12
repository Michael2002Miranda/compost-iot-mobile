import 'package:flutter/material.dart';

import '../app_state.dart';
import '../clasificacion.dart';
import 'tema.dart';
import 'widgets.dart';

/// Ficha de registro del indicador CFC (calidad física del compost).
///
/// Cada criterio se puntúa de 0 a 2 según Bejarano-Meza et al. (2026); el
/// compost se considera maduro con 7 puntos o más sobre 8.
class CfcPage extends StatefulWidget {
  const CfcPage({super.key, required this.estado});

  final AppState estado;

  @override
  State<CfcPage> createState() => _CfcPageState();
}

class _CfcPageState extends State<CfcPage> {
  String? _color;
  String? _aroma;
  String? _textura;
  String? _humedad;
  final _observaciones = TextEditingController();
  bool _guardando = false;

  static const _opcionesColor = {
    'Marrón oscuro': 'marron_oscuro',
    'Marrón claro': 'marron_claro',
    'Negro o verdoso': 'negro_verdoso',
  };
  static const _opcionesAroma = {
    'Tierra húmeda': 'tierra_humeda',
    'Neutro': 'neutro',
    'Putrefacto / amoniaco': 'putrefacto',
  };
  static const _opcionesTextura = {
    'Suelta y granulada': 'suelta_granulada',
    'Grumosa': 'grumosa',
    'Compacta o pastosa': 'compacta_pastosa',
  };
  static const _opcionesHumedad = {
    'Humedece sin gotear': 'humedece_sin_gotear',
    'Seca': 'seca',
    'Gotea': 'gotea',
  };

  int get _puntaje => puntajeCfc(
        color: _color ?? '',
        aroma: _aroma ?? '',
        textura: _textura ?? '',
        humedad: _humedad ?? '',
      );

  bool get _completo => _color != null && _aroma != null && _textura != null && _humedad != null;
  bool get _maduro => _completo && esCompostMaduro(_puntaje);

  @override
  void dispose() {
    _observaciones.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_completo) return;
    setState(() => _guardando = true);

    final error = await widget.estado.guardarCfc(
      color: _color!,
      aroma: _aroma!,
      textura: _textura!,
      humedad: _humedad!,
      observaciones: _observaciones.text.trim(),
    );

    if (!mounted) return;
    setState(() => _guardando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? 'Registro CFC guardado en la base de datos.'
              : 'Sin conexión: el registro quedó guardado en el dispositivo.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calidad física del compost')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Text(
            'Indicador CFC · ${widget.estado.activa?.nombre ?? 'sin compostera'}',
            style: const TextStyle(fontSize: 12.5, color: Tema.textoSecundario),
          ),
          const SizedBox(height: 14),
          OpcionSelector(
            titulo: 'Color',
            opciones: _opcionesColor.keys.toList(),
            seleccionada: _nombre(_opcionesColor, _color),
            onSeleccion: (valor) => setState(() => _color = _opcionesColor[valor]),
          ),
          const SizedBox(height: 12),
          OpcionSelector(
            titulo: 'Aroma',
            opciones: _opcionesAroma.keys.toList(),
            seleccionada: _nombre(_opcionesAroma, _aroma),
            onSeleccion: (valor) => setState(() => _aroma = _opcionesAroma[valor]),
          ),
          const SizedBox(height: 12),
          OpcionSelector(
            titulo: 'Textura',
            opciones: _opcionesTextura.keys.toList(),
            seleccionada: _nombre(_opcionesTextura, _textura),
            onSeleccion: (valor) => setState(() => _textura = _opcionesTextura[valor]),
          ),
          const SizedBox(height: 12),
          OpcionSelector(
            titulo: 'Humedad al tacto',
            opciones: _opcionesHumedad.keys.toList(),
            seleccionada: _nombre(_opcionesHumedad, _humedad),
            onSeleccion: (valor) => setState(() => _humedad = _opcionesHumedad[valor]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _observaciones,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observaciones (opcional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _completo
                  ? (_maduro ? Tema.verdeClaro : const Color(0xFFFFF3E0))
                  : const Color(0xFFF3F6F3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _completo
                    ? (_maduro ? Tema.verde : const Color(0xFFFFCC80))
                    : const Color(0xFFE0E6E1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  !_completo
                      ? Icons.info_outline
                      : (_maduro ? Icons.verified : Icons.hourglass_bottom),
                  color: !_completo
                      ? Tema.textoSecundario
                      : (_maduro ? Tema.verde : const Color(0xFFEF6C00)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        !_completo
                            ? 'Complete los cuatro criterios'
                            : (_maduro ? 'Cumple los criterios de madurez' : 'Aún no alcanza la madurez'),
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Puntaje $_puntaje / 8 · se considera maduro con 7 u 8 puntos',
                        style: const TextStyle(fontSize: 11.5, color: Tema.textoSecundario),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: (_completo && !_guardando) ? _guardar : null,
            icon: _guardando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Guardar registro'),
          ),
        ],
      ),
    );
  }

  String? _nombre(Map<String, String> opciones, String? codigo) {
    if (codigo == null) return null;
    for (final entrada in opciones.entries) {
      if (entrada.value == codigo) return entrada.key;
    }
    return null;
  }
}
