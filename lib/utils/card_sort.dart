/// 牌組匯出 / 盤點對帳共用的卡片排序：發售日新→舊 → 系列碼 → 包內卡號。

/// 卡號自然排序：取斜線前的部分，拆成（文字前綴, 數字, 尾綴）比較，
/// 讓 "2/100" 排在 "10/100" 前面，"TG05" 排在 "TG10" 前面。
int compareCardNum(String a, String b) {
  (String, int, String) key(String s) {
    final head = s.split('/').first.trim();
    final m = RegExp(r'^(\D*)(\d+)(.*)$').firstMatch(head);
    if (m == null) return (head.toLowerCase(), 1 << 30, '');
    return (
      m.group(1)!.toLowerCase(),
      int.tryParse(m.group(2)!) ?? 1 << 30,
      m.group(3)!.toLowerCase(),
    );
  }

  final ka = key(a), kb = key(b);
  final p = ka.$1.compareTo(kb.$1);
  if (p != 0) return p;
  final n = ka.$2.compareTo(kb.$2);
  if (n != 0) return n;
  return ka.$3.compareTo(kb.$3);
}

/// 一張卡的排序：先照系列發售日新→舊，同日期照系列碼分組，同包內照卡號小→大。
int compareCardEntry({
  required String dateA,
  required String setA,
  required String numA,
  required String dateB,
  required String setB,
  required String numB,
}) {
  final byDate = dateB.compareTo(dateA); // 新→舊
  if (byDate != 0) return byDate;
  final bySet = setA.compareTo(setB);
  if (bySet != 0) return bySet;
  return compareCardNum(numA, numB);
}
