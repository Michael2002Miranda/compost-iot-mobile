import 'package:flutter/material.dart';

import '../ui/tema.dart';

/// Formato de fecha y hora en español, sin depender de `intl`.
String dosDigitos(int n) => n.toString().padLeft(2, '0');

String fechaCorta(DateTime fecha) =>
    '${dosDigitos(fecha.day)}/${dosDigitos(fecha.month)}/${fecha.year}';

String horaCorta(DateTime fecha) => '${dosDigitos(fecha.hour)}:${dosDigitos(fecha.minute)}';

String fechaHora(DateTime fecha) => '${fechaCorta(fecha)} ${horaCorta(fecha)}';

String haceCuanto(DateTime fecha) {
  final diferencia = DateTime.now().difference(fecha);
  if (diferencia.inSeconds < 60) return 'hace ${diferencia.inSeconds} s';
  if (diferencia.inMinutes < 60) return 'hace ${diferencia.inMinutes} min';
  if (diferencia.inHours < 24) return 'hace ${diferencia.inHours} h';
  return 'hace ${diferencia.inDays} d';
}

String numero(double valor, {int decimales = 1}) => valor.toStringAsFixed(decimales);

/// Tarjeta con el valor de un parámetro y su clasificación.
class TarjetaMetrica extends StatelessWidget {
  const TarjetaMetrica({
    super.key,
    required this.icono,
    required this.color,
    required this.titulo,
    required this.valor,
    required this.unidad,
    required this.detalle,
    this.colorDetalle,
    this.onTap,
  });

  final IconData icono;
  final Color color;
  final String titulo;
  final String valor;
  final String unidad;
  final String detalle;
  final Color? colorDetalle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      detalle,
                      style: TextStyle(fontSize: 12, color: colorDetalle ?? Tema.textoSecundario),
                    ),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  text: valor,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color),
                  children: [
                    TextSpan(
                      text: unidad.isEmpty ? '' : ' $unidad',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta de estado (óptimo, atención, crítico).
class ChipEstado extends StatelessWidget {
  const ChipEstado({super.key, required this.texto, required this.color, this.icono});

  final String texto;
  final Color color;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

/// Aviso de que los datos mostrados provienen de la copia local.
class AvisoSinConexion extends StatelessWidget {
  const AvisoSinConexion({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 18, color: Color(0xFFEF6C00)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF8A4B00)),
            ),
          ),
        ],
      ),
    );
  }
}

class MensajeVacio extends StatelessWidget {
  const MensajeVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Tema.verdeClaro, shape: BoxShape.circle),
            child: Icon(icono, size: 34, color: Tema.verde),
          ),
          const SizedBox(height: 14),
          Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Tema.textoSecundario, height: 1.4),
          ),
          if (accion != null) ...[const SizedBox(height: 16), accion!],
        ],
      ),
    );
  }
}

class SeccionTitulo extends StatelessWidget {
  const SeccionTitulo({super.key, required this.texto, this.accion});

  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Tema.texto),
            ),
          ),
          if (accion != null) accion!,
        ],
      ),
    );
  }
}

/// Selector de una opción entre varias, con el aspecto de las fichas del informe.
class OpcionSelector extends StatelessWidget {
  const OpcionSelector({
    super.key,
    required this.titulo,
    required this.opciones,
    required this.seleccionada,
    required this.onSeleccion,
    this.puntos,
  });

  final String titulo;
  final List<String> opciones;
  final String? seleccionada;
  final ValueChanged<String> onSeleccion;
  final Map<String, int>? puntos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ...opciones.map((opcion) {
          final activa = opcion == seleccionada;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onSeleccion(opcion),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: activa ? Tema.verdeClaro : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: activa ? Tema.verde : const Color(0xFFE0E6E1),
                    width: activa ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      activa ? Icons.radio_button_checked : Icons.radio_button_off,
                      size: 18,
                      color: activa ? Tema.verde : const Color(0xFFB6C2B9),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        opcion,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: activa ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (puntos != null && puntos!.containsKey(opcion))
                      Text(
                        '${puntos![opcion]} pts',
                        style: const TextStyle(fontSize: 11.5, color: Tema.textoSecundario),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

