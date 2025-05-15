import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

class CameraFaceCaptureScreen extends StatefulWidget {
  const CameraFaceCaptureScreen({super.key});

  @override
  _CameraFaceCaptureScreenState createState() =>
      _CameraFaceCaptureScreenState();
}

class _CameraFaceCaptureScreenState extends State<CameraFaceCaptureScreen> {
  final Color verdeAmazonico = const Color(0xFF006d5b);
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  FaceDetector? _faceDetector;
  Face? _detectedFace;
  XFile? _capturedImage;
  String _instruction = 'Encuadre su rostro en el área naranja';
  bool _blinkDetected = false;
  bool _headTurnDetected = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Permission.camera.request();
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController.initialize();
    } catch (e) {
      _showError('Error al inicializar la cámara: $e');
      return;
    }

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks:
            true, // Mejorar la precisión de los puntos de referencia faciales
        enableClassification: true, // Mejorar la clasificación
        performanceMode:
            FaceDetectorMode
                .accurate, // Cambiar a "accurate" para mejorar la detección
      ),
    );

    _cameraController.startImageStream(_processCameraImage);

    setState(() => _isCameraInitialized = true);
  }

  void _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;

    _isDetecting = true;

    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final camera = _cameraController.description;

    final imageRotationRaw = camera.sensorOrientation;

    final imageRotation =
        InputImageRotationValue.fromRawValue(imageRotationRaw) ??
        InputImageRotation.rotation0deg;
    final inputImageFormat = InputImageFormat.nv21;

    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);

    try {
      final faces = await _faceDetector!.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;

        // Detectar parpadeo
        final leftEye = face.leftEyeOpenProbability ?? 1.0;
        final rightEye = face.rightEyeOpenProbability ?? 1.0;

        if (!_blinkDetected && leftEye < 0.3 && rightEye < 0.3) {
          _blinkDetected = true;
        }

        // Detectar movimiento de cabeza izquierda/derecha
        final yaw = face.headEulerAngleY ?? 0.0;
        if (!_headTurnDetected && yaw.abs() > 15) {
          _headTurnDetected = true;
        }

        // Determinar mensaje
        String instruction = '';
        if (!_blinkDetected) {
          instruction = '👁 Parpadea para continuar';
        } else if (!_headTurnDetected) {
          instruction = '↔️ Mueve la cabeza de lado';
        } else {
          instruction = '✅ Rostro real detectado - Puedes capturar';
        }

        setState(() {
          _detectedFace = face;
          _instruction = instruction;
        });
      } else {
        setState(() {
          _detectedFace = null;
          _instruction = 'Encuadre su rostro en el área naranja';
          _blinkDetected = false;
          _headTurnDetected = false;
        });
      }
    } catch (e) {
      setState(() => _instruction = 'Error al procesar la imagen');
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _captureImage() async {
    if (_detectedFace == null) {
      setState(() => _instruction = '❌ No se detectó un rostro válido');
      return;
    }

    try {
      final image = await _cameraController.takePicture();

      final imageBytes = await File(image.path).readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) {
        setState(() => _instruction = 'Error al procesar imagen');
        return;
      }

      final faceRect = _detectedFace!.boundingBox;

      // Margen para expandir el recorte
      const int extraTop = 150;
      const int extraBottom = 200;
      const int extraSides = 50;

      // Calcular límites seguros
      final int left = (faceRect.left - extraSides).toInt().clamp(
        0,
        decodedImage.width,
      );
      final int top = (faceRect.top - extraTop).toInt().clamp(
        0,
        decodedImage.height,
      );
      final int right = (faceRect.right + extraSides).toInt().clamp(
        0,
        decodedImage.width,
      );
      final int bottom = (faceRect.bottom + extraBottom).toInt().clamp(
        0,
        decodedImage.height,
      );

      final int width = right - left;
      final int height = bottom - top;

      final cropped = img.copyCrop(
        decodedImage,
        x: left,
        y: top,
        width: width,
        height: height,
      );

      // Guardar imagen recortada
      final croppedPath = '${image.path}_recorte.jpg';
      final croppedFile = File(croppedPath)
        ..writeAsBytesSync(img.encodeJpg(cropped));

      setState(() {
        _capturedImage = XFile(croppedPath);
        _instruction = '✅ Foto recortada correctamente';
      });

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pop(context, File(croppedPath));
    } catch (e) {
      setState(() => _instruction = '❌ Error al capturar imagen');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('⚠️ $message')));
  }

  // void _showMessage(String message) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text(message), backgroundColor: Colors.green),
  //   );
  // }

  @override
  void dispose() {
    _cameraController.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Captura de Rostro'),
        backgroundColor: verdeAmazonico,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Vista de la cámara (fondo completo)
          CameraPreview(_cameraController),

          CustomPaint(
            size: Size.infinite,
            painter: CircularHolePainter(
              center: Offset(
                MediaQuery.of(context).size.width / 2,
                MediaQuery.of(context).size.height / 2,
              ),
              radius: 150,
            ),
          ),

          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _detectedFace != null ? Colors.green : Colors.orange,
                  width: 5,
                ),
              ),
            ),
          ),

          // Resto del código permanece igual...
          Positioned(
            bottom: 160,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      _detectedFace != null
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                  width: 1,
                ),
              ),
              child: Text(
                _instruction,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          if (_capturedImage != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Image.file(File(_capturedImage!.path), height: 120),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: (_detectedFace != null && _blinkDetected && _headTurnDetected) ? Colors.green : Colors.grey,
        onPressed:
            (_detectedFace != null && _blinkDetected && _headTurnDetected) ? _captureImage : null,
        child: Icon(Icons.camera, color: Colors.white),
      ),
    );
  }
}

class CircularHolePainter extends CustomPainter {
  final Offset center;
  final double radius;

  CircularHolePainter({required this.center, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withOpacity(0.5)
          ..style = PaintingStyle.fill;

    final fullScreen =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole =
        Path()..addOval(Rect.fromCircle(center: center, radius: radius));

    final combined = Path.combine(PathOperation.difference, fullScreen, hole);
    canvas.drawPath(combined, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
