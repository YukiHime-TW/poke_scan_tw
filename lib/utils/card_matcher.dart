/// 掃描結果比對：把 OCR 讀到的文字行，配對到卡片資料庫裡的一張卡。
///
/// 舊做法的問題：
///  - `_normalizeForOCR` 對兩邊都做 S→5 / V→1，把現行 SV 王朝的代號整個打爛、一堆相撞
///  - `contains` 雙向 + 長度差<=2 判定太鬆，first-match-wins、沒有評分
///  - 完全沒用到編號的「/總數」——DB 裡 67 種總數有 41 種只對到唯一一個 set
///
/// 新做法：以「編號 / 總數」為錨點，對每個候選 set 做加權評分（代號相似度 ×
/// 總數是否吻合 × 該卡實際存在），回傳最高分者 + 信心等級。

class ScanCandidate {
  final String setCode; // 資料庫真實 key
  final String cardKey; // 例如 "037/078"
  final Map<String, dynamic> cardData;
  final double score;
  final bool totalMatched; // 讀到的總數 == 該 set 卡數
  final String rawSetToken;
  final String rawNum;

  ScanCandidate({
    required this.setCode,
    required this.cardKey,
    required this.cardData,
    required this.score,
    required this.totalMatched,
    required this.rawSetToken,
    required this.rawNum,
  });

  /// 高信心：可以直接自動加。低信心：要跳確認。
  bool get isHighConfidence => score >= 150 || (score >= 110 && totalMatched);
}

class CardMatcher {
  final Map<String, dynamic> database;

  // setCode(大寫) -> 真實 key
  late final Map<String, String> _keyByUpper;
  // setCode -> 該 set 數字編號的分母（總數），沒有就是 0
  late final Map<String, int> _setTotals;
  // 總數 -> 有這個總數的 setCode 清單（用來做「只讀到編號」的消歧義）
  late final Map<int, List<String>> _setsByTotal;

  CardMatcher(this.database) {
    _keyByUpper = {for (final k in database.keys) k.toUpperCase(): k};
    _setTotals = {};
    database.forEach((setCode, sd) {
      final cards = (sd is Map) ? sd['cards'] : null;
      if (cards is! Map) return;
      for (final ck in cards.keys) {
        final parts = ck.toString().split('/');
        if (parts.length == 2 && RegExp(r'^\d+$').hasMatch(parts[1])) {
          _setTotals[setCode] = int.parse(parts[1]);
          break;
        }
      }
    });
    _setsByTotal = {};
    _setTotals.forEach((setCode, total) {
      (_setsByTotal[total] ??= []).add(setCode);
    });
  }

  // OCR 常見誤讀（保守版：不碰 S / V，因為 SV 是現行王朝代號）
  static const Map<String, String> _confuse = {
    '0': 'O', 'O': '0',
    '1': 'I', 'I': '1', 'L': '1',
    '8': 'B', 'B': '8',
    '2': 'Z', 'Z': '2',
    '6': 'G', 'G': '6',
    '5': 'S', // 只單向：5 可能其實是 S；不要 S->5
  };

  String _canon(String s) {
    final b = StringBuffer();
    for (final ch in s.split('')) {
      b.write(_confuse[ch] ?? ch);
    }
    return b.toString();
  }

