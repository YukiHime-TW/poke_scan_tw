"""從官方訓練家網站的卡片詳情頁，補齊卡片的完整資料（招式 / 特性 / 效果 /
弱點 / 撤退 / 進化階級 / 圖鑑編號 …），寫回 assets/sets/*.json。

對象：image 為官方 tw<id>.png 的卡（約 12,000 張）。無官方 id 的（tcgdex
webp / 空字串）跳過，列進 detail_misses.txt。

新增欄位（有才寫）：
  hp            int
  stage         基礎 / 1階進化 / 2階進化
  evolvesFrom   進化前的名稱
  dex           圖鑑編號（字串，可能含 "、"）
  category      分類（例：獨角寶可夢）
  abilities     [{name, text}]
  attacks       [{name, cost:[繁中屬性...], damage, text}]
  weakness      例："火×2"（無則不寫）
  resistance    例："鬥-30"（無則不寫）
  retreat       int（撤退所需能量數）
  effect        訓練家 / 特殊能量的效果內文
  illustrator   繪師

    python scrape_details.py            # 用既有快取
    python scrape_details.py --refresh  # 全部重抓
"""

import json
import os
import re
import sys
import time

import requests
from bs4 import BeautifulSoup

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

SETS_DIR = "../assets/sets"
CACHE_FILE = "detail_cache.json"
MISS_FILE = "detail_misses.txt"
DETAIL = "https://asia.pokemon-card.com/tw/card-search/detail/{}/"
HEADERS = {"User-Agent": "Mozilla/5.0"}

_ID_RE = re.compile(r"/tw0*(\d+)\.png")
_EN2ZH = {
    "Grass": "草", "Fire": "火", "Water": "水", "Lightning": "雷",
    "Psychic": "超", "Fighting": "鬥", "Darkness": "惡", "Metal": "鋼",
    "Fairy": "妖精", "Dragon": "龍", "Colorless": "無色", "Void": "虛",
}
_ABILITY_RE = re.compile(r"^\[[^\]]*特性\]")
_RULE_RE = re.compile(r"^\[.*規則\]$")
_SCRAPED_KEYS = (
    "hp", "stage", "evolvesFrom", "dex", "category", "abilities",
    "attacks", "weakness", "resistance", "retreat", "effect", "illustrator",
)

_session = requests.Session()
_session.headers.update(HEADERS)


def _energies(span):
    out = []
    if not span:
        return out
    for img in span.select("img"):
        src = img.get("src", "")
        m = re.search(r"/energy/([A-Za-z]+)\.png", src)
        if m:
            out.append(_EN2ZH.get(m.group(1), m.group(1)))
    return out


def _txt(el):
    return el.get_text(" ", strip=True) if el else ""


