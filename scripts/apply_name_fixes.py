"""依 name_diffs.tsv 與使用者決策，把官方卡名套回 assets/sets/*.json。

決策：
  B 編號↔名稱對錯      -> 照官方
  F 其他大差異          -> 照官方
  D 能量卡格式          -> 照官方（基本/基礎【X】能量）
  E 官方多後綴標記      -> 維持我方，不動
  I 空白差異            -> 維持我方，不動
  H 零寬字元            -> 維持我方，但把我方名稱裡的零寬/方向字元清掉
  C 老大的指令/博士的研究 -> 用我方格式「前綴 空格 副標」，副標換成官方括號裡的正確名字
                          （官方裸名、抽不出副標的 -> 不動，列進 review）
  G 小差異/異體字        -> 這次不動（使用者稍後審）
  A 官方頁抓壞           -> 不動

另：set == SV4M 全部跳過（高版整段有誤，使用者要逐張人工對）。
"""

import collections
import json
import os
import re
import sys

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

SETS_DIR = "../assets/sets"
DIFF_FILE = "name_diffs.tsv"
CHANGELOG = "name_fix_changelog.tsv"
REVIEW = "name_fix_review.tsv"

ZW_RE = re.compile(r"[​‌‍‎‏﻿]")

# G 桶：交給 fix_translation.py 處理的異體字（這裡不動資料），以「我方名稱含此子字串」判斷
G_TO_FIXTRANS = (
    "火暴", "卷卷耳", "保姆", "拳海蔘", "引力山嶽", "奇蹟修正檔", "車輪球",
    "喫剩的東西", "夠贊狗", "辣味香料咖喱", "頓甲龍", "盆纔怪", "妮莫的揹包",
    "改造之鎚", "多邊獸2", "N的PP提升劑", "神秘珍寶", "巨大爐灶", "台北的皮卡丘",
    "Ｑ", "Ｚ", "Ｕ", "Ｎ",
)
# G 桶：官方那邊才是錯的（呐是簡體），維持我方
G_KEEP_OURS = ("吶喊隊",)

C_PREFIX = ("老大的指令", "博士的研究")
C_PAREN = re.compile(r"^(老大的指令|博士的研究)\s*[（(]\s*(.+?)\s*[)）]\s*$")
BAD_OFFICIAL = {"卡牌搜尋結果"}


def load_diffs():
    rows = []
    with open(DIFF_FILE, encoding="utf-8") as f:
        next(f)
        for line in f:
            p = line.rstrip("\n").split("\t")
            if len(p) == 6:
                rows.append((p[0], p[1], p[2], int(p[3]), p[4], p[5]))
    return rows


def categorize(rows):
    byset = collections.defaultdict(dict)
    for s, n, i, d, o, f in rows:
        byset[s][o] = f
    out = {}
    for s, n, i, d, o, f in rows:
        if f in BAD_OFFICIAL:
            k = "A"
        elif byset[s].get(f) == o and o != f:
            k = "B"
        elif o.startswith(C_PREFIX) or f.startswith(C_PREFIX):
            k = "C"
        elif "能量" in o and ("【" in f or f.startswith("基礎")):
            k = "D"
        elif ZW_RE.search(o + f):
            k = "H"
        elif o.replace(" ", "") == f.replace(" ", "").replace("　", ""):
            k = "I"
        elif f.endswith(("]", "）", ")")) and (f.startswith(o) or o in f):
            k = "E"
        elif d <= 2:
            k = "G"
        else:
            k = "F"
        out[(s, n)] = (k, o, f)
    return out


def target_name(cat, ours, official):
    """回傳應該寫入的新名字；None 表示不動。"""
    k = cat
    if k in ("B", "F", "D"):
        return official
    if k == "H":
        cleaned = ZW_RE.sub("", ours)
        return cleaned if cleaned != ours else None
    if k == "C":
        m = C_PAREN.match(official)
        if m:
            cand = f"{m.group(1)} {m.group(2)}"
            return cand if cand != ours else None
        return None  # 官方裸名 / 抽不出 -> 人工
    if k == "G":
        if any(x in ours for x in G_KEEP_OURS):
            return None  # 官方是錯的，維持我方
        if any(x in ours for x in G_TO_FIXTRANS):
            return None  # 異體字，交給 fix_translation.py
        return official  # 其餘是真的不同名字 -> 照官方
    return None  # A / E / I


def main():
    decided = categorize(load_diffs())
    changelog, review = [], []
    files_changed = 0

    for fn in sorted(f for f in os.listdir(SETS_DIR) if f.endswith(".json")):
        path = os.path.join(SETS_DIR, fn)
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        modified = False
        for set_code, set_data in data.items():
            cards = set_data.get("cards")
            if not isinstance(cards, dict):
                continue
            for num, card in cards.items():
                key = (set_code, num)
                if key not in decided:
                    continue
                cat, ours, official = decided[key]
                if set_code == "SV4M":
                    review.append((set_code, num, cat, ours, official, "SV4M整段人工"))
                    continue
                new = target_name(cat, card.get("name", ""), official)
                if new is None:
                    # C：官方裸名（抽不出副標）才需要人工；格式一致的直接略過
                    if cat == "C" and not C_PAREN.match(official):
                        review.append(
                            (set_code, num, cat, ours, official, "官方裸名待確認")
                        )
                    continue
                if card.get("name") != new:
                    changelog.append((set_code, num, cat, card.get("name", ""), new))
                    card["name"] = new
                    modified = True
        if modified:
            with open(path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            files_changed += 1

    with open(CHANGELOG, "w", encoding="utf-8") as f:
        f.write("set\tnum\t類\t原本\t改為\n")
        for r in changelog:
            f.write("\t".join(r) + "\n")
    with open(REVIEW, "w", encoding="utf-8") as f:
        f.write("set\tnum\t類\t我方\t官方\t備註\n")
        for r in review:
            f.write("\t".join(r) + "\n")

    by = collections.Counter(r[2] for r in changelog)
    print(f"✅ 改了 {len(changelog)} 張、{files_changed} 個檔。分類：{dict(by)}")
    print(f"   changelog → {CHANGELOG}")
    print(f"   待人工 {len(review)} 筆 → {REVIEW}")


if __name__ == "__main__":
    main()
