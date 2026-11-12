import 'package:flutter/material.dart';

import '../clasificacion.dart';
import '../modelos.dart';
import 'tema.dart';
import 'widgets.dart';

/// Gráfico de líneas dibujado con `CustomPainter` (sin dependencias externas).
///
/// Muestra la serie del parámetro elegido, la banda de valores óptimos del
/// informe y el último valor registrado.
class GraficoLinea extends StatelessWidget {
  const GraficoLinea({
    super.key,
    required this.datos,
    required this.parametro,
    required this.color,
  });

  final List<Medicion> datos;
  final String parametro;
  final Color color;

  double _valor(Medicion m) {
    switch (parametro) {
      case 'temperatura':
        return m.temperatura;
      case 'humedad':
        return m.humedad;
      default:
        return m.ph;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Sin datos para el período seleccionado',
            style: TextStyle(color: Tema.textoSecundario, fontSize: 13),
          ),
        ),
      );
    }

    return SizedBox(
      height: 210,
      width: double.infinity,
      child: CustomPaint(
        painter: _PintorSerie(
          datos: datos,
          valores: datos.map(_valor).toList(),
          color: color,
          banda: _bandaOptima(parametro),
        ),
      ),
    );
  }

  /// Devuelve (mínimo, máximo) del tramo considerado óptimo para el parámetro.
  static (double, double) _bandaOptima(String parametro) {
    final definicion = definiciones[parametro];
    if (definicion == null) return (0, 0);

    double? inicio;
    double fin = 0;
    var anterior = 0.0;

    for (final tramo in definicion.tramos) {
      if (tramo.estado == EstadoParametro.optimo) {
        inicio ??= anterior;
        fin = tramo.hasta == double.infinity ? anterior : tramo.hasta;
      }
      anterior = tramo.hasta;
    }

    if (inicio == null) return (0, 0);
    return (inicio, fin);
  }
}

class _PintorSerie extends CustomPainter {
  _PintorSerie({
    required this.datos,
    required this.valores,
    required this.color,
    required this.banda,
  });

  final List<Medicion> datos;
  final List<double> valores;
  final Color color;
  final (double, double) banda;

  static const double _izquierda = 38;
  static const double _derecha = 12;
  static const double _arriba = 12;
  static const double _abajo = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final ancho = size.width - _izquierda - _derecha;
    final alto = size.height - _arriba - _abajo;
    if (ancho <= 0 || alto <= 0) return;

    var minimo = valores.reduce((a, b) => a < b ? a : b);
    var maximo = valores.reduce((a, b) => a > b ? a : b);

    if (maximo == minimo) {
      maximo = maximo + 1;
      minimo = minimo - 1;
    }
    final margen = (maximo - minimo) * 0.15;
    minimo -= margen;
    maximo += margen;

    double y(double valor) => _arriba + alto - ((valor - minimo) / (maximo - minimo)) * alto;
    double x(int indice) => valores.length == 1
        ? _izquierda + ancho / 2
        : _izquierda + (indice / (valores.length - 1)) * ancho;

    // Banda de valores óptimos.
    final (bandaMin, bandaMax) = banda;
    if (bandaMax > bandaMin && bandaMin < maximo && bandaMax > minimo) {
      final top = y(bandaMax.clamp(minimo, maximo));
      final bottom = y(bandaMin.clamp(minimo, maximo));
      canvas.drawRect(
        Rect.fromLTRB(_izquierda, top, _izquierda + ancho, bottom),
        Paint()..color = Tema.verde.withValues(alpha: 0.10),
      );
    }

    // Rejilla horizontal y etiquetas del eje Y.
    final rejilla = Paint()
      ..color = const Color(0xFFE6ECE7)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final valor = minimo + (maximo - minimo) * (i / 4);
      final posicion = y(valor);
      canvas.drawLine(Offset(_izquierda, posicion), Offset(_izquierda + ancho, posicion), rejilla);
      _texto(canvas, numero(valor), Offset(0, posicion - 6), ancho: _izquierda - 6, alinearDerecha: true);
    }

    // Serie.
    final trazo = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final camino = Path();
    for (var i = 0; i < valores.length; i++) {
      final punto = Offset(x(i), y(valores[i]));
      if (i == 0) {
        camino.moveTo(punto.dx, punto.dy);
      } else {
        camino.lineTo(punto.dx, punto.dy);
      }
    }
    canvas.drawPath(camino, trazo);

    // Puntos (se omiten si hay demasiados para no saturar).
    if (valores.length <= 60) {
      final relleno = Paint()..color = Colors.white;
      final borde = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      for (var i = 0; i < valores.length; i++) {
        final punto = Offset(x(i), y(valores[i]));
        canvas.drawCircle(punto, 2.8, relleno);
        canvas.drawCircle(punto, 2.8, borde);
      }
    }

    // Etiquetas del eje X: primera y última fecha.
    _texto(canvas, fechaCorta(datos.first.fechaHora), Offset(_izquierda, size.height - 16));
    if (datos.length > 1) {
      _texto(
        canvas,
        fechaCorta(datos.last.fechaHora),
        Offset(_izquierda, size.height - 16),
        ancho: ancho,
        alinearDerecha: true,
      );
    }

    // Último valor destacado.
    final ultimo = valores.last;
    final posicionUltimo = Offset(x(valores.length - 1), y(ultimo));
    canvas.drawCircle(posicionUltimo, 4.5, Paint()..color = color);
    final etiqueta = TextPainter(
      text: TextSpan(
        text: ' ${numero(ultimo)} ',
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    var dx = posicionUltimo.dx - etiqueta.width - 4;
    if (dx < _izquierda) dx = posicionUltimo.dx + 6;
    var dy = posicionUltimo.dy - etiqueta.height - 4;
    if (dy < 0) dy = posicionUltimo.dy + 6;
    etiqueta.paint(canvas, Offset(dx, dy));
  }

  void _texto(
    Canvas canvas,
    String texto,
    Offset posicion, {
    double? ancho,
    bool alinearDerecha = false,
  }) {
    final pintor = TextPainter(
      text: TextSpan(
        text: texto,
        style: const TextStyle(fontSize: 10, color: Tema.textoSecundario),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: ancho ?? double.infinity);

    final dx = alinearDerecha && ancho != null ? posicion.dx + ancho - pintor.width : posicion.dx;
    pintor.paint(canvas, Offset(dx, posicion.dy));
  }

  @override
  bool shouldRepaint(covariant _PintorSerie anterior) =>
      anterior.valores != valores || anterior.color != color || anterior.banda != banda;
}
