"""用 tcgdex 校對並修正 type 標錯的卡（add_elem 的後續清理）。

add_type.py 當年把所有卡預設成 type=="寶可夢"，再靠人工把訓練家 / 能量改掉，
有一批沒改到 —— 例如 S-era 各 set 末段的訓練家（丹帝、竹蘭、回收網…）仍是「寶可夢」。

只檢查「type==寶可夢 且 沒有 elem」的卡（錯誤是單向的：非寶可夢被設成寶可夢，
所以這個子集就涵蓋了幾乎所有標錯的卡）。以我方 setCode 直接當 tcgdex setId
（僅 S* / SV* 系列有，促銷包 S-P/M-P/SV-P 與 SM/AC combo 包不在 tcgdex，跳過）。

tcgdex category / trainerType / energyType → 我方 type：
  Pokemon                      -> 寶可夢（順便補 elem）
  Trainer + Supporter          -> 訓練家|支援者
  Trainer + Item               -> 訓練家|物品
  Trainer + Stadium            -> 訓練家|競技場
  Trainer + Tool               -> 訓練家|道具
  Energy  + Special            -> 特殊能量
  Energy  + Basic              -> 基本能量
"""

import json
import os
import sys
import time
import urllib.error
import urllib.request

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

SETS_DIR = "../assets/sets"
CARD_CACHE = "elem_tcgdex_cache.json"        # 與 add_elem_tcgdex.py 共用
SET_CACHE = "tcgdex_set_exists.json"
LOG_FILE = "fix_type_log.txt"
UNRESOLVED_FILE = "fix_type_unresolved.txt"

CARD_API = "https://api.tcgdex.net/v2/zh-tw/cards/"
SET_API = "https://api.tcgdex.net/v2/zh-tw/sets/"

EN2ZH = {
    "Grass": "草", "Fire": "火", "Water": "水", "Lightning": "雷",
    "Psychic": "超", "Fighting": "鬥", "Darkness": "惡", "Metal": "鋼",
    "Fairy": "妖精", "Dragon": "龍", "Colorless": "無色",
}
TRAINER_MAP = {
    "Supporter": "訓練家|支援者",
    "Item": "訓練家|物品",
    "Stadium": "訓練家|競技場",
    "Tool": "訓練家|道具",
}


def _load(path, default):
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    return default


card_cache = _load(CARD_CACHE, {})
set_exists = _load(SET_CACHE, {})


def _get(url):
    for i in range(3):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=20) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return None
            time.sleep(1.2 * (i + 1))
        except Exception:
            time.sleep(1.2 * (i + 1))
    return None


def set_in_tcgdex(set_code):
    if set_code not in set_exists:
        set_exists[set_code] = _get(SET_API + set_code) is not None
        time.sleep(0.1)
    return set_exists[set_code]


def fetch_card(card_id):
    if card_id not in card_cache:
        card_cache[card_id] = _get(CARD_API + card_id)
        time.sleep(0.12)
    return card_cache[card_id]


def expected_type(obj):
    cat = obj.get("category")
    if cat == "Pokemon":
        return "寶可夢"
    if cat == "Trainer":
        return TRAINER_MAP.get(obj.get("trainerType"))
    if cat == "Energy":
        return "特殊能量" if obj.get("energyType") == "Special" else "基本能量"
    return None


def main():
    files = sorted(f for f in os.listdir(SETS_DIR) if f.endswith(".json"))
    fixed_type = filled_elem = unresolved = skipped_set = 0
    logs, unresolved_rows = [], []

    for filename in files:
        path = os.path.join(SETS_DIR, filename)
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        modified = False

        for set_code, set_data in data.items():
            cards = set_data.get("cards")
            if not isinstance(cards, dict):
                continue

            targets = [
                (k, c) for k, c in cards.items()
                if c.get("type") == "寶可夢" and "elem" not in c
            ]
            if not targets:
                continue
            if not set_in_tcgdex(set_code):
                skipped_set += len(targets)
                for k, c in targets:
                    unresolved_rows.append(
                        f"{set_code}\t{k}\t{c.get('name','')}\t(set not in tcgdex)"
                    )
                unresolved += len(targets)
                continue

            for card_num, card in targets:
                local_id = card_num.split("/")[0]
                obj = fetch_card(f"{set_code}-{local_id}")
                if not obj:
                    unresolved += 1
                    unresolved_rows.append(
                        f"{set_code}\t{card_num}\t{card.get('name','')}\t(card 404)"
                    )
                    continue

                exp = expected_type(obj)
                if exp and exp != "寶可夢":
                    logs.append(
                        f"{set_code}\t{card_num}\t{card.get('name','')}\t"
                        f"寶可夢 -> {exp}"
                    )
                    card["type"] = exp
                    modified = True
                    fixed_type += 1
                elif exp == "寶可夢":
                    types = obj.get("types") or []
                    elem = EN2ZH.get(types[0]) if types else None
                    if elem:
                        card["elem"] = elem
                        modified = True
                        filled_elem += 1
                    else:
                        unresolved += 1
                        unresolved_rows.append(
                            f"{set_code}\t{card_num}\t{card.get('name','')}\t"
                            f"(pokemon, no types)"
                        )
                else:
                    unresolved += 1
                    unresolved_rows.append(
                        f"{set_code}\t{card_num}\t{card.get('name','')}\t"
                        f"(tcgdex category={obj.get('category')})"
                    )

        if modified:
            with open(path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"   ✅ {filename}")

    with open(CARD_CACHE, "w", encoding="utf-8") as f:
        json.dump(card_cache, f, ensure_ascii=False)
    with open(SET_CACHE, "w", encoding="utf-8") as f:
        json.dump(set_exists, f, ensure_ascii=False)
    with open(LOG_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(logs))
    with open(UNRESOLVED_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(unresolved_rows))

    print(
        f"\n✨ 完成。type 修正 {fixed_type}（見 {LOG_FILE}）｜"
        f"順便補 elem {filled_elem}｜"
        f"未解決 {unresolved}（含不在 tcgdex 的 set {skipped_set}，見 {UNRESOLVED_FILE}）"
    )


if __name__ == "__main__":
    main()
