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
      'Incline su celular horizontalmente y alinee el documento al lado izquierdo';

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
      ResolutionPreset.max,
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
      // 📸 Tomar la foto con la cámara
      final imagen = await _controladorCamara.takePicture();
      final bytes = await File(imagen.path).readAsBytes();

      // 🖼️ Decodificar la imagen en memoria para poder procesarla
      img.Image? original = img.decodeImage(bytes);

      if (original == null) {
        setState(() => _instruccion = 'Error al procesar imagen');
        return;
      }

      // Forzamos la rotación porque la vista siempre es horizontal, pero la imagen es vertical
      original = img.copyRotate(original, angle: 0);

      // 📐 Tamaño real de la pantalla (considerando que usaste RotatedBox(quarterTurns: 1))
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      // 📦 Definir el marco naranja visible (mismo tamaño que usaste en el Widget)
      final marcoEnPantalla = Rect.fromCenter(
        center: Offset(screenWidth / 2, screenHeight / 2),
        width: screenWidth * 0.9,
        height: screenHeight * 0.7,
      );

      // 📏 Escalado proporcional de la imagen con respecto al tamaño de pantalla
      final scaleX = original.width / screenWidth;
      final scaleY = original.height / screenHeight;

      // 🔁 Convertir las coordenadas del marco en pantalla a coordenadas reales en la imagen
      final cropX = (marcoEnPantalla.left * scaleX).toInt().clamp(
        0,
        original.width - 1,
      );
      final cropY = (marcoEnPantalla.top * scaleY).toInt().clamp(
        0,
        original.height - 1,
      );
      final cropWidth = (marcoEnPantalla.width * scaleX).toInt().clamp(
        0,
        original.width - cropX,
      );
      final cropHeight = (marcoEnPantalla.height * scaleY).toInt().clamp(
        0,
        original.height - cropY,
      );

      // ✂️ Recortar la imagen a la región exactamente dentro del marco
      final recortada = img.copyCrop(
        original,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      // 💾 Guardar la imagen recortada en un nuevo archivo
      final rutaRecorte = '${imagen.path}_recorte.jpg';
      final archivoFinal = File(rutaRecorte)
        ..writeAsBytesSync(img.encodeJpg(recortada, quality: 90));

      // ✅ Mostrar vista previa y mensaje de éxito
      setState(() {
        _imagenCapturada = XFile(rutaRecorte);
        _instruccion = '✅ Documento recortado correctamente';
      });

      // ⏳ Esperar 1 segundo antes de cerrar
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      // 🔙 Devolver la imagen recortada
      Navigator.pop(context, archivoFinal);
    } catch (e) {
      // ❌ Mostrar error si algo falla
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
              const CircularProgressIndicator(color: Colors.white),
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
          RotatedBox(
            quarterTurns: 1,
            child: Center(
              child: AspectRatio(
                aspectRatio: _controladorCamara.value.aspectRatio,
                child: CameraPreview(_controladorCamara),
              ),
            ),
          ),

          // Marco rectangular para el documento
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 3),
                borderRadius: BorderRadius.circular(9),
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
                      fontSize: 15,
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
