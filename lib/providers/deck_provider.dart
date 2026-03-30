import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Deck {
  String id;
  String name;
  Map<String, int> cards; // Key: "setCode-cNum", Value: 數量
  DateTime lastUpdated;

  Deck({
    required this.id,
    required this.name,
    required this.cards,
    required this.lastUpdated,
  });

  // 轉換為 JSON 儲存
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cards': cards,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory Deck.fromJson(Map<String, dynamic> json) => Deck(
        id: json['id'],
        name: json['name'],
        cards: Map<String, int>.from(json['cards']),
        lastUpdated: DateTime.parse(json['lastUpdated']),
      );
}

class DeckProvider with ChangeNotifier {
  List<Deck> _decks = [];
  String? _currentEditingDeckId;

  List<Deck> get decks => _decks;

  // 取得目前正在編輯的牌組
  Deck? get currentDeck => _currentEditingDeckId == null
      ? null
      : _decks.firstWhere((d) => d.id == _currentEditingDeckId);

  DeckProvider() {
    _loadDecks();
  }

  // --- 基礎操作 ---

  void createDeck(String name) {
    final newDeck = Deck(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      cards: {},
      lastUpdated: DateTime.now(),
    );
    _decks.add(newDeck);
    _currentEditingDeckId = newDeck.id;
    _saveDecks();
    notifyListeners();
  }

  void deleteDeck(String id) {
    _decks.removeWhere((d) => d.id == id);
    if (_currentEditingDeckId == id) _currentEditingDeckId = null;
    _saveDecks();
    notifyListeners();
  }

  void selectDeck(String? id) {
    _currentEditingDeckId = id;
    notifyListeners();
  }

  // --- 牌組編輯邏輯 ---

  // 加入卡片到牌組
  // 需要傳入卡片名稱，因為同名卡限制 4 張是看名稱，不看 ID
  String? addCardToDeck(
      String fullId, String cardName, Map<String, dynamic> database) {
    final deck = currentDeck;
    if (deck == null) return "請先選擇牌組";

    // 1. 計算總張數
    int totalCount = deck.cards.values.fold(0, (sum, count) => sum + count);
    if (totalCount >= 60) return "牌組已滿 60 張";

    // 2. 檢查同名卡限制 (4張)
    // 我們需要計算牌組中所有「名稱相同」但「ID不同」的卡片總數
    int nameCount = 0;
    deck.cards.forEach((id, count) {
      // 拆解 ID 取得 setCode 和 cNum 來從 database 找名稱
      List<String> parts = id.split('-');
      String sCode = parts[0];
      String cNum = parts[1];
      String? existingName = database[sCode]?['cards']?[cNum]?['name'];

      if (existingName == cardName) {
        nameCount += count;
      }
    });

    if (nameCount >= 4) return "同名卡片「$cardName」最多只能放 4 張";

    // 3. 執行加入
    deck.cards[fullId] = (deck.cards[fullId] ?? 0) + 1;
    deck.lastUpdated = DateTime.now();
    _saveDecks();
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
    _saveDecks();
    notifyListeners();
  }

  // --- 持久化 ---

  Future<void> _saveDecks() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = json.encode(_decks.map((d) => d.toJson()).toList());
    prefs.setString('user_decks', data);
  }

  Future<void> _loadDecks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('user_decks');
    if (data != null) {
      final List<dynamic> decoded = json.decode(data);
      _decks = decoded.map((d) => Deck.fromJson(d)).toList();
      notifyListeners();
    }
  }
}
