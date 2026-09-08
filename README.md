# 繁中PTCG集換所

繁體中文寶可夢集換式卡牌（PTCG）玩家與收藏家的工具：收藏管理、牌組構築、
用相機掃描卡片編號快速登錄。

> 非官方的粉絲自製工具，與 Nintendo、The Pokémon Company、Creatures Inc.
> 無任何關係。卡片名稱與圖片版權皆屬原公司所有。

- 網頁版：<https://yukihime-tw.github.io/poke_scan_tw/>
- 隱私權政策：[PRIVACY.md](PRIVACY.md)

## 功能

- **收藏管理**：依系列瀏覽，點一下 +1；彩色／黑白區分持有；完成度進度條
- **卡片詳情**：長按卡片彈出詳情（招式・特性・效果・弱點・繪師等），
  在裡面直接調整「收藏／這副牌／想要」的張數
- **願望清單**：以數量記錄想要幾張，收藏達標時自動移出；卡面左下角粉紅星星標記；
  可一鍵複製成「還缺 N」的對齊文字貼社群
- **相機掃描**：對準卡片左下角編號，裝置端 OCR（ML Kit）辨識並加入收藏，不上傳照片
- **牌組 / 收藏本**：牌組限 60 張・同名 4 張，另依 `deck_rules.json` 套用光輝寶可夢 /
  ACE SPEC / ◇ / 「傳說的」競技場（算 2 張）/ V-UNION（算 4 張）等額外張數上限；
  收藏本無限制；比對實體庫存；匯出牌表
- **牌組合法性檢查**：牌組清單依 `formats.json` 標示 **標準 / 開放 / 未完成**
  （標準賽制的 reg 白名單 + 官方「過往可用卡清單」的舊標記卡 + 全面禁用卡），
  預覽頁列出非標準卡、禁用卡、缺張、缺基礎寶可夢與違反的額外組牌規則
- **篩選**：收藏狀態（含願望清單）/ 賽制 / 種類 / 屬性 / 稀有度 / 機制標籤
  （稀有度與機制標籤依卡表內容動態產生）+ 關鍵字（名稱・編號・系列）
- **雲端同步**：Google 登入後收藏、願望清單與牌組跨裝置同步（Firestore）；
  不登入則只存本機，登出時清除本機資料

## 技術

Flutter（Android / iOS / Web）、Provider、Firebase Auth + Cloud Firestore、
Google ML Kit 文字辨識、`sliver_tools`。

App 啟動時從 `raw.githubusercontent.com/.../refs/heads/main/assets` 抓最新卡表
JSON 與設定檔，**所以卡片資料變更需合併進 `main` 才會生效**，不需重出 App。
執行期抓取的設定檔（皆有打包在 APK 內的預設值作 fallback）：

| 檔案 | 作用 |
|---|---|
| `assets/rarity_order.json` | 稀有度篩選 chip 的排序（陣列，不在清單內的排最後） |
| `assets/formats.json` | `standard`：標準賽制 reg 白名單；`standardNames`：reg 為 A–G 但官方仍列標準合法的卡名（過往可用卡清單，含新舊名並列）；`banned`：全面禁用卡的 `setCode-num`。供賽制篩選與牌組合法性檢查共用 |
| `assets/tags_order.json` | 機制標籤 chip 的分組排序 |
| `assets/deck_rules.json` | 追加組牌張數上限；`cardLimits[]`，每條 `where`（nameContains / type / rarity，全中才算命中）+ `scope`（`deck` 整套牌總量 / `name` 每個同名）+ `max` + 選用 `weight`（畫面 1 張實際算幾張，如傳說的競技場 2、V-UNION 4）。新規則同型只改資料 |

## 專案結構

```
lib/                    Flutter 原始碼
assets/sets/            各系列卡片資料 JSON（131 個系列）
assets/index.json       系列索引
assets/rarity_order.json / formats.json / tags_order.json   執行期設定檔
scripts/                資料維護腳本（見下）
store/                  Play 上架素材（圖示、功能圖、文案、表單答案）
android/ ios/ web/      各平台設定
```

## 資料維護（scripts/）

`python scraper.py` 會依序跑完整條管線：

| 腳本 | 作用 |
|---|---|
| `scraper.py` | 從卡表來源爬新卡（編號 / 名稱 / 稀有度），更新 `index.json` |
| `convert.py` | 簡體 → 繁體（OpenCC `s2t`；`s2tw` 不適用，見檔內註解） |
| `fix_translation.py` | 異體字與舊譯名修正字典 |
| `add_date.py` | 補系列發售日期 |
| `add_match.py` | 補賽制標記（reg） |
| `add_type.py` | 補卡片種類（預設寶可夢，再由後續腳本 / 人工修正） |
| `add_elem.py` | 補寶可夢屬性 elem（官方清單頁 `pokemonEnergy` 篩選） |
| `add_elem_tcgdex.py` | 補無官方圖的卡的 elem（tcgdex API） |
| `fix_type_tcgdex.py` / `fix_type_official.py` | 用 tcgdex / 官方詳情頁校對修正 type |

管線外的獨立工具（各自手動執行，不在 `scraper.py` 裡）：

| 腳本 | 作用 |
|---|---|
| `scrape_details.py` | 爬官方詳情頁補 hp / 招式 / 特性 / 效果 / 弱點 / 繪師等（量大、單獨跑） |
| `card_editor.py` | 本機網頁工具 `localhost:8770`，瀏覽 / 編輯卡片欄位、勾機制標籤 → `card["tags"]`（標籤定義見 `mechanic_tags.json`） |
| `check_names.py` | 對官方卡片頁核對卡名 |
| `add_rarity.py` | 補空白稀有度 |
| `gen_icons.py` | 產生 App 圖示與 Play 素材 |

```
pip install -r scripts/requirements.txt   # requests, beautifulsoup4, opencc, Pillow ...
```

## 建置

```bash
# Android APK（自動輸出 build/app/outputs/flutter-apk/pokescan_<版本>.apk）
flutter build apk --release

# Android App Bundle（上 Play 用）
flutter build appbundle --release

# Web
flutter build web --release --base-href /poke_scan_tw/
```

APK 簽署需 `android/key.properties`（指向上傳用 keystore）。版本號改
`pubspec.yaml` 的 `version:`。

### 部署網頁版（gh-pages）

`gh-pages` 分支放的是 `flutter build web` 的產物。合併進 `main` 後：

```bash
flutter build web --release --base-href /poke_scan_tw/
# 用一個乾淨 worktree 取代整個 gh-pages 內容後 push（不要在 build/web 裡塞 git repo）
git worktree add /tmp/ghp origin/gh-pages
rm -rf /tmp/ghp/*; cp -r build/web/. /tmp/ghp/
git -C /tmp/ghp add -A && git -C /tmp/ghp commit -m "更新網頁版"
git -C /tmp/ghp push origin HEAD:gh-pages
git worktree remove /tmp/ghp
```
