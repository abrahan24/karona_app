import 'package:flutter/material.dart';
import 'package:karona_app/Driver_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:karona_app/TipoUsuarioScreen.dart';

class LoginWidget extends StatelessWidget {
  const LoginWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const Color verdeAmazonico = Color(0xFF006d5b);
    const Color cremaClaro = Color.fromARGB(255, 37, 37, 37);

    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    Future<void> handleLogin() async {
      // Validación básica (deberías añadir más validaciones)
      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor ingresa email y contraseña')),
        );
        return;
      }

      // Simulación de login exitoso
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDriverLoggedIn', true);

      // Navegar al dashboard del conductor
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverDashboardScreen()),
      );
    }

    return Scaffold(
      backgroundColor: cremaClaro,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                SizedBox(
                  height: 250,
                  child: Image.asset('assets/Logo_Karona_R.png'),
                ),
                const SizedBox(height: 1),

                // Campo de email
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email, color: verdeAmazonico),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: verdeAmazonico, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Campo de contraseña
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock, color: verdeAmazonico),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: verdeAmazonico, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Botón de login
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
                    onPressed: handleLogin,
                    child: const Text(
                      'Iniciar Sesión',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Texto de redirección a registro
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TipoUsuarioScreen()),
                    );
                  },
                  child: Text(
                    '¿No tienes cuenta? Regístrate aquí',
                    style: TextStyle(
                      color: verdeAmazonico,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
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
}