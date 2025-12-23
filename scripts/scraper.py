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

        if os.path.exists(set_file_path):
            # 嘗試讀取一下，確保檔案不是空的或壞的
            try:
                with open(set_file_path, 'r', encoding='utf-8') as f:
                    existing_data = json.load(f)
                
                # 如果讀取成功，且裡面有該系列的 key，就視為已存在
                if set_code in existing_data:
                    print(f"⏩ [{set_code}] 已存在，跳過。")
                    continue
            except:
                # 如果讀取失敗 (例如 JSON 格式壞掉)，則不跳過，重新爬取修復
                print(f"⚠️ [{set_code}] 檔案存在但損毀，準備重新爬取...")

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

                        card_num = num_text

                        existing_card = current_set_data['cards'].get(card_num)
                        
                        # 情況 1: 卡片已存在  -> 跳過
                        if existing_card:
                            skipped_count += 1
                            continue
                        
                        # 情況 2: 卡片不存在 (新卡!) -> 往下執行
                        if not existing_card:
                            print(f"   ✨ 發現新卡片: {card_num}")

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

                        image_url = ""
                        # 1. 嘗試保留舊圖片
                        if existing_card and existing_card.get('image'):
                            image_url = existing_card.get('image')

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
            
            print(f"   💾 {set_code} 處理完畢。跳過: {skipped_count} 張, 處理(新增): {processed_count} 張")

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

if __name__ == "__main__":
    start_time = time.time()

    run_scraper()

    print("\n🚦 開始簡體轉繁體...")
    subprocess.run(["python", "convert.py"], check=True)

    print("\n🚦 開始轉換台灣翻譯...")
    subprocess.run(["python", "fix_translation.py"], check=True)

    print("\n🚦 加入擴充包發售日期...")
    subprocess.run(["python", "add_date.py"], check=True)

    # print("\n🚦 開始補圖...")
    # subprocess.run(["python", "image_patch.py"], check=True)
    
    elapsed_time = time.time() - start_time
    print(f"\n🎉 全部完成！")
    print(f"⏱️ 總共花費 {elapsed_time:.2f} 秒。")

    print("\n✅ 全部完成！")