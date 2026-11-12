import 'package:flutter/material.dart';

import '../app_state.dart';
import 'cfc_page.dart';
import 'comparacion_page.dart';
import 'ppfm_page.dart';
import 'tema.dart';

class RegistrosPage extends StatelessWidget {
  const RegistrosPage({super.key, required this.estado});

  final AppState estado;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        final ppfm = estado.almacen.registrosPpfmLocales.length;
        final cfc = estado.almacen.registrosCfcLocales.length;

        return Scaffold(
          appBar: AppBar(title: const Text('Registros del estudio')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Tema.verdeClaro,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.science_outlined, color: Tema.verde),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Los indicadores del estudio se registran desde aquí y se envían a la base de datos.',
                        style: TextStyle(fontSize: 12.5, color: Tema.verdeOscuro, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _tarjeta(
                context,
                icono: Icons.compost,
                color: const Color(0xFF6D4C41),
                titulo: 'Calidad física del compost',
                subtitulo: 'Indicador CFC · color, aroma, textura y humedad',
                detalle: '$cfc registros guardados en el dispositivo',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CfcPage(estado: estado)),
                ),
              ),
              _tarjeta(
                context,
                icono: Icons.my_location,
                color: const Color(0xFF1565C0),
                titulo: 'Precisión de los parámetros',
                subtitulo: 'Indicador PPFM · sensor frente a instrumento patrón',
                detalle: '$ppfm registros guardados en el dispositivo',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PpfmPage(estado: estado)),
                ),
              ),
              _tarjeta(
                context,
                icono: Icons.compare_arrows,
                color: Tema.verde,
                titulo: 'Comparación de grupos',
                subtitulo: 'Posprueba del grupo control (GC) frente al experimental (GE)',
                detalle: 'Promedios de PFC, PPFM y CFC por grupo',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ComparacionPage(estado: estado)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tarjeta(
    BuildContext context, {
    required IconData icono,
    required Color color,
    required String titulo,
    required String subtitulo,
    required String detalle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitulo, style: const TextStyle(fontSize: 12, color: Tema.textoSecundario)),
                    const SizedBox(height: 4),
                    Text(detalle, style: TextStyle(fontSize: 11, color: color)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Tema.textoSecundario),
            ],
          ),
        ),
      ),
    );
  }
}
