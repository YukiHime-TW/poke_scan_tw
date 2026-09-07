"""用官方訓練家網站的卡片頁核對所有卡名。

對每張 image 為官方 tw<id>.png 的卡，抓
    https://asia.pokemon-card.com/tw/card-search/detail/<id>/
取 <title> 的卡名，與 assets/sets/*.json 裡的 name 比對。

用法：
    python check_names.py            # 只爬 + 產生 name_diffs.tsv（可續跑，有快取）
    python check_names.py --apply    # 讀 name_diffs.tsv，把差異套回 JSON
                                     #   預設只套「編輯距離 <= 2」的小差異，
                                     #   大差異列在 name_diffs_review.tsv 供人工看
    python check_names.py --apply --all   # 連大差異也一起套

差異欄位：set / num / id / dist / ours / official
"""

import html
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
CACHE_FILE = "name_check_cache.json"
DIFF_FILE = "name_diffs.tsv"
REVIEW_FILE = "name_diffs_review.tsv"

DETAIL = "https://asia.pokemon-card.com/tw/card-search/detail/{}/"
HEADERS = {"User-Agent": "Mozilla/5.0"}

_ID_RE = re.compile(r"/tw0*(\d+)\.png")
_TITLE_RE = re.compile(r"<title>\s*(.*?)\s*\|\s*訓練家網站\s*</title>", re.S)

_session = requests.Session()
_session.headers.update(HEADERS)


def _lev(a, b):
    if a == b:
        return 0
    m, n = len(a), len(b)
    prev = list(range(n + 1))
    for i in range(1, m + 1):
        cur = [i] + [0] * n
        for j in range(1, n + 1):
            cur[j] = min(
                prev[j] + 1,
                cur[j - 1] + 1,
                prev[j - 1] + (a[i - 1] != b[j - 1]),
            )
        prev = cur
    return prev[n]


def load_cache():
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE, encoding="utf-8") as f:
            return json.load(f)
    return {}


def fetch_official_name(card_id, cache):
    key = str(card_id)
    if key in cache:
        return cache[key], True  # (name, from_cache)
    name = None
    for i in range(3):
        try:
            r = _session.get(DETAIL.format(card_id), timeout=20)
            if r.status_code == 404:
                break
            r.raise_for_status()
            m = _TITLE_RE.search(r.text)
            if m:
                # HTML entity 還原；官方把「〈訓練家的〉」用角括號包住，統一去掉再比
                name = html.unescape(m.group(1)).strip()
                name = re.sub(r"[〈〉<>]", "", name)
            break
        except Exception:
            time.sleep(1.2 * (i + 1))
    cache[key] = name
    return name, False


def iter_cards():
    for fn in sorted(f for f in os.listdir(SETS_DIR) if f.endswith(".json")):
        path = os.path.join(SETS_DIR, fn)
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        for set_code, set_data in data.items():
            cards = set_data.get("cards")
            if isinstance(cards, dict):
                yield path, data, set_code, cards


def crawl():
    cache = load_cache()
    rows = []
    seen = 0
    for _path, _data, set_code, cards in iter_cards():
        for num, card in cards.items():
            m = _ID_RE.search(card.get("image", "") or "")
            if not m:
                continue
            seen += 1
            official, from_cache = fetch_official_name(m.group(1), cache)
            if seen % 200 == 0:
                print(f"   … {seen} 張（差異 {len(rows)}）")
                with open(CACHE_FILE, "w", encoding="utf-8") as f:
                    json.dump(cache, f, ensure_ascii=False)
            if official:
                ours = card.get("name", "")
                if official != ours:
                    rows.append(
                        (set_code, num, m.group(1),
                         _lev(ours, official), ours, official)
                    )
            if not from_cache:
                time.sleep(0.1)

    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(cache, f, ensure_ascii=False)
    rows.sort(key=lambda r: (r[3], r[0]))
    with open(DIFF_FILE, "w", encoding="utf-8") as f:
        f.write("set\tnum\tid\tdist\tours\tofficial\n")
        for r in rows:
            f.write("\t".join(str(x) for x in r) + "\n")
    print(f"\n✨ 核對 {seen} 張，發現 {len(rows)} 筆名稱差異 → {DIFF_FILE}")

    charswaps = collect_char_swaps(rows)
    if charswaps:
        print("\n可能的異體字（單字對單字，出現 >=2 次）：")
        for (w, c), n in charswaps.most_common():
            print(f'    "{w}": "{c}",   # x{n}')


def collect_char_swaps(rows):
    import collections

    cnt = collections.Counter()
    for _s, _n, _i, dist, ours, official in rows:
        if dist == 1 and len(ours) == len(official):
            for a, b in zip(ours, official):
                if a != b:
                    cnt[(a, b)] += 1
    return collections.Counter({k: v for k, v in cnt.items() if v >= 2})


def apply_diffs(take_all):
    if not os.path.exists(DIFF_FILE):
        print(f"❌ 找不到 {DIFF_FILE}，先跑一次 crawl。")
        return
    wanted = {}
    review = []
    with open(DIFF_FILE, encoding="utf-8") as f:
        next(f)
        for line in f:
            parts = line.rstrip("\n").split("\t")
            if len(parts) != 6:
                continue
            set_code, num, _id, dist, _ours, official = parts
            if take_all or int(dist) <= 2:
                wanted[(set_code, num)] = official
            else:
                review.append(line)

    changed_files = changed = 0
    for path, data, set_code, cards in iter_cards():
        modified = False
        for num, card in cards.items():
            new = wanted.get((set_code, num))
            if new and card.get("name") != new:
                card["name"] = new
                modified = True
                changed += 1
        if modified:
            with open(path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            changed_files += 1

    with open(REVIEW_FILE, "w", encoding="utf-8") as f:
        f.writelines(review)
    print(
        f"✅ 套用 {changed} 筆名稱到 {changed_files} 個檔"
        f"｜大差異 {len(review)} 筆留待人工（{REVIEW_FILE}）"
    )


if __name__ == "__main__":
    if "--apply" in sys.argv:
        apply_diffs("--all" in sys.argv)
    else:
        crawl()
