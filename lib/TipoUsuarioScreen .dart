// ignore: file_names
import 'package:flutter/material.dart';
import 'RegistroClienteScreen.dart';
import 'RegistroConductorScreen.dart';

// Pantalla para seleccionar el tipo de usuario
class TipoUsuarioScreen extends StatefulWidget {
  const TipoUsuarioScreen({super.key});

  @override
  State<TipoUsuarioScreen> createState() => _TipoUsuarioScreenState();
}

class _TipoUsuarioScreenState extends State<TipoUsuarioScreen> {
  String? tipoSeleccionado;
  final Color verdeAmazonico = const Color(0xFF006d5b);
  final Color cremaClaro = Color.fromARGB(255, 37, 37, 37);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cremaClaro,
      appBar: AppBar(
        title: const Text('Seleccione su tipo de usuario'),
        backgroundColor: verdeAmazonico,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '¿Cómo deseas registrarte?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              // Tarjeta para Cliente
              _buildTipoUsuarioCard(
                'Cliente',
                'Usa nuestro servicio como pasajero',
                Icons.person,
                tipoSeleccionado == 'Cliente',
                () {
                  setState(() {
                    tipoSeleccionado = 'Cliente';
                  });
                },
              ),
              const SizedBox(height: 20),
              // Tarjeta para Conductor
              _buildTipoUsuarioCard(
                'Conductor',
                'Ofrece tus servicios de transporte',
                Icons.directions_car,
                tipoSeleccionado == 'Conductor',
                () {
                  setState(() {
                    tipoSeleccionado = 'Conductor';
                  });
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed:
                    tipoSeleccionado == null
                        ? null
                        : () {
                          // Efecto de sonido al presionar
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      tipoSeleccionado == 'Cliente'
                                          ? const RegistroClienteScreen()
                                          : const RegistroConductorScreen(),
                            ),
                          );
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: verdeAmazonico,
                  disabledBackgroundColor:
                      Colors.grey.shade700, // Color cuando está deshabilitado
                  foregroundColor: Colors.white, // Color del texto e icono
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6, // Sombra más pronunciada
                  shadowColor: verdeAmazonico.withOpacity(0.5),
                ),
                child: const Text(
                  'Continuar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipoUsuarioCard(
    String titulo,
    String descripcion,
    IconData icono,
    bool seleccionado,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: seleccionado ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: seleccionado ? verdeAmazonico : Colors.grey.shade300,
          width: seleccionado ? 2 : 1,
        ),
      ),
      color: const Color.fromARGB(255, 50, 50, 50),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icono,
                size: 40,
                color: seleccionado ? verdeAmazonico : Colors.grey.shade400,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: seleccionado ? verdeAmazonico : Colors.white,
                      ),
                    ),
                    Text(
                      descripcion,
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
              if (seleccionado)
                const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }
}

