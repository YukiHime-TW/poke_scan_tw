import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img; // 必須安裝: flutter pub add image
import '../providers/collection_provider.dart';
import '../providers/deck_provider.dart';
import '../utils/gemini_helper.dart';

class WebScannerScreen extends StatefulWidget {
  const WebScannerScreen({super.key});

  @override
  State<WebScannerScreen> createState() => _WebScannerScreenState();
}

class _WebScannerScreenState extends State<WebScannerScreen> {
  CameraController? _controller;
  bool _isProcessing = false;
  Uint8List? _croppedBytes; // 新增：儲存裁切後的圖片數據

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _controller = CameraController(
        cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first),
        ResolutionPreset.max,
      );

      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      _showMsg("相機初始化失敗", Colors.red);
    }
  }

  Future<void> _takePictureAndScan() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) return;

    try {
      // 1. 拍照
      final XFile image = await _controller!.takePicture();
      final Uint8List originalBytes = await image.readAsBytes();

      // 2. 立即進行裁切
      final Uint8List cropped = await _cropToRedBox(originalBytes);

      // 3. 凍結畫面：只顯示裁切後的圖案
      setState(() {
        _isProcessing = true;
        _croppedBytes = cropped;
      });

      // 4. 將裁切後的圖傳給 AI
      final result = await GeminiHelper.identifyCard(cropped);

      if (result != null) {
        await _processIdentifiedCard(
            result['setCode'] ?? "", result['cardNum'] ?? "");
      } else {
        _showMsg("🤔 AI 無法辨識卡片", Colors.orange);
      }
    } catch (e) {
      _showMsg("錯誤: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // 核心：裁切邏輯
  Future<Uint8List> _cropToRedBox(Uint8List bytes) async {
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;

    // 取得當前螢幕尺寸 (假設 CameraPreview 填滿螢幕)
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;

    // 我們定義的紅框尺寸
    const double boxW = 280.0;
    const double boxH = 390.0;

    // 計算圖片與螢幕的比例
    final double factorX = image.width / screenW;
    final double factorY = image.height / screenH;

    // 計算裁切區域
    final int cropW = (boxW * factorX).toInt();
    final int cropH = (boxH * factorY).toInt();
    final int cropX = ((image.width - cropW) / 2).toInt();
    final int cropY = ((image.height - cropH) / 2).toInt();

    // 裁切
    img.Image cropped =
        img.copyCrop(image, x: cropX, y: cropY, width: cropW, height: cropH);

    return Uint8List.fromList(img.encodeJpg(cropped, quality: 85));
  }

  void _resetScanner() {
    setState(() {
      _croppedBytes = null;
      _isProcessing = false;
    });
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
          // --- 邏輯切換：如果已經拍完裁切好了，就顯示那塊小圖；否則顯示鏡頭 ---
          if (_croppedBytes != null)
            Center(
              child: Container(
                width: 280,
                height: 390,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.greenAccent, width: 3),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.5), blurRadius: 20)
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_croppedBytes!, fit: BoxFit.cover),
                ),
              ),
            )
          else
            SizedBox.expand(child: CameraPreview(_controller!)),

          // 只有在預覽時顯示遮罩
          if (_croppedBytes == null) _buildOverlay(),

          // 頂部返回
          Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context))),

          // 底部控制
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_croppedBytes != null && !_isProcessing)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24),
                    onPressed: _resetScanner,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text("重新拍攝",
                        style: TextStyle(color: Colors.white)),
                  ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _croppedBytes == null ? _takePictureAndScan : null,
                  child: Container(
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
                        : const Icon(Icons.camera_alt,
                            size: 40, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // 提示文字
          Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Text(
                _isProcessing
                    ? "AI 辨識中..."
                    : (_croppedBytes != null ? "辨識完成" : "請將卡片放入框內後拍照"),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 10, color: Colors.black)]),
              )),
        ],
      ),
    );
  }

  // 原有的 _buildOverlay, _processIdentifiedCard, _showMsg, dispose 保持不變
  Widget _buildOverlay() {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter:
              ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.srcOut),
          child: Stack(
            children: [
              Container(color: Colors.black),
              Center(
                child: Container(
                  width: 280,
                  height: 390,
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Container(
            width: 280,
            height: 390,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.redAccent, width: 3),
                borderRadius: BorderRadius.circular(15)),
          ),
        ),
      ],
    );
  }

  Future<void> _processIdentifiedCard(String setCode, String cardNum) async {
    final collectionProvider =
        Provider.of<CollectionProvider>(context, listen: false);
    final deckProvider = Provider.of<DeckProvider>(context, listen: false);
    String formattedNum = cardNum.padLeft(3, '0');
    var cardInfo = collectionProvider.getCardInfo(setCode, formattedNum);

    if (cardInfo != null) {
      String fullName = "${cardInfo['name']} ($setCode-$formattedNum)";
      if (deckProvider.currentDeck != null) {
        deckProvider.addCardToDeck("$setCode-$formattedNum", cardInfo['name'],
            collectionProvider.database);
        _showMsg("🎉 【牌組】已加入: $fullName", Colors.green);
      } else {
        await collectionProvider.addCard(setCode, formattedNum);
        _showMsg("🎉 【收藏】已加入: $fullName", Colors.green);
      }
      Future.delayed(const Duration(seconds: 1), () => _resetScanner());
    } else {
      _showMsg("找不到卡片: $setCode-$cardNum", Colors.orange);
    }
  }

  void _showMsg(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3)));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
