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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Tema.sans(14.5, peso: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detalle,
                      style: Tema.sans(11.5, color: colorDetalle ?? Tema.tintaSuave, altura: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    valor,
                    style: Tema.serif(26, color: color, peso: 600),
                  ),
                  if (unidad.isNotEmpty)
                    Text(
                      unidad,
                      style: Tema.sans(10.5, color: color, peso: FontWeight.w700),
                    ),
                ],
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            texto.toUpperCase(),
            style: Tema.sans(9.5, color: color, peso: FontWeight.w700, espaciado: 0.7),
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
        color: const Color(0xFFFBF3E2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Tema.ocre.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 16, color: Tema.ocre),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: Tema.sans(11.5, color: const Color(0xFF7A5416), altura: 1.35),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(color: Tema.salvia, shape: BoxShape.circle),
            child: Icon(icono, size: 30, color: Tema.olivaOscuro),
          ),
          const SizedBox(height: 14),
          Text(titulo, style: Tema.serif(17), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: Tema.sans(12.5, color: Tema.tintaSuave, altura: 1.45),
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
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texto.toUpperCase(),
              style: Tema.sans(10.5, color: Tema.tintaSuave, peso: FontWeight.w700, espaciado: 1.4),
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
        Text(titulo, style: Tema.sans(13, peso: FontWeight.w600)),
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
                  color: activa ? Tema.salvia : Tema.superficie,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: activa ? Tema.oliva : Tema.borde,
                    width: activa ? 1.3 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      activa ? Icons.radio_button_checked : Icons.radio_button_off,
                      size: 17,
                      color: activa ? Tema.olivaOscuro : const Color(0xFFBDB5A3),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        opcion,
                        style: Tema.sans(13.5, peso: activa ? FontWeight.w600 : FontWeight.w400),
                      ),
                    ),
                    if (puntos != null && puntos!.containsKey(opcion))
                      Text(
                        '${puntos![opcion]} pts',
                        style: Tema.sans(11, color: Tema.tintaSuave),
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
