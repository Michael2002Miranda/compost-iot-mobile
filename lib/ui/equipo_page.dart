import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../modelos.dart';
import 'tema.dart';
import 'widgets.dart';

/// Instrucciones para conectar el prototipo a la red de la vivienda.
///
/// El equipo se configura desde el propio celular (portal WiFiManager): no hace
/// falta computadora ni cargar el firmware de nuevo.
class EquipoPage extends StatelessWidget {
  const EquipoPage({super.key, required this.estado, required this.compostera});

  final AppState estado;
  final Compostera compostera;

  bool get _recibiendo {
    final ultima = estado.ultima;
    if (ultima == null) return false;
    return DateTime.now().difference(ultima.fechaHora).inMinutes < 3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar el equipo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Tema.verde, Tema.verdeOscuro],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Código de tu compostera',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  compostera.codigo ?? '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${compostera.nombre} · Grupo ${compostera.grupo}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: compostera.codigo ?? ''));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código copiado')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copiar código'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    minimumSize: const Size.fromHeight(42),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _estadoEquipo(),
          const SizedBox(height: 18),
          const SeccionTitulo(texto: 'Pasos para conectarlo'),
          _paso(
            1,
            'Enchufa el prototipo',
            'Conéctalo a la corriente con el cargador del celular. El LED debe encenderse.',
          ),
          _paso(
            2,
            'Conéctate a la red del equipo',
            'En los ajustes de WiFi del celular aparece una red llamada «CompostIoT-Setup». '
                'Conéctate a ella (no tiene contraseña).',
          ),
          _paso(
            3,
            'Abre la página de configuración',
            'Se abre sola. Si no aparece, escribe 192.168.4.1 en el navegador del celular.',
          ),
          _paso(
            4,
            'Elige tu WiFi y escribe el código',
            'Selecciona la red de tu casa (debe ser de 2.4 GHz), escribe su contraseña y pega '
                'el código de arriba.',
          ),
          _paso(
            5,
            'Guarda y espera',
            'El equipo se reinicia y empieza a enviar. En un minuto verás los datos en Inicio.',
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.build_outlined, size: 18, color: Color(0xFF8D6E00)),
                    SizedBox(width: 8),
                    Text(
                      'Si necesitas reconfigurarlo',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6D5200)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mantén pulsado el botón BOOT del equipo durante 3 segundos: la red '
                  '«CompostIoT-Setup» vuelve a aparecer y puedes cambiar el WiFi o el código.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF6D5200)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'El equipo debe quedar dentro del alcance del WiFi de la casa. El celular puede '
            'estar en cualquier red o con datos móviles: la aplicación lee los datos de Internet.',
            style: TextStyle(fontSize: 11.5, color: Tema.textoSecundario, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _estadoEquipo() {
    final vinculado = (compostera.codigo ?? '').isNotEmpty;
    final color = _recibiendo ? Tema.verde : const Color(0xFFEF6C00);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _recibiendo ? Tema.verdeClaro : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            _recibiendo ? Icons.sensors : Icons.sensors_off,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _recibiendo ? 'Recibiendo datos' : 'Esperando la primera lectura',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  _recibiendo
                      ? 'Última lectura ${haceCuanto(estado.ultima!.fechaHora)}'
                      : vinculado
                          ? 'Cuando termines los pasos, los datos aparecerán aquí.'
                          : 'Completa los pasos para vincular tu equipo.',
                  style: const TextStyle(fontSize: 11.5, color: Tema.textoSecundario),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paso(int numero, String titulo, String detalle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Tema.verdeClaro, shape: BoxShape.circle),
            child: Text(
              '$numero',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Tema.verdeOscuro,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  style: const TextStyle(fontSize: 12, height: 1.4, color: Tema.textoSecundario),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
