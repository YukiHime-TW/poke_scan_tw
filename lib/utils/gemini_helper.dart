import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class GeminiHelper {
  // 關鍵：使用 const String.fromEnvironment 從編譯環境抓取變數
  // 這樣在編譯時，變數就會被直接替換掉
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  static Future<Map<String, String>?> identifyCard(Uint8List imageBytes) async {
    if (_apiKey.isEmpty) {
      print("❌ 錯誤：找不到 GEMINI_API_KEY，請確認編譯參數是否包含 --dart-define");
      return null;
    }

    try {
      final model = GenerativeModel(model: 'gemini-flash-latest', apiKey: _apiKey);

      final prompt = [
        Content.multi([
          DataPart('image/jpeg', imageBytes),
          TextPart("""
            Identify this Pokémon TCG card from the image. 
            Return the result ONLY in the following JSON format:
            {
              "setCode": "Expansion set code, e.g., SV4a",
              "cardNum": "Card number, e.g., 190"
            }
            Do not include any other text or explanation. 
            Respond only with the raw JSON string.
          """),
        ])
      ];

      final response = await model.generateContent(prompt);
      final text = response.text;

      if (text != null) {
        String cleanJson = text
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .replaceAll(RegExp(r'^[^{]*'), '')
            .replaceAll(RegExp(r'[^}]*$'), '')
            .trim();

        final Map<String, dynamic> data = json.decode(cleanJson);
        return {
          "setCode": data['setCode'].toString(),
          "cardNum": data['cardNum'].toString(),
        };
      }
    } catch (e) {
      print("Gemini 辨識出錯: $e");
    }
    return null;
  }
}
