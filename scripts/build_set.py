"""從官方訓練家網站（asia.pokemon-card.com/tw）單一資料源，建立 / 更新
一個擴充包的 assets/sets/<CODE>.json 的「結構欄位」。

取代舊的多來源拼裝流程：
  scraper.py + convert.py + fix_translation.py + add_date.py + add_match.py +
  add_type.py + add_elem.py + add_elem_tcgdex.py + fix_type_tcgdex.py +
  fix_type_official.py + check_names.py + apply_name_fixes.py + image_patch.py

本腳本負責的欄位
  集合層：name（既有檔案已整理過的保留）、releaseDate、match_reg
  卡片層：name（僅新卡）、rarity、type、image、reg、elem
詳情欄位（hp / stage / evolvesFrom / dex / category / abilities / attacks /
weakness / resistance / retreat / effect / illustrator）仍由 scrape_details.py
負責——既有卡片原封保留，新卡片留白，跑完 build_set 後再跑 scrape_details。

資料來源
  1. card-search/                       擴充包清單：code / 名稱 / 發售日
  2. card-search/list/?expansionCodes=  該包所有卡片的官方圖 id（依官方頁序）
  3. card-search/detail/<id>/           每張卡的 編號 / 卡名 / span.alpha / 種類 / 屬性
  4. card-search/list/?rarity[]=<code>  稀有度對照（重用 add_rarity 的代碼表）
  圖網址由 id 直接組出：card-img/tw{id:08d}.png

賽制標記 reg
  取「官方 span.alpha」與「卡包發售期區塊」較舊者——實體卡不可能比發售當下
  的區塊新（官方詳情頁會把仍在環境內的萬用卡標記回溯改新，見 60e8717）。
  促銷冊系列（-P，跨年份共用一個發售日）不夾，直接採 span.alpha。
  基本能量固定 "None"；官方標記 n/a → ""。

用法
  python build_set.py --list                官方擴充包清單（code / 名 / 日）
  python build_set.py --validate <CODE>     只比對現有 json 的結構欄位，不寫檔
  python build_set.py <CODE> [<CODE> ...]   寫回結構欄位（既有詳情保留）
  python build_set.py <CODE> --details      寫完接著跑 scrape_details 補詳情
  加 --refresh 重抓清單頁 / id 清單 / 稀有度對照表

促銷冊（S-P / SV-P / SM-P / M-P）會隨時間持續加卡：這幾包的 id 清單每次都
重抓（不看快取），所以平常跑 `build_set.py M-P --details` 就會帶進新卡，
既有卡的詳情 / 標籤原封保留，不必加 --refresh。
"""

import argparse
import json
import os
import re
import subprocess
import sys
import time

import requests
from bs4 import BeautifulSoup

from scrape_details import _EN2ZH
from add_rarity import RARITY_CODES

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

SETS_DIR = "../assets/sets"
INDEX_FILE = "../assets/index.json"
BASE = "https://asia.pokemon-card.com/tw/card-search/"
IMG = "https://asia.pokemon-card.com/tw/card-img/tw{:08d}.png"

EXPANSIONS_CACHE = "expansions_cache.json"
IDLIST_CACHE = "idlist_cache.json"
RARITY_CACHE = "rarity_map.json"
RAW_CACHE = "build_raw_cache.json"  # id -> {num,name,alpha,type,elem}

ORDER = "ABCDEFGHIJ"
PROMO = {"S-P", "SV-P", "SM-P", "M-P"}
# 賽制區塊隨發售日推進的分界（該日(含)之後印的卡，最新只可能是這個區塊）
ERA_BOUNDARIES = [
    ("2019-12-20", "A"), ("2020-01-01", "B"), ("2020-05-01", "C"),
    ("2021-01-01", "D"), ("2022-01-01", "E"), ("2023-01-01", "F"),
    ("2024-01-01", "G"), ("2025-01-01", "H"), ("2026-01-01", "I"),
]
# 詳情頁 skillInformation 的 h3 標題（去掉結尾「卡」後）-> 我方 type
TYPE_BY_HEADER = {
    "招式": "寶可夢",
    "物品": "訓練家|物品",
    "支援者": "訓練家|支援者",
    "競技場": "訓練家|競技場",
    "寶可夢道具": "訓練家|道具",
    "基本能量": "基本能量",
    "特殊能量": "特殊能量",
}
_FW = {c: chr(ord(c) - 0xFEE0) for c in
       "ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ"
       "ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ０１２３４５６７８９"}
_ZW = dict.fromkeys(map(ord, "​‌‍﻿"), None)

