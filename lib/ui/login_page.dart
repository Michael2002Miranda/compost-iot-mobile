import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config.dart';
import 'tema.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.estado});

  final AppState estado;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _ocultaPassword = true;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _error = null;
    });

    final error = await widget.estado.entrar(_email.text, _password.text);

    if (!mounted) return;
    setState(() {
      _enviando = false;
      _error = error;
    });
  }

  void _abrirRegistro() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RegistroPage(estado: widget.estado)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(color: Tema.verdeClaro, shape: BoxShape.circle),
                      child: const Icon(Icons.eco, size: 40, color: Tema.verde),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Compost IoT',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Tema.verdeOscuro),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Monitoreo del compostaje en tiempo real',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: Tema.textoSecundario),
                  ),
                  const SizedBox(height: 28),
                  const Text('Bienvenido', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text(
                    'Inicia sesión para ver tu compostera',
                    style: TextStyle(fontSize: 13, color: Tema.textoSecundario),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.mail_outline, size: 20),
                    ),
                    validator: (valor) {
                      final texto = (valor ?? '').trim();
                      if (texto.isEmpty) return 'Ingrese su correo';
                      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(texto)) {
                        return 'El correo no es válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: _ocultaPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _entrar(),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _ocultaPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _ocultaPassword = !_ocultaPassword),
                      ),
                    ),
                    validator: (valor) =>
                        (valor ?? '').length < 6 ? 'Mínimo 6 caracteres' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF5C6C0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 18, color: Color(0xFFC62828)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF8E1F17)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _enviando ? null : _entrar,
                    child: _enviando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                          )
                        : const Text('Ingresar'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _enviando ? null : _abrirRegistro,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: Tema.verde,
                      side: const BorderSide(color: Tema.verde),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Crear cuenta'),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Universidad Privada Antenor Orrego · 2026',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Tema.textoSecundario),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key, required this.estado});

  final AppState estado;

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmar = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _error = null;
    });

    final error = await widget.estado.registrar(_nombre.text, _email.text, _password.text);

    if (!mounted) return;
    setState(() => _enviando = false);

    if (error == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada. Ya puedes registrar tu compostera.')),
      );
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Registra tus datos para acceder al monitoreo de tu compostera.',
                  style: TextStyle(fontSize: 13, color: Tema.textoSecundario),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _nombre,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                  validator: (valor) =>
                      (valor ?? '').trim().length < 3 ? 'Ingrese su nombre completo' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.mail_outline, size: 20),
                  ),
                  validator: (valor) {
                    final texto = (valor ?? '').trim();
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(texto)) {
                      return 'El correo no es válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                  ),
                  validator: (valor) =>
                      (valor ?? '').length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmar,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Repetir contraseña',
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                  ),
                  validator: (valor) =>
                      valor != _password.text ? 'Las contraseñas no coinciden' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: const TextStyle(color: Color(0xFFC62828), fontSize: 12.5)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _enviando ? null : _registrar,
                  child: _enviando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text('Crear cuenta'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Versión ${AppConfig.version}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Tema.textoSecundario),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
