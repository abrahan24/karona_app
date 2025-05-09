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

  @override
  void initState() {
    super.initState();
    _currentDriverPos = widget.driverLocation;
    _currentClientPos = widget.clientLocation;
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

    _createPolyline();
    _animationController.forward();
  }

  Future<void> _createPolyline() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/'
          '${widget.driverLocation.longitude},${widget.driverLocation.latitude};'
          '${widget.destination.longitude},${widget.destination.latitude}?overview=full',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geometry = data['routes'][0]['geometry'];

        setState(() {
          _polylineCoordinates = _decodePolyline(geometry);
        });
      }
    } catch (e) {
      debugPrint('Error al crear la ruta: $e');
      // Ruta de emergencia (línea recta)
      setState(() {
        _polylineCoordinates = [widget.driverLocation, widget.destination];
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  void _updatePositions() {
    if (_polylineCoordinates.isEmpty) return;

    int driverIndex = (_polylineCoordinates.length * _animationValue).toInt();
    driverIndex = driverIndex.clamp(0, _polylineCoordinates.length - 1);
    _currentDriverPos = _polylineCoordinates[driverIndex];

    if (_animationValue < 0.5) {
      _currentClientPos = widget.clientLocation;
    } else {
      double clientProgress = (_animationValue - 0.5) * 2;
      _currentClientPos = LatLng(
        widget.clientLocation.latitude +
            (_currentDriverPos.latitude - widget.clientLocation.latitude) *
                clientProgress,
        widget.clientLocation.longitude +
            (_currentDriverPos.longitude - widget.clientLocation.longitude) *
                clientProgress,
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
              initialCenter: _currentDriverPos,
              initialZoom: 15.0,
              onMapReady: () {
                debugPrint('Mapa cargado completamente');
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.karona.app',
              ),
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
                    point: widget.destination,
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
          // _buildRideInfoCard(),
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
              _buildInfoRow('Cliente:', 'Juan Pérez'),
              _buildInfoRow('Teléfono:', '+591 70012345'),
              _buildInfoRow('Distancia:', '2.5 km'),
              _buildInfoRow('Tiempo estimado:', '8 min'),
              _buildInfoRow('Tarifa estimada:', '\$15.00'),
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