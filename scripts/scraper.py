import requests
from bs4 import BeautifulSoup
import json
import time
import os
import re
import subprocess
from tcgdexsdk import TCGdex

# ==========================================
# 1. 設定區
# ==========================================
SETS_DIR = '../assets/sets'     # 存放分開 JSON 的資料夾
INDEX_FILE = '../assets/index.json' # 索引檔案路徑

TARGET_URLS_DIR = 'target_urls.json' # 目標網址清單

PROMO_CODES = [
    "SM-P",
    "S-P",
    "SV-P",
    "M-P"
]

# 初始化 TCGdex
tcgdex = TCGdex("zh-tw")

def clean_text(text):
    if not text: return ""
    return text.strip().replace('\n', '')
    
def load_target_urls():
    if not os.path.exists(TARGET_URLS_DIR):
        print(f"❌ 錯誤：找不到設定檔 {TARGET_URLS_DIR}")
        return []
    
    try:
        with open(TARGET_URLS_DIR, 'r', encoding='utf-8') as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        print(f"❌ 設定檔 JSON 格式錯誤: {e}")
        return []

def run_scraper():
    TARGET_URLS = load_target_urls()
    if not TARGET_URLS:
        print("❌ 無有效的目標網址，爬蟲終止。")
        return

    print("🚀 開始執行智慧爬蟲...")
    start_time = time.time()

    headers = {'User-Agent': 'Mozilla/5.0'}

    # 1. 確保資料夾存在
    if not os.path.exists(SETS_DIR):
        os.makedirs(SETS_DIR)

    # 2. 開始迴圈
    for target in TARGET_URLS:
        set_code = target['code']
        set_name = target['name']

        # 定義該系列的檔案路徑
        set_file_path = os.path.join(SETS_DIR, f"{set_code}.json")
        
        # ------------------------------------------------------
        # 👇 步驟 A: 讀取單一系列的舊資料
        # ------------------------------------------------------
        current_set_data = {}
        if os.path.exists(set_file_path):
            try:
                with open(set_file_path, 'r', encoding='utf-8') as f:
                    full_data = json.load(f)
                    if set_code in full_data:
                        current_set_data = full_data[set_code]
            except:
                pass 

        # 初始化資料結構 (如果是新檔案)
        if not current_set_data:
            current_set_data = {
                "name": set_name,
                "releaseDate": "2000-01-01", # 預設日期，之後可用 add_date.py 更新
                "cards": {}
            }

        # ------------------------------------------------------
        # 👇 步驟 B: 爬取網頁 (這裡不跳過，必須爬才能比對新卡)
        # ------------------------------------------------------
        print(f"🕷️ 掃描系列: {set_name} ({set_code})...")
        try:
            resp = requests.get(target['url'], headers=headers, timeout=15)
            soup = BeautifulSoup(resp.text, 'html.parser')
            tables = soup.find_all('table', class_='roundy')
            processed_count = 0 # 新增或補圖的數量
            skipped_count = 0   # 已存在的數量
            
            for table in tables:
                rows = table.find_all('tr')
                for row in rows:
                    cols = row.find_all('td')
                    if len(cols) < 3: continue

                    try:
                        # 提取編號
                        num_text = clean_text(cols[0].text)
                        if not num_text or not num_text[0].isdigit():
                            continue

                        card_num = num_text # e.g. 001/158

                        # ==================================================
                        # 👇 【核心修改】: 判斷是否為新卡或缺圖卡
                        # ==================================================
                        
                        existing_card = current_set_data['cards'].get(card_num)
                        
                        # 情況 1: 卡片已存在 且 有圖片 -> 完美，跳過
                        if existing_card and existing_card.get('image') and len(existing_card['image']) > 0:
                            skipped_count += 1
                            continue
                        
                        # 情況 2: 卡片不存在 (新卡!) 或 存在但沒圖 -> 往下執行
                        if not existing_card:
                            print(f"   ✨ 發現新卡片: {card_num}")
                        elif not existing_card.get('image'):
                            print(f"   🔄 補圖中: {card_num}")
                            pass

                        # ==================================================
                        # 👇 資料解析與補圖邏輯
                        # ==================================================

                        # 提取名稱 (順便更新文字，以防是新卡)
                        name_text = "未知"
                        if len(cols) >= 3:
                            name_text = clean_text(cols[1].text)

                        # 特例處理: name_text 為 "25周年收藏版" 的資料是錯誤的，跳過不存
                        if name_text == "25周年收藏版":
                            continue

                        # 提取稀有度
                        rarity_text = ""
                        if len(cols) >= 4:
                            rarity_text = clean_text(cols[2].text)

                        # 如果編號格式為 "001/S-P"、"001/SV-P"、"001/M-P"，則將稀有度設置為PROMO
                        if any(code in num_text for code in PROMO_CODES):
                            rarity_text = "PROMO"

                        # --------------------------------------------------
                        # 圖片獲取 (呼叫 TCGdex SDK)
                        # --------------------------------------------------
                        image_url = ""

                        # 1. 嘗試保留舊圖片
                        if existing_card and existing_card.get('image'):
                            image_url = existing_card.get('image')

                        # 2. 嘗試 TCGdex SDK
                        if not image_url:
                            try:
                                card_num_for_search = card_num.split('/')[0] # 取斜線前部分 (例如 005)
                                full_card_num = f"{set_code}-{card_num_for_search}"

                                # TCGdex 查詢
                                card = tcgdex.card.getSync(full_card_num)
                                if card and card.image:
                                    image_url = f"{card.image}/high.webp"
                            except:
                                print(f"   ⚠️ TCGdex 查詢失敗: {full_card_num}")
                                pass

                        # 3. 嘗試從官網推算 (Fallback)
                        if not image_url:
                            try:
                                # 檢查是否為高版本卡 (SR/SAR 等)，如果是通常不適用順序推算，跳過
                                is_high_rarity = False
                                if '/' in card_num:
                                    parts = card_num.split('/')
                                    if len(parts) == 2 and parts[0].isdigit() and parts[1].isdigit():
                                        if int(parts[0]) > int(parts[1]):
                                            is_high_rarity = True

                                if not is_high_rarity:
                                    # 尋找該系列的 001 號卡片 (需要模糊搜尋，因為 Key 可能是 "001/165")
                                    base_card = None
                                    cards_in_set = current_set_data[set_code]['cards']
                                    
                                    # 遍歷尋找 001 開頭的卡
                                    for k, v in cards_in_set.items():
                                        if k.startswith("001/") or k == "001":
                                            base_card = v
                                            break

                                    # 如果找到了 001 且它有官網圖片連結
                                    if base_card and base_card.get('image') and "asia.pokemon-card.com" in base_card['image']:
                                        base_image_url = base_card['image']
                                        
                                        # 解析檔名數字 (例如 tw00004637.png -> 00004637)
                                        match = re.search(r'tw(\d+)\.png', base_image_url)
                                        if match:
                                            base_number_str = match.group(1) # "00004637"
                                            base_number_int = int(base_number_str)

                                            # 計算目標卡片的檔名數字
                                            # 公式: 001的檔名數字 + (當前卡號 - 1)
                                            target_offset = int(card_num_for_search) - 1
                                            new_number_int = base_number_int + target_offset

                                            # 轉回字串並補零 (保持跟原本一樣的位數，通常是8位)
                                            new_number_str = str(new_number_int).zfill(len(base_number_str))

                                            # 替換網址
                                            image_url = base_image_url.replace(f"tw{base_number_str}.png", f"tw{new_number_str}.png")
                                            print(f"   📸 官網補圖成功: {full_card_num}")
                                    else:
                                        print(f"   ⚠️ 官網補圖失敗: 找不到系列 {set_code} 的 001 號卡片作為基準，無法推算 {full_card_num} 的圖片")
                                else:
                                    print(f"   ⚠️ 官網補圖跳過: {full_card_num} 為高版本卡，跳過官網補圖邏輯")
                            except Exception as logic_error:
                                print(f"   ⚠️ 官網補圖邏輯錯誤: {logic_error}")
                                pass
                        # --------------------------------------------------

                        # 4. 更新/寫入資料
                        # 這裡使用 update 確保如果原本有其他欄位(如 note)不會被洗掉
                        if card_num not in current_set_data['cards']:
                            current_set_data['cards'][card_num] = {}

                        current_set_data['cards'][card_num]['name'] = name_text
                        current_set_data['cards'][card_num]['rarity'] = rarity_text
                        
                        # 只有當真的抓到新圖時才更新 image，避免把原本手動填的蓋成空字串
                        if image_url:
                            current_set_data['cards'][card_num]['image'] = image_url
                        elif 'image' not in current_set_data['cards'][card_num]:
                            current_set_data['cards'][card_num]['image'] = ""

                        processed_count += 1
                    except Exception:
                        continue
            
            print(f"   💾 {set_code} 處理完畢。跳過(已有圖): {skipped_count} 張, 處理(補圖/新增): {processed_count} 張")
            
            # --- 步驟 C: 儲存單一檔案 ---
            output_data = {set_code: current_set_data}
            with open(set_file_path, 'w', encoding='utf-8') as f:
                json.dump(output_data, f, ensure_ascii=False, indent=2)
            
            # 只有在真的有發送大量請求時才睡覺
            if processed_count > 5:
                time.sleep(1)
            else:
                time.sleep(0.1)

        except Exception as e:
            print(f"   ❌ {set_code} 失敗: {e}")

    # 3. 建立索引檔 (Index)
    print("📑 正在更新索引檔 index.json ...")
    actual_files = [f.replace('.json', '') for f in os.listdir(SETS_DIR) if f.endswith('.json')]
    actual_files.sort()

    with open(INDEX_FILE, 'w', encoding='utf-8') as f:
        json.dump(actual_files, f, ensure_ascii=False, indent=2)

    elapsed_time = time.time() - start_time
    print(f"\n🎉 全部完成！")
    print(f"⏱️ 總共花費 {elapsed_time:.2f} 秒。")

if __name__ == "__main__":
    run_scraper()

    print("\n🚦 開始簡體轉繁體...")
    subprocess.run(["python", "convert.py"], check=True)

    print("\n🚦 開始轉換台灣翻譯...")
    subprocess.run(["python", "fix_translation.py"], check=True)

    print("\n🚦 加入擴充包發售日期...")
    subprocess.run(["python", "add_date.py"], check=True)

    print("\n✅ 全部完成！")