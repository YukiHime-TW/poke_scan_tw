"""執行期資料健檢——App 直接抓 `main` 的 `assets/`，壞一次全體壞，
這支在 push / PR 動到 `assets/` 時把明顯錯誤攔下來。

純標準庫、不連網、秒級。全過 exit 0；有 ERROR exit 1（WARNING 不影響）。

    python validate_data.py
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"
SETS = ASSETS / "sets"

CONFIGS = ["index.json", "formats.json", "rarity_order.json",
           "tags_order.json", "deck_rules.json"]
_KEY_RE = re.compile(r"^[A-Za-z]*\d[\w.]*/[\w.\-]+$")
_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
# 硬性必填（缺了 App 會顯示未知 / 崩）。image 不列——高版本卡常無官方圖，
# 缺圖是已知待補（見 improvement-backlog），只當 WARNING。
_CARD_REQ = ("name", "type")
_NO_IMG = ("", "X")  # 「還沒有圖」的標記，不算重複、不算真網址

errors: list[str] = []
warnings: list[str] = []


def err(msg):
    errors.append(msg)


def warn(msg):
    warnings.append(msg)


def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f), None
    except Exception as e:  # noqa: BLE001
        return None, str(e)


def check_configs_parse():
    for name in CONFIGS:
        p = ASSETS / name
        if not p.exists():
            err(f"{name}：檔案不存在")
            continue
        _, e = load_json(p)
        if e:
            err(f"{name}：JSON 解析失敗 — {e}")


def check_index_matches_files():
    idx, e = load_json(ASSETS / "index.json")
    if e:
        return set()
    if not isinstance(idx, list) or not all(isinstance(x, str) for x in idx):
        err("index.json：應為字串陣列")
        return set()
    listed = set(idx)
    on_disk = {p.stem for p in SETS.glob("*.json")}
    for code in sorted(listed - on_disk):
        err(f"index.json 列了 {code}，但 assets/sets/{code}.json 不存在")
    for code in sorted(on_disk - listed):
        err(f"assets/sets/{code}.json 存在，但 index.json 沒列 {code}")
    if len(idx) != len(listed):
        err("index.json：有重複項目")
    return listed & on_disk


def check_set_file(code):
    """回傳 {card_key: card_dict}（給跨檔檢查用），並就地累積 errors。"""
    path = SETS / f"{code}.json"
    data, e = load_json(path)
    if e:
        err(f"{code}.json：JSON 解析失敗 — {e}")
        return {}
    if not isinstance(data, dict) or list(data.keys()) != [code]:
        err(f"{code}.json：最上層應為單一鍵 {{\"{code}\": ...}}")
        return {}
    sd = data[code]
    if not isinstance(sd.get("name"), str) or not sd["name"].strip():
        err(f"{code}：缺 name")
    if not _DATE_RE.match(str(sd.get("releaseDate", ""))):
        err(f"{code}：releaseDate 格式應為 YYYY-MM-DD（現 {sd.get('releaseDate')!r}）")
    cards = sd.get("cards")
    if not isinstance(cards, dict) or not cards:
        err(f"{code}：cards 應為非空物件")
        return {}

    seen_img: dict[str, str] = {}
    no_img = 0
    for key, card in cards.items():
        where = f"{code} {key}"
        if not _KEY_RE.match(key):
            warn(f"{where}：卡號 key 格式非典型")
        if not isinstance(card, dict):
            err(f"{where}：卡片應為物件")
            continue
        for f in _CARD_REQ:
            if not isinstance(card.get(f), str) or not card[f].strip():
                err(f"{where}：缺 {f}")
        if "reg" not in card:
            err(f"{where}：缺 reg 欄位（n/a 可用空字串）")
        img = card.get("image", "")
        if not isinstance(img, str) or img in _NO_IMG:
            no_img += 1
        elif img in seen_img:
            err(f"{where}：image 與 {seen_img[img]} 重複 — {img}")
        else:
            seen_img[img] = key
    if no_img:
        warn(f"{code}：{no_img}/{len(cards)} 張尚無圖")
    return {f"{code}-{k}": v for k, v in cards.items()}


def check_formats(all_cards, valid_codes):
    fmt, e = load_json(ASSETS / "formats.json")
    if e or not isinstance(fmt, dict):
        return
    if not isinstance(fmt.get("standard"), list) or not fmt["standard"]:
        err("formats.json：standard 應為非空陣列")
    names = {c.get("name") for c in all_cards.values() if isinstance(c, dict)}
    for bid in fmt.get("banned", []):
        if bid not in all_cards:
            err(f"formats.json banned：{bid} 在資料庫找不到對應卡片")
    for nm in fmt.get("standardNames", []):
        hit = nm in names or any(
            isinstance(n, str) and
            (n.startswith(f"{nm} ") or n.startswith(f"{nm}（")
             or n.startswith(f"{nm}("))
            for n in names)
        if not hit:
            warn(f"formats.json standardNames：「{nm}」目前沒有任何卡對應")
    fu = fmt.get("feedbackUrl")
    if fu not in (None, "") and not str(fu).startswith("http"):
        err(f"formats.json：feedbackUrl 應為網址或空字串（現 {fu!r}）")


def check_deck_rules():
    dr, e = load_json(ASSETS / "deck_rules.json")
    if e or not isinstance(dr, dict):
        return
    lim = dr.get("cardLimits")
    if not isinstance(lim, list):
        err("deck_rules.json：cardLimits 應為陣列")
        return
    for i, r in enumerate(lim):
        if not isinstance(r, dict):
            err(f"deck_rules.json cardLimits[{i}]：應為物件")
            continue
        if not r.get("id") or not r.get("label"):
            err(f"deck_rules.json cardLimits[{i}]：缺 id / label")
        if r.get("scope") not in ("deck", "name"):
            err(f"deck_rules.json cardLimits[{i}]：scope 應為 deck / name")
        if not isinstance(r.get("max"), int):
            err(f"deck_rules.json cardLimits[{i}]：max 應為整數")


def main():
    check_configs_parse()
    codes = check_index_matches_files()
    all_cards: dict[str, dict] = {}
    for code in sorted(codes):
        all_cards.update(check_set_file(code))
    check_formats(all_cards, codes)
    check_deck_rules()

    for w in warnings:
        print(f"⚠️  {w}")
    for e in errors:
        print(f"❌ {e}")
    total_cards = len(all_cards)
    if errors:
        print(f"\n✗ {len(errors)} 個錯誤（{len(warnings)} 警告）｜"
              f"{len(codes)} 包 {total_cards} 張")
        return 1
    print(f"\n✓ 通過｜{len(codes)} 包 {total_cards} 張"
          f"（{len(warnings)} 警告）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
