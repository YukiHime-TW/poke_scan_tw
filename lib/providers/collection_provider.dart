import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class CollectionProvider with ChangeNotifier {
  Map<String, dynamic> _database = {};
  Map<String, int> _userCollection = {};
  bool _isLoading = true;

  // 恢復使用本地變數來儲存 User，由 Stream 控制
  User? _user;

  bool get isLoading => _isLoading;
  Map<String, dynamic> get database => _database;
  Map<String, int> get userCollection => _userCollection;
  User? get user => _user; // UI 讀取這個變數

  CollectionProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      // 1. 先讀取索引檔 (目錄)
      final String indexString =
          await rootBundle.loadString('assets/index.json');
      List<dynamic> setList = json.decode(indexString);

      // 2. 準備平行讀取所有擴充包
      // 我們建立一個 Future 列表，讓所有檔案同時開始讀取，速度最快
      List<Future<String>> futures = setList.map((code) {
        return rootBundle.loadString('assets/sets/$code.json');
      }).toList();

      // 3. 等待所有檔案讀取完成
      final List<String> results = await Future.wait(futures);

      // 4. 合併資料
      _database = {};
      for (String jsonString in results) {
        Map<String, dynamic> part = json.decode(jsonString);
        _database.addAll(part);
      }

      print("✅ 資料庫載入完成，共載入 ${setList.length} 個擴充包");
    } catch (e) {
      print("⚠️ 資料庫載入失敗: $e");
    }

    // 5. 監聽 Firebase (保持原本邏輯)
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

  // --- 讀取邏輯 ---
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

        // 同步備份到本地
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('my_collection', json.encode(_userCollection));
      } else {
        if (_userCollection.isNotEmpty) {
          await _saveToCloud();
        }
      }
    } catch (e) {
      print("雲端讀取失敗: $e");
      await _loadFromLocal();
    }
  }

  // --- 寫入邏輯 ---
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('my_collection', json.encode(_userCollection));

    if (_user != null) {
      await _saveToCloud();
    }
  }

  Future<void> _saveToCloud() async {
    if (_user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'data': _userCollection,
        'last_updated': FieldValue.serverTimestamp(),
        'email': _user!.email,
        'name': _user!.displayName,
      }, SetOptions(merge: true)); // merge: true 會自動判斷是新增還是更新
      print("✅ 收藏已同步至雲端");
    } catch (e) {
      print("❌ 收藏雲端同步失敗: $e");
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

  // --- 修改卡片與查詢 ---

  // 內部使用：找尋真正的 Key (解決 "001" vs "001/158" 的問題)
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
    // 1. 全部轉大寫匹配
    String searchSet = setCode.toUpperCase();

    // 2. 找到對應的 Set (遍歷 database 的 keys 進行不分大小寫匹配)
    String? realSetKey = _database.keys
        .firstWhere((k) => k.toUpperCase() == searchSet, orElse: () => setCode);

    String? realKey = _findRealKeyInDatabase(realSetKey, rawCardNum);
    if (realKey != null) {
      return _database[realSetKey]['cards'][realKey];
    }
    return null;
  }

  Future<void> addCard(String setCode, String rawCardNum) async {
    String? realKey = _findRealKeyInDatabase(setCode, rawCardNum);
    if (realKey != null) {
      String storageKey = "$setCode-$realKey";
      if (_userCollection.containsKey(storageKey)) {
        _userCollection[storageKey] = _userCollection[storageKey]! + 1;
      } else {
        _userCollection[storageKey] = 1;
      }
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

  // --- 智慧辨識處理核心 ---
  // isDeckMode: 是否為牌組編輯模式 (如果是，則自動加入牌組；否則加入收藏)
  // deckProvider: 傳入 DeckProvider 供牌組模式使用
  Future<String?> processScannedText(String rawText,
      {dynamic deckProvider}) async {
    // 1. 預處理字串：轉大寫、去除多餘換行、修正常見 OCR 錯誤
    String cleanText = rawText
        .toUpperCase()
        .replaceAll('O', '0') // 字母 O 轉 數字 0
        .replaceAll('I', '1') // 字母 I 轉 數字 1
        .replaceAll('S', '5') // 字母 S 轉 數字 5
        .replaceAll('Z', '2') // 字母 Z 轉 數字 2
        .replaceAll('|', ''); // 去除 OCR 常見的垂直線噪音

    // 2. Regex 匹配：(系列號) (卡號)
    // 支援格式：SV4a 190/190, S-P 001, SV-P 005 等
    // 群組 1: 系列號 (2-6位 A-Z, 0-9 或 -)
    // 群組 2: 卡號 (1-3位數字)
    final RegExp regex = RegExp(r'([A-Z0-9\-]{2,6})\s*(\d{1,3})');
    final matches = regex.allMatches(cleanText);

    if (matches.isEmpty) return null;

    String? lastAddedInfo;

    for (var match in matches) {
      String setCode = match.group(1)!;
      String cardNum = match.group(2)!.padLeft(3, '0'); // 自動補零成 001

      // 3. 驗證資料庫是否存在
      var cardInfo = getCardInfo(setCode, cardNum);

      // 如果找不到，嘗試針對 SetCode 做模糊修正
      if (cardInfo == null) {
        // 修正常見系列號錯誤，例如 '5V4A' 修正回 'SV4A'
        if (setCode.startsWith('5V'))
          setCode = setCode.replaceFirst('5V', 'SV');
        cardInfo = getCardInfo(setCode, cardNum);
      }

      if (cardInfo != null) {
        // 4. 根據模式自動加入
        if (deckProvider != null && deckProvider.currentDeck != null) {
          // 牌組編輯模式：加入目前牌組
          String fullId = "$setCode-$cardNum";
          deckProvider.addCardToDeck(fullId, cardInfo['name'], _database);
          lastAddedInfo = "【牌組】${cardInfo['name']} ($setCode-$cardNum)";
        } else {
          // 收藏模式：加入我的收藏
          await addCard(setCode, cardNum);
          lastAddedInfo = "【收藏】${cardInfo['name']} ($setCode-$cardNum)";
        }
        // 成功辨識一張就先回傳（或你想一次掃多張可改為 List）
        return lastAddedInfo;
      }
    }
    return null;
  }
}
