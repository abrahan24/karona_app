import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:karona_app/CameraFaceCaptureScreen.dart';

class RegistroConductorScreen extends StatefulWidget {
  const RegistroConductorScreen({super.key});

  @override
  State<RegistroConductorScreen> createState() =>
      _RegistroConductorScreenState();
}

class _RegistroConductorScreenState extends State<RegistroConductorScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color verdeAmazonico = const Color(0xFF006d5b);
  final Color cremaClaro = Color.fromARGB(255, 37, 37, 37);

  // Controladores
  final TextEditingController nombresController = TextEditingController();
  final TextEditingController apellidosController = TextEditingController();
  String generoSeleccionado = 'Masculino';
  final TextEditingController direccionController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController celularController = TextEditingController();
  final TextEditingController licenciaController = TextEditingController();
  final TextEditingController categoriaLicenciaController =
      TextEditingController();
  final TextEditingController experienciaController = TextEditingController();

  // Imágenes
  File? fotoRostro;
  File? fotoDocumento;
  File? fotoLicencia;
  final ImagePicker picker = ImagePicker();

  // OCR
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isProcessingImage = false;
  String _ultimoTextoReconocido = '';

  // Lista de géneros
  final List<String> generos = ['Masculino', 'Femenino', 'Otro'];

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cremaClaro,
      appBar: AppBar(
        title: const Text('Registro de Conductor'),
        backgroundColor: verdeAmazonico,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Campos de información personal
                    TextFormField(
                      controller: nombresController,
                      decoration: _inputDecoration('Nombres'),
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Ingrese sus nombres' : null,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: apellidosController,
                      decoration: _inputDecoration('Apellidos'),
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Ingrese sus apellidos' : null,
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: generoSeleccionado,
                      decoration: _inputDecoration('Género'),
                      items:
                          generos.map((genero) {
                            return DropdownMenuItem(
                              value: genero,
                              child: Text(genero),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          generoSeleccionado = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: direccionController,
                      decoration: _inputDecoration('Dirección'),
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Ingrese su dirección' : null,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: correoController,
                      decoration: _inputDecoration('Correo electrónico'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value!.isEmpty) return 'Ingrese su correo';
                        if (!value.contains('@')) return 'Correo no válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: celularController,
                      decoration: _inputDecoration('Celular'),
                      keyboardType: TextInputType.phone,
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Ingrese su celular' : null,
                    ),
                    const SizedBox(height: 15),

                    // Campos específicos de conductor
                    TextFormField(
                      controller: licenciaController,
                      decoration: _inputDecoration('Número de licencia'),
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Ingrese su licencia' : null,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: categoriaLicenciaController,
                      decoration: _inputDecoration('Categoría de licencia'),
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Ingrese la categoría' : null,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: experienciaController,
                      decoration: _inputDecoration('Años de experiencia'),
                      keyboardType: TextInputType.number,
                      validator:
                          (value) =>
                              value!.isEmpty
                                  ? 'Ingrese años de experiencia'
                                  : null,
                    ),
                    const SizedBox(height: 20),

                    // Sección de imágenes con OCR
                    _buildImageSection(),

                    const SizedBox(height: 30),

                    // Botón de registro
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: verdeAmazonico,
                        ),
                        onPressed: _submitForm,
                        child: const Text(
                          'Registrarme',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Indicador de procesamiento
          if (_isProcessingImage)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documentación requerida:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),

        // Botones para fotos con OCR
        _buildPhotoButton(
          icon: Icons.camera_alt,
          label: 'Tomar foto de rostro',
          onPressed: () async {
            final foto = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CameraFaceCaptureScreen()),
            );

            if (foto != null) {
              setState(() {
                fotoRostro = foto;
              });
            }
          },
        ),

        _buildPhotoButton(
          icon: Icons.credit_card,
          label: 'Tomar foto de documento',
          onPressed: () => _tomarFoto(1),
        ),

        _buildPhotoButton(
          icon: Icons.card_membership,
          label: 'Tomar foto de licencia',
          onPressed: () => _tomarFoto(2),
        ),

        // Vistas previas de las fotos
        if (fotoRostro != null)
          _buildImagePreview('Foto de rostro:', fotoRostro!),
        if (fotoDocumento != null)
          _buildImagePreview('Foto de documento:', fotoDocumento!),
        if (fotoLicencia != null)
          _buildImagePreview('Foto de licencia:', fotoLicencia!),
      ],
    );
  }

  Widget _buildPhotoButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: verdeAmazonico,
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildImagePreview(String label, File image) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 5),
        Image.file(image, height: 300, width: 150, fit: BoxFit.cover),
      ],
    );
  }

  Future<void> _tomarFoto(int tipo) async {
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() => _isProcessingImage = true);

      try {
        final file = File(image.path);
        final inputImage = InputImage.fromFile(file);
        final recognizedText = await _textRecognizer.processImage(inputImage);

        setState(() {
          _ultimoTextoReconocido = recognizedText.text;
          switch (tipo) {
            case 0: // Foto de rostro
              fotoRostro = file;
              break;
            case 1: // Foto de documento
              fotoDocumento = file;
              _procesarDocumento(recognizedText);
              break;
            case 2: // Foto de licencia
              fotoLicencia = file;
              _procesarLicencia(recognizedText);
              break;
          }
        });

        _mostrarTextoReconocido(recognizedText.text);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar imagen: ${e.toString()}')),
        );
      } finally {
        setState(() => _isProcessingImage = false);
      }
    }
  }

  void _procesarDocumento(RecognizedText recognizedText) {
    final textoCompleto = recognizedText.text;

    // Buscar nombres (patrón simple)
    final nombreRegex = RegExp(r'([A-Z][a-z]+(?:\s[A-Z][a-z]+)+)');
    final nombreMatch = nombreRegex.firstMatch(textoCompleto);
    if (nombreMatch != null && nombresController.text.isEmpty) {
      nombresController.text = nombreMatch.group(1)!;
    }

    // Buscar apellidos (similar a nombres)
    final apellidoRegex = RegExp(r'([A-Z][a-z]+\s[A-Z][a-z]+)$');
    final apellidoMatch = apellidoRegex.firstMatch(textoCompleto);
    if (apellidoMatch != null && apellidosController.text.isEmpty) {
      apellidosController.text = apellidoMatch.group(1)!;
    }

    // Buscar número de documento (ejemplo para DNI)
    final docRegex = RegExp(r'[0-9]{8}');
    final docMatches = docRegex.allMatches(textoCompleto);
    if (docMatches.isNotEmpty) {
      // Usar el número más largo encontrado (podría ser el DNI)
      final doc = docMatches
          .map((m) => m.group(0))
          .reduce((a, b) => a!.length > b!.length ? a : b);
      // Puedes asignarlo a algún campo si es necesario
    }
  }

  void _procesarLicencia(RecognizedText recognizedText) {
    final textoCompleto = recognizedText.text;

    // Buscar número de licencia (formato común)
    final licenciaRegex = RegExp(r'[A-Z0-9]{7,15}');
    final licenciaMatches = licenciaRegex.allMatches(textoCompleto);
    if (licenciaMatches.isNotEmpty) {
      licenciaController.text = licenciaMatches.first.group(0)!;
    }

    // Buscar categoría (ej. A, B, C, etc.)
    final categoriaRegex = RegExp(r'Categor[ií]a[:]?\s*([A-Z])');
    final catMatch = categoriaRegex.firstMatch(textoCompleto);
    if (catMatch != null) {
      categoriaLicenciaController.text = catMatch.group(1)!;
    }

    // Buscar fecha de emisión (ejemplo)
    final fechaRegex = RegExp(r'(\d{2}[/-]\d{2}[/-]\d{4})');
    final fechaMatch = fechaRegex.firstMatch(textoCompleto);
    if (fechaMatch != null) {
      // Podrías procesar la fecha si es necesario
    }
  }

  void _mostrarTextoReconocido(String texto) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Texto reconocido'),
            content: SingleChildScrollView(child: Text(texto)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: verdeAmazonico, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (fotoRostro == null || fotoDocumento == null || fotoLicencia == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe tomar todas las fotos requeridas'),
          ),
        );
        return;
      }

      // Aquí iría la lógica para registrar al conductor
      print('''
        Conductor registrado:
        Nombre: ${nombresController.text} ${apellidosController.text}
        Licencia: ${licenciaController.text} (${categoriaLicenciaController.text})
        Documentos: 
          - Rostro: ${fotoRostro!.path}
          - Documento: ${fotoDocumento!.path}
          - Licencia: ${fotoLicencia!.path}
        Texto reconocido: $_ultimoTextoReconocido
      ''');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registro exitoso')));

      // Navegar a la pantalla principal
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
