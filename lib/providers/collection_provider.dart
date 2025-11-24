import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CollectionProvider with ChangeNotifier {
  Map<String, dynamic> _database = {};
  Map<String, int> _userCollection = {};
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  Map<String, dynamic> get database => _database;
  Map<String, int> get userCollection => _userCollection;

  CollectionProvider() {
    _init();
  }

  Future<void> _init() async {
    // 1. 載入 JSON
    final String jsonString = await rootBundle.loadString('assets/data.json');
    _database = json.decode(jsonString);

    // 2. 載入使用者收藏
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('my_collection');
    if (savedData != null) {
      Map<String, dynamic> decoded = json.decode(savedData);
      _userCollection =
          decoded.map((key, value) => MapEntry(key, value as int));
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- 核心修改：智慧型 Key 搜尋器 ---
  // 這個函式負責把 "001" 轉換成資料庫裡真正的 Key "001/158"
  String? _findRealKeyInDatabase(String setCode, String inputNumber) {
    if (!_database.containsKey(setCode)) return null;

    Map<String, dynamic> cards = _database[setCode]['cards'];

    // 1. 清理輸入：只取斜線前的數字，並補零 (例如 "1/158" -> "001")
    String cleanNum = inputNumber.split('/')[0].trim().padLeft(3, '0');

    // 2. 直接比對 (如果運氣好，資料庫剛好是 "001")
    if (cards.containsKey(cleanNum)) {
      return cleanNum;
    }

    // 3. 模糊比對 (資料庫是 "001/158"，我們要找開頭是 "001/" 的)
    // 我們遍歷該系列所有的 Key
    for (String dbKey in cards.keys) {
      // 檢查 dbKey 是否以 "001/" 開頭
      // 或是 dbKey 剛好就是 "001" (防止漏網之魚)
      if (dbKey == cleanNum || dbKey.startsWith("$cleanNum/")) {
        return dbKey; // 找到了！回傳完整的 "001/158"
      }
    }

    return null; // 真的找不到
  }

  // 加入卡片
  Future<void> addCard(String setCode, String rawCardNum) async {
    // 使用上面的智慧搜尋器找出真正的 Key
    String? realKey = _findRealKeyInDatabase(setCode, rawCardNum);

    if (realKey != null) {
      // 組合唯一 ID，這裡我們用 "系列-完整編號" (例如 S4a-001/190)
      // 這樣能確保 Key 是獨一無二的
      String storageKey = "$setCode-$realKey";

      if (_userCollection.containsKey(storageKey)) {
        _userCollection[storageKey] = _userCollection[storageKey]! + 1;
      } else {
        _userCollection[storageKey] = 1;
      }

      notifyListeners();
      _saveToDisk();
      print("已收藏: $storageKey (原始輸入: $rawCardNum)");
    } else {
      print("❌ 找不到卡片: $setCode $rawCardNum");
    }
  }

  // 取得卡片資訊 (給掃描器顯示名稱用)
  Map<String, dynamic>? getCardInfo(String setCode, String rawCardNum) {
    String? realKey = _findRealKeyInDatabase(setCode, rawCardNum);
    if (realKey != null) {
      return _database[setCode]['cards'][realKey];
    }
    return null;
  }

  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('my_collection', json.encode(_userCollection));
  }
}
