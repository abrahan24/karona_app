import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RideScreen extends StatefulWidget {
  final LatLng driverLocation;
  final LatLng clientLocation;
  final LatLng destination;

  const RideScreen({
    super.key,
    required this.driverLocation,
    required this.clientLocation,
    required this.destination,
  });

  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> with TickerProviderStateMixin {
  late MapController _mapController;
  late LatLng _currentDriverPos;
  late LatLng _currentClientPos;
  List<LatLng> _polylineCoordinates = [];
  late AnimationController _animationController;
  double _animationValue = 0.0;
  bool _isLoading = true;

  // Configuración de Valhalla
  final String valhallaUrl = 'http://localhost:8002/route';

  @override
  void initState() {
    super.initState();
    // Ubicaciones actualizadas con las coordenadas proporcionadas
    _currentDriverPos = const LatLng(-11.043992, -68.775170); // Conductor
    _currentClientPos = const LatLng(-11.039016, -68.771850); // Cliente
    _mapController = MapController();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..addListener(() {
        setState(() {
          _animationValue = _animationController.value;
          _updatePositions();
        });
      });

    _createValhallaPolyline().then((_) {
      setState(() {
        _isLoading = false;
        _adjustMapToRoute();
      });
    });
    _animationController.forward();
  }

  Future<void> _createValhallaPolyline() async {
    try {
      final response = await http.post(
        Uri.parse(valhallaUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "locations": [
            {"lat": _currentDriverPos.latitude, "lon": _currentDriverPos.longitude},
            {"lat": -11.032907, "lon": -68.775390} // Destino actualizado
          ],
          "costing": "motorcycle", // Modo de transporte ajustado
          "directions_options": {"units": "km"},
          "id": "valhalla_directions"
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geometry = data['trip']['legs'][0]['shape'];
        
        setState(() {
          _polylineCoordinates = _decodeValhallaPolyline(geometry);
        });
      } else {
        throw Exception('Error en la respuesta de Valhalla: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al crear la ruta con Valhalla: $e');
      // Ruta de emergencia (línea recta entre conductor y destino)
      setState(() {
        _polylineCoordinates = [
          _currentDriverPos,
          const LatLng(-11.032907, -68.775390)
        ];
      });
    }
  }

  List<LatLng> _decodeValhallaPolyline(String encoded) {
    final List<LatLng> points = [];
    final coords = encoded.split(',');

    for (int i = 0; i < coords.length; i += 2) {
      if (i + 1 >= coords.length) break;
      points.add(LatLng(
        double.parse(coords[i + 1]),
        double.parse(coords[i]),
      ));
    }
    return points;
  }

  void _adjustMapToRoute() {
    if (_polylineCoordinates.isEmpty) return;

    final allPoints = [
      _currentDriverPos,
      _currentClientPos,
      const LatLng(-11.032907, -68.775390), // Destino
      ..._polylineCoordinates
    ];

    // Calcular límites del mapa
    double minLat = allPoints[0].latitude;
    double maxLat = allPoints[0].latitude;
    double minLng = allPoints[0].longitude;
    double maxLng = allPoints[0].longitude;

    for (final point in allPoints) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLng = min(minLng, point.longitude);
      maxLng = max(maxLng, point.longitude);
    }

    // Añadir margen adicional
    const padding = 0.005;
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;

    // Calcular centro y zoom
    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    // Fórmula mejorada para calcular zoom
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = max(latDiff, lngDiff);
    final zoom = (17 - log(maxDiff * 1000) / log(2)).clamp(14.0, 18.0);

    _mapController.move(center, zoom);
  }

  void _updatePositions() {
    if (_polylineCoordinates.isEmpty) return;

    // Animación del conductor
    int driverIndex = (_polylineCoordinates.length * _animationValue).toInt();
    driverIndex = driverIndex.clamp(0, _polylineCoordinates.length - 1);
    _currentDriverPos = _polylineCoordinates[driverIndex];

    // Animación del cliente (comienza a moverse cuando la animación está al 50%)
    if (_animationValue < 0.5) {
      _currentClientPos = const LatLng(-11.039016, -68.771850);
    } else {
      double clientProgress = (_animationValue - 0.5) * 2;
      _currentClientPos = LatLng(
        -11.039016 + (_currentDriverPos.latitude - -11.039016) * clientProgress,
        -68.771850 + (_currentDriverPos.longitude - -68.771850) * clientProgress,
      );
    }

    _mapController.move(_currentDriverPos, _mapController.camera.zoom);
  }

  double _getBearing() {
    if (_polylineCoordinates.length < 2) return 0;

    int nextIndex = (_polylineCoordinates.length * _animationValue).toInt() + 1;
    nextIndex = nextIndex.clamp(0, _polylineCoordinates.length - 1);

    LatLng current = _currentDriverPos;
    LatLng next = _polylineCoordinates[nextIndex];

    return _calculateBearing(current, next);
  }

  double _calculateBearing(LatLng begin, LatLng end) {
    double lat1 = begin.latitude * (pi / 180);
    double lon1 = begin.longitude * (pi / 180);
    double lat2 = end.latitude * (pi / 180);
    double lon2 = end.longitude * (pi / 180);

    double y = sin(lon2 - lon1) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lon2 - lon1);
    double bearing = atan2(y, x) * (180 / pi);
    return (bearing + 360) % 360;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrera en curso'),
        backgroundColor: const Color(0xFF006d5b),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-11.038, -68.773), // Centro inicial entre ubicaciones
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.karona.app',
              ),
              if (_polylineCoordinates.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _polylineCoordinates,
                      color: const Color(0xFF006d5b),
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 60.0,
                    height: 60.0,
                    point: _currentDriverPos,
                    child: Transform.rotate(
                      angle: _getBearing() * (pi / 180),
                      child: const Icon(
                        Icons.directions_bike,
                        color: Colors.green,
                        size: 36,
                      ),
                    ),
                  ),
                  Marker(
                    width: 60.0,
                    height: 60.0,
                    point: _currentClientPos,
                    child: const Icon(
                      Icons.person_pin_circle,
                      color: Colors.blue,
                      size: 36,
                    ),
                  ),
                  Marker(
                    width: 60.0,
                    height: 60.0,
                    point: const LatLng(-11.032907, -68.775390),
                    child: const Icon(
                      Icons.flag,
                      color: Colors.red,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          _buildRideInfoCard(),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildRideInfoCard() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detalles de la carrera',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Conductor:', 'En camino'),
              _buildInfoRow('Cliente:', 'Esperando en ubicación'),
              _buildInfoRow('Destino:', 'Terminal de buses'),
              _buildInfoRow('Distancia:', '1.2 km'),
              _buildInfoRow('Tiempo estimado:', '5 min'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Card(
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              if (_animationValue < 0.8)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text(
                    'Cancelar Carrera',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              if (_animationValue >= 0.8)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006d5b),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    'Finalizar Carrera',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Carrera finalizada con éxito'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}