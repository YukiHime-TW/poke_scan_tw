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
import '../utils/card_matcher.dart';
import 'deck_provider.dart' show DeckRule;

class CollectionProvider with ChangeNotifier {
  Map<String, dynamic> _database = {};
  Map<String, int> _userCollection = {};
  Map<String, int> _wishlist = {}; // "setCode-num" -> 想要張數
  bool _isLoading = true;
  User? _user;
  int _sessionId = 0; // 每次登入狀態改變都 +1，用來作廢進行中的雲端載入

  // 稀有度順序、標準賽制 reg 清單、機制標籤順序（啟動時抓 main，離線用 bundled）
  List<String> _rarityOrder = [];
  Set<String> _standardRegs = {};
  Set<String> _standardNames = {}; // reg 非 H/I/J 但官方仍列為標準合法的卡名
  Set<String> _bannedIds = {}; // 全面禁用卡「setCode-num」
  List<String> _tagOrder = [];
  List<DeckRule> _deckRules = []; // 追加組牌規則（光輝 / ACE SPEC / ◇ …）

  // --- GitHub Raw 網址配置 ---
  final String _remoteBaseUrl =
      "https://raw.githubusercontent.com/YukiHime-TW/poke_scan_tw/refs/heads/main/assets";

  bool get isLoading => _isLoading;
  Map<String, dynamic> get database => _database;
  Map<String, int> get userCollection => _userCollection;
  Map<String, int> get wishlist => _wishlist;
  User? get user => _user;

  List<String> get rarityOrder => _rarityOrder;
  Set<String> get standardRegs => _standardRegs;
  Set<String> get standardNames => _standardNames;
  Set<String> get bannedIds => _bannedIds;
  List<DeckRule> get deckRules => _deckRules;

  /// 資料庫裡實際出現過的稀有度，依 rarity_order.json 排序（表裡沒有的排最後）。
  List<String> get availableRarities {
    final set = <String>{};
    for (final sd in _database.values) {
      final cards = (sd is Map) ? sd['cards'] : null;
      if (cards is Map) {
        for (final c in cards.values) {
          set.add((c is Map ? c['rarity'] : null)?.toString() ?? '');
        }
      }
    }
    int rank(String r) {
      final i = _rarityOrder.indexOf(r);
      return i < 0 ? 9999 : i;
    }

    final list = set.toList()
      ..sort((a, b) {
        final d = rank(a).compareTo(rank(b));
        return d != 0 ? d : a.compareTo(b);
      });
    return list;
  }

  /// 資料庫裡實際出現過的機制標籤，依 tags_order.json 排序。
  List<String> get availableTags {
    final set = <String>{};
    for (final sd in _database.values) {
      final cards = (sd is Map) ? sd['cards'] : null;
      if (cards is Map) {
        for (final c in cards.values) {
          final t = (c is Map) ? c['tags'] : null;
          if (t is List) set.addAll(t.map((e) => e.toString()));
        }
      }
    }
    int rank(String x) {
      final i = _tagOrder.indexOf(x);
      return i < 0 ? 9999 : i;
    }

    return set.toList()
      ..sort((a, b) {
        final d = rank(a).compareTo(rank(b));
        return d != 0 ? d : a.compareTo(b);
      });
  }

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

