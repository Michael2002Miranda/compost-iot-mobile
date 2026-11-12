import 'package:flutter/material.dart';

import '../app_state.dart';
import '../modelos.dart';
import 'tema.dart';

/// Alta de una compostera. El código generado es el que se configura en el ESP32.
class ComposteraPage extends StatefulWidget {
  const ComposteraPage({super.key, required this.estado});

  final AppState estado;

  @override
  State<ComposteraPage> createState() => _ComposteraPageState();
}

class _ComposteraPageState extends State<ComposteraPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _ubicacion = TextEditingController();
  String _grupo = 'GE';
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _ubicacion.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    final creada = await widget.estado.crearCompostera(
      nombre: _nombre.text.trim(),
      grupo: _grupo,
      ubicacion: _ubicacion.text.trim(),
    );
    if (!mounted) return;
    setState(() => _guardando = false);

    if (creada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.estado.errorSesion ?? 'No se pudo registrar la compostera.')),
      );
      return;
    }

    await _mostrarCodigo(creada);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _mostrarCodigo(Compostera compostera) {
    return showDialog<void>(
      context: context,
      builder: (contexto) => AlertDialog(
        icon: const Icon(Icons.sensors, color: Tema.verde, size: 34),
        title: const Text('Compostera registrada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configura este código en el ESP32 para que las lecturas lleguen a tu compostera:',
              style: TextStyle(fontSize: 12.5, color: Tema.textoSecundario),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Tema.verdeClaro,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Tema.verde),
              ),
              child: Text(
                compostera.codigo ?? '—',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: Tema.verdeOscuro,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'En el firmware:  #define CODIGO_DISPOSITIVO "${compostera.codigo ?? ''}"',
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 6),
            Text(
              'Identificador interno: ${compostera.id}',
              style: const TextStyle(fontSize: 11, color: Tema.textoSecundario),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva compostera')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre de la compostera'),
              validator: (valor) =>
                  (valor ?? '').trim().length < 2 ? 'Ingrese un nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ubicacion,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Ubicación (opcional)'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Grupo del estudio',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'El diseño cuasi experimental compara la posprueba del grupo control (sin la app) '
              'con la del grupo experimental (con la app).',
              style: TextStyle(fontSize: 11.5, color: Tema.textoSecundario, height: 1.35),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _opcionGrupo(
                    'GE',
                    'Experimental',
                    'Usa la aplicación',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _opcionGrupo(
                    'GC',
                    'Control',
                    'Monitoreo manual',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _guardando ? null : _crear,
              icon: _guardando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add),
              label: const Text('Registrar compostera'),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Color(0xFF1565C0)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Al registrarla se genera un código único. Ese código se graba en el ESP32 '
                      'y es lo que permite asociar cada lectura a tu cuenta.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF0D47A1), height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _opcionGrupo(String codigo, String titulo, String detalle) {
    final activa = _grupo == codigo;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _grupo = codigo),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: activa ? Tema.verdeClaro : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activa ? Tema.verde : const Color(0xFFE0E6E1),
            width: activa ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  activa ? Icons.check_circle : Icons.circle_outlined,
                  size: 16,
                  color: activa ? Tema.verde : const Color(0xFFB6C2B9),
                ),
                const SizedBox(width: 6),
                Text(
                  '$codigo · $titulo',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(detalle, style: const TextStyle(fontSize: 11, color: Tema.textoSecundario)),
          ],
        ),
      ),
    );
  }
}
