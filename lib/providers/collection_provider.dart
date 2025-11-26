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

  // 【修正重點 1】恢復使用本地變數來儲存 User，由 Stream 控制，確保同步
  User? _user;

  bool get isLoading => _isLoading;
  Map<String, dynamic> get database => _database;
  Map<String, int> get userCollection => _userCollection;
  User? get user => _user; // UI 讀取這個變數

  CollectionProvider() {
    _init();
  }

  Future<void> _init() async {
    // 1. 載入靜態資料庫
    final String jsonString = await rootBundle.loadString('assets/data.json');
    _database = json.decode(jsonString);

    // 2. 【修正重點 2】這是唯一的真理來源。當 Firebase 通知狀態改變，我們才更新 UI
    FirebaseAuth.instance.authStateChanges().listen((User? firebaseUser) async {
      _user = firebaseUser; // 更新本地變數

      if (firebaseUser != null) {
        print("✅ 監聽器偵測到登入: ${firebaseUser.displayName}");
        await _loadFromCloud(firebaseUser.uid);
      } else {
        print("💤 監聽器偵測到未登入/已登出");
        _userCollection = {};
        await _loadFromLocal();
      }

      _isLoading = false;
      notifyListeners(); // 強制通知 UI 重繪
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
    // 注意：這裡不呼叫 notifyListeners，統一交給 authStateChanges 處理，避免重複刷新
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
      }, SetOptions(merge: true));
    } catch (e) {
      print("雲端儲存失敗: $e");
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
      // 不需要手動 notifyListeners，因為 authStateChanges 會觸發
    } catch (e) {
      print("登入錯誤: $e");
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      // 不需要手動 notifyListeners，因為 authStateChanges 會觸發
    } catch (e) {
      print("登出錯誤: $e");
    }
  }

  // --- 修改卡片 ---
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
