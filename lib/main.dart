import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const CompostApp());
}

class CompostApp extends StatelessWidget {
  const CompostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitoreo de Compostaje IoT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const CompostHomePage(),
    );
  }
}

class CompostHomePage extends StatefulWidget {
  const CompostHomePage({super.key});

  @override
  State<CompostHomePage> createState() => _CompostHomePageState();
}

class _CompostHomePageState extends State<CompostHomePage> {
  // Endpoint de producción en Render
  final String _apiUrl = 'https://compost-iot-backend.onrender.com/api/mediciones/ultima';
  
  bool _isLoading = false;
  String _errorMessage = '';
  Map<String, dynamic>? _lastMeasurement;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchMediciones(showLoading: true);

    // Auto-refresh en tiempo real cada 3 segundos
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchMediciones(showLoading: false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMediciones({bool showLoading = false}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        // Maneja respuestas tanto en formato envuelto { status, data } como directas
        if (jsonResponse is Map<String, dynamic>) {
          setState(() {
            _lastMeasurement = jsonResponse.containsKey('data') 
                ? jsonResponse['data'] as Map<String, dynamic> 
                : jsonResponse;
            _errorMessage = '';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error del servidor: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
      });
    } finally {
      if (showLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compost IoT Monitor'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchMediciones(showLoading: true),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.eco, size: 48, color: Colors.green),
                    const SizedBox(height: 8),
                    Text(
                      'Estado del Compostador',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage.isNotEmpty)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_lastMeasurement != null)
              Expanded(
                child: ListView(
                  children: [
                    _buildMetricTile(
                      icon: Icons.thermostat,
                      label: 'Temperatura',
                      value: '${_lastMeasurement!['temperatura'] ?? 'N/A'} °C',
                      color: Colors.orange,
                    ),
                    _buildMetricTile(
                      icon: Icons.water_drop,
                      label: 'Humedad',
                      value: '${_lastMeasurement!['humedad'] ?? 'N/A'} %',
                      color: Colors.blue,
                    ),
                    if (_lastMeasurement!.containsKey('ph'))
                      _buildMetricTile(
                        icon: Icons.science,
                        label: 'pH',
                        value: '${_lastMeasurement!['ph']}',
                        color: Colors.purple,
                      ),
                  ],
                ),
              )
            else
              const Center(
                child: Text('No hay mediciones registradas'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}