def parse(html):
    soup = BeautifulSoup(html, "html.parser")
    info = soup.select_one("section.cardInformationColumn")
    if not info:
        return None
    out = {}

    main = info.select_one("p.mainInfomation")
    if main:
        num = main.select_one("span.number")
        if num and num.text.strip().isdigit():
            out["hp"] = int(num.text.strip())

    abilities, attacks = [], []
    effect_lines = []
    skill_box = info.select_one("div.skillInformation")
    header = _txt(skill_box.select_one("h3.commonHeader")) if skill_box else ""
    is_trainer_energy = header not in ("招式", "")
    for sk in (skill_box.select("div.skill") if skill_box else []):
        name = _txt(sk.select_one("span.skillName"))
        eff = _txt(sk.select_one("p.skillEffect"))
        if _RULE_RE.match(name):
            continue  # 規則框（樣板文字）
        if _ABILITY_RE.match(name):
            abilities.append({"name": _ABILITY_RE.sub("", name).strip(),
                              "text": eff})
        elif is_trainer_energy or name == "":
            if eff:
                effect_lines.append(eff)
        else:
            atk = {"name": name,
                   "cost": _energies(sk.select_one("span.skillCost")),
                   "damage": _txt(sk.select_one("span.skillDamage")),
                   "text": eff}
            attacks.append(atk)
    if abilities:
        out["abilities"] = abilities
    if attacks:
        out["attacks"] = attacks
    if effect_lines:
        out["effect"] = "\n".join(effect_lines)

    sub = info.select_one("div.subInformation")
    if sub:
        wp = sub.select_one("td.weakpoint")
        if wp and wp.select_one("img"):
            e = _energies(wp)
            mod = re.sub(r"\s+", "", wp.get_text("", strip=True))
            if e:
                out["weakness"] = e[0] + (mod if mod else "")
        rs = sub.select_one("td.resist")
        if rs and rs.select_one("img"):
            e = _energies(rs)
            mod = re.sub(r"\s+", "", rs.get_text("", strip=True))
            if e:
                out["resistance"] = e[0] + (mod if mod else "")
        esc = sub.select_one("td.escape")
        if esc:
            out["retreat"] = len(esc.select("img"))

    extra = soup.select_one("section.extraInformationColumn")
    if extra:
        # evolutionStep 是巢狀 ul，class first/second/third 就是階級
        active = extra.select_one("li.step.active")
        if active:
            par = active.find_parent("ul", class_="evolutionStep")
            stage_map = {"first": "基礎", "second": "1階進化",
                         "third": "2階進化"}
            for c in (par.get("class") or []) if par else []:
                if c in stage_map:
                    out["stage"] = stage_map[c]
            if out.get("stage") and out["stage"] != "基礎" and par:
                wrap_li = par.find_parent("li")
                gp = (wrap_li.find_parent("ul", class_="evolutionStep")
                      if wrap_li else None)
                if gp:
                    for li in gp.find_all("li", class_="step", recursive=False):
                        t = _txt(li)
                        if t:
                            out["evolvesFrom"] = t
                            break
        h3 = extra.select_one("div.extraInformation h3")
        if h3:
            m = re.match(r"No\.([\d、]+)\s*(.*)", _txt(h3))
            if m:
                out["dex"] = m.group(1)
                if m.group(2):
                    out["category"] = m.group(2).strip()
        ill = extra.select_one("div.illustrator a")
        if ill:
            out["illustrator"] = _txt(ill)

    return out


def fetch(card_id, cache):
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
            result = parse(r.text)
            break
        except Exception:
            time.sleep(1.2 * (i + 1))
    cache[key] = result
    return result


def main():
    refresh = "--refresh" in sys.argv
    cache = {}
    if os.path.exists(CACHE_FILE) and not refresh:
        with open(CACHE_FILE, encoding="utf-8") as f:
            cache = json.load(f)

    files = sorted(f for f in os.listdir(SETS_DIR) if f.endswith(".json"))
    seen = filled = miss = 0
    misses = []
    for filename in files:
        path = os.path.join(SETS_DIR, filename)
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        modified = False
        for set_code, sd in data.items():
            cards = sd.get("cards")
            if not isinstance(cards, dict):
                continue
            for num, card in cards.items():
                m = _ID_RE.search(card.get("image", "") or "")
                if not m:
                    miss += 1
                    misses.append(f"{set_code}\t{num}\t{card.get('name','')}")
                    continue
                if not refresh and any(k in card for k in _SCRAPED_KEYS):
                    continue
                seen += 1
                d = fetch(m.group(1), cache)
                if seen % 100 == 0:
                    print(f"   … {seen}（已補 {filled}）")
                    with open(CACHE_FILE, "w", encoding="utf-8") as f:
                        json.dump(cache, f, ensure_ascii=False)
                time.sleep(0.15)
                if not d:
                    continue
                for k in _SCRAPED_KEYS:
                    if k in d and card.get(k) != d[k]:
                        card[k] = d[k]
                        modified = True
                filled += 1
        if modified:
            with open(path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"   ✅ {filename}")

    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(cache, f, ensure_ascii=False)
    with open(MISS_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(misses))
    print(f"\n✨ 完成。補了 {filled} 張的詳情｜無官方 id {miss}（見 {MISS_FILE}）")


if __name__ == "__main__":
    main()
