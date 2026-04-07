import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/collection_provider.dart';
import '../utils/web_ocr_helper.dart';

class WebScannerScreen extends StatefulWidget {
  const WebScannerScreen({super.key});

  @override
  State<WebScannerScreen> createState() => _WebScannerScreenState();
}

class _WebScannerScreenState extends State<WebScannerScreen> {
  CameraController? _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // 嘗試獲取相機列表
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        _showMsg("找不到任何相機設備", Colors.orange);
        return;
      }

      _controller = CameraController(
        // 優先找後鏡頭，找不到就找第一個
        cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        ),
        ResolutionPreset.high,
      );

      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      // 捕捉到那個 JSArray 錯誤或是權限錯誤
      print("相機初始化發生錯誤: $e");
      _showMsg("無法啟動相機。請確保已允許相機權限，且正在使用安全連線 (localhost 或 HTTPS)", Colors.red);
    }
  }

  Future<void> _takePictureAndScan() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final XFile image = await _controller!.takePicture();
      // 在 Web 上，image.path 是一個可以被 Tesseract 讀取的 Blob URL
      final String recognizedText = await WebOCRHelper.scanImage(image.path);
      await _processRawText(recognizedText);
    } catch (e) {
      _showMsg("辨識錯誤: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _processRawText(String text) async {
    final provider = Provider.of<CollectionProvider>(context, listen: false);
    final RegExp regex = RegExp(r'([A-Z0-9\-]{2,6})\s*(\d{1,3})');
    final match = regex.firstMatch(text.toUpperCase());

    if (match != null) {
      String setCode = match.group(1)!;
      String cardNum = match.group(2)!;
      var cardInfo = provider.getCardInfo(setCode, cardNum);

      if (cardInfo != null) {
        provider.addCard(setCode, cardNum);
        _showMsg(
            "🎉 成功識別: ${cardInfo['name']} ($setCode-$cardNum)", Colors.green);
        return;
      }
    }
    _showMsg("🤔 未能識別卡號，請再試一次", Colors.orange);
  }

  void _showMsg(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: CameraPreview(_controller!)),
          // 覆蓋層 (復刻你的手機版 UI)
          _buildOverlay(),
          // 返回按鈕
          Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context))),
          // 拍照按鈕
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePictureAndScan,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: _isProcessing ? Colors.grey : Colors.white24),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.camera_alt,
                          size: 40, color: Colors.white),
                ),
              ),
            ),
          ),
          const Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: Text("網頁版掃描模式\n請將編號對準紅框後拍照",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)]))),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Center(
      child: Container(
        width: 300,
        height: 100,
        decoration: BoxDecoration(
            border: Border.all(color: Colors.redAccent, width: 2),
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
