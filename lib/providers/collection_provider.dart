import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class CollectionProvider with ChangeNotifier {
  Map<String, dynamic> _database = {};
  Map<String, int> _userCollection = {};
  bool _isLoading = true;
  User? _user;

  // --- GitHub Raw 網址配置 ---
  final String _remoteBaseUrl =
      "https://raw.githubusercontent.com/YukiHime-TW/poke_scan_tw/refs/heads/main/assets";

  bool get isLoading => _isLoading;
  Map<String, dynamic> get database => _database;
  Map<String, int> get userCollection => _userCollection;
  User? get user => _user;

  CollectionProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. 取得索引 (優先找網路，失敗則找內建)
      List<dynamic> setList = await _fetchIndex();
      _database = {};

      // 2. 平行下載/讀取所有擴充包
      List<Future<Map<String, dynamic>?>> futures = setList.map((code) async {
        String? jsonString = await _loadSetJson(code.toString());
        if (jsonString != null && jsonString.isNotEmpty) {
          try {
            return json.decode(jsonString) as Map<String, dynamic>;
          } catch (e) {
            print("❌ 解析 JSON 失敗 ($code): $e");
          }
        }
        return null;
      }).toList();

      final results = await Future.wait(futures);

      // 3. 關鍵修正：合併所有 JSON 到最頂層
      for (var data in results) {
        if (data != null) {
          _database.addAll(data);
        }
      }

      print("✅ 資料庫初始化完成，共載入 ${_database.length} 個擴充包");
    } catch (e) {
      print("⚠️ 初始化資料庫發生嚴重錯誤: $e");
    }

    // 4. 監聽 Firebase 登入狀態
    FirebaseAuth.instance.authStateChanges().listen((User? firebaseUser) async {
      _user = firebaseUser;
      if (firebaseUser != null) {
        await _loadFromCloud(firebaseUser.uid);
      } else {
        await _loadFromLocal();
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  // --- 資料讀取與更新邏輯 ---

  Future<List<dynamic>> _fetchIndex() async {
    try {
      final res = await http
          .get(Uri.parse('$_remoteBaseUrl/index.json'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return json.decode(res.body);
      }
    } catch (e) {
      print("⚠️ 無法獲取遠端索引: $e");
    }
    final String localIndex = await rootBundle.loadString('assets/index.json');
    return json.decode(localIndex);
  }

  Future<String?> _loadSetJson(String code) async {
    final String url = '$_remoteBaseUrl/sets/$code.json';

    if (kIsWeb) {
      try {
        final res = await http.get(Uri.parse(url));
        return res.statusCode == 200 ? res.body : null;
      } catch (e) {
        return null;
      }
    }

    // 手機版：硬碟快取與背景更新
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$code.json');

      String? cachedContent;
      if (await file.exists()) {
        cachedContent = await file.readAsString();
      }

      // 背景發起請求檢查更新
      http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10))
          .then((res) async {
        if (res.statusCode == 200 && res.body != cachedContent) {
          await file.writeAsString(res.body);
          print("🔄 卡包 $code 背景更新完成");
        }
      }).catchError((_) {});

      if (cachedContent != null) return cachedContent;
    } catch (e) {
      print("❌ 手機快取讀取失敗 ($code): $e");
    }

    // 最後保底 (讀取內建 APK 資源)
    try {
      return await rootBundle.loadString('assets/sets/$code.json');
    } catch (e) {
      return null;
    }
  }

  // --- 收藏同步邏輯 ---

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('my_collection');
    if (savedData != null) {
      Map<String, dynamic> decoded = json.decode(savedData);
      _userCollection =
          decoded.map((key, value) => MapEntry(key, value as int));
    } else {
      _userCollection = {};
    }
  }

  Future<void> _loadFromCloud(String uid) async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        var data = doc.get('data') as Map<String, dynamic>;
        _userCollection = data.map((key, value) => MapEntry(key, value as int));
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('my_collection', json.encode(_userCollection));
      } else if (_userCollection.isNotEmpty) {
        await _saveToCloud();
      }
    } catch (e) {
      print("雲端讀取失敗: $e");
      await _loadFromLocal();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('my_collection', json.encode(_userCollection));
    if (_user != null) await _saveToCloud();
  }

  Future<void> _saveToCloud() async {
    if (_user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'data': _userCollection,
        'last_updated': FieldValue.serverTimestamp(),
        'email': _user!.email,
        'name': _user!.displayName,
      }, SetOptions(merge: true));
    } catch (e) {
      print("雲端同步失敗: $e");
    }
  }

  // --- 查詢與修改邏輯 ---

  String? _findRealKeyInDatabase(String setCode, String inputNumber) {
    if (!_database.containsKey(setCode)) return null;
    Map<String, dynamic> cards = _database[setCode]['cards'];
    String cleanNum = inputNumber.split('/')[0].trim().padLeft(3, '0');
    if (cards.containsKey(cleanNum)) return cleanNum;
    for (String dbKey in cards.keys) {
      if (dbKey == cleanNum || dbKey.startsWith("$cleanNum/")) return dbKey;
    }
    return null;
  }

  Map<String, dynamic>? getCardInfo(String setCode, String rawCardNum) {
    String searchSet = setCode.toUpperCase();
    String? realSetKey = _database.keys
        .firstWhere((k) => k.toUpperCase() == searchSet, orElse: () => setCode);
    String? realKey = _findRealKeyInDatabase(realSetKey, rawCardNum);
    if (realKey != null) return _database[realSetKey]['cards'][realKey];
    return null;
  }

  Future<void> addCard(String setCode, String rawCardNum) async {
    String? realKey = _findRealKeyInDatabase(setCode, rawCardNum);
    if (realKey != null) {
      String storageKey = "$setCode-$realKey";
      _userCollection[storageKey] = (_userCollection[storageKey] ?? 0) + 1;
      notifyListeners();
      _save();
    }
  }

  Future<void> removeCard(String setCode, String rawCardNum) async {
    String? realKey = _findRealKeyInDatabase(setCode, rawCardNum);
    if (realKey != null) {
      String key = "$setCode-$realKey";
      if (_userCollection.containsKey(key)) {
        if (_userCollection[key]! > 1) {
          _userCollection[key] = _userCollection[key]! - 1;
        } else {
          _userCollection.remove(key);
        }
        notifyListeners();
        _save();
      }
    }
  }

  // --- 登入/登出 ---

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print("登入錯誤: $e");
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print("登出錯誤: $e");
    }
  }

  // --- OCR 智慧處理 ---

  Future<String?> processScannedText(String rawText, {dynamic deckProvider}) async {
    print("🔍 OCR 原始讀取內容: \n$rawText");

    print("🔍 OCR 全文讀取: \n$rawText");

    // 1. 預處理：去除括號與雜質，但保留斜線 (因為編號常有 037/078)
    String cleanText = rawText
        .toUpperCase()
        .replaceAll('(', ' ')
        .replaceAll(')', ' ')
        .replaceAll('[', ' ')
        .replaceAll(']', ' ')
        .replaceAll('|', '1');

    // 2. 強化版 Regex
    // 我們尋找：[系列代號] + [空格] + [編號] (後面可能有 /總數)
    // 例如: "SV4A 123" 或 "SV4A 123/190"
    final RegExp regex = RegExp(r'([A-Z0-9\-]{2,8})\s+(\d{1,3})(?:/\d+)?');
    final matches = regex.allMatches(cleanText);

    if (matches.isEmpty) return null;

    // 我們優先處理「靠後面」的匹配，因為編號通常在卡片底部
    final reversedMatches = matches.toList().reversed;

    for (var match in reversedMatches) {
      String detectedSet = match.group(1)!.trim();
      String detectedNum = match.group(2)!.trim();
      String formattedNum = detectedNum.padLeft(3, '0');

      print("🎯 處理片段: 系列[$detectedSet] 編號[$formattedNum]");

      // --- 核心優化：資料庫 Key 匹配策略 ---
      String? bestSetMatch;

      // 方法 A: 直接檢查資料庫的 Key 是否被「包含」在偵測到的字串中
      // 例如：detectedSet "GSV1V" 包含了資料庫的 "SV1V"
      for (String dbKey in _database.keys) {
        String upperDbKey = dbKey.toUpperCase();

        // 1. 完整包含比對
        if (detectedSet.contains(upperDbKey)) {
          bestSetMatch = dbKey;
          break;
        }

        // 2. OCR 規範化比對 (處理 1 / L / I / V 互換)
        String normDetected = _normalizeForOCR(detectedSet);
        String normDbKey = _normalizeForOCR(upperDbKey);

        if (normDetected.contains(normDbKey) ||
            normDbKey.contains(normDetected)) {
          // 如果長度相近且規範化後匹配
          if ((detectedSet.length - upperDbKey.length).abs() <= 2) {
            bestSetMatch = dbKey;
            break;
          }
        }
      }

      if (bestSetMatch != null) {
        var cardInfo = getCardInfo(bestSetMatch, formattedNum);
        if (cardInfo != null) {
          String fullName = "${cardInfo['name']} ($bestSetMatch-$formattedNum)";
          if (deckProvider != null && deckProvider.currentDeck != null) {
            deckProvider.addCardToDeck(
                "$bestSetMatch-$formattedNum", cardInfo['name'], _database);
            return "【牌組】$fullName";
          } else {
            await addCard(bestSetMatch, formattedNum);
            return "【收藏】$fullName";
          }
        }
      }
    }
    return null;
  }

  // 將長得像的字元統一，大幅提升 OCR 匹配率
  String _normalizeForOCR(String input) {
    return input
        .replaceAll('L', '1')
        .replaceAll('I', '1')
        .replaceAll('|', '1')
        .replaceAll('V', '1') // 有時候 SV1V 的 V 會被讀成 1
        .replaceAll('S', '5')
        .replaceAll('O', '0');
  }

}