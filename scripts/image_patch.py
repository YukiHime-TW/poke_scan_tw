import json
import os
import re
import time
from tcgdexsdk import TCGdex
from tqdm import tqdm

# ==========================================
# 設定區
# ==========================================
SETS_DIR = '../assets/sets' # 請確認路徑是否正確

# 初始化 TCGdex
print("🔌 初始化 TCGdex SDK...")
tcgdex = TCGdex("zh-tw")

# 用來收集缺少基準卡片的系列
sets_missing_base_report = []

# 用來收集有哪些缺少圖片的系列
sets_missing_image_report = []

def fill_images_for_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        set_code = list(data.keys())[0]
        set_data = data[set_code]
        cards = set_data.get('cards', {})
        set_name = set_data.get('name', '未知')
        
        updated_count = 0
        total_cards = len(cards)
        
        # --- 準備工作：尋找該系列的「基準卡片 (001)」---
        base_card = None
        for k, v in cards.items():
            # 邏輯：找 001 開頭，且必須該卡片已經有官網圖片
            if k.startswith("001/") or k == "001":
                if v.get('image') and "asia.pokemon-card.com" in v['image']:
                    base_card = v
                    break
        
        # 開始補圖
        for card_num, card_info in cards.items():
            # 1. 如果已經有圖片，跳過
            if card_info.get('image') and len(card_info['image']) > 0:
                continue

            image_url = ""
            
            # 方法 A: TCGdex SDK
            try:
                card_num_search = card_num.split('/')[0]
                full_id = f"{set_code}-{card_num_search}"
                res = tcgdex.card.getSync(full_id)
                if res and res.image and "None" not in res.image:
                    image_url = f"{res.image}/high.webp"
            except:
                pass

            # 方法 B: 官網推算法 (Fallback)
            if not image_url and base_card:
                try:
                    is_high_rarity = False
                    if '/' in card_num:
                        parts = card_num.split('/')
                        if len(parts) == 2 and parts[0].isdigit() and parts[1].isdigit():
                            if int(parts[0]) > int(parts[1]):
                                is_high_rarity = True
                    
                    if not is_high_rarity:
                        base_image_url = base_card['image']
                        match = re.search(r'tw(\d+)\.png', base_image_url)
                        if match:
                            base_number_str = match.group(1)
                            base_number_int = int(base_number_str)
                            target_num_int = int(card_num.split('/')[0])
                            offset = target_num_int - 1
                            new_number_int = base_number_int + offset
                            new_number_str = str(new_number_int).zfill(len(base_number_str))
                            image_url = base_image_url.replace(f"tw{base_number_str}.png", f"tw{new_number_str}.png")
                except:
                    pass

            # 3. 如果補到了，寫入變數
            if image_url:
                card_info['image'] = image_url
                updated_count += 1

        # --- 統計分析 ---
        # 檢查補完後還有多少張缺圖
        remaining_missing = 0
        for v in cards.values():
            if not v.get('image'):
                remaining_missing += 1
        
        # 如果還有缺圖，就加入報告
        if remaining_missing > 0:
            sets_missing_image_report.append({
                "code": set_code,
                "name": set_name,
                "missing_count": remaining_missing,
                "total": total_cards
            })
            # 如果是因為缺少基準卡片導致無法補圖，加入另一個報告
            if not base_card:
                sets_missing_base_report.append({
                    "code": set_code,
                    "name": set_name,
                    "missing_count": remaining_missing,
                    "total": total_cards
                })

        # 4. 如果有更新，寫回檔案
        if updated_count > 0:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            return True
            
    except Exception as e:
        print(f"❌ 處理 {file_path} 失敗: {e}")

    return False

def main():
    if not os.path.exists(SETS_DIR):
        print(f"❌ 找不到目錄: {SETS_DIR}")
        return

    print(f"🚀 開始掃描 {SETS_DIR} 下的所有檔案...")
    
    files = [f for f in os.listdir(SETS_DIR) if f.endswith('.json')]
    files.sort()
    
    total_updated_files = 0
    
    # 使用 tqdm 顯示總進度條
    for filename in tqdm(files, desc="處理進度"):
        file_path = os.path.join(SETS_DIR, filename)
        if fill_images_for_file(file_path):
            total_updated_files += 1

    print(f"\n✅ 補圖程序完成！共更新了 {total_updated_files} 個系列的檔案。")
    print("-" * 60)
    
    # --- 顯示報告 ---
    if sets_missing_image_report:
        print(f"⚠️ 以下系列【還有缺圖】：")
        print("-" * 60)
        print(f"{'代號':<10} {'缺圖數':<10} {'系列名稱'}")
        print("-" * 60)
        
        # 依照缺圖數量排序，從少到多
        sets_missing_image_report.sort(key=lambda x: x['missing_count'], reverse=False)

        for item in sets_missing_image_report:
            print(f"{item['code']:<10} {item['missing_count']}/{item['total']:<9} {item['name']}")
            
        print("-" * 60)
    else:
        print("🎉 沒有發現還有缺圖的系列。")

    if sets_missing_base_report:
        print(f"⚠️ 以下系列因為【缺少基準卡片】而無法補圖：")
        print("-" * 60)
        print(f"{'代號':<10} {'缺圖數':<10} {'系列名稱'}")
        print("-" * 60)
        
        # 依照缺圖數量排序，從少到多
        sets_missing_base_report.sort(key=lambda x: x['missing_count'], reverse=False)

        for item in sets_missing_base_report:
            print(f"{item['code']:<10} {item['missing_count']}/{item['total']:<9} {item['name']}")
            
        print("-" * 60)
    else:
        print("🎉 沒有發現因為缺少基準卡而無法補圖的系列。")

if __name__ == "__main__":
    main()