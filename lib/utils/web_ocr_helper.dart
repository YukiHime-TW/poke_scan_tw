import 'dart:async';
import 'dart:js_interop'; // 最新的 Web 通訊庫

// 1. 使用 Extension Type 定義 Tesseract 的 JavaScript 結構
// 這讓 Dart 知道 JS 物件裡有哪些方法可以呼叫
@JS('Tesseract')
extension type Tesseract(JSObject _) implements JSObject {
  external JSPromise recognize(JSString image, JSString lang);
}

// 定義 recognize 回傳的結果結構
extension type TesseractResult(JSObject _) implements JSObject {
  external TesseractData get data;
}

extension type TesseractData(JSObject _) implements JSObject {
  external String get text;
}

// 2. 宣告全域變數 Tesseract
@JS('Tesseract')
external Tesseract get tesseract;

class WebOCRHelper {
  static Future<String> scanImage(String imageUrl) async {
    try {
      // 呼叫 JS 方法：tesseract.recognize(url, 'eng')
      final promise = tesseract.recognize(imageUrl.toJS, 'eng'.toJS);
      
      // 將 JSPromise 轉為 Dart Future
      final result = await promise.toDart as TesseractResult;

      // 透過定義好的 getter 取得 text
      return result.data.text;
    } catch (e) {
      print("Web OCR Error: $e");
      return "";
    }
  }
}