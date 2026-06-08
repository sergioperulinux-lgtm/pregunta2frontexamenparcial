// lib/screens/home_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

// ┌─────────────────────────────────────────────────────────┐
// │  ⚠️  CAMBIAR ESTA URL por la de tu backend en Render   │
// └─────────────────────────────────────────────────────────┘
const String API_URL = 'https://TU-BACKEND.onrender.com';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File?                    _imagen;
  bool                     _cargando = false;
  Map<String, dynamic>?    _resultado;
  String?                  _error;
  final ImagePicker        _picker = ImagePicker();

  // ── Colores por nivel de demencia ──────────────────────────
  Color _colorClase(String clase) {
    if (clase.contains('Non'))      return const Color(0xFF27AE60);
    if (clase.contains('Very'))     return const Color(0xFFF39C12);
    if (clase.contains('Mild'))     return const Color(0xFFE67E22);
    if (clase.contains('Moderate')) return const Color(0xFFE74C3C);
    return Colors.grey;
  }

  // ── Seleccionar imagen ─────────────────────────────────────
  Future<void> _elegirImagen(ImageSource fuente) async {
    try {
      final XFile? xfile = await _picker.pickImage(
        source: fuente,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 90,
      );
      if (xfile != null) {
        setState(() {
          _imagen    = File(xfile.path);
          _resultado = null;
          _error     = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Error al seleccionar imagen: $e');
    }
  }

  // ── Enviar al backend y obtener predicción ─────────────────
  Future<void> _analizar() async {
    if (_imagen == null) return;
    setState(() { _cargando = true; _error = null; _resultado = null; });

    try {
      // Convertir imagen a base64
      final bytes  = await _imagen!.readAsBytes();
      final b64    = base64Encode(bytes);

      // POST al backend Flask
      final resp = await http.post(
        Uri.parse('$API_URL/predecir'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'imagen_base64': b64}),
      ).timeout(const Duration(seconds: 40));

      if (resp.statusCode == 200) {
        setState(() {
          _resultado = jsonDecode(resp.body);
          _cargando  = false;
        });
      } else {
        setState(() {
          _error    = 'Error del servidor: ${resp.statusCode}';
          _cargando = false;
        });
      }
    } on SocketException {
      setState(() {
        _error    = 'Sin conexión. Verifica que el backend esté activo.';
        _cargando = false;
      });
    } catch (e) {
      setState(() { _error = 'Error: $e'; _cargando = false; });
    }
  }

  // ── UI ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          'Clasificador Alzheimer CNN',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        centerTitle: true,
        elevation: 3,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _cardInfo(),
            const SizedBox(height: 14),
            _cardImagen(),
            const SizedBox(height: 14),
            _botonesAccion(),
            const SizedBox(height: 14),
            if (_cargando)  _cardCargando(),
            if (_error != null) _cardError(),
            if (_resultado != null) _cardResultado(),
          ],
        ),
      ),
    );
  }

  // ── Card: información superior ─────────────────────────────
  Widget _cardInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.biotech, color: Colors.white, size: 42),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detección con Red Neuronal',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 4),
                Text('Sube una MRI cerebral para detectar\nel nivel de demencia por Alzheimer',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Card: área de imagen ───────────────────────────────────
  Widget _cardImagen() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: double.infinity,
          height: 210,
          child: _imagen != null
              ? Image.file(_imagen!, fit: BoxFit.cover)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_search, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 10),
                    Text('Selecciona una imagen MRI',
                        style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('JPG o PNG',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Botones seleccionar / analizar ─────────────────────────
  Widget _botonesAccion() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _elegirImagen(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galería'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _elegirImagen(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Cámara'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: (_imagen != null && !_cargando) ? _analizar : null,
            icon: const Icon(Icons.manage_search, color: Colors.white),
            label: const Text('ANALIZAR CON CNN',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Card: cargando ─────────────────────────────────────────
  Widget _cardCargando() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          children: [
            CircularProgressIndicator(color: Color(0xFF1565C0)),
            SizedBox(height: 16),
            Text('Procesando con la CNN...',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ── Card: error ────────────────────────────────────────────
  Widget _cardError() {
    return Card(
      color: Colors.red[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card: resultado principal ──────────────────────────────
  Widget _cardResultado() {
    final clase      = _resultado!['clase_predicha'] as String;
    final confianza  = (_resultado!['confianza'] as num).toDouble();
    final descripcion = _resultado!['descripcion'] as String;
    final nivel      = _resultado!['nivel'] as int;
    final probs      = _resultado!['probabilidades'] as Map<String, dynamic>;
    final color      = _colorClase(clase);

    return Column(
      children: [
        // ── Resultado principal ────────────────────
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: color, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(Icons.check_circle_outline, color: color, size: 36),
                ),
                const SizedBox(height: 14),
                Text(clase,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                    textAlign: TextAlign.center),
                const SizedBox(height: 6),
                // Indicador de nivel
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: CircleAvatar(
                      radius: 6,
                      backgroundColor: i <= nivel ? color : Colors.grey[300],
                    ),
                  )),
                ),
                const SizedBox(height: 10),
                Text('Confianza: ${confianza.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 15, color: Colors.grey[700])),
                const SizedBox(height: 8),
                Text(descripcion,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Barras de probabilidad ─────────────────
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Probabilidades por clase',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 14),
                ...probs.entries.map((e) {
                  final prob   = (e.value as num).toDouble();
                  final barColor = _colorClase(e.key);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key, style: const TextStyle(fontSize: 12)),
                            Text('${prob.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: prob / 100,
                            minHeight: 9,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Aviso médico ───────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Resultado orientativo. Siempre consultar a un médico especialista.',
                  style: TextStyle(fontSize: 12, color: Colors.brown),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
