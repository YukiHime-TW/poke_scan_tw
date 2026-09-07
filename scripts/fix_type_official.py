"""用官方詳情頁的種類，修正促銷 / combo 包裡標錯的 type，順便補 elem。

對象：type == 寶可夢 且沒有 elem、且 image 是官方 tw<id>.png 的卡
（多在 S-P / M-P / SV-P / SM-P / AS* / AC* —— 這些不在 tcgdex，
fix_type_tcgdex.py 處理不到）。

官方詳情頁 (/tw/card-search/detail/<id>/)：
  - 寶可夢：有 <p class="mainInfomation"> ... <span class="type">屬性</span>
           <img src=".../energy/<Type>.png"> → 補 elem，type 不動
  - 訓練家 / 能量：<h3 class="commonHeader">支援者卡 / 物品卡 / 競技場卡 /
                   寶可夢道具 / 特殊能量 / 基本能量</h3> → 依此修正 type

無官方 id（image 空 / tcgdex / 52poke）抓不到 → 列進 review 給人工。
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
CACHE_FILE = "official_kind_cache.json"
LOG_FILE = "fix_type_official_log.tsv"
REVIEW_FILE = "fix_type_official_review.tsv"

DETAIL = "https://asia.pokemon-card.com/tw/card-search/detail/{}/"
HEADERS = {"User-Agent": "Mozilla/5.0"}

_ID_RE = re.compile(r"/tw0*(\d+)\.png")
_POKE_RE = re.compile(
    r'class="mainInfomation".*?<span class="type">屬性</span>\s*'
    r'<img src="[^"]*/various_images/energy/([A-Za-z]+)\.png"',
    re.S,
)
_KIND_RE = re.compile(
    r'<h3 class="commonHeader">\s*(支援者卡|物品卡|競技場卡|寶可夢道具|特殊能量|基本能量)\s*</h3>'
)

EN2ZH = {
    "Grass": "草", "Fire": "火", "Water": "水", "Lightning": "雷",
    "Psychic": "超", "Fighting": "鬥", "Darkness": "惡", "Metal": "鋼",
    "Fairy": "妖精", "Dragon": "龍", "Colorless": "無色",
}
KIND2TYPE = {
    "支援者卡": "訓練家|支援者",
    "物品卡": "訓練家|物品",
    "競技場卡": "訓練家|競技場",
    "寶可夢道具": "訓練家|道具",
    "特殊能量": "特殊能量",
    "基本能量": "基本能量",
}

_session = requests.Session()
_session.headers.update(HEADERS)


def load_cache():
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE, encoding="utf-8") as f:
            return json.load(f)
    return {}


def probe(card_id, cache):
    key = str(card_id)
    if key in cache:
        return cache[key]
    result = None
    for i in range(3):
        try:
            r = _session.get(DETAIL.format(card_id), timeout=20)
            if r.status_code == 404:
                break
            r.raise_for_status()
            mp = _POKE_RE.search(r.text)
            if mp:
                result = {"kind": "pokemon", "elem": EN2ZH.get(mp.group(1))}
            else:
                mk = _KIND_RE.search(r.text)
                if mk:
                    result = {"kind": "trainer", "type": KIND2TYPE[mk.group(1)]}
            break
        except Exception:
            time.sleep(1.2 * (i + 1))
    cache[key] = result
    return result


def main():
    cache = load_cache()
    files = sorted(f for f in os.listdir(SETS_DIR) if f.endswith(".json"))
    fixed_type = filled_elem = noid = unknown = 0
    logs, review = [], []
    seen = 0

    for filename in files:
        path = os.path.join(SETS_DIR, filename)
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        modified = False
        for set_code, set_data in data.items():
            cards = set_data.get("cards")
            if not isinstance(cards, dict):
                continue
            for num, card in cards.items():
                if card.get("type") != "寶可夢" or "elem" in card:
                    continue
                m = _ID_RE.search(card.get("image", "") or "")
                if not m:
                    noid += 1
                    review.append(
                        f"{set_code}\t{num}\t{card.get('name','')}\t無官方id"
                    )
                    continue
                seen += 1
                info = probe(m.group(1), cache)
                if seen % 100 == 0:
                    print(f"   … 查了 {seen}（改type {fixed_type} / 補elem {filled_elem}）")
                    with open(CACHE_FILE, "w", encoding="utf-8") as f:
                        json.dump(cache, f, ensure_ascii=False)
                time.sleep(0.12)

                if not info:
                    unknown += 1
                    review.append(
                        f"{set_code}\t{num}\t{card.get('name','')}\t官方頁判不出"
                    )
                    continue
                if info["kind"] == "trainer":
                    logs.append(
                        f"{set_code}\t{num}\t{card.get('name','')}\t"
                        f"寶可夢 -> {info['type']}"
                    )
                    card["type"] = info["type"]
                    modified = True
                    fixed_type += 1
                elif info.get("elem"):
                    card["elem"] = info["elem"]
                    modified = True
                    filled_elem += 1
                else:
                    unknown += 1
                    review.append(
                        f"{set_code}\t{num}\t{card.get('name','')}\t寶可夢但無屬性"
                    )
        if modified:
            with open(path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"   ✅ {filename}")

    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(cache, f, ensure_ascii=False)
    with open(LOG_FILE, "w", encoding="utf-8") as f:
        f.write("set\tnum\tname\t變更\n")
        f.write("\n".join(logs))
    with open(REVIEW_FILE, "w", encoding="utf-8") as f:
        f.write("set\tnum\tname\t原因\n")
        f.write("\n".join(review))
    print(
        f"\n✨ 完成。type 修正 {fixed_type}（見 {LOG_FILE}）｜補 elem {filled_elem}｜"
        f"無官方 id {noid}｜判不出 {unknown}（見 {REVIEW_FILE}）"
    )


if __name__ == "__main__":
    main()
