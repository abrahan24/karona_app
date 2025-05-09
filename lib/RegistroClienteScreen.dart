// ignore: file_names
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// Formulario para Cliente
class RegistroClienteScreen extends StatefulWidget {
  const RegistroClienteScreen({super.key});

  @override
  State<RegistroClienteScreen> createState() => _RegistroClienteScreenState();
}

class _RegistroClienteScreenState extends State<RegistroClienteScreen> {
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
  
  // Imágenes
  File? fotoRostro;
  File? fotoDocumento;
  final ImagePicker picker = ImagePicker();
  
  // Lista de géneros
  final List<String> generos = ['Masculino', 'Femenino', 'Otro'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cremaClaro,
      appBar: AppBar(
        title: const Text('Registro de Cliente'),
        backgroundColor: verdeAmazonico,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Campos del formulario
                TextFormField(
                  controller: nombresController,
                  decoration: _inputDecoration('Nombres'),
                  validator: (value) => value!.isEmpty ? 'Ingrese sus nombres' : null,
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: apellidosController,
                  decoration: _inputDecoration('Apellidos'),
                  validator: (value) => value!.isEmpty ? 'Ingrese sus apellidos' : null,
                ),
                const SizedBox(height: 15),
                
                DropdownButtonFormField<String>(
                  value: generoSeleccionado,
                  decoration: _inputDecoration('Género'),
                  items: generos.map((genero) {
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
                  validator: (value) => value!.isEmpty ? 'Ingrese su dirección' : null,
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
                  controller: passwordController,
                  obscureText: true,
                  decoration: _inputDecoration('Contraseña'),
                  validator: (value) => value!.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: celularController,
                  decoration: _inputDecoration('Celular'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? 'Ingrese su celular' : null,
                ),
                const SizedBox(height: 20),
                
                // Sección de imágenes
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
        
        ElevatedButton.icon(
          icon: const Icon(Icons.camera_alt, color: Colors.white),
          label: const Text('Tomar foto de rostro', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: verdeAmazonico,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: () => _tomarFoto(true),
        ),
        const SizedBox(height: 10),
        
        ElevatedButton.icon(
          icon: const Icon(Icons.credit_card, color: Colors.white),
          label: const Text('Tomar foto de documento', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: verdeAmazonico,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: () => _tomarFoto(false),
        ),
        
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
      ],
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

  Future<void> _tomarFoto(bool esRostro) async {
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      setState(() {
        if (esRostro) {
          fotoRostro = File(image.path);
        } else {
          fotoDocumento = File(image.path);
        }
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (fotoRostro == null || fotoDocumento == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe tomar ambas fotos para continuar')));
        return;
      }
      
      // Aquí iría la lógica para registrar al cliente
      print('Cliente registrado: ${nombresController.text} ${apellidosController.text}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro exitoso')));
      
      // Navegar a la pantalla principal
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}