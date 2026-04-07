import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart'; // 需在 pubspec.yaml 新增
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/collection_provider.dart';
import '../providers/deck_provider.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool _isProcessing = false;
  
  // 相機控制參數
  bool _isFlashOn = false;
  double _currentZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  // 監聽 App 生命週期 (切換到背景再回來時重啟相機)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        // 選擇後鏡頭
        final camera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );

        _controller = CameraController(
          camera,
          ResolutionPreset.high, // 使用高解析度以看清小字
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );

        try {
          await _controller!.initialize();
          
          // 取得變焦範圍
          _minZoomLevel = await _controller!.getMinZoomLevel();
          _maxZoomLevel = await _controller!.getMaxZoomLevel();

          if (mounted) {
            setState(() {
              _isCameraInitialized = true;
            });
          }
        } catch (e) {
          print("相機初始化失敗: $e");
        }
      }
    } else {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("請允許相機權限以進行掃描"))
        );
      }
    }
  }

  // 切換閃光燈
  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    try {
      _isFlashOn = !_isFlashOn;
      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off
      );
      setState(() {});
    } catch (e) {
      print("閃光燈錯誤: $e");
    }
  }

  // 設定變焦
  Future<void> _setZoom(double value) async {
    if (_controller == null) return;
    try {
      await _controller!.setZoomLevel(value);
      setState(() {
        _currentZoomLevel = value;
      });
    } catch (e) {
      print("變焦錯誤: $e");
    }
  }

  // 核心邏輯：拍照並辨識
  Future<void> _takePictureAndScan() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // 1. 拍照
      final XFile image = await _controller!.takePicture();
      // 2. 建立 InputImage
      final inputImage = InputImage.fromFilePath(image.path);
      // 3. 執行辨識
      await _processInputImage(inputImage);
    } catch (e) {
      print("掃描錯誤: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("掃描發生錯誤: $e"))
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // 從相簿選圖並辨識
  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() => _isProcessing = true);
        final inputImage = InputImage.fromFilePath(image.path);
        await _processInputImage(inputImage);
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      print("相簿選圖錯誤: $e");
    }
  }

  // 共用的文字解析邏輯
  Future<void> _processInputImage(InputImage inputImage) async {
    final recognizedText = await _textRecognizer.processImage(inputImage);
    final collectionProvider =
        Provider.of<CollectionProvider>(context, listen: false);
    final deckProvider = Provider.of<DeckProvider>(context, listen: false);

    String fullText = "";
    for (TextBlock block in recognizedText.blocks) {
      fullText += "${block.text} ";
    }

    // 呼叫智慧處理邏輯
    final resultInfo = await collectionProvider.processScannedText(fullText,
        deckProvider: deckProvider);

    if (mounted) {
      if (resultInfo != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("🎉 $resultInfo"),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 1500)));
        // 如果想連拍，這裡不需要 Navigator.pop
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. 相機預覽 (全螢幕)
          Center(
            child: CameraPreview(_controller!),
          ),

          // 2. 掃描框框與遮罩
          _buildOverlay(),

          // 3. 頂部工具列 (返回、閃光燈)
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
                IconButton(
                  icon: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white, 
                    size: 30
                  ),
                  onPressed: _toggleFlash,
                ),
              ],
            ),
          ),

          // 4. 底部控制區 (變焦、快門、相簿)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // 變焦滑桿
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    children: [
                      const Icon(Icons.zoom_out, color: Colors.white, size: 20),
                      Expanded(
                        child: Slider(
                          value: _currentZoomLevel,
                          min: _minZoomLevel,
                          max: _maxZoomLevel > 5.0 ? 5.0 : _maxZoomLevel, // 限制最大 5 倍
                          activeColor: Colors.white,
                          inactiveColor: Colors.white24,
                          onChanged: (value) => _setZoom(value),
                        ),
                      ),
                      const Icon(Icons.zoom_in, color: Colors.white, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // 按鈕區
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 相簿按鈕
                    IconButton(
                      icon: const Icon(Icons.photo_library, color: Colors.white, size: 30),
                      onPressed: _pickImageFromGallery,
                    ),
                    
                    // 拍照掃描按鈕
                    GestureDetector(
                      onTap: _takePictureAndScan,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: _isProcessing ? Colors.grey : Colors.white24,
                        ),
                        child: _isProcessing 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(Icons.document_scanner, size: 40, color: Colors.white),
                      ),
                    ),
                    
                    // 佔位符 (保持排版平衡)
                    const SizedBox(width: 50),
                  ],
                ),
              ],
            ),
          ),
          
          // 5. 提示文字
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Text(
              "請將【左下角編號】對準中央紅框\n(例如: SV4a 001/190)",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 建立遮罩與掃描框
  Widget _buildOverlay() {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.black54,
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 300,
                    height: 100, // 扁長型框框，適合掃描一行字的卡號
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 紅色邊框線 (視覺輔助)
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 300,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.redAccent, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}