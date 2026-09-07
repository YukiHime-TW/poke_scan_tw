"""屬性回填 Phase 2：處理 image 用 tcgdex webp、Phase 1 對不到官方 id 的寶可夢卡。

這些卡在 assets/sets/*.json 裡 image 形如
    https://assets.tcgdex.net/zh-tw/SV/SV8a/002/high.webp
序列/擴充包代號就在網址裡，直接打 tcgdex API：
    GET https://api.tcgdex.net/v2/zh-tw/cards/<setId>-<localId>
回傳含 category(Pokemon/Trainer/Energy)、types(['Grass'] 等)。

行為：
  - category == Pokemon 且有 types → 寫入 elem（英→繁對照同 add_elem.py）
  - category != Pokemon → 我們的 type 標錯了（多半是被 add_type.py 無腦設成寶可夢的
    訓練家卡），記到 elem_type_mismatch.txt 供人工修 type，不自動改
  - 查不到 / 無 types → 記到 elem_tcgdex_misses.txt

只處理「type==寶可夢 且 沒有 elem 且 image 含 assets.tcgdex.net」的卡。
"""

import json
import os
import re
import sys
import time
import urllib.request

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

SETS_DIR = "../assets/sets"
CACHE_FILE = "elem_tcgdex_cache.json"
MISS_FILE = "elem_tcgdex_misses.txt"
MISMATCH_FILE = "elem_type_mismatch.txt"

API = "https://api.tcgdex.net/v2/zh-tw/cards/"

EN2ZH = {
    "Grass": "草",
    "Fire": "火",
    "Water": "水",
    "Lightning": "雷",
    "Psychic": "超",
    "Fighting": "鬥",
    "Darkness": "惡",
    "Metal": "鋼",
    "Fairy": "妖精",
    "Dragon": "龍",
    "Colorless": "無色",
}

_URL_RE = re.compile(r"assets\.tcgdex\.net/zh-tw/[^/]+/([^/]+)/")

_cache = {}
if os.path.exists(CACHE_FILE):
    with open(CACHE_FILE, encoding="utf-8") as f:
        _cache = json.load(f)


def fetch_card(card_id):
    if card_id in _cache:
        return _cache[card_id]
    result = None
    for i in range(3):
        try:
            req = urllib.request.Request(
                API + card_id, headers={"User-Agent": "Mozilla/5.0"}
            )
            with urllib.request.urlopen(req, timeout=20) as r:
                result = json.load(r)
            break
        except urllib.error.HTTPError as e:
            if e.code == 404:
                break
            time.sleep(1.5 * (i + 1))
        except Exception:
            time.sleep(1.5 * (i + 1))
    _cache[card_id] = result
    return result


def main():
    files = sorted(f for f in os.listdir(SETS_DIR) if f.endswith(".json"))
    hit = mismatch = miss = 0
    updated_files = 0
    misses, mismatches = [], []

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
                if card.get("type") != "寶可夢" or "elem" in card:
                    continue
                img = card.get("image", "") or ""
                m = _URL_RE.search(img)
                if not m:
                    continue
                set_id = m.group(1)
                local_id = card_num.split("/")[0]
                obj = fetch_card(f"{set_id}-{local_id}")
                time.sleep(0.12)

                if not obj:
                    miss += 1
                    misses.append(f"{set_code}\t{card_num}\t{card.get('name','')}")
                    continue

                category = obj.get("category")
                if category and category != "Pokemon":
                    mismatch += 1
                    mismatches.append(
                        f"{set_code}\t{card_num}\t{card.get('name','')}\t"
                        f"tcgdex={category}"
                    )
                    continue

                types = obj.get("types") or []
                elem = EN2ZH.get(types[0]) if types else None
                if elem is None:
                    miss += 1
                    misses.append(
                        f"{set_code}\t{card_num}\t{card.get('name','')}\t(no types)"
                    )
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

    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(_cache, f, ensure_ascii=False)
    with open(MISS_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(misses))
    with open(MISMATCH_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(mismatches))

    print(
        f"\n✨ Phase 2 完成。寫入 {updated_files} 檔｜命中 {hit}｜"
        f"type 標錯(非寶可夢) {mismatch}（見 {MISMATCH_FILE}）｜"
        f"仍未命中 {miss}（見 {MISS_FILE}）"
    )


if __name__ == "__main__":
    main()
