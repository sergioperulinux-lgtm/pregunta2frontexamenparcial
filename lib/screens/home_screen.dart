// lib/screens/home_screen.dart
// ✅ Corregido para Flutter Web — usa file_picker en vez de image_picker
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

// ── URL del backend en Render ──────────────────────────────
const String API_URL = 'https://pregunta2examenparcial.onrender.com';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Uint8List?            _imagenBytes;
  String?               _nombreArchivo;
  bool                  _cargando = false;
  Map<String, dynamic>? _resultado;
  String?               _error;

  // ── Color por clase ────────────────────────────────────────
  Color _colorClase(String clase) {
    if (clase.contains('Non'))      return const Color(0xFF27AE60);
    if (clase.contains('Very'))     return const Color(0xFFF39C12);
    if (clase.contains('Mild'))     return const Color(0xFFE67E22);
    if (clase.contains('Moderate')) return const Color(0xFFE74C3C);
    return Colors.grey;
  }

  // ── Seleccionar imagen con file_picker ─────────────────────
  // file_picker abre el explorador de archivos nativo del navegador
  Future<void> _elegirImagen() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        withData: true, // ← carga los bytes directamente, clave para Web
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _imagenBytes    = result.files.single.bytes!;
          _nombreArchivo  = result.files.single.name;
          _resultado      = null;
          _error          = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Error al seleccionar imagen: $e');
    }
  }

  // ── Enviar al backend ──────────────────────────────────────
  Future<void> _analizar() async {
    if (_imagenBytes == null) return;
    setState(() { _cargando = true; _error = null; _resultado = null; });

    try {
      final b64  = base64Encode(_imagenBytes!);
      final resp = await http.post(
        Uri.parse('$API_URL/predecir'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'imagen_base64': b64}),
      ).timeout(const Duration(seconds: 60));

      if (resp.statusCode == 200) {
        setState(() { _resultado = jsonDecode(resp.body); _cargando = false; });
      } else {
        setState(() { _error = 'Error del servidor: ${resp.statusCode}'; _cargando = false; });
      }
    } catch (e) {
      setState(() {
        _error    = 'Error de conexión. El backend puede estar iniciando (espera 30s y reintenta).\n$e';
        _cargando = false;
      });
    }
  }

  // ── BUILD ──────────────────────────────────────────────────
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
      body: Center(
        child: ConstrainedBox(
          // Limitar ancho en pantallas grandes (se ve mejor)
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _cardInfo(),
                const SizedBox(height: 16),
                _cardImagen(),
                const SizedBox(height: 16),
                _botonesAccion(),
                const SizedBox(height: 16),
                if (_cargando)          _cardCargando(),
                if (_error != null)     _cardError(),
                if (_resultado != null) _cardResultado(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Card info ──────────────────────────────────────────────
  Widget _cardInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF1E88E5)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.biotech, color: Colors.white, size: 44),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detección con Red Neuronal CNN',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                SizedBox(height: 5),
                Text(
                  'Sube una imagen MRI cerebral para detectar\nel nivel de demencia por Alzheimer',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Card imagen ────────────────────────────────────────────
  Widget _cardImagen() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: double.infinity,
          height: 240,
          child: _imagenBytes != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_imagenBytes!, fit: BoxFit.contain),
                    // Nombre del archivo arriba
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        color: Colors.black45,
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        child: Text(
                          _nombreArchivo ?? '',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_search, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text('Haz clic en "Subir Imagen MRI"',
                        style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('Formatos aceptados: JPG, JPEG, PNG',
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Botones acción ─────────────────────────────────────────
  Widget _botonesAccion() {
    return Column(
      children: [
        // Botón principal para subir imagen
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _elegirImagen,
            icon: const Icon(Icons.upload_file, size: 22),
            label: const Text('SUBIR IMAGEN MRI',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1565C0), width: 2),
              foregroundColor: const Color(0xFF1565C0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Botón analizar
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: (_imagenBytes != null && !_cargando) ? _analizar : null,
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

  // ── Card cargando ──────────────────────────────────────────
  Widget _cardCargando() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          children: [
            CircularProgressIndicator(color: Color(0xFF1565C0)),
            SizedBox(height: 16),
            Text('Analizando imagen con la CNN...',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            SizedBox(height: 4),
            Text('Puede tardar hasta 60 segundos la primera vez',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ── Card error ─────────────────────────────────────────────
  Widget _cardError() {
    return Card(
      color: Colors.red[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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

  // ── Card resultado ─────────────────────────────────────────
  Widget _cardResultado() {
    final clase       = _resultado!['clase_predicha'] as String;
    final confianza   = (_resultado!['confianza'] as num).toDouble();
    final descripcion = _resultado!['descripcion'] as String;
    final nivel       = _resultado!['nivel'] as int;
    final probs       = _resultado!['probabilidades'] as Map<String, dynamic>;
    final color       = _colorClase(clase);

    return Column(
      children: [
        // Resultado principal
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
                  radius: 32,
                  backgroundColor: color.withOpacity(0.12),
                  child:
                      Icon(Icons.check_circle_outline, color: color, size: 38),
                ),
                const SizedBox(height: 14),
                Text(clase,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                // Indicador de nivel (puntos)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: CircleAvatar(
                        radius: 7,
                        backgroundColor:
                            i <= nivel ? color : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text('Confianza: ${confianza.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                const SizedBox(height: 8),
                Text(descripcion,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Barras de probabilidad
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Probabilidades por clase',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 14),
                ...probs.entries.map((e) {
                  final prob     = (e.value as num).toDouble();
                  final barColor = _colorClase(e.key);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                            Text('${prob.toStringAsFixed(1)}%',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: barColor)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: prob / 100,
                            minHeight: 10,
                            backgroundColor: Colors.grey[200],
                            valueColor:
                                AlwaysStoppedAnimation<Color>(barColor),
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

        // Aviso médico
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
        const SizedBox(height: 20),
      ],
    );
  }
}
