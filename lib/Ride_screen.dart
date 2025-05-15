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
  late final MapController _mapController;
  late LatLng _currentDriverPos;
  late LatLng _currentClientPos;
  List<LatLng> _polylineCoordinates = [];
  late AnimationController _animationController;
  double _animationValue = 0.0;
  bool _isLoading = true;

  final String valhallaUrl = 'http://192.168.1.25:8002/route';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentDriverPos = widget.driverLocation;
    _currentClientPos = widget.clientLocation;

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
      _animationController.forward();
    });
  }
  
double? _totalDistanceKm = 0.0;
double? _totalDurationMin = 0.0;

Future<void> _createValhallaPolyline() async {
  try {
    final response = await http.post(
      Uri.parse(valhallaUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "locations": [
          {
            "lat": widget.driverLocation.latitude,
            "lon": widget.driverLocation.longitude
          },
          {
            "lat": widget.destination.latitude,
            "lon": widget.destination.longitude
          }
        ],
        "costing": "motorcycle",
        "directions_options": {"units": "km"},
        "id": "valhalla_directions"
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final geometry = data['trip']['legs'][0]['shape'];
      final double distance = data['trip']['summary']['length']; // en km
      final double duration = data['trip']['summary']['time'] / 60.0; // en minutos

      setState(() {
        _polylineCoordinates = _decodeValhallaPolyline(geometry);
        _totalDistanceKm = distance;
        _totalDurationMin = duration;
      });
    } else {
      throw Exception('Error en la respuesta de Valhalla: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error al crear la ruta con Valhalla: $e');
    setState(() {
      _polylineCoordinates = [widget.driverLocation, widget.destination];
    });
  }
}

 List<LatLng> _decodeValhallaPolyline(String encoded) {
  List<LatLng> poly = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;

  while (index < len) {
    int b, shift = 0, result = 0;

    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1F) << shift;
      shift += 5;
    } while (b >= 0x20);
    int deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += deltaLat;

    shift = 0;
    result = 0;

    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1F) << shift;
      shift += 5;
    } while (b >= 0x20);
    int deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += deltaLng;

    poly.add(LatLng(lat / 1e6, lng / 1e6));
  }

  return poly;
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

  void _adjustMapToRoute() {
    final points = [..._polylineCoordinates];
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      minLat = min(minLat, p.latitude);
      maxLat = max(maxLat, p.latitude);
      minLng = min(minLng, p.longitude);
      maxLng = max(maxLng, p.longitude);
    }

    const padding = 0.005;
    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = max(latDiff, lngDiff);
    final zoom = (17 - log(maxDiff * 1000) / log(2)).clamp(13.0, 18.0);

    _mapController.move(center, zoom);
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
    double lat1 = begin.latitude * pi / 180;
    double lon1 = begin.longitude * pi / 180;
    double lat2 = end.latitude * pi / 180;
    double lon2 = end.longitude * pi / 180;

    double y = sin(lon2 - lon1) * cos(lat2);
    double x = cos(lat1) * sin(lat2) -
        sin(lat1) * cos(lat2) * cos(lon2 - lon1);
    return (atan2(y, x) * 180 / pi + 360) % 360;
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
              initialZoom: 15,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              if (_polylineCoordinates.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _polylineCoordinates,
                      color: const Color(0xFF006d5b),
                      strokeWidth: 5,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 60,
                    height: 60,
                    point: _currentDriverPos,
                    child: Transform.rotate(
                      angle: _getBearing() * (pi / 180),
                      child: const Icon(Icons.directions_bike, size: 36, color: Colors.green),
                    ),
                  ),
                  Marker(
                    width: 60,
                    height: 60,
                    point: _currentClientPos,
                    child: const Icon(Icons.person_pin_circle, size: 36, color: Colors.blue),
                  ),
                  Marker(
                    width: 60,
                    height: 60,
                    point: widget.destination,
                    child: const Icon(Icons.flag, size: 36, color: Colors.red),
                  ),
                ],
              ),
            ],
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
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
              Text('Detalles de la carrera', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Conductor: En camino'),
              Text('Cliente: Esperando en ubicación'),
              Text('Destino: Terminal de buses'),
              Text('Distancia: ${_totalDistanceKm?.toStringAsFixed(2) ?? '--'} km'),
              Text('Tiempo estimado: ${_totalDurationMin?.toStringAsFixed(0) ?? '--'} min')
            ],
          ),
        ),
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
                  icon: const Icon(Icons.close,color: Colors.white,),
                  label: const Text('Cancelar Carrera',style: TextStyle(color: Colors.white),),
                  onPressed: () => Navigator.pop(context),
                ),
              if (_animationValue >= 0.8)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006d5b),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  icon: const Icon(Icons.check,color: Colors.white,),
                  label: const Text('Finalizar Carrera',style: TextStyle(color: Colors.white),),
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