  int _lev(String a, String b) {
    final m = a.length, n = b.length;
    if (m == 0) return n;
    if (n == 0) return m;
    var prev = List<int>.generate(n + 1, (i) => i);
    var cur = List<int>.filled(n + 1, 0);
    for (var i = 1; i <= m; i++) {
      cur[0] = i;
      for (var j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        cur[j] = [cur[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost]
            .reduce((x, y) => x < y ? x : y);
      }
      final t = prev;
      prev = cur;
      cur = t;
    }
    return prev[n];
  }

  /// 單一 (代號 token, 編號 token, 總數) 對一個 DB set key 的相似度分數。0 = 不像。
  double _codeScore(String token, String upperKey) {
    if (token == upperKey) return 100;
    if (_canon(token) == _canon(upperKey)) return 70;

    // 一方包含另一方（去掉常見前綴雜訊，例如 OCR 把符號讀成字）
    if (token.length >= 3 &&
        (token.contains(upperKey) || upperKey.contains(token)) &&
        (token.length - upperKey.length).abs() <= 2) {
      return 45;
    }
    final d = _lev(_canon(token), _canon(upperKey));
    if (d == 1) return 50;
    if (d == 2 && upperKey.length >= 4) return 22;
    return 0;
  }

  String? _resolveCardKey(String setCode, String num3) {
    final cards = database[setCode]?['cards'];
    if (cards is! Map) return null;
    if (cards.containsKey(num3)) return num3;
    for (final k in cards.keys) {
      final ks = k.toString();
      if (ks == num3 || ks.startsWith('$num3/')) return ks;
    }
    return null;
  }

  /// lines: OCR 讀到的文字行，**由畫面下方往上排**（下面的先）。
  ScanCandidate? match(List<String> lines) {
    final joined = lines.join(' \n ').toUpperCase().replaceAll(RegExp(r'[（）()\[\]]'), ' ');

    // 1) 抓「編號 / 總數」；抓不到就退而求其次抓單獨的 1~3 位數字
    final numRe = RegExp(r'(\d{1,3})\s*[/／]\s*(\d{1,3})');
    final bareRe = RegExp(r'(?<![\dA-Z])(\d{1,3})(?![\dA-Z])');

    final numHits = <({String num, int? total})>[];
    for (final m in numRe.allMatches(joined)) {
      numHits.add((num: m.group(1)!, total: int.tryParse(m.group(2)!)));
    }
    if (numHits.isEmpty) {
      for (final m in bareRe.allMatches(joined)) {
        numHits.add((num: m.group(1)!, total: null));
      }
    }
    if (numHits.isEmpty) return null;

    // 2) 代號 token：2~6 碼英數，允許夾一個 '-'
    final codeRe = RegExp(r'[A-Z0-9]{1,4}-?[A-Z0-9]{1,4}');
    final codeTokens = <String>{};
    for (final m in codeRe.allMatches(joined)) {
      final t = m.group(0)!;
      if (RegExp(r'[A-Z]').hasMatch(t) && t.length >= 2 && t.length <= 7) {
        codeTokens.add(t);
      }
    }
    // 2b) 完全沒讀到代號，但讀到「編號 / 總數」——若該總數在整個資料庫裡
    //     只對到唯一一個 set，就靠它消歧義（低信心，會跳確認）。
    if (codeTokens.isEmpty) {
      for (final nh in numHits) {
        if (nh.total == null) continue;
        final sets = _setsByTotal[nh.total!];
        if (sets == null || sets.length != 1) continue;
        final realKey = sets.first;
        final cardKey = _resolveCardKey(realKey, nh.num.padLeft(3, '0'));
        if (cardKey == null) continue;
        return ScanCandidate(
          setCode: realKey,
          cardKey: cardKey,
          cardData: Map<String, dynamic>.from(
              database[realKey]['cards'][cardKey] as Map),
          score: 95, // < 110，一定跳確認
          totalMatched: true,
          rawSetToken: '',
          rawNum: nh.num.padLeft(3, '0'),
        );
      }
      return null;
    }

    ScanCandidate? best;
    for (final nh in numHits) {
      final num3 = nh.num.padLeft(3, '0');
      for (final token in codeTokens) {
        for (final entry in _keyByUpper.entries) {
          final upperKey = entry.key;
          final realKey = entry.value;

          final cs = _codeScore(token, upperKey);
          if (cs <= 0) continue;

          final cardKey = _resolveCardKey(realKey, num3);
          if (cardKey == null) continue; // 這個 set 裡根本沒這張號碼

          final totalMatched =
              nh.total != null && _setTotals[realKey] == nh.total;

          double score = cs;
          if (totalMatched) score += 80; // 總數吻合是最強訊號
          if (nh.total != null && !totalMatched && _setTotals[realKey] != 0) {
            score -= 25; // 讀到總數但對不上 -> 扣分
          }

          if (best == null || score > best.score) {
            best = ScanCandidate(
              setCode: realKey,
              cardKey: cardKey,
              cardData: Map<String, dynamic>.from(
                  database[realKey]['cards'][cardKey] as Map),
              score: score,
              totalMatched: totalMatched,
              rawSetToken: token,
              rawNum: num3,
            );
          }
        }
      }
    }

    // 分數太低就當作認不出來
    if (best == null || best.score < 60) return null;
    return best;
  }
}
