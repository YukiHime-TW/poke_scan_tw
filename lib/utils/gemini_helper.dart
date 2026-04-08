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
            You are a professional Pokémon TCG card identifier. 
            1. Carefully look at the center of the image to identify the Pokémon or Trainer name.
            2. Locate the bottom-left or bottom-right corners for the set code (e.g., SV4a, AC1a) and the card number (e.g., 190/190).
            3. Based on the artwork and text, return ONLY a JSON object:
            {
              "setCode": "the expansion code",
              "cardNum": "the number part only"
            }
            Important: If you see "SV4a 190/190", setCode is "SV4a" and cardNum is "190".
            Respond with raw JSON only.
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
