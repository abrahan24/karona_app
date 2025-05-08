import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class RegistroWidget extends StatefulWidget {
  const RegistroWidget({super.key});

  @override
  State<RegistroWidget> createState() => _RegistroWidgetState();
}

class _RegistroWidgetState extends State<RegistroWidget> {
  String tipoSeleccionado = 'Cliente';
  final Color verdeAmazonico = const Color(0xFF006d5b);
  final Color cremaClaro = const Color.fromARGB(255, 37, 37, 37);
  final Color blanco = const Color.fromARGB(255, 254, 254, 254);
  final _formKey = GlobalKey<FormState>();

  // Controladores para campos comunes
  final TextEditingController nombresController = TextEditingController();
  final TextEditingController apellidosController = TextEditingController();
  String generoSeleccionado = 'Masculino';
  final TextEditingController direccionController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Controladores para cliente
  final TextEditingController celularController = TextEditingController();

  // Controladores para conductor
  final TextEditingController licenciaController = TextEditingController();
  final TextEditingController categoriaLicenciaController = TextEditingController();

  // Controladores para documento de identidad
  final TextEditingController ciController = TextEditingController();
  final TextEditingController complementoController = TextEditingController();
  final TextEditingController expedidoController = TextEditingController();

  // Archivos de imágenes
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
        title: const Text('Registro de Usuario'),
        backgroundColor: verdeAmazonico,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selector de tipo de usuario
                DropdownButtonFormField<String>(
                  value: tipoSeleccionado,
                  decoration: _inputDecoration('Tipo de usuario'),
                  items: const [
                    DropdownMenuItem(value: 'Cliente', child: Text('Cliente')),
                    DropdownMenuItem(value: 'Conductor', child: Text('Conductor')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      tipoSeleccionado = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Campos comunes a ambos tipos de usuario
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

                // Selector de género
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
                  validator: (value) => value == null ? 'Seleccione un género' : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: direccionController,
                  decoration: _inputDecoration('Dirección/Domicilio'),
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

                // Sección de captura de imágenes
                _buildImageSection(),

                // Campos específicos según tipo de usuario
                if (tipoSeleccionado == 'Cliente') ...[
                  TextFormField(
                    controller: celularController,
                    decoration: _inputDecoration('Celular'),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value!.isEmpty ? 'Ingrese su celular' : null,
                  ),
                  const SizedBox(height: 15),
                ],

                if (tipoSeleccionado == 'Conductor') ...[
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

                 
                ],

                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: verdeAmazonico,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submitForm,
                    child: const Text(
                      'Registrarme',
                      style: TextStyle(fontSize: 18, color: Colors.white),
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
          'Documentación:',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 10),
        
        // Botón para foto de rostro
        ElevatedButton.icon(
          icon: const Icon(Icons.camera_alt,color: Color.fromARGB(255, 254, 254, 254),),
          label: Text(fotoRostro == null ? 'Tomar foto de rostro' : 'Foto tomada',
            style: const TextStyle(color: Colors.white),),
          style: ElevatedButton.styleFrom(
            backgroundColor: verdeAmazonico,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: () => _tomarFoto(true),
        ),
        const SizedBox(height: 10),
        
        // Botón para foto de documento
        ElevatedButton.icon(
          icon: const Icon(Icons.credit_card, color: Color.fromARGB(255, 254, 254, 254),),
          label: Text(fotoDocumento == null ? 'Tomar foto de documento' : 'Documento capturado',
           style: const TextStyle(color: Colors.white),),
          style: ElevatedButton.styleFrom(
            backgroundColor: verdeAmazonico,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: () => _tomarFoto(false),
        ),
        
        // Mostrar vista previa si hay imágenes
        if (fotoRostro != null) ...[
          const SizedBox(height: 10),
          Text('Foto de rostro:', style: TextStyle(color: Colors.white)),
          Image.file(fotoRostro!, height: 100, width: 100, fit: BoxFit.cover),
        ],
        
        if (fotoDocumento != null) ...[
          const SizedBox(height: 10),
          Text('Foto de documento:', style: TextStyle(color: Colors.white)),
          Image.file(fotoDocumento!, height: 100, width: 150, fit: BoxFit.cover),
        ],
        
        const SizedBox(height: 20),
        
        // Campos para datos del documento (se pueden autocompletar si se usa OCR)
        TextFormField(
          controller: ciController,
          decoration: _inputDecoration('Número de CI'),
          keyboardType: TextInputType.number,
          validator: (value) => value!.isEmpty ? 'Ingrese su CI' : null,
        ),
        const SizedBox(height: 15),
        
        TextFormField(
          controller: complementoController,
          decoration: _inputDecoration('Complemento (ej: LP, CB, etc.)'),
          validator: (value) => value!.isEmpty ? 'Ingrese complemento' : null,
        ),
        const SizedBox(height: 15),
        
        TextFormField(
          controller: expedidoController,
          decoration: _inputDecoration('Expedido en (ej: La Paz)'),
          validator: (value) => value!.isEmpty ? 'Ingrese lugar de expedición' : null,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      fillColor: Colors.white,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
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
          // Aquí podrías añadir validación de rostro con algún paquete de ML
        } else {
          fotoDocumento = File(image.path);
          // Aquí podrías implementar OCR para extraer datos automáticamente
        }
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (fotoRostro == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe tomar una foto de su rostro')));
        return;
      }
      
      if (fotoDocumento == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe tomar una foto de su documento')));
        return;
      }
      
      // Procesar el registro
      _registrarUsuario();
    }
  }

  void _registrarUsuario() {
    // Aquí iría la lógica para registrar al usuario en tu backend
    final datosUsuario = {
      'tipo': tipoSeleccionado,
      'nombres': nombresController.text,
      'apellidos': apellidosController.text,
      'genero': generoSeleccionado,
      'direccion': direccionController.text,
      'correo': correoController.text,
      'ci': ciController.text,
      'complemento': complementoController.text,
      'expedido': expedidoController.text,
      'foto_rostro': fotoRostro?.path,
      'foto_documento': fotoDocumento?.path,
    };
    
    if (tipoSeleccionado == 'Cliente') {
      datosUsuario['celular'] = celularController.text;
    } else {
      datosUsuario['licencia'] = licenciaController.text;
      datosUsuario['categoria'] = categoriaLicenciaController.text;
    }
    
    print('Datos del usuario: $datosUsuario');
    
    // Mostrar confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${tipoSeleccionado} registrado exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Aquí normalmente redirigirías a otra pantalla o harías la petición HTTP
  }
}