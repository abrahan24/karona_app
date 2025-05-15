import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

class CameraCardCaptureScreen extends StatefulWidget {
  const CameraCardCaptureScreen({super.key});

  @override
  _CameraCardCaptureScreenState createState() =>
      _CameraCardCaptureScreenState();
}

class _CameraCardCaptureScreenState extends State<CameraCardCaptureScreen> {
  final Color verdeAmazonico = const Color(0xFF006d5b);

  late CameraController _controladorCamara;
  bool _camaraInicializada = false;
  XFile? _imagenCapturada;
  String _instruccion =
      'Incline su celular horizontalmente y alinee el documento';

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    // Solicitar permiso para la cámara
    await Permission.camera.request();
    final camaras = await availableCameras();
    final camaraTrasera = camaras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );

    _controladorCamara = CameraController(
      camaraTrasera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controladorCamara.initialize();
      // Forzar orientación horizontal
      await _controladorCamara.lockCaptureOrientation(
        DeviceOrientation.landscapeLeft,
      );
    } catch (e) {
      _mostrarError('Error al inicializar la cámara: $e');
      return;
    }

    setState(() => _camaraInicializada = true);
  }

  Future<void> _capturarImagen() async {
    try {
      final imagen = await _controladorCamara.takePicture();
      final bytes = await File(imagen.path).readAsBytes();
      img.Image? original = img.decodeImage(bytes);

      if (original == null) {
        setState(() => _instruccion = 'Error al procesar imagen');
        return;
      }

      // Obtener la orientación real del sensor
      final orientation = _controladorCamara.description.sensorOrientation;

      // Determinar rotación necesaria (depende de tu preview)
      int rotationAngle = 0;
      if (orientation == 90) {
        rotationAngle = -90;
      } else if (orientation == 270) {
        rotationAngle = 90;
      }

      original = img.copyRotate(original, angle: rotationAngle);

      // 📐 Dimensiones del marco visible (el rectángulo naranja)
      final screenWidth =
          MediaQuery.of(context).size.height; // porque está girado
      final screenHeight = MediaQuery.of(context).size.width;

      final marcoWidth = screenWidth * 0.8;
      final marcoHeight = screenHeight * 0.5;

      final marcoLeft = (screenWidth - marcoWidth) / 2;
      final marcoTop = (screenHeight - marcoHeight) / 2;

      // 🧮 Convertimos coordenadas de pantalla a imagen
      final scaleX = original.width / screenWidth;
      final scaleY = original.height / screenHeight;

      final cropX = (marcoLeft * scaleX).toInt();
      final cropY = (marcoTop * scaleY).toInt();
      final cropWidth = (marcoWidth * scaleX).toInt();
      final cropHeight = (marcoHeight * scaleY).toInt();

      final recorte = img.copyCrop(
        original,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      final rutaRecorte = '${imagen.path}_recortada.jpg';
      final archivoRecorte = File(rutaRecorte)
        ..writeAsBytesSync(img.encodeJpg(recorte));

      setState(() {
        _imagenCapturada = XFile(rutaRecorte);
        _instruccion = '✅ Documento recortado correctamente';
      });

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pop(context, archivoRecorte);
    } catch (e) {
      setState(() => _instruccion = '❌ Error al capturar imagen');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('⚠️ $mensaje')));
  }

  @override
  void dispose() {
    _controladorCamara.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_camaraInicializada) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Configurando cámara...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Captura de Documento'),
        backgroundColor: verdeAmazonico,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Vista de la cámara rotada para horizontalidad
          RotatedBox(quarterTurns: 1, child: CameraPreview(_controladorCamara)),

          // Marco rectangular para el documento
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Área oscurecida alrededor del marco
          CustomPaint(
            size: Size.infinite,
            painter: _PintorMarcoDocumento(
              rect: Rect.fromCenter(
                center: Offset(
                  MediaQuery.of(context).size.width / 2,
                  MediaQuery.of(context).size.height / 2,
                ),
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.5,
              ),
            ),
          ),

          // Instrucciones
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orangeAccent, width: 1),
              ),
              child: Column(
                children: [
                  Text(
                    _instruccion,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Asegúrese que el documento esté bien iluminado y visible',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // Vista previa de la imagen capturada
          if (_imagenCapturada != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Image.file(File(_imagenCapturada!.path), height: 120),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: _capturarImagen,
        child: const Icon(Icons.camera, color: Colors.white),
      ),
    );
  }
}

class _PintorMarcoDocumento extends CustomPainter {
  final Rect rect;

  _PintorMarcoDocumento({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withOpacity(0.5)
          ..style = PaintingStyle.fill;

    final pantallaCompleta =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final areaDocumento = Path()..addRect(rect);

    final combinado = Path.combine(
      PathOperation.difference,
      pantallaCompleta,
      areaDocumento,
    );
    canvas.drawPath(combinado, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
