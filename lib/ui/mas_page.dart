import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config.dart';
import 'compostera_page.dart';
import 'equipo_page.dart';
import 'investigador_page.dart';
import 'sus_page.dart';
import 'tema.dart';
import 'widgets.dart';

class MasPage extends StatelessWidget {
  const MasPage({super.key, required this.estado});

  final AppState estado;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        final usuario = estado.usuario;

        return Scaffold(
          appBar: AppBar(title: const Text('Más')),
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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        (usuario?.nombre ?? '?').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            usuario?.nombre ?? 'Usuario',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            usuario?.email ?? '',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          if (usuario?.esInvestigador ?? false) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Investigador del estudio',
                                style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SeccionTitulo(texto: 'Mis composteras'),
              ...estado.composteras.map((c) {
                final activa = c.id == estado.activa?.id;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: Icon(Icons.grass, color: activa ? Tema.verde : Tema.textoSecundario),
                    title: Text(c.nombre, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(
                      'Grupo ${c.grupo} · código ${c.codigo ?? '—'}',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    trailing: activa
                        ? const Chip(
                            label: Text('Activa', style: TextStyle(fontSize: 10.5)),
                            visualDensity: VisualDensity.compact,
                          )
                        : null,
                    onTap: () => estado.seleccionarCompostera(c),
                  ),
                );
              }),
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: const Icon(Icons.add_circle_outline, color: Tema.verde),
                  title: const Text('Registrar nueva compostera', style: TextStyle(fontSize: 14)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ComposteraPage(estado: estado)),
                  ),
                ),
              ),
              if (estado.activa != null)
                Card(
                  margin: const EdgeInsets.only(top: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: const Icon(Icons.sensors, color: Tema.verde),
                    title: const Text('Configurar mi equipo', style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      'Conectar el prototipo al WiFi de la casa',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EquipoPage(estado: estado, compostera: estado.activa!),
                      ),
                    ),
                  ),
                ),
              if (estado.esInvestigador) ...[
                const SizedBox(height: 18),
                const SeccionTitulo(texto: 'Estudio'),
                _opcion(
                  context,
                  icono: Icons.groups_outlined,
                  titulo: 'Panel del investigador',
                  subtitulo: 'Las composteras de todos los participantes',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => InvestigadorPage(estado: estado)),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              const SeccionTitulo(texto: 'Evaluación del sistema'),
              _opcion(
                context,
                icono: Icons.star_outline,
                titulo: 'Usabilidad (SUS)',
                subtitulo: 'Cuestionario de 10 ítems · puntaje sobre 100',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SusPage(estado: estado)),
                ),
              ),
              _opcion(
                context,
                icono: Icons.fact_check_outlined,
                titulo: 'Funcionalidad',
                subtitulo: 'Casos de prueba ejecutados',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => FuncionalidadPage(estado: estado)),
                ),
              ),
              const SizedBox(height: 18),
              const SeccionTitulo(texto: 'Configuración'),
              _opcion(
                context,
                icono: Icons.dns_outlined,
                titulo: 'Servidor de la API',
                subtitulo: estado.api.baseUrl,
                onTap: () => _editarServidor(context),
              ),
              _opcion(
                context,
                icono: Icons.info_outline,
                titulo: 'Acerca de',
                subtitulo: 'Versión ${AppConfig.version}',
                onTap: () => _acercaDe(context),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => _cerrarSesion(context),
                icon: const Icon(Icons.logout, color: Color(0xFFC62828)),
                label: const Text('Cerrar sesión', style: TextStyle(color: Color(0xFFC62828))),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: const BorderSide(color: Color(0xFFE0A5A0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _opcion(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icono, color: Tema.verde),
        title: Text(titulo, style: const TextStyle(fontSize: 14)),
        subtitle: Text(
          subtitulo,
          style: const TextStyle(fontSize: 11.5),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
      ),
    );
  }

  Future<void> _editarServidor(BuildContext context) async {
    final controlador = TextEditingController(text: estado.api.baseUrl);
    final formKey = GlobalKey<FormState>();

    final guardado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Servidor de la API'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Dirección del backend. Cámbiela si usa un servidor local en la misma red del ESP32.',
                style: TextStyle(fontSize: 12, color: Tema.textoSecundario),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controlador,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(hintText: 'https://…'),
                validator: (valor) {
                  final texto = (valor ?? '').trim();
                  if (!texto.startsWith('http')) return 'Debe iniciar con http:// o https://';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(contexto).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(contexto).pop(true), child: const Text('Guardar')),
        ],
      ),
    );

    if (guardado != true || !context.mounted) return;
    final error = await estado.cambiarApi(controlador.text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Servidor actualizado: ${estado.api.baseUrl}')),
    );
  }

  Future<void> _acercaDe(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (contexto) => AlertDialog(
        icon: const Icon(Icons.eco, color: Tema.verde, size: 34),
        title: const Text('Compost IoT'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Compost IoT monitorea la temperatura, la humedad y el pH de tu compostera '
              'y te avisa cuando algún valor sale del rango recomendado.',
              style: TextStyle(fontSize: 12.5, height: 1.45),
            ),
            SizedBox(height: 12),
            Text(
              'Qué datos se guardan',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 3),
            Text(
              'Las mediciones del sensor, las alertas y las fichas que registres quedan '
              'asociadas a tu cuenta y se usan únicamente para el seguimiento de tu compostera.',
              style: TextStyle(fontSize: 11.5, height: 1.4, color: Tema.textoSecundario),
            ),
            SizedBox(height: 12),
            Text('Versión ${AppConfig.version}', style: TextStyle(fontSize: 11)),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.of(contexto).pop(), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Desea salir de su cuenta?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(contexto).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(contexto).pop(true), child: const Text('Salir')),
        ],
      ),
    );

    if (confirmar == true) {
      await estado.salir();
    }
  }
}
