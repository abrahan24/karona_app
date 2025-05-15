import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:karona_app/CameraCardCaptureScreen.dart';
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

  // Imágenes
  File? fotoRostro;
  File? fotoDocumentoAnverso;
  File? fotoDocumentoReverso;
  File? fotoLicenciaAnverso;
  File? fotoLicenciaReverso;
  bool puedeContinuar = false;

  final ImagePicker picker = ImagePicker();

  // OCR
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isProcessingImage = false;
  // ignore: unused_field
  String _ultimoTextoReconocido = '';

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

        // Botón de rostro con vista previa incluida
        _buildPhotoButton(
          icon: Icons.camera_alt,
          label: 'Tomar foto de rostro',
          foto: fotoRostro,
          esDocumento: false,
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
        const SizedBox(height: 20),

        // Botón de documento
        _buildPhotoButton(
          icon: Icons.credit_card,
          label: 'Tomar foto de documento',
          foto: fotoDocumentoAnverso,
          esDocumento: true,
          onPressed: () => _tomarFoto(1),
        ),
        const SizedBox(height: 20),

        // Botón de licencia
        _buildPhotoButton(
          icon: Icons.card_membership,
          label: 'Tomar foto de licencia',
          foto: fotoLicenciaAnverso,
          esDocumento: true,
          onPressed: () => _tomarFoto(2),
        ),
      ],
    );
  }

  Widget _buildPhotoButton({
    required IconData icon,
    required String label,
    required File? foto,
    required bool esDocumento,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: verdeAmazonico,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onPressed: onPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(color: Colors.white)),
                  if (foto != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (foto != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  foto,
                  width: esDocumento ? 224 : 144,
                  height: esDocumento ? 144 : 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildImagePreview(String label, File image, VoidCallback onDelete) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 5),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  image,
                  height: 150,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    _confirmDelete(context: context, onConfirm: onDelete);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete({
    required BuildContext context,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar esta foto?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      onConfirm();
    }
  }

  Future<void> _tomarFoto(int tipo) async {
    setState(() => _isProcessingImage = true);

    try {
      File? file;

      if (tipo == 1 || tipo == 2) {
        // Abrir la cámara de documentos/licencia
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CameraCardCaptureScreen(),
          ),
        );

        if (result != null && result is File) {
          file = result;
        } else {
          setState(() => _isProcessingImage = false);
          return; // Se canceló la foto
        }
      } else {
        // Foto de rostro desde cámara directa
        final XFile? image = await picker.pickImage(source: ImageSource.camera);
        if (image != null) {
          file = File(image.path);
        } else {
          setState(() => _isProcessingImage = false);
          return;
        }
      }

      if (file != null) {
        if (tipo == 1 || tipo == 2) {
          // Procesar OCR
          final inputImage = InputImage.fromFile(file);
          final recognizedText = await _textRecognizer.processImage(inputImage);

          setState(() {
            _ultimoTextoReconocido = recognizedText.text;

            if (tipo == 1) {
              fotoDocumentoAnverso = file;
            } else {
              fotoLicenciaAnverso = file;
            }
          });

          _mostrarTextoReconocido(recognizedText.text);
        } else if (tipo == 0) {
          setState(() {
            fotoRostro = file;
          });
        }

        _verificarCompletitud();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar imagen: ${e.toString()}')),
      );
    } finally {
      setState(() => _isProcessingImage = false);
    }
  }

  void _verificarCompletitud() {
    puedeContinuar =
        fotoRostro != null &&
        fotoDocumentoAnverso != null &&
        fotoDocumentoReverso != null &&
        fotoLicenciaAnverso != null &&
        fotoLicenciaReverso != null;
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

  // InputDecoration _inputDecoration(String hint) {
  //   return InputDecoration(
  //     hintText: hint,
  //     filled: true,
  //     fillColor: Colors.white,
  //     border: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(12),
  //       borderSide: BorderSide.none,
  //     ),
  //     focusedBorder: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(12),
  //       borderSide: BorderSide(color: verdeAmazonico, width: 2),
  //     ),
  //     contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
  //   );
  // }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (fotoRostro == null || fotoDocumentoAnverso == null || fotoLicenciaAnverso == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe tomar todas las fotos requeridas'),
          ),
        );
        return;
      }

      // Aquí iría la lógica para registrar al conductor

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registro exitoso')));

      // Navegar a la pantalla principal
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
