import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraFaceCaptureScreen extends StatefulWidget {
  const CameraFaceCaptureScreen({super.key});

  @override
  _CameraFaceCaptureScreenState createState() =>
      _CameraFaceCaptureScreenState();
}

class _CameraFaceCaptureScreenState extends State<CameraFaceCaptureScreen> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  FaceDetector? _faceDetector;
  Face? _detectedFace;
  XFile? _capturedImage;
  String _instruction = 'Buscando rostro...';

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
        enableLandmarks: true,  // Mejorar la precisión de los puntos de referencia faciales
        enableClassification: true,  // Mejorar la clasificación
        performanceMode: FaceDetectorMode.accurate,  // Cambiar a "accurate" para mejorar la detección
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
    final inputImageFormatRaw = image.format.raw;

    final imageRotation = InputImageRotationValue.fromRawValue(imageRotationRaw) ??
        InputImageRotation.rotation0deg;
    final inputImageFormat = InputImageFormat.nv21;

    // Depuración: Verifica los valores de imagen y sus metadatos
    print('Image Size: $imageSize');
    print('Image Rotation: $imageRotation');
    print('Input Image Format: $inputImageFormat');

    if (inputImageFormat == null) {
      _showError('Formato u orientación no compatibles');
      _isDetecting = false;
      return;
    }

    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);

    try {
      // Depuración: Verifica si el detector está funcionando
      final faces = await _faceDetector!.processImage(inputImage);

      print('Faces detected: ${faces.length}'); // Mostrar cuántas caras detecta

      if (faces.isNotEmpty) {
        setState(() {
          _detectedFace = faces.first;
        });
        _showMessage('Rostro detectado');
      } else {
        setState(() {
          _detectedFace = null;
        });
        _showMessage('No se detectaron rostros.');
      }
    } catch (e) {
      // Si ocurre un error, se muestra con el mensaje de error
      _showError('Error al procesar la imagen: $e');
    } finally {
      _isDetecting = false;
    }
  }


  Future<void> _captureImage() async {
    if (_detectedFace == null) {
      _showError("No se detectó un rostro válido");
      return;
    }

    try {
      final image = await _cameraController.takePicture();
      setState(() {
        _capturedImage = image;
        _instruction = 'Foto tomada correctamente';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('✅ Foto capturada')));
    } catch (e) {
      _showError('Error al capturar imagen: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('⚠️ $message')));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

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
      appBar: AppBar(title: Text('Captura de Rostro')),
      body: Stack(
        children: [
          CameraPreview(_cameraController),
          Center(
            child: Container(
              width: 250,
              height: 350,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 160,
            left: 20,
            right: 20,
            child: Text(
              _instruction,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                backgroundColor: Colors.black45,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_capturedImage != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.file(File(_capturedImage!.path), height: 120),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _detectedFace != null ? Colors.green : Colors.grey,
        onPressed: _detectedFace != null ? _captureImage : null,
        child: Icon(Icons.camera),
      ),
    );
  }
}
