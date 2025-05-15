import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'CameraCardCaptureScreen.dart';

class RegistroClienteScreen extends StatefulWidget {
  const RegistroClienteScreen({super.key});

  @override
  State<RegistroClienteScreen> createState() => _RegistroClienteScreenState();
}

class _RegistroClienteScreenState extends State<RegistroClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color verdeAmazonico = const Color(0xFF006d5b);
  final Color cremaClaro = const Color.fromARGB(255, 37, 37, 37);

  File? fotoRostro;
  File? fotoAnverso;
  File? fotoReverso;
  bool puedeContinuar = false;

  final ImagePicker picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cremaClaro,
      appBar: AppBar(
        title: const Text('Verificación de Identidad'),
        backgroundColor: verdeAmazonico,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildBotonFoto(
                  label: 'Foto de rostro',
                  icon: Icons.face,
                  foto: fotoRostro,
                  esDocumento: false,
                  onPressed: () => _tomarFoto(0),
                ),
                const SizedBox(height: 20),
                _buildBotonFoto(
                  label: 'Cédula de Identidad (Anverso)',
                  icon: Icons.credit_card,
                  foto: fotoAnverso,
                  esDocumento: true,
                  onPressed: () => _tomarFoto(1),
                ),
                const SizedBox(height: 20),
                _buildBotonFoto(
                  label: 'Cédula de Identidad (Reverso)',
                  icon: Icons.credit_card_outlined,
                  foto: fotoReverso,
                  esDocumento: true,
                  onPressed: () => _tomarFoto(2),
                ),
                const SizedBox(height: 30),
                AnimatedOpacity(
                  opacity: puedeContinuar ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 500),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: puedeContinuar ? verdeAmazonico : Colors.grey,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                    ),
                    onPressed: puedeContinuar ? _submitForm : null,
                    child: const Text(
                      'Siguiente',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotonFoto({
    required String label,
    required IconData icon,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  height: 144,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _tomarFoto(int tipoFoto) async {
    if (tipoFoto == 0) {
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        setState(() {
          fotoRostro = File(image.path);
          _verificarCompletitud();
        });
      }
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CameraCardCaptureScreen(),
        ),
      );

      if (result != null && result is File) {
        setState(() {
          if (tipoFoto == 1) {
            fotoAnverso = result;
          } else if (tipoFoto == 2) {
            fotoReverso = result;
          }
          _verificarCompletitud();
        });
      }
    }
  }

  void _verificarCompletitud() {
    puedeContinuar = fotoRostro != null && fotoAnverso != null && fotoReverso != null;
  }

  void _submitForm() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Documentación verificada')),
    );
  }
}
