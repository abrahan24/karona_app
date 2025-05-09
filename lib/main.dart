import 'package:flutter/material.dart';
import 'Splash_screen.dart';
import 'LoginWidget.dart';
import 'Driver_dashboard.dart';
import 'TipoUsuarioScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Karona App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color.fromARGB(255, 37, 37, 37),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF006d5b),
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginWidget(),
        '/driver_dashboard': (context) => const DriverDashboardScreen(),
        '/driver_profile': (context) => const DriverProfileScreen(),
        '/register': (context) => const TipoUsuarioScreen(),
      },
    );
  }
}