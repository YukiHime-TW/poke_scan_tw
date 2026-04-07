import 'dart:async';
import 'dart:js_interop'; // 使用最新的 Interop 庫

// 定義 JavaScript 的 Tesseract 全域物件結構
@JS('Tesseract')
external JSObject get tesseract;

class WebOCRHelper {
  static Future<String> scanImage(String imageUrl) async {
    try {
      // 取得 Tesseract.recognize 方法
      final JSFunction recognize =
          tesseract.getProperty('recognize'.toJS) as JSFunction;

      // 呼叫方法：recognize(url, 'eng')
      // 這會回傳一個 JSPromise
      final JSPromise promise = recognize.callAsFunction(
          tesseract, imageUrl.toJS, 'eng'.toJS) as JSPromise;

      // 等待 Promise 轉換為 Dart Future
      final JSObject result = await promise.toDart as JSObject;

      // 取得 result.data.text
      final JSObject data = result.getProperty('data'.toJS) as JSObject;
      final JSString text = data.getProperty('text'.toJS) as JSString;

      return text.toDart;
    } catch (e) {
      print("Web OCR Error (Wasm compatible): $e");
      return "";
    }
  }
}
