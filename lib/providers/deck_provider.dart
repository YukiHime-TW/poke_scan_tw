import 'dart:convert';
import 'dart:async'; // 新增
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 新增
import 'package:cloud_firestore/cloud_firestore.dart'; // 新增

class Deck {
  String id;
  String name;
  Map<String, int> cards;
  DateTime lastUpdated;

  Deck({
    required this.id,
    required this.name,
    required this.cards,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cards': cards,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory Deck.fromJson(Map<String, dynamic> json) {
    // 處理 Firestore 的 Timestamp 或 JSON 的 String 轉 DateTime
    DateTime parseDate;
    if (json['lastUpdated'] is Timestamp) {
      parseDate = (json['lastUpdated'] as Timestamp).toDate();
    } else {
      parseDate = DateTime.parse(
          json['lastUpdated'] ?? DateTime.now().toIso8601String());
    }

    return Deck(
      id: json['id'],
      name: json['name'],
      cards: Map<String, int>.from(json['cards'] ?? {}),
      lastUpdated: parseDate,
    );
  }
}

class DeckProvider with ChangeNotifier {
  List<Deck> _decks = [];
  String? _currentEditingDeckId;

  // Firebase 相關變數
  User? _user;
  StreamSubscription? _authSubscription;

  List<Deck> get decks => _decks;

  Deck? get currentDeck => _currentEditingDeckId == null
      ? null
      : _decks.firstWhere((d) => d.id == _currentEditingDeckId,
          orElse: () => _decks.first);

  DeckProvider() {
    _init();
  }

  // 初始化：監聽登入狀態切換
  void _init() {
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((firebaseUser) {
      _user = firebaseUser;
      if (firebaseUser != null) {
        // 登入狀態：從雲端讀取
        _loadDecksFromCloud();
      } else {
        // 登出狀態：從本地讀取
        _loadDecksFromLocal();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // --- 核心同步邏輯 ---

  // 從本地載入 (離線模式)
  Future<void> _loadDecksFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('user_decks');
    if (data != null) {
      final List<dynamic> decoded = json.decode(data);
      _decks = decoded.map((d) => Deck.fromJson(d)).toList();
    } else {
      _decks = [];
    }
    notifyListeners();
  }

  // 從雲端載入並同步到本地
  Future<void> _loadDecksFromCloud() async {
    if (_user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('decks')
          .get();

      if (snapshot.docs.isNotEmpty) {
        _decks = snapshot.docs.map((doc) => Deck.fromJson(doc.data())).toList();
        _saveDecksToLocal(); // 更新本地暫存
      } else {
        // 如果雲端沒資料但本地有，可以考慮做第一次上傳同步
        await _loadDecksFromLocal();
        for (var deck in _decks) {
          _syncSingleDeckToCloud(deck);
        }
      }
      notifyListeners();
    } catch (e) {
      print("❌ 雲端牌組加載失敗: $e");
      _loadDecksFromLocal(); // 失敗時降級使用本地
    }
  }

  // 將單一牌組同步到雲端
  Future<void> _syncSingleDeckToCloud(Deck deck) async {
    if (_user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('decks')
          .doc(deck.id)
          .set(deck.toJson());
    } catch (e) {
      print("❌ 雲端牌組同步失敗: $e");
    }
  }

  // --- 基礎操作 (修改為同時觸發雲端同步) ---

  void createDeck(String name) {
    final newDeck = Deck(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      cards: {},
      lastUpdated: DateTime.now(),
    );
    _decks.add(newDeck);
    _currentEditingDeckId = newDeck.id;

    _saveDecksToLocal();
    _syncSingleDeckToCloud(newDeck);
    notifyListeners();
  }

  void deleteDeck(String id) {
    _decks.removeWhere((d) => d.id == id);
    if (_currentEditingDeckId == id) _currentEditingDeckId = null;

    _saveDecksToLocal();
    if (_user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('decks')
          .doc(id)
          .delete();
    }
    notifyListeners();
  }

  void selectDeck(String? id) {
    _currentEditingDeckId = id;
    notifyListeners();
  }

  // --- 牌組編輯邏輯 ---

  String? addCardToDeck(
      String fullId, String cardName, Map<String, dynamic> database) {
    final deck = currentDeck;
    if (deck == null) return "請先選擇牌組";

    int totalCount = deck.cards.values.fold(0, (sum, count) => sum + count);
    if (totalCount >= 60) return "牌組已滿 60 張";

    int nameCount = 0;
    deck.cards.forEach((id, count) {
      List<String> parts = id.split('-');
      String sCode = parts[0];
      String cNum = parts[1];
      String? existingName = database[sCode]?['cards']?[cNum]?['name'];
      if (existingName == cardName) nameCount += count;
    });

    if (nameCount >= 4) return "同名卡片「$cardName」最多只能放 4 張";

    deck.cards[fullId] = (deck.cards[fullId] ?? 0) + 1;
    deck.lastUpdated = DateTime.now();

    _saveDecksToLocal();
    _syncSingleDeckToCloud(deck);
    notifyListeners();
    return null;
  }

  void removeCardFromDeck(String fullId) {
    final deck = currentDeck;
    if (deck == null || !deck.cards.containsKey(fullId)) return;

    if (deck.cards[fullId]! > 1) {
      deck.cards[fullId] = deck.cards[fullId]! - 1;
    } else {
      deck.cards.remove(fullId);
    }
    deck.lastUpdated = DateTime.now();

    _saveDecksToLocal();
    _syncSingleDeckToCloud(deck);
    notifyListeners();
  }

  // --- 持久化工具 ---

  Future<void> _saveDecksToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = json.encode(_decks.map((d) => d.toJson()).toList());
    prefs.setString('user_decks', data);
  }
}