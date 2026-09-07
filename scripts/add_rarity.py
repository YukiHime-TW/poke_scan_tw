"""補齊 rarity 空白的卡（約 4,600 張）。

官方訓練家網站的清單頁可用 rarity[] 篩選（詳情頁本身不顯示稀有度）：
    GET /tw/card-search/list/?rarity[]=<code>&pageNo=<N>
逐一稀有度、逐頁抓，以 image 網址的 twXXXXXXXX id 為鍵建 {id: 稀有度代碼}，
再回填 assets/sets/*.json 裡 rarity 為空字串 / 缺欄位的卡。

只填空的，不覆蓋既有值。
官方代碼 11「無標記」寫回 ""（我方慣例：沒有稀有度標記就留空）。

    python add_rarity.py            # 用既有快取
    python add_rarity.py --refresh  # 重抓清單頁
"""

import json
import os
import re
import sys
import time

import requests

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

SETS_DIR = "../assets/sets"
CACHE_FILE = "rarity_map.json"
MISS_FILE = "rarity_misses.txt"

BASE = "https://asia.pokemon-card.com/tw/card-search/list/"
HEADERS = {"User-Agent": "Mozilla/5.0"}

# 官方 rarity[] 代碼 -> 標籤（label 即我方採用的稀有度碼）
RARITY_CODES = {
    1: "C", 2: "U", 3: "R", 4: "RR", 5: "RRR", 6: "PR", 7: "TR", 8: "SR",
    9: "HR", 10: "UR", 11: "", 12: "K", 13: "A", 14: "AR", 15: "SAR",
    16: "S", 17: "SSR", 18: "ACE", 19: "BWR", 20: "MUR", 21: "MA",
}

_IMG_ID_RE = re.compile(r"/tw0*(\d+)\.png")
_PAGE_TOTAL_RE = re.compile(r"共\s*([\d,]+)\s*頁")

_session = requests.Session()
_session.headers.update(HEADERS)


def _fetch(params, tries=3):
    for i in range(tries):
        try:
            r = _session.get(BASE, params=params, timeout=20)
            r.raise_for_status()
            return r.text
        except Exception as e:
            print(f"      ⚠️ {params} 第 {i + 1} 次失敗: {e}")
            time.sleep(1.5 * (i + 1))
    return None


def build_map(force=False):
    if os.path.exists(CACHE_FILE) and not force:
        with open(CACHE_FILE, encoding="utf-8") as f:
            m = json.load(f)
        print(f"📦 使用既有 {CACHE_FILE}（{len(m)} 筆）。加 --refresh 可重抓。")
        return m

    rmap = {}
    for code, label in RARITY_CODES.items():
        first = _fetch({"rarity[]": code, "pageNo": 1})
        if first is None:
            print(f"❌ 稀有度 {label or '無標記'}({code}) 抓不到，跳過")
            continue
        mt = _PAGE_TOTAL_RE.search(first)
        total = int(mt.group(1).replace(",", "")) if mt else 1
        print(f"💎 {label or '無標記'}({code})：共 {total} 頁")
        for page in range(1, total + 1):
            html = first if page == 1 else _fetch({"rarity[]": code, "pageNo": page})
            if html is None:
                continue
            for cid in _IMG_ID_RE.findall(html):
                if cid in rmap and rmap[cid] != label:
                    print(f"      ⚠️ id {cid} 稀有度衝突: {rmap[cid]!r} vs {label!r}")
                    continue
                rmap[cid] = label
            if page % 10 == 0:
                print(f"      … {page}/{total}（累計 {len(rmap)}）")
            time.sleep(0.12)

    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(rmap, f, ensure_ascii=False)
    print(f"💾 已寫入 {CACHE_FILE}（{len(rmap)} 筆）")
    return rmap


def backfill(rmap):
    files = sorted(f for f in os.listdir(SETS_DIR) if f.endswith(".json"))
    updated_files = hit = miss = skip = 0
    misses = []
    for filename in files:
        path = os.path.join(SETS_DIR, filename)
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        modified = False
        for set_code, set_data in data.items():
            cards = set_data.get("cards")
            if not isinstance(cards, dict):
                continue
            for card_num, card in cards.items():
                if (card.get("rarity", "") or "").strip():
                    skip += 1
                    continue
                m = _IMG_ID_RE.search(card.get("image", "") or "")
                if not m or m.group(1) not in rmap:
                    miss += 1
                    misses.append(
                        f"{set_code}\t{card_num}\t{card.get('name', '')}"
                    )
                    continue
                label = rmap[m.group(1)]
                if card.get("rarity", "") != label:
                    card["rarity"] = label
                    modified = True
                hit += 1
        if modified:
            with open(path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            updated_files += 1
            print(f"   ✅ {filename}")

    with open(MISS_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(misses))
    print(
        f"\n✨ 完成。寫入 {updated_files} 檔｜補上 {hit}｜"
        f"未命中 {miss}（見 {MISS_FILE}）｜已有值略過 {skip}"
    )


if __name__ == "__main__":
    m = build_map(force="--refresh" in sys.argv)
    if not m:
        raise SystemExit("❌ 對照表空的")
    backfill(m)
