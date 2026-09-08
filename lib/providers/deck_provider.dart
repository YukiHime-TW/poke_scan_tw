import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Deck {
  String id;
  String name;
  Map<String, int> cards;
  DateTime lastUpdated;
  bool isBinder;

  Deck({
    required this.id,
    required this.name,
    required this.cards,
    required this.lastUpdated,
    this.isBinder = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cards': cards,
        'lastUpdated': lastUpdated.toIso8601String(),
        'isBinder': isBinder,
      };

  factory Deck.fromJson(Map<String, dynamic> json) {
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
      isBinder: json['isBinder'] ?? false,
    );
  }
}

class DeckLegality {
  final String status; // "標準" | "開放" | "未完成"
  final List<String> nonStandardNames; // 已輪替（非標準）的卡名
  final int cardCount;
  final bool hasBasic; // 至少一張基礎寶可夢

  DeckLegality(
      {required this.status,
      required this.nonStandardNames,
      required this.cardCount,
      required this.hasBasic});
}

class DeckProvider with ChangeNotifier {
  List<Deck> _decks = [];
  String? _currentEditingDeckId;
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

  void _init() {
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((firebaseUser) {
      _user = firebaseUser;
      if (firebaseUser != null)
        _loadDecksFromCloud();
      else
        _loadDecksFromLocal();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  List<String> _smartSplit(String fullId, Map<String, dynamic> database) {
    List<String> allParts = fullId.split('-');
    for (int i = 1; i < allParts.length; i++) {
      String potentialSet = allParts.sublist(0, i).join('-');
      if (database.containsKey(potentialSet))
        return [potentialSet, allParts.sublist(i).join('-')];
    }
    int firstDash = fullId.indexOf('-');
    if (firstDash == -1) return [fullId, ""];
    return [fullId.substring(0, firstDash), fullId.substring(firstDash + 1)];
  }

  /// 牌組合法性（只對「牌組」有意義，收藏本不用查）。
  DeckLegality checkLegality(Deck deck, Map<String, dynamic> database,
      Set<String> standardRegs) {
    final regs = standardRegs.isEmpty
        ? const {"H", "I", "J", "NONE"}
        : standardRegs;
    int count = 0;
    final nonStd = <String>{};
    bool hasBasic = false;
    deck.cards.forEach((id, n) {
      count += n;
      final parts = _smartSplit(id, database);
      final card = database[parts[0]]?['cards']?[parts[1]];
      if (card == null) return;
      final reg = (card['reg'] ?? "").toString().toUpperCase();
      if (!regs.contains(reg)) nonStd.add(card['name'].toString());
      if (card['type'] == "寶可夢" && card['stage'] == "基礎") hasBasic = true;
    });
    final String status = count < 60
        ? "未完成"
        : (nonStd.isEmpty ? "標準" : "開放");
    return DeckLegality(
        status: status,
        nonStandardNames: nonStd.toList(),
        cardCount: count,
        hasBasic: hasBasic);
  }

  Map<String, int> getCardUsages(String fullId) {
    Map<String, int> usages = {};
    for (var deck in _decks) {
      if (deck.cards.containsKey(fullId))
        usages[deck.name] = deck.cards[fullId]!;
    }
    return usages;
  }

  // --- 修改後的導出功能：增加雙重排序 (擴充包 + 卡號) ---
  String generateExportText(Deck deck, Map<String, dynamic> database) {
    StringBuffer buffer = StringBuffer();
    buffer.writeln("【${deck.isBinder ? '收藏本' : '牌組'}：${deck.name}】");
    int total = deck.cards.values.fold(0, (sum, c) => sum + c);
    buffer.writeln("📋 總張數：$total\n");

    List<Map<String, dynamic>> sortedCards = [];
    deck.cards.forEach((id, count) {
      final parts = _smartSplit(id, database);
      final card = database[parts[0]]?['cards']?[parts[1]];
      if (card != null) {
        sortedCards.add({
          'sCode': parts[0],
          'cNum': parts[1], // 保留原始卡號字串用於排序
          'name': card['name'],
          'rarity': card['rarity'],
          'type': card['type'],
          'count': count
        });
      }
    });

    // 核心排序修改：先排擴充包代號，代號相同時排卡片編號
    sortedCards.sort((a, b) {
      int setCompare = a['sCode'].compareTo(b['sCode']);
      if (setCompare != 0) return setCompare;
      // 在同一個擴充包內，依照 cNum (卡號) 排序
      return a['cNum'].compareTo(b['cNum']);
    });

    Map<String, List<String>> categories = {
      "▼ 寶可夢": [],
      "▼ 物品": [],
      "▼ 支援者": [],
      "▼ 競技場": [],
      "▼ 道具": [],
      "▼ 特殊能量": [],
      "▼ 能量": [], // 統一為能量或基本能量
      "▼ 其他": []
    };

    for (var c in sortedCards) {
      String line = "";
      // 根據你的需求：常見稀有度不顯示括號，特殊稀有度才顯示
      if (c['rarity'] == 'C' ||
          c['rarity'] == 'U' ||
          c['rarity'] == 'R' ||
          c['rarity'] == 'RR' ||
          c['rarity'] == 'RRR' ||
          c['rarity'] == '' ||
          c['rarity'] == 'None') {
        line = "• [${c['sCode']}] ${c['name']} x${c['count']}";
      } else {
        line = "• [${c['sCode']}] ${c['name']} (${c['rarity']}) x${c['count']}";
      }

      switch (c['type']) {
        case "寶可夢":
          categories["▼ 寶可夢"]!.add(line);
          break;
        case "訓練家|物品":
          categories["▼ 物品"]!.add(line);
          break;
        case "訓練家|支援者":
          categories["▼ 支援者"]!.add(line);
          break;
        case "訓練家|競技場":
          categories["▼ 競技場"]!.add(line);
          break;
        case "訓練家|道具":
          categories["▼ 道具"]!.add(line);
          break;
        case "特殊能量":
          categories["▼ 特殊能量"]!.add(line);
          break;
        case "基本能量":
        case "能量":
          categories["▼ 能量"]!.add(line);
          break;
        default:
          if (c['name'].contains("能量")) {
            categories["▼ 能量"]!.add(line);
          } else {
            categories["▼ 其他"]!.add(line);
          }
          break;
      }
    }

    categories.forEach((title, list) {
      if (list.isNotEmpty) {
        // 顯示該大類別共有幾「種」卡片
        buffer.writeln("$title (${list.length} 種)\n${list.join('\n')}\n");
      }
    });

    buffer.writeln("---\nGenerated by PokeScan TW");
    return buffer.toString();
  }

  void renameDeck(String id, String newName) {
    final index = _decks.indexWhere((d) => d.id == id);
    if (index != -1) {
      _decks[index].name = newName;
      _decks[index].lastUpdated = DateTime.now();
      _saveDecksToLocal();
      _syncSingleDeckToCloud(_decks[index]);
      notifyListeners();
    }
  }

  String? addCardToDeck(
      String fullId, String cardName, Map<String, dynamic> database) {
    final deck = currentDeck;
    if (deck == null) return "請先選擇目標";

    if (!deck.isBinder) {
      int totalCount = deck.cards.values.fold(0, (sum, count) => sum + count);
      if (totalCount >= 60) return "牌組已滿 60 張";
    }

    final parts = _smartSplit(fullId, database);
    var cardData = database[parts[0]]?['cards']?[parts[1]];
    String regMark = (cardData?['reg'] ?? "").toString().toUpperCase();
    bool isBasicEnergy = (regMark == "NONE") ||
        (cardName.startsWith("基本") && cardName.endsWith("能量"));

    if (!deck.isBinder && !isBasicEnergy) {
      int nameCount = 0;
      deck.cards.forEach((existingId, count) {
        final eParts = _smartSplit(existingId, database);
        if (database[eParts[0]]?['cards']?[eParts[1]]?['name'] == cardName)
          nameCount += count;
      });
      if (nameCount >= 4) return "同名卡片「$cardName」最多只能放 4 張";
    }

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
    if (deck.cards[fullId]! > 1)
      deck.cards[fullId] = deck.cards[fullId]! - 1;
    else
      deck.cards.remove(fullId);
    deck.lastUpdated = DateTime.now();
    _saveDecksToLocal();
    _syncSingleDeckToCloud(deck);
    notifyListeners();
  }

  void selectDeck(String? id) {
    _currentEditingDeckId = id;
    notifyListeners();
  }

  Future<void> _loadDecksFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('user_decks');
    _decks = (data != null)
        ? (json.decode(data) as List).map((d) => Deck.fromJson(d)).toList()
        : [];
    notifyListeners();
  }

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
        _saveDecksToLocal();
      } else {
        await _loadDecksFromLocal();
        for (var deck in _decks) _syncSingleDeckToCloud(deck);
      }
      notifyListeners();
    } catch (e) {
      _loadDecksFromLocal();
    }
  }

  Future<void> _syncSingleDeckToCloud(Deck deck) async {
    if (_user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('decks')
        .doc(deck.id)
        .set(deck.toJson());
  }

  void createDeck(String name, bool isBinder) {
    final newDeck = Deck(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        cards: {},
        lastUpdated: DateTime.now(),
        isBinder: isBinder);
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
    if (_user != null)
      FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('decks')
          .doc(id)
          .delete();
    notifyListeners();
  }

  Future<void> _saveDecksToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
        'user_decks', json.encode(_decks.map((d) => d.toJson()).toList()));
  }
}
