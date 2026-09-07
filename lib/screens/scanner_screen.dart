import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../providers/collection_provider.dart';
import '../providers/deck_provider.dart';
import '../utils/card_matcher.dart';

// --- 裁切框的幾何（畫面比例）---
// 紅框給使用者對準的可見區域
const double _boxCx = 0.5, _boxCy = 0.60; // 中心：水平置中、垂直偏下
const double _boxW = 0.66, _boxH = 0.13;
// 實際裁下來丟 OCR 的區域：比紅框大一圈，容忍預覽/實拍的長寬比誤差
const double _cropW = 0.74, _cropH = 0.22;

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
  String _statusMessage = "請將卡片【左下角編號】對準紅框";
  bool _isFlashOn = false;

  ScanCandidate? _pendingConfirm; // 低信心 -> 跳確認

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
      ResolutionPreset.veryHigh, // 1080p：夠讀小編號又不會像 max 那樣拖慢
      enableAudio: false,
    );

    try {
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (mounted) setState(() => _controller = controller);
    } catch (e) {
      debugPrint("相機啟動失敗: $e");
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
        _statusMessage = "辨識中…";
      });

      final File croppedFile = await _processAndCropImage(rawImage);
      setState(() => _capturedImage = XFile(croppedFile.path));

      final inputImage = InputImage.fromFile(croppedFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // 用 blocks/lines 的 bounding box，把文字行由「畫面下方往上」排
      final withY = <({String text, double y})>[];
      for (final b in recognizedText.blocks) {
        for (final l in b.lines) {
          withY.add((text: l.text, y: l.boundingBox.center.dy));
        }
      }
      withY.sort((a, b) => b.y.compareTo(a.y));
      final bottomFirst = withY.map((e) => e.text).toList();
      if (bottomFirst.isEmpty && recognizedText.text.trim().isNotEmpty) {
        bottomFirst.addAll(recognizedText.text.split('\n'));
      }

      final collection =
          Provider.of<CollectionProvider>(context, listen: false);
      final deck = Provider.of<DeckProvider>(context, listen: false);
      final ScanCandidate? cand = collection.analyzeScan(bottomFirst);

      if (!mounted) return;

      if (cand == null) {
        HapticFeedback.lightImpact();
        setState(() {
          _statusMessage = "🤔 認不出編號，換個角度或開閃光燈再試";
          _isProcessing = false;
        });
        return;
      }

      if (cand.isHighConfidence) {
        final label = await collection.commitScan(cand, deckProvider: deck);
        HapticFeedback.vibrate();
        if (!mounted) return;
        setState(() => _statusMessage = "✅ $label");
        await Future.delayed(const Duration(milliseconds: 1200));
        _resetScanner();
      } else {
        // 低信心 -> 跳確認
        HapticFeedback.selectionClick();
        setState(() {
          _pendingConfirm = cand;
          _isProcessing = false;
          _statusMessage = "是這張嗎？";
        });
      }
    } catch (e) {
      debugPrint("掃描出錯: $e");
      _resetScanner();
    }
  }

  Future<void> _confirmPending(bool yes) async {
    final cand = _pendingConfirm;
    setState(() => _pendingConfirm = null);
    if (cand == null) return;
    if (!yes) {
      _resetScanner();
      return;
    }
    final collection = Provider.of<CollectionProvider>(context, listen: false);
    final deck = Provider.of<DeckProvider>(context, listen: false);
    final label = await collection.commitScan(cand, deckProvider: deck);
    HapticFeedback.vibrate();
    if (!mounted) return;
    setState(() => _statusMessage = "✅ $label");
    await Future.delayed(const Duration(milliseconds: 1000));
    _resetScanner();
  }

  // 裁切：直接取「擷取到的圖片本身」的固定比例，不再靠螢幕座標換算
  // （CameraPreview 不是 cover-fit，用螢幕矩形去對圖片會裁錯位置）
  Future<File> _processAndCropImage(XFile xFile) async {
    final bytes = await xFile.readAsBytes();
    img.Image? src = img.decodeImage(bytes);
    if (src == null) return File(xFile.path);
    src = img.bakeOrientation(src);

    int cw = (src.width * _cropW).round();
    int ch = (src.height * _cropH).round();
    int cx = ((src.width * _boxCx) - cw / 2).round().clamp(0, src.width - cw);
    int cy = ((src.height * _boxCy) - ch / 2).round().clamp(0, src.height - ch);

    img.Image out = img.copyCrop(src, x: cx, y: cy, width: cw, height: ch);

    // 太小的話放大，幫 OCR
    if (out.width < 1000) {
      out = img.copyResize(out, width: 1400);
    }
    // 前處理：灰階 + 拉對比，小編號讀得比較準
    out = img.grayscale(out);
    out = img.contrast(out, contrast: 135);

    final tempDir = await getTemporaryDirectory();
    final f = File(
        '${tempDir.path}/code_crop_${DateTime.now().millisecondsSinceEpoch}.png');
    await f.writeAsBytes(img.encodePng(out)); // PNG 無損，利於文字辨識
    return f;
  }

  void _resetScanner() {
    if (!mounted) return;
    setState(() {
      _capturedImage = null;
      _isProcessing = false;
      _pendingConfirm = null;
      _statusMessage = "請將卡片【左下角編號】對準紅框";
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
                    width: 320, fit: BoxFit.contain))
          else if (isReady)
            CameraPreview(_controller!)
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          if (isReady && _capturedImage == null)
            Positioned.fill(
              child: CustomPaint(painter: ScannerOverlayPainter()),
            ),
          if (_pendingConfirm != null) _buildConfirmPanel() else _buildUI(),
        ],
      ),
    );
  }

  Widget _buildConfirmPanel() {
    final c = _pendingConfirm!;
    final img = (c.cardData['image'] ?? '').toString();
    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("是這張嗎？",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (img.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320, maxWidth: 240),
                child: Image.network(img, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox(height: 200, child: Icon(Icons.image_not_supported, color: Colors.white54, size: 60))),
              ),
            const SizedBox(height: 10),
            Text("${c.cardData['name'] ?? ''}  (${c.setCode}-${c.cardKey})",
                style: const TextStyle(color: Colors.white, fontSize: 15)),
            Text("信心分數 ${c.score.toStringAsFixed(0)}",
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12)),
                  onPressed: () => _confirmPending(true),
                  icon: const Icon(Icons.check),
                  label: const Text("就是這張"),
                ),
                const SizedBox(width: 20),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12)),
                  onPressed: () => _confirmPending(false),
                  icon: const Icon(Icons.refresh),
                  label: const Text("重掃"),
                ),
              ],
            ),
          ],
        ),
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
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width * _boxCx, size.height * _boxCy),
      width: size.width * _boxW,
      height: size.height * _boxH,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));

    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.7);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(rrect),
      ),
      scrim,
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.redAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
