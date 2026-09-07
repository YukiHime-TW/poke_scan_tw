"""補齊寶可夢卡片的「屬性(能量色)」欄位 elem。

資料來源：官方訓練家網站的卡牌搜尋清單頁（server-rendered HTML）
    GET /tw/card-search/list/?cardType=1&pokemonEnergy=<1..11>&pageNo=<N>
每頁 20 張，每張帶 <img data-original=".../tw00019551.png">，
其中 19551 即卡片詳情 id，也就是我們 assets/sets/*.json 裡 image 網址的 twXXXXXXXX。

流程：
  Phase 1  逐一屬性、逐頁抓清單 → 建 { "19551": "草", ... } 對照表，快取到 elem_map.json
  Phase 2  遍歷 assets/sets/*.json，從每張卡 image 取出 tw id → 查表 → 寫入 card['elem']

沒有官方 tw id 的卡（image 是 tcgdex webp / 空字串 / 52poke）這一版對不到，
會列在最後的 misses.txt，之後再用 expansionCodes 逐 set 補。
"""

import json
import os
import re
import sys
import time

import requests

try:  # Windows 主控台預設 cp950，emoji 會炸
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

SETS_DIR = "../assets/sets"
CACHE_FILE = "elem_map.json"
MISS_FILE = "elem_misses.txt"

BASE = "https://asia.pokemon-card.com/tw/card-search/list/"
HEADERS = {"User-Agent": "Mozilla/5.0"}

# 官方 pokemonEnergy 代碼 → 繁中屬性名（已於詳情頁逐一核對）
ENERGY_CODES = {
    1: "草",
    2: "火",
    3: "水",
    4: "雷",
    5: "超",
    6: "鬥",
    7: "惡",
    8: "鋼",
    9: "妖精",
    10: "龍",
    11: "無色",
}

_IMG_ID_RE = re.compile(r"/tw0*(\d+)\.png")
_PAGE_TOTAL_RE = re.compile(r"共\s*([\d,]+)\s*頁")


def _fetch(params, tries=3):
    for i in range(tries):
        try:
            r = requests.get(BASE, params=params, headers=HEADERS, timeout=20)
            r.raise_for_status()
            return r.text
        except Exception as e:
            print(f"      ⚠️ {params} 第 {i + 1} 次失敗: {e}")
            time.sleep(1.5 * (i + 1))
    return None


def build_elem_map(force=False):
    if os.path.exists(CACHE_FILE) and not force:
        with open(CACHE_FILE, encoding="utf-8") as f:
            m = json.load(f)
        print(f"📦 使用既有 {CACHE_FILE}（{len(m)} 筆）。加 --refresh 可重抓。")
        return m

    elem_map = {}
    for code, name in ENERGY_CODES.items():
        first = _fetch({"cardType": 1, "pokemonEnergy": code, "pageNo": 1})
        if first is None:
            print(f"❌ 屬性 {name}({code}) 第 1 頁抓不到，跳過")
            continue
        mt = _PAGE_TOTAL_RE.search(first)
        total = int(mt.group(1).replace(",", "")) if mt else 1
        print(f"🎨 {name}({code})：共 {total} 頁")

        for page in range(1, total + 1):
            html = first if page == 1 else _fetch(
                {"cardType": 1, "pokemonEnergy": code, "pageNo": page}
            )
            if html is None:
                continue
            ids = _IMG_ID_RE.findall(html)
            for cid in ids:
                # 同一 id 不該同時屬於兩個屬性；若發生，保留先抓到的並示警
                if cid in elem_map and elem_map[cid] != name:
                    print(f"      ⚠️ id {cid} 屬性衝突: {elem_map[cid]} vs {name}")
                    continue
                elem_map[cid] = name
            if page % 10 == 0:
                print(f"      … {page}/{total}（累計 {len(elem_map)} 筆）")
            time.sleep(0.15)

    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(elem_map, f, ensure_ascii=False, indent=0)
    print(f"💾 已寫入 {CACHE_FILE}（{len(elem_map)} 筆）")
    return elem_map


def backfill(elem_map):
    files = sorted(f for f in os.listdir(SETS_DIR) if f.endswith(".json"))
    updated_files = 0
    hit = miss = skip_nonpoke = 0
    misses = []

    for filename in files:
        path = os.path.join(SETS_DIR, filename)
        modified = False
        try:
            with open(path, encoding="utf-8") as f:
                data = json.load(f)
        except Exception as e:
            print(f"   ❌ {filename} 讀取失敗: {e}")
            continue

        for set_code, set_data in data.items():
            cards = set_data.get("cards")
            if not isinstance(cards, dict):
                continue
            for card_num, card in cards.items():
                if card.get("type") != "寶可夢":
                    skip_nonpoke += 1
                    continue
                m = _IMG_ID_RE.search(card.get("image", "") or "")
                elem = elem_map.get(m.group(1)) if m else None
                if elem is None:
                    miss += 1
                    misses.append(f"{set_code}\t{card_num}\t{card.get('name', '')}")
                    continue
                if card.get("elem") != elem:
                    card["elem"] = elem
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
        f"\n✨ 完成。寫入 {updated_files} 檔｜命中 {hit}｜"
        f"未命中 {miss}（見 {MISS_FILE}）｜非寶可夢略過 {skip_nonpoke}"
    )


if __name__ == "__main__":
    refresh = "--refresh" in sys.argv
    m = build_elem_map(force=refresh)
    if not m:
        print("❌ 對照表是空的，中止。")
        raise SystemExit(1)
    backfill(m)
