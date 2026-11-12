import 'package:flutter/material.dart';

import '../app_state.dart';
import 'tema.dart';

/// Cuestionario SUS (System Usability Scale) de 10 ítems.
/// Mide la dimensión «usabilidad» de la variable independiente.
class SusPage extends StatefulWidget {
  const SusPage({super.key, required this.estado});

  final AppState estado;

  @override
  State<SusPage> createState() => _SusPageState();
}

class _SusPageState extends State<SusPage> {
  static const _items = [
    'Me gustaría usar esta aplicación con frecuencia.',
    'Encontré la aplicación innecesariamente compleja.',
    'Pensé que la aplicación era fácil de usar.',
    'Creo que necesitaría apoyo técnico para poder usar la aplicación.',
    'Encontré las funciones de la aplicación bien integradas.',
    'Pensé que había demasiada inconsistencia en la aplicación.',
    'Imagino que la mayoría de las personas aprendería a usarla rápidamente.',
    'Encontré la aplicación muy difícil de usar.',
    'Me sentí muy seguro al usar la aplicación.',
    'Necesité aprender muchas cosas antes de poder usarla.',
  ];

  final List<int> _respuestas = List.filled(10, 0);
  bool _enviando = false;
  double? _resultado;

  bool get _completo => _respuestas.every((r) => r > 0);

  double get _puntaje {
    var sumaImpares = 0;
    var sumaPares = 0;
    for (var i = 0; i < 10; i++) {
      if (i.isEven) {
        sumaImpares += _respuestas[i] - 1;
      } else {
        sumaPares += 5 - _respuestas[i];
      }
    }
    return (sumaImpares + sumaPares) * 2.5;
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    final puntaje = await widget.estado.enviarSus(_respuestas);
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _resultado = puntaje ?? _puntaje;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usabilidad (SUS)')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const Text(
            'Marque de 1 (totalmente en desacuerdo) a 5 (totalmente de acuerdo) para cada afirmación.',
            style: TextStyle(fontSize: 12.5, color: Tema.textoSecundario, height: 1.4),
          ),
          const SizedBox(height: 14),
          ...List.generate(_items.length, (indice) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6ECE7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${indice + 1}. ${_items[indice]}',
                    style: const TextStyle(fontSize: 12.5, height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (posicion) {
                      final valor = posicion + 1;
                      final activo = _respuestas[indice] == valor;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setState(() => _respuestas[indice] = valor),
                          child: Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: activo ? Tema.verde : const Color(0xFFF3F6F3),
                              border: Border.all(
                                color: activo ? Tema.verde : const Color(0xFFDCE5DD),
                              ),
                            ),
                            child: Text(
                              '$valor',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: activo ? Colors.white : Tema.textoSecundario,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          }),
          if (_resultado != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Tema.verdeClaro,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Tema.verde),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Tema.verde),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Puntaje SUS: ${_resultado!.toStringAsFixed(1)} / 100',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          FilledButton.icon(
            onPressed: (_completo && !_enviando) ? _enviar : null,
            icon: _enviando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send),
            label: const Text('Enviar evaluación'),
          ),
        ],
      ),
    );
  }
}

/// Lista de verificación de funcionalidad: cada caso aprobado cuenta como
/// evidencia del indicador «funcionalidad» de la variable independiente.
class FuncionalidadPage extends StatefulWidget {
  const FuncionalidadPage({super.key, required this.estado});

  final AppState estado;

  @override
  State<FuncionalidadPage> createState() => _FuncionalidadPageState();
}

class _FuncionalidadPageState extends State<FuncionalidadPage> {
  static const _casos = [
    'Registro e inicio de sesión de usuario',
    'Registro de compostera y generación del código del dispositivo',
    'Recepción de lecturas del ESP32 en tiempo real',
    'Clasificación de los parámetros fisicoquímicos (PFC)',
    'Alertas ante valores fuera de rango',
    'Registro de precisión frente al instrumento patrón (PPFM)',
    'Registro de calidad física del compost (CFC)',
    'Exportación de datos para el análisis estadístico',
  ];

  final Set<int> _aprobados = {};

  Future<void> _registrar() async {
    for (var i = 0; i < _casos.length; i++) {
      if (!_aprobados.contains(i)) continue;
      try {
        await widget.estado.api.registrarPrueba(_casos[i]);
      } catch (_) {
        // Sin conexión: se conserva la marca en pantalla para la evidencia.
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_aprobados.length} casos registrados.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Funcionalidad')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const Text(
            'Marque los casos de prueba que se ejecutaron correctamente.',
            style: TextStyle(fontSize: 12.5, color: Tema.textoSecundario),
          ),
          const SizedBox(height: 12),
          ...List.generate(_casos.length, (indice) {
            final aprobado = _aprobados.contains(indice);
            return CheckboxListTile(
              value: aprobado,
              onChanged: (valor) {
                setState(() {
                  if (valor == true) {
                    _aprobados.add(indice);
                  } else {
                    _aprobados.remove(indice);
                  }
                });
              },
              title: Text(_casos[indice], style: const TextStyle(fontSize: 13)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          }),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _aprobados.isEmpty ? null : _registrar,
            icon: const Icon(Icons.check),
            label: Text('Registrar ${_aprobados.length} casos aprobados'),
          ),
        ],
      ),
    );
  }
}
