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
      // 【修改重點】
      // 嘗試使用 update 來 "覆蓋" data 欄位
      // 這樣當本地刪除卡片時，雲端也會跟著變成空的，而不是保留舊資料
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({
        'data': _userCollection,
        'last_updated': FieldValue.serverTimestamp(),
        // 這裡可以順便更新基本資料，確保最新
        'email': _user!.email,
        'name': _user!.displayName,
      });
    } catch (e) {
      // 如果 update 失敗（通常是因為文件還不存在，例如第一次登入）
      // 我們就改用 set 來建立新文件
      print("Update 失敗，改用 Set 建立新文件: $e");
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .set({
          'data': _userCollection,
          'last_updated': FieldValue.serverTimestamp(),
          'email': _user!.email,
          'name': _user!.displayName,
        });
      } catch (e2) {
        print("雲端儲存完全失敗: $e2");
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

  // 【新增】供 ScannerScreen 查詢卡片資訊用
  Map<String, dynamic>? getCardInfo(String setCode, String rawCardNum) {
    String? realKey = _findRealKeyInDatabase(setCode, rawCardNum);
    if (realKey != null) {
      return _database[setCode]['cards'][realKey];
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
}
