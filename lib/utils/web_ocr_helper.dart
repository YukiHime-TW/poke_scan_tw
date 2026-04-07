import 'dart:async';
import 'dart:js_util'; // 必須要有這個，才能處理 JavaScript 的 Promise
import 'package:js/js.dart'; // 處理 @JS 註解

// 告訴 Dart 這是要呼叫 JS 全域變數 Tesseract 中的 recognize 方法
@JS('Tesseract.recognize')
external dynamic _recognize(dynamic image, String lang);

class WebOCRHelper {
  static Future<String> scanImage(String imageUrl) async {
    try {
      // 呼叫 JavaScript 方法，這會回傳一個 JS Promise
      final jsPromise = _recognize(imageUrl, 'eng');

      // 將 JS Promise 轉換為 Dart 的 Future
      final result = await promiseToFuture(jsPromise);

      // 從回傳的 JS 物件中提取 data.text
      // JS 結構是 result.data.text
      final data = getProperty(result, 'data');
      final String text = getProperty(data, 'text');

      return text;
    } catch (e) {
      print("Web OCR Error: $e");
      return "";
    }
  }
}