      // 設定檔（稀有度順序、賽制清單）
      final ro = await _loadJsonConfig('rarity_order.json');
      if (ro is List) _rarityOrder = ro.map((e) => e.toString()).toList();
      final fmt = await _loadJsonConfig('formats.json');
      if (fmt is Map && fmt['standard'] is List) {
        _standardRegs = (fmt['standard'] as List)
            .map((e) => e.toString().toUpperCase())
            .toSet();
      }
      if (fmt is Map && fmt['standardNames'] is List) {
        // 官方「過往可用卡清單」是以卡名列出，但同一張卡有帶角色副標的異圖
        // （例：「老大的指令 赤日」「老大的指令 魁奇思」都是「老大的指令」），
        // 這些也算標準合法。展開成完整卡名集合，讓比對維持精確相等即可。
        final base =
            (fmt['standardNames'] as List).map((e) => e.toString()).toSet();
        final expanded = <String>{...base};
        for (final sd in _database.values) {
          final cards = (sd is Map) ? sd['cards'] : null;
          if (cards is! Map) continue;
          for (final c in cards.values) {
            final n = (c is Map ? c['name'] : null)?.toString() ?? '';
            if (n.isEmpty || expanded.contains(n)) continue;
            for (final b in base) {
              if (n.startsWith('$b ') ||
                  n.startsWith('$b（') ||
                  n.startsWith('$b(')) {
                expanded.add(n);
                break;
              }
            }
          }
        }
        _standardNames = expanded;
      }
      if (fmt is Map && fmt['banned'] is List) {
        _bannedIds = (fmt['banned'] as List).map((e) => e.toString()).toSet();
      }
      final to = await _loadJsonConfig('tags_order.json');
      if (to is List) _tagOrder = to.map((e) => e.toString()).toList();
      final dr = await _loadJsonConfig('deck_rules.json');
      if (dr is Map && dr['cardLimits'] is List) {
        _deckRules = (dr['cardLimits'] as List)
            .whereType<Map>()
            .map((e) => DeckRule.fromJson(e.cast<String, dynamic>()))
            .toList();
      }
    } catch (e) {
      print("⚠️ 初始化資料庫發生嚴重錯誤: $e");
    }

    // 4. 監聽 Firebase 登入狀態
    FirebaseAuth.instance.authStateChanges().listen((User? firebaseUser) async {
      _user = firebaseUser;
      final session = ++_sessionId;
      if (firebaseUser != null) {
        await _loadFromCloud(firebaseUser.uid, session);
      } else {
        await _loadFromLocal();
      }
      if (session != _sessionId) return; // 已被後續的登入事件取代
      _isLoading = false;
      notifyListeners();
    });
  }

  // --- 資料讀取與更新邏輯 ---

  /// 抓 main 上的設定檔，失敗則用 APK 內建的離線版本。
  Future<dynamic> _loadJsonConfig(String filename) async {
    try {
      final res = await http
          .get(Uri.parse('$_remoteBaseUrl/$filename'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) return json.decode(res.body);
    } catch (_) {}
    try {
      return json.decode(await rootBundle.loadString('assets/$filename'));
    } catch (_) {
      return null;
    }
  }

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

  Map<String, int> _decodeCounts(String? raw) {
    if (raw == null) return {};
    final Map<String, dynamic> decoded = json.decode(raw);
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _userCollection = _decodeCounts(prefs.getString('my_collection'));
    _wishlist = _decodeCounts(prefs.getString('my_wishlist'));
  }

  Future<void> _loadFromCloud(String uid, int session) async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (session != _sessionId) return; // 中途登出 / 切換帳號 → 丟棄
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        _userCollection = (data['data'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt()));
        _wishlist = (data['wishlist'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt()));
        _pruneWishlist();
        final prefs = await SharedPreferences.getInstance();
        if (session != _sessionId) return;
        prefs.setString('my_collection', json.encode(_userCollection));
        prefs.setString('my_wishlist', json.encode(_wishlist));
      } else if (_userCollection.isNotEmpty || _wishlist.isNotEmpty) {
        await _saveToCloud();
      }
    } catch (e) {
      if (session != _sessionId) return;
      print("雲端讀取失敗: $e");
      await _loadFromLocal();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('my_collection', json.encode(_userCollection));
    prefs.setString('my_wishlist', json.encode(_wishlist));
    if (_user != null) await _saveToCloud();
  }

  Future<bool> _saveToCloud() async {
    if (_user == null) return false;
    try {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'data': _userCollection,
        'wishlist': _wishlist,
        'last_updated': FieldValue.serverTimestamp(),
        'email': _user!.email,
        'name': _user!.displayName,
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      print("雲端同步失敗: $e");
      return false;
    }
  }

  /// 已擁有張數 >= 想要張數的卡，從願望清單移除。
  void _pruneWishlist() {
    _wishlist.removeWhere(
        (id, want) => (_userCollection[id] ?? 0) >= want || want <= 0);
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
      final want = _wishlist[storageKey];
      if (want != null && _userCollection[storageKey]! >= want) {
        _wishlist.remove(storageKey); // 收齊了就從願望清單移除
      }
      notifyListeners();
      _save();
    }
  }

  // --- 願望清單 ---

  int wishOf(String fullId) => _wishlist[fullId] ?? 0;

  Future<void> setWish(String fullId, int n) async {
    if (n <= 0) {
      _wishlist.remove(fullId);
    } else {
      _wishlist[fullId] = n;
    }
    notifyListeners();
    await _save();
  }

  Future<void> addWish(String fullId) => setWish(fullId, wishOf(fullId) + 1);
  Future<void> removeWish(String fullId) => setWish(fullId, wishOf(fullId) - 1);

  String generateWishlistText() {
    final buffer = StringBuffer("【願望清單】\n");
    final rows = <List<String>>[];
    _wishlist.forEach((id, want) {
      final dash = id.indexOf('-');
      if (dash < 0) return;
      final sCode = id.substring(0, dash);
      final num = id.substring(dash + 1);
      final card = _database[sCode]?['cards']?[num];
      if (card == null) return;
      final have = _userCollection[id] ?? 0;
      final need = want - have;
      if (need <= 0) return; // 收齊的不列
      rows.add([sCode, num, card['name'].toString(), '$need']);
    });
    rows.sort((a, b) {
      final s = a[0].compareTo(b[0]);
      return s != 0 ? s : a[1].compareTo(b[1]);
    });
    for (final r in rows) {
      buffer.writeln("• [${r[0]}] ${r[2]}　還缺 ${r[3]}");
    }
    buffer.writeln("\n共 ${rows.length} 種");
    return buffer.toString();
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
    _sessionId++; // 作廢任何進行中的 _loadFromCloud

    // 1. 最後同步一次。同步失敗（離線 / 出錯）就「不」清本機 ——
    //    寧可訪客暫時看到舊資料，也不要弄丟還沒上雲的變更。
    final synced = _user == null ? true : await _saveToCloud();

    // 2. 同步成功才清本機，回到乾淨的訪客狀態
    //    （避免同機換帳號時資料髒掉、或被推進別人的雲端）
    if (synced) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('my_collection');
      await prefs.remove('my_wishlist');
      await prefs.remove('user_decks'); // deck_provider 的 auth listener 會讀空
      _userCollection = {};
      _wishlist = {};
      notifyListeners();
    }

    // 3. 一定要登出 Firebase：Google 登出失敗不能擋（不然帳號還在，
    //    本機卻空了，之後編輯會把空資料覆蓋回雲端）
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      print("Google 登出錯誤: $e");
    }
    await FirebaseAuth.instance.signOut();
  }

  // --- 掃描：解析 (純函式，不改資料) + 送出 (真的加卡) ---

  /// lines：OCR 讀到的文字行，由畫面「下方往上」排。回傳最佳候選或 null。
  ScanCandidate? analyzeScan(List<String> bottomFirstLines) {
    if (_database.isEmpty) return null;
    final matcher = CardMatcher(_database);
    final r = matcher.match(bottomFirstLines);
    if (r != null) {
      print("🎯 掃描候選: ${r.setCode}-${r.cardKey} "
          "score=${r.score.toStringAsFixed(0)} total=${r.totalMatched} "
          "high=${r.isHighConfidence}");
    } else {
      print("🤔 掃描：無法配對 → $bottomFirstLines");
    }
    return r;
  }

  /// 確認後真的加進「收藏」或「當前牌組」。回傳給使用者看的字串。
  Future<String?> commitScan(ScanCandidate c, {dynamic deckProvider}) async {
    final name = c.cardData['name'] ?? '未知';
    final fullName = "$name (${c.setCode}-${c.cardKey})";
    if (deckProvider != null && deckProvider.currentDeck != null) {
      final err = deckProvider.addCardToDeck(
          "${c.setCode}-${c.cardKey}", name, _database,
          deckRules: _deckRules, bannedIds: _bannedIds);
      if (err != null) return "⚠️ $err";
      return "【牌組】$fullName";
    }
    await addCard(c.setCode, c.rawNum);
    return "【收藏】$fullName";
  }
}