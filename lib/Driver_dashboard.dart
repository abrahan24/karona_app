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
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _completedRides = 42;
      _pendingRequests = 3;
      _rating = 4.8;
    });
  }

  void _simulateRequests() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _available) {
        setState(() {
          _pendingRequests++;
          _hasNewRequest = true;
        });
        _showRideRequest();
      }
    });
  }

  void _showRideRequest() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva solicitud de carrera'),
        content: const Text('Hay un pasajero buscando conductor en tu zona.'),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RideScreen(
                    driverLocation: const LatLng(-11.043992, -68.775170),
                    clientLocation: const LatLng(-11.039016, -68.771850),
                    destination: const LatLng(-11.032907, -68.775390),
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenHeight > 800;

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
                  content: Text('Tienes $_pendingRequests solicitudes pendientes'),
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
            itemBuilder: (BuildContext context) => [
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
      body: _buildDashboardBody(isLargeScreen),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF006d5b),
        onPressed: () => _completeRide(),
        child: const Icon(Icons.directions_car, color: Colors.white),
      ),
    );
  }

  Widget _buildDashboardBody(bool isLargeScreen) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isLargeScreen ? 20 : 16,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAvailabilityCard(isLargeScreen),
            SizedBox(height: isLargeScreen ? 24 : 20),
            _buildStatsHeader(),
            SizedBox(height: isLargeScreen ? 16 : 10),
            _buildStatsGrid(isLargeScreen),
            SizedBox(height: isLargeScreen ? 24 : 20),
            _buildRecentRidesHeader(),
            SizedBox(height: isLargeScreen ? 16 : 10),
            _buildRecentRidesList(isLargeScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityCard(bool isLargeScreen) {
    return Card(
      color: const Color.fromARGB(255, 50, 50, 50),
      child: Padding(
        padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min, // IMPORTANTE: Evita overflow
          children: [
            Text(
              'Estado Actual',
              style: TextStyle(
                fontSize: isLargeScreen ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isLargeScreen ? 16 : 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Disponible para carreras',
                style: TextStyle(
                  fontSize: isLargeScreen ? 18 : 16,
                  color: Colors.white,
                ),
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

  Widget _buildStatsGrid(bool isLargeScreen) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.1, // Ajustado para evitar overflow
      crossAxisSpacing: isLargeScreen ? 16 : 10,
      mainAxisSpacing: isLargeScreen ? 16 : 10,
      padding: EdgeInsets.zero,
      children: [
        _buildCompactStatCard(
          'Carreras Realizadas',
          _completedRides.toString(),
          Icons.directions_car,
          isLargeScreen,
        ),
        _buildCompactStatCard(
          'Solicitudes Pendientes',
          _pendingRequests.toString(),
          Icons.access_time,
          isLargeScreen,
        ),
        _buildCompactStatCard(
          'Calificación',
          _rating.toStringAsFixed(1),
          Icons.star,
          isLargeScreen,
        ),
        _buildCompactStatCard(
          'Ingresos Hoy',
          '\$125.50',
          Icons.attach_money,
          isLargeScreen,
        ),
      ],
    );
  }

  Widget _buildCompactStatCard(
    String title,
    String value,
    IconData icon,
    bool isLargeScreen,
  ) {
    return Card(
      color: const Color.fromARGB(255, 50, 50, 50),
      child: Container(
        padding: EdgeInsets.all(isLargeScreen ? 8 : 6),
        constraints: BoxConstraints(
          minHeight: 0, // Permite que la tarjeta se encoja si es necesario
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // IMPORTANTE: Evita overflow
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isLargeScreen ? 28 : 24,
              color: const Color(0xFF006d5b),
            ),
            SizedBox(height: isLargeScreen ? 4 : 2),
            Text(
              value,
              style: TextStyle(
                fontSize: isLargeScreen ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isLargeScreen ? 4 : 2),
            Text(
              title,
              style: TextStyle(
                fontSize: isLargeScreen ? 12 : 10,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

  Widget _buildRecentRidesList(bool isLargeScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min, // IMPORTANTE: Evita overflow
      children: [
        _buildCompactRideItem('Juan Pérez', 'Av. Siempre Viva 742', '\$15.20', isLargeScreen),
        SizedBox(height: isLargeScreen ? 8 : 6),
        _buildCompactRideItem('María García', 'Calle Falsa 123', '\$22.50', isLargeScreen),
        SizedBox(height: isLargeScreen ? 8 : 6),
        _buildCompactRideItem('Carlos López', 'Boulevard Los Olivos', '\$18.75', isLargeScreen),
      ],
    );
  }

  Widget _buildCompactRideItem(
    String name,
    String address,
    String price,
    bool isLargeScreen,
  ) {
    return Card(
      color: const Color.fromARGB(255, 50, 50, 50),
      child: Container(
        padding: EdgeInsets.all(isLargeScreen ? 10 : 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: isLargeScreen ? 20 : 16,
              backgroundColor: const Color(0xFF006d5b),
              child: Text(
                name[0],
                style: TextStyle(
                  fontSize: isLargeScreen ? 16 : 14,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: isLargeScreen ? 12 : 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min, // IMPORTANTE: Evita overflow
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: isLargeScreen ? 14 : 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    address,
                    style: TextStyle(
                      fontSize: isLargeScreen ? 12 : 10,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: isLargeScreen ? 12 : 8),
            Text(
              price,
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: isLargeScreen ? 14 : 12,
              ),
            ),
          ],
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