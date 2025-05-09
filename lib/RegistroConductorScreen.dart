// ignore: file_names
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// Formulario para Conductor (similar al de cliente pero con campos adicionales)
class RegistroConductorScreen extends StatefulWidget {
  const RegistroConductorScreen({super.key});

  @override
  State<RegistroConductorScreen> createState() => _RegistroConductorScreenState();
}

class _RegistroConductorScreenState extends State<RegistroConductorScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color verdeAmazonico = const Color(0xFF006d5b);
  final Color cremaClaro = Color.fromARGB(255, 37, 37, 37);

  // Controladores (incluye todos los de cliente más los específicos de conductor)
  final TextEditingController nombresController = TextEditingController();
  final TextEditingController apellidosController = TextEditingController();
  String generoSeleccionado = 'Masculino';
  final TextEditingController direccionController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController celularController = TextEditingController();
  final TextEditingController licenciaController = TextEditingController();
  final TextEditingController categoriaLicenciaController = TextEditingController();
  final TextEditingController experienciaController = TextEditingController();
  
  // Imágenes
  File? fotoRostro;
  File? fotoDocumento;
  File? fotoLicencia;
  final ImagePicker picker = ImagePicker();
  
  // Lista de géneros
  final List<String> generos = ['Masculino', 'Femenino', 'Otro'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cremaClaro,
      appBar: AppBar(
        title: const Text('Registro de Conductor'),
        backgroundColor: verdeAmazonico,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Campos comunes
                TextFormField(
                  controller: nombresController,
                  decoration: _inputDecoration('Nombres'),
                  validator: (value) => value!.isEmpty ? 'Ingrese sus nombres' : null,
                ),
                const SizedBox(height: 15),
                
                // ... (otros campos comunes como en RegistroClienteScreen)
                
                // Campos específicos de conductor
                TextFormField(
                  controller: licenciaController,
                  decoration: _inputDecoration('Número de licencia'),
                  validator: (value) => value!.isEmpty ? 'Ingrese su licencia' : null,
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: categoriaLicenciaController,
                  decoration: _inputDecoration('Categoría de licencia'),
                  validator: (value) => value!.isEmpty ? 'Ingrese la categoría' : null,
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: experienciaController,
                  decoration: _inputDecoration('Años de experiencia'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Ingrese años de experiencia' : null,
                ),
                const SizedBox(height: 20),
                
                // Sección de imágenes (incluye foto de licencia)
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
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documentación requerida:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white),
        ),
        const SizedBox(height: 10),
        
        // Botones para fotos (similar a RegistroClienteScreen pero con adicional para licencia)
        ElevatedButton.icon(
          icon: const Icon(Icons.camera_alt, color: Colors.white),
          label: const Text('Tomar foto de rostro', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: verdeAmazonico,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: () => _tomarFoto(0),
        ),
        const SizedBox(height: 10),
        
        ElevatedButton.icon(
          icon: const Icon(Icons.credit_card, color: Colors.white),
          label: const Text('Tomar foto de documento', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: verdeAmazonico,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: () => _tomarFoto(1),
        ),
        const SizedBox(height: 10),
        
        ElevatedButton.icon(
          icon: const Icon(Icons.card_membership, color: Colors.white),
          label: const Text('Tomar foto de licencia', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: verdeAmazonico,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: () => _tomarFoto(2),
        ),
        
        // Vistas previas de las fotos
        if (fotoRostro != null) ...[
          const SizedBox(height: 10),
          const Text('Foto de rostro:'),
          Image.file(fotoRostro!, height: 100, width: 100, fit: BoxFit.cover),
        ],
        
        if (fotoDocumento != null) ...[
          const SizedBox(height: 10),
          const Text('Foto de documento:'),
          Image.file(fotoDocumento!, height: 100, width: 150, fit: BoxFit.cover),
        ],
        
        if (fotoLicencia != null) ...[
          const SizedBox(height: 10),
          const Text('Foto de licencia:'),
          Image.file(fotoLicencia!, height: 100, width: 150, fit: BoxFit.cover),
        ],
      ],
    );
  }

  Future<void> _tomarFoto(int tipo) async {
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      setState(() {
        switch (tipo) {
          case 0:
            fotoRostro = File(image.path);
            break;
          case 1:
            fotoDocumento = File(image.path);
            break;
          case 2:
            fotoLicencia = File(image.path);
            break;
        }
      });
    }
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
          const SnackBar(content: Text('Debe tomar todas las fotos requeridas')));
        return;
      }
      
      // Aquí iría la lógica para registrar al conductor
      print('Conductor registrado: ${nombresController.text} ${apellidosController.text}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro exitoso')));
      
      // Navegar a la pantalla principal
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}