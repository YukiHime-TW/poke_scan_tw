import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../providers/collection_provider.dart';
import '../providers/deck_provider.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  bool _isProcessing = false;
  XFile? _capturedImage;
  String _statusMessage = "請將【左下角編號】對準紅框";
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    _textRecognizer.close();
    super.dispose();
  }

  // 防止閃退：App 縮小後釋放相機，回來後重新啟動
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _stopCamera() async {
    if (_controller != null) {
      await _controller!.dispose();
      if (mounted) setState(() => _controller = null);
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final controller = CameraController(
      cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first),
      ResolutionPreset.max,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      // --- 核心修正：強制預設關閉閃光燈 ---
      await controller.setFlashMode(FlashMode.off);

      if (mounted) setState(() => _controller = controller);
    } catch (e) {
      print("相機啟動失敗: $e");
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    setState(() => _isFlashOn = !_isFlashOn);
    await _controller!
        .setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
  }

  Future<void> _takePictureAndScan() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) return;

    try {
      final XFile rawImage = await _controller!.takePicture();

      if (!mounted) return;
      setState(() {
        _isProcessing = true;
        _statusMessage = "辨識中...";
      });

      // 執行精確裁切 (小框框模式)
      final File croppedFile = await _processAndCropImage(rawImage);

      setState(() {
        _capturedImage = XFile(croppedFile.path);
      });

      final inputImage = InputImage.fromFile(croppedFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final collectionProvider =
          Provider.of<CollectionProvider>(context, listen: false);
      final deckProvider = Provider.of<DeckProvider>(context, listen: false);

      final resultInfo = await collectionProvider
          .processScannedText(recognizedText.text, deckProvider: deckProvider);

      if (mounted) {
        if (resultInfo != null) {
          HapticFeedback.vibrate();
          setState(() => _statusMessage = "✅ $resultInfo");
          await Future.delayed(const Duration(milliseconds: 1500));
          _resetScanner();
        } else {
          HapticFeedback.lightImpact();
          setState(() {
            _statusMessage = "🤔 無法辨識編號，請再試一次";
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      _resetScanner();
    }
  }

  // 裁切邏輯：改回長方形編號框 (300x110)
  Future<File> _processAndCropImage(XFile xFile) async {
    final Uint8List bytes = await xFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(bytes);
    if (originalImage == null) return File(xFile.path);

    originalImage = img.bakeOrientation(originalImage);

    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;

    // 定義編號專用的長方形框
    const double rectW = 300.0;
    const double rectH = 110.0;

    double factorX = originalImage.width / screenW;
    double factorY = originalImage.height / screenH;
    double factor = factorX > factorY ? factorX : factorY;

    int cropW = (rectW * factor).toInt();
    int cropH = (rectH * factor).toInt();
    int cropX = ((originalImage.width - cropW) / 2).toInt();
    int cropY = ((originalImage.height - cropH) / 2).toInt();

    img.Image cropped = img.copyCrop(originalImage,
        x: cropX, y: cropY, width: cropW, height: cropH);

    final tempDir = await getTemporaryDirectory();
    final croppedFile = File(
        '${tempDir.path}/code_crop_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await croppedFile
        .writeAsBytes(img.encodeJpg(cropped, quality: 95)); // 調高畫質以利編號讀取

    return croppedFile;
  }

  void _resetScanner() {
    if (!mounted) return;
    setState(() {
      _capturedImage = null;
      _isProcessing = false;
      _statusMessage = "請將【左下角編號】對準紅框";
    });
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _controller != null && _controller!.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_capturedImage != null)
            Center(
                child: Image.file(File(_capturedImage!.path),
                    width: 300, fit: BoxFit.contain))
          else if (isReady)
            CameraPreview(_controller!)
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          if (isReady && _capturedImage == null)
            Positioned.fill(
              child: CustomPaint(
                painter: ScannerOverlayPainter(
                    rectWidth: 300, rectHeight: 110, borderRadius: 10),
              ),
            ),
          _buildUI(),
        ],
      ),
    );
  }

  Widget _buildUI() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, color: Colors.white)),
                onPressed: () => Navigator.pop(context),
              ),
              IconButton(
                icon: CircleAvatar(
                  backgroundColor: _isFlashOn ? Colors.yellow : Colors.black54,
                  child: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white),
                ),
                onPressed: _toggleFlash,
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.black87, borderRadius: BorderRadius.circular(20)),
          child: Text(_statusMessage,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 30),
        GestureDetector(
          onTap: _isProcessing
              ? null
              : (_capturedImage == null ? _takePictureAndScan : _resetScanner),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              color: _isProcessing ? Colors.white10 : Colors.white24,
            ),
            child: _isProcessing
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                        color: Colors.cyanAccent, strokeWidth: 3))
                : Icon(
                    _capturedImage == null ? Icons.camera_alt : Icons.refresh,
                    size: 35,
                    color: Colors.white),
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final double rectWidth;
  final double rectHeight;
  final double borderRadius;
  ScannerOverlayPainter(
      {required this.rectWidth,
      required this.rectHeight,
      required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.7);
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: rectWidth,
            height: rectHeight),
        Radius.circular(borderRadius),
      ));
    canvas.drawPath(
        Path.combine(PathOperation.difference, backgroundPath, holePath),
        paint);

    final borderPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(size.width / 2, size.height / 2),
              width: rectWidth,
              height: rectHeight),
          Radius.circular(borderRadius),
        ),
        borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
