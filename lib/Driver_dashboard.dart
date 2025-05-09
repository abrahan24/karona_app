import 'package:flutter/material.dart';
import 'package:karona_app/Ride_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverDashboardScreen extends StatefulWidget {
  static const String routeName = '/driver_dashboard';

  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _completedRides = 0;
  int _pendingRequests = 0;
  double _rating = 5.0;
  bool _available = true;
  bool _hasNewRequest = false;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
    _simulateRequests();
  }

  Future<void> _loadDriverData() async {
    // Simulación de carga de datos del conductor
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _completedRides = 42;
      _pendingRequests = 3;
      _rating = 4.8;
    });
  }

  void _simulateRequests() {
    // Simulación de nuevas solicitudes (solo para demo)
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _available) {
        setState(() {
          _pendingRequests++;
          _hasNewRequest = true;
        });
        _showRideRequest();
      }
    });
  }

  // En el método que muestra la notificación de nueva carrera:
  void _showRideRequest() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Nueva solicitud de carrera'),
            content: const Text(
              'Hay un pasajero buscando conductor en tu zona.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Rechazar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006d5b),
                ),
                onPressed: () {
                  setState(() {
                    _pendingRequests--;
                    _hasNewRequest = false;
                  });
                  Navigator.pop(context);

                  // Navegar a la pantalla de carrera
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => RideScreen(
                            driverLocation: const LatLng(
                              -17.7838,
                              -63.180,
                            ), // Ubicación inicial conductor
                            clientLocation: const LatLng(
                              -17.7865,
                              -63.181,
                            ), // Ubicación cliente
                            destination: const LatLng(
                              -17.7899,
                              -63.195,
                            ), // Destino
                          ),
                    ),
                  );
                },
                child: const Text(
                  'Aceptar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDriverLoggedIn', false);
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Conductor'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _hasNewRequest,
              child: const Icon(Icons.notifications),
            ),
            onPressed: () {
              setState(() {
                _hasNewRequest = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Tienes $_pendingRequests solicitudes pendientes',
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              } else if (value == 'profile') {
                Navigator.pushNamed(context, '/driver_profile');
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Text('Ver Perfil'),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Text('Cerrar Sesión'),
                  ),
                ],
          ),
        ],
      ),
      body: _buildDashboardBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF006d5b),
        onPressed: () => _completeRide(),
        child: const Icon(Icons.directions_car, color: Colors.white),
      ),
    );
  }

  Widget _buildDashboardBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAvailabilityCard(),
          const SizedBox(height: 20),
          _buildStatsHeader(),
          const SizedBox(height: 10),
          _buildStatsGrid(),
          const SizedBox(height: 20),
          _buildRecentRidesHeader(),
          const SizedBox(height: 10),
          _buildRecentRidesList(),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return Card(
      color: const Color.fromARGB(255, 50, 50, 50),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Estado Actual',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text(
                'Disponible para carreras',
                style: TextStyle(color: Colors.white),
              ),
              value: _available,
              activeColor: const Color(0xFF006d5b),
              onChanged: (value) => setState(() => _available = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    return const Text(
      'Mis Estadísticas',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _buildStatCard(
          'Carreras Realizadas',
          _completedRides.toString(),
          Icons.directions_car,
        ),
        _buildStatCard(
          'Solicitudes Pendientes',
          _pendingRequests.toString(),
          Icons.access_time,
        ),
        _buildStatCard('Calificación', _rating.toStringAsFixed(1), Icons.star),
        _buildStatCard('Ingresos Hoy', '\$125.50', Icons.attach_money),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      color: const Color.fromARGB(255, 50, 50, 50),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: const Color(0xFF006d5b)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRidesHeader() {
    return const Text(
      'Carreras Recientes',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildRecentRidesList() {
    return Column(
      children: [
        _buildRideItem('Juan Pérez', 'Av. Siempre Viva 742', '\$15.20'),
        _buildRideItem('María García', 'Calle Falsa 123', '\$22.50'),
        _buildRideItem('Carlos López', 'Boulevard Los Olivos', '\$18.75'),
      ],
    );
  }

  Widget _buildRideItem(String name, String address, String price) {
    return Card(
      color: const Color.fromARGB(255, 50, 50, 50),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF006d5b),
          child: Text(name[0], style: const TextStyle(color: Colors.white)),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white)),
        subtitle: Text(address, style: const TextStyle(color: Colors.grey)),
        trailing: Text(
          price,
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _completeRide() {
    setState(() {
      _completedRides++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Carrera completada con éxito')),
    );
  }
}

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: const Center(
        child: Text(
          'Perfil del conductor',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