# build_set 負責覆寫的卡片欄位；其餘（詳情）由既有檔案帶過來、scrape_details 補
STRUCT_KEYS = ("name", "rarity", "type", "image", "reg", "elem")
DETAIL_KEYS = ("hp", "stage", "evolvesFrom", "dex", "category", "abilities",
               "attacks", "weakness", "resistance", "retreat", "effect",
               "illustrator", "tags", "tagsReviewed")
KEY_ORDER = ["name", "rarity", "type", "image", "reg", "elem", "hp", "stage",
             "evolvesFrom", "dex", "category", "abilities", "attacks",
             "weakness", "resistance", "retreat", "effect", "illustrator",
             "tags", "tagsReviewed"]

_session = requests.Session()
_session.headers.update({"User-Agent": "Mozilla/5.0"})


class FetchError(RuntimeError):
    """重試耗盡的網路 / HTTP 失敗——與『404＝沒有這一頁』區分開，
    讓 build() 直接中止而不是把失敗頁當成清單結束、寫出殘缺的集合。"""


def _get(url, params=None, tries=3):
    last = None
    for i in range(tries):
        try:
            r = _session.get(url, params=params, timeout=25)
            if r.status_code == 404:
                return None
            r.raise_for_status()
            return r.text
        except Exception as e:
            last = e
            print(f"      ⚠️ {params or url} 第 {i + 1} 次失敗: {e}")
            time.sleep(1.5 * (i + 1))
    raise FetchError(f"{url}  {params or ''}  連抓 {tries} 次都失敗：{last}")


def _load(path, default):
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    return default


def _save(path, obj):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False)


def era_of(date):
    for lim, blk in ERA_BOUNDARIES:
        if date and date < lim:
            return blk
    return "J"


def clamp_reg(alpha, era, is_promo):
    alpha = (alpha or "").strip()
    if alpha in ("", "n/a", "-", "–", "－"):
        return ""
    if alpha not in ORDER:
        return alpha
    if is_promo:
        return alpha
    return era if ORDER.index(alpha) > ORDER.index(era) else alpha


def norm_name(raw):
    if not raw:
        return ""
    s = raw.split("|")[0].translate(_ZW).translate(_FW)
    return re.sub(r"\s+", " ", s).strip()


# --------------------------------------------------------------------------- #
def fetch_expansions(refresh=False):
    cache = _load(EXPANSIONS_CACHE, {})
    if cache and not refresh:
        return cache
    out, page = {}, 1
    while True:
        html = _get(BASE, {"pageNo": page})
        if not html:
            break
        soup = BeautifulSoup(html, "html.parser")
        lis = soup.select("ul.expansionList li.expansion")
        if not lis:
            break
        for li in lis:
            a = li.select_one("a.expansionLink")
            m = re.search(r"expansionCodes=([^&]+)", a.get("href", "") if a else "")
            if not m:
                continue
            title = li.select_one("h3.expansionTitle")
            t = li.select_one("time.relaseDate")  # 官方拼字
            date = ""
            if t and t.get("datetime"):
                mm, dd, yy = t["datetime"].split("-")
                date = f"{yy}-{mm}-{dd}"
            out[m.group(1)] = {
                "name": title.get_text(strip=True) if title else m.group(1),
                "releaseDate": date,
            }
        if f"pageNo={page + 1}" not in html:
            break
        page += 1
        time.sleep(0.2)
    if out:
        _save(EXPANSIONS_CACHE, out)
        print(f"📑 擴充包清單：{len(out)} 個")
    return out


def fetch_id_list(code, refresh=False):
    cache = _load(IDLIST_CACHE, {})
    # 促銷冊（-P）會隨時間持續加卡，id 清單永遠不算「抓完」，每次都重抓；
    # 詳情頁仍走各自的快取，所以只有真正的新卡會實際發請求。
    if code in cache and not refresh and code not in PROMO:
        return cache[code]
    ids, page = [], 1
    while True:
        # 網路失敗會 raise FetchError（中止建置）；回傳 None 只代表該頁 404＝沒這頁
        html = _get(BASE + "list/", {"expansionCodes": code, "pageNo": page})
        if not html:
            break
        found = re.findall(r"/card-img/tw0*(\d+)\.png", html)
        if not found:
            break
        ids.extend(int(x) for x in found)
        mt = re.search(r"共\s*([\d,]+)\s*頁", html)
        total = int(mt.group(1).replace(",", "")) if mt else page
        if page >= total:
            break
        page += 1
        time.sleep(0.15)
    seen, uniq = set(), []
    for i in ids:
        if i not in seen:
            seen.add(i)
            uniq.append(i)
    cache[code] = uniq
    _save(IDLIST_CACHE, cache)
    return uniq


def fetch_rarity_map(refresh=False):
    cache = _load(RARITY_CACHE, {})
    if cache and not refresh:
        return cache
    rmap = {}
    for rc, label in RARITY_CODES.items():
        page = 1
        while True:
            html = _get(BASE + "list/", {"rarity[]": rc, "pageNo": page})
            if not html:
                break
            for cid in re.findall(r"/card-img/tw0*(\d+)\.png", html):
                rmap.setdefault(cid, label)
            mt = re.search(r"共\s*([\d,]+)\s*頁", html)
            total = int(mt.group(1).replace(",", "")) if mt else page
            if page >= total:
                break
            page += 1
            time.sleep(0.12)
        print(f"   \U0001f48e {label or 'no-mark'}({rc}) 累計 {len(rmap)}")
    _save(RARITY_CACHE, rmap)
    return rmap


def extract_raw(cid, html):
    soup = BeautifulSoup(html, "html.parser")
    title = soup.select_one("title")
    num = soup.select_one("span.collectorNumber")
    alpha = soup.select_one("span.alpha")
    hdr = soup.select_one("div.skillInformation h3.commonHeader")
    header = (hdr.get_text(strip=True) if hdr else "").rstrip("卡")
    typ = TYPE_BY_HEADER.get(header, "寶可夢")
    elem = ""
    if typ == "寶可夢":
        mi = soup.select_one("p.mainInfomation")
        for im in (mi.select("img") if mi else []):
            m = re.search(r"/energy/([A-Za-z]+)\.png", im.get("src", ""))
            if m:
                elem = _EN2ZH.get(m.group(1), m.group(1))
                break
    return {
        "num": num.get_text(strip=True) if num else str(cid),
        "name": norm_name(title.get_text(strip=True) if title else ""),
        "alpha": alpha.get_text(strip=True) if alpha else "",
        "type": typ,
        "elem": elem,
    }


def get_raw(cid, rcache, refresh):
    raw = rcache.get(str(cid))
    if raw is not None and not refresh:
        return raw
    html = _get(BASE + f"detail/{cid}/")
    if not html:
        return None
    raw = extract_raw(cid, html)
    rcache[str(cid)] = raw
    time.sleep(0.15)
    return raw


def sort_key(k):
    p = k.split("/")[0].strip()
    m = re.match(r"([A-Za-z]*)(\d+)", p)
    if m:
        return (len(m.group(1)) > 0, m.group(1).lower(), int(m.group(2)))
    return (True, p, 99999)


def build(code, expansions, rarity_map, refresh=False):
    if code not in expansions:
        raise SystemExit(f"❌ 官方清單找不到 {code}（--refresh 重抓？）")
    meta = expansions[code]
    date = meta["releaseDate"]
    era = era_of(date)
    is_promo = code in PROMO

    path = os.path.join(SETS_DIR, f"{code}.json")
    old = _load(path, {}).get(code, {})
    old_cards = old.get("cards", {})
    set_name = old.get("name") or meta["name"]

    ids = fetch_id_list(code, refresh=refresh)
    print(f"🕷️  {code}  {meta['name']}  {date}  era={era}  官方圖 {len(ids)} 張"
          f"（既有 {len(old_cards)} 張）")

    # 用既有卡片的圖片 id 建反查表：官方 collectorNumber 對某些卡（LEGEND 的
    # 下半、基本能量的 3 字母代碼、部分促銷卡）不是「001/102」格式，改用圖 id 對上既有 key
    id2key = {}
    for k, c in old_cards.items():
        m = re.search(r"/tw0*(\d+)\.png", c.get("image", "") or "")
        if m:
            id2key.setdefault(m.group(1), k)

    rcache = _load(RAW_CACHE, {})
    cards, seen_nums = {}, set()
    for n, cid in enumerate(ids, 1):
        raw = get_raw(cid, rcache, refresh)
        if raw is None:
            print(f"   ⚠️ id {cid} 無詳情頁，略過")
            continue
        num = raw["num"]
        if str(cid) in id2key:
            key = id2key[str(cid)]            # 既有卡片認得這張圖 -> 沿用其 key
        elif re.match(r"[A-Za-z]*\d+/", num) or re.match(r"\d+$", num):
            key = num
        else:
            print(f"   ⚠️ id {cid} 的 collectorNumber={num!r} 非標準格式且無既有對應，略過")
            continue
        seen_nums.add(key)
        prev = old_cards.get(key, {})
        card = {
            "name": prev.get("name") or raw["name"],
            # 促銷冊整本一律 "PROMO"（不看既有值）；其餘查官方稀有度對照，查不到沿用既有
            "rarity": "PROMO" if is_promo
                      else rarity_map.get(str(cid), prev.get("rarity", "")),
            "type": raw["type"],
            "image": IMG.format(cid),
            "reg": "None" if raw["type"] == "基本能量"
                   else clamp_reg(raw["alpha"], era, is_promo),
        }
        # 官方詳情頁沒抓到屬性時（圖片缺失 / 版型變動）沿用既有 elem，避免解析失敗變成資料遺失
        elem = raw["elem"] or prev.get("elem", "")
        if elem:
            card["elem"] = elem
        for dk in DETAIL_KEYS:            # 詳情原封帶過來
            if dk in prev:
                card[dk] = prev[dk]
        cards[key] = {k: card[k] for k in KEY_ORDER
                      if k in card and (card[k] != "" or k == "reg")}
        if n % 50 == 0:
            print(f"   … {n}/{len(ids)}")
            _save(RAW_CACHE, rcache)
    _save(RAW_CACHE, rcache)

    carried = [k for k in old_cards if k not in seen_nums]
    for k in carried:
        cards[k] = old_cards[k]
    if carried:
        print(f"   ↩︎ 官方清單沒有、沿用既有 {len(carried)} 張：{sorted(carried)[:12]}"
              f"{' …' if len(carried) > 12 else ''}")

    cards = {k: cards[k] for k in sorted(cards, key=sort_key)}
    letters = sorted({c["reg"] for c in cards.values()
                      if c.get("reg", "") in ORDER})
    # 促銷冊跨年份、逐卡不夾 reg，match_reg 沿用既有值即可
    match_reg = old.get("match_reg", "") if is_promo else "".join(letters)
    out = {code: {
        "name": set_name,
        "releaseDate": date,
        "match_reg": match_reg or "".join(letters) or old.get("match_reg", ""),
        "cards": cards,
    }}
    return out


def write_set(code, obj):
    path = os.path.join(SETS_DIR, f"{code}.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"   ✅ 寫入 {path}（{len(obj[code]['cards'])} 張）")
    files = sorted(x[:-5] for x in os.listdir(SETS_DIR) if x.endswith(".json"))
    with open(INDEX_FILE, "w", encoding="utf-8") as f:
        json.dump(files, f, ensure_ascii=False, indent=2)


def validate(code, built):
    path = os.path.join(SETS_DIR, f"{code}.json")
    if not os.path.exists(path):
        print(f"（{code}.json 不存在，無法比對）")
        return
    cur = json.load(open(path, encoding="utf-8"))[code]
    new = built[code]
    for mk in ("name", "releaseDate", "match_reg"):
        if cur.get(mk) != new.get(mk):
            print(f"  META {mk}: {cur.get(mk)!r} -> {new.get(mk)!r}")
    ck, nk = set(cur["cards"]), set(new["cards"])
    if nk - ck:
        print(f"  只在新版: {sorted(nk - ck)}")
    if ck - nk:
        print(f"  只在舊版: {sorted(ck - nk)}")
    n = 0
    for k in sorted(ck & nk):
        a, b = cur["cards"][k], new["cards"][k]
        for f in STRUCT_KEYS:
            if a.get(f, "") != b.get(f, ""):
                n += 1
                print(f"  {k} {f}: {a.get(f)!r} -> {b.get(f)!r}")
    print(f"\n  === {code}: 結構欄位差異 {n} 處（詳情欄位不比，交給 scrape_details）===")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("codes", nargs="*")
    ap.add_argument("--validate", action="store_true")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--refresh", action="store_true")
    ap.add_argument("--details", action="store_true",
                    help="寫完後接著跑 scrape_details.py 補詳情")
    args = ap.parse_args()

    expansions = fetch_expansions(refresh=args.refresh)
    if args.list:
        for c, m in sorted(expansions.items(),
                           key=lambda kv: kv[1]["releaseDate"]):
            print(f"  {c:8} {m['releaseDate']}  {m['name']}")
        print(f"\n共 {len(expansions)} 個擴充包")
        return
    if not args.codes:
        ap.error("需要指定擴充包代碼，或用 --list")

    rarity_map = fetch_rarity_map(refresh=args.refresh)
    for code in args.codes:
        built = build(code, expansions, rarity_map, refresh=args.refresh)
        if args.validate:
            validate(code, built)
        else:
            write_set(code, built)
    if args.details and not args.validate:
        print("\n🚦 接著跑 scrape_details.py …")
        # 靜態參數、無 shell=True；sys.executable=當前直譯器、script=同目錄固定檔名，皆非外部輸入
        script = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                              "scrape_details.py")
        subprocess.run([sys.executable, script], check=True)  # noqa: S603


if __name__ == "__main__":
    main()
