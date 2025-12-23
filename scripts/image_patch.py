import json
import os
import re
import time
from tcgdexsdk import TCGdex

# ==========================================
# 設定區
# ==========================================
SETS_DIR = '../assets/sets'

# 初始化 TCGdex
print("🔌 初始化 TCGdex SDK...")
tcgdex = TCGdex("zh-tw")

def fill_images_for_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # 取得 Set ID (通常只有一個 key)
        set_code = list(data.keys())[0]
        set_data = data[set_code]
        cards = set_data.get('cards', {})
        
        updated_count = 0
        
        # --- 準備工作：尋找該系列的「基準卡片 (001)」---
        # 用於官方網址推算法
        base_card = None
        for k, v in cards.items():
            # 尋找 001 開頭的卡片 (例如 "001/158" 或 "001")
            if k.startswith("001/") or k == "001":
                if v.get('image') and "asia.pokemon-card.com" in v['image']:
                    base_card = v
                    break

        # 開始遍歷每一張卡
        for card_num, card_info in cards.items():

            # 1. 如果已經有圖片，跳過
            if card_info.get('image') and len(card_info['image']) > 0:
                continue

            # 2. 開始補圖
            image_url = ""
            card_name = card_info.get('name', '未知')

            # 方法 A: TCGdex SDK
            try:
                card_num_search = card_num.split('/')[0]
                full_id = f"{set_code}-{card_num_search}"
                
                # 呼叫 SDK
                res = tcgdex.card.getSync(full_id)
                if res and res.image:
                    # 檢查網址是否有效 (有時候會回傳 None 字串)
                    if "None" not in res.image:
                        image_url = f"{res.image}/high.webp"
                        # print(f"   [TCGdex] 成功: {full_id}")
            except:
                pass

            # 方法 B: 官網推算法 (Fallback)
            if not image_url and base_card:
                try:
                    # 檢查是否為高版本卡 (例如 195/190)，這種通常不能用推算的
                    is_high_rarity = False
                    if '/' in card_num:
                        parts = card_num.split('/')
                        if len(parts) == 2 and parts[0].isdigit() and parts[1].isdigit():
                            if int(parts[0]) > int(parts[1]):
                                is_high_rarity = True
                    
                    if not is_high_rarity:
                        # 解析基準圖片 ID
                        base_image_url = base_card['image']
                        match = re.search(r'tw(\d+)\.png', base_image_url)
                        
                        if match:
                            base_number_str = match.group(1)
                            base_number_int = int(base_number_str)
                            
                            # 計算目標 ID
                            # 目標 = 基準ID + (當前卡號 - 1)
                            target_num_int = int(card_num.split('/')[0])
                            offset = target_num_int - 1
                            new_number_int = base_number_int + offset
                            
                            # 補零回原本長度
                            new_number_str = str(new_number_int).zfill(len(base_number_str))
                            
                            image_url = base_image_url.replace(f"tw{base_number_str}.png", f"tw{new_number_str}.png")
                except:
                    pass

            # 3. 如果補到了，寫入變數
            if image_url:
                card_info['image'] = image_url
                updated_count += 1
                print(f"   📸 補圖成功 ({set_code}): {card_num} {card_name}")

        # 4. 如果有更新，寫回檔案
        if updated_count > 0:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"💾 {set_code} 存檔完成，共補齊 {updated_count} 張圖片。")
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
    
    for filename in files:
        file_path = os.path.join(SETS_DIR, filename)
        if fill_images_for_file(file_path):
            total_updated_files += 1

    print(f"\n✅ 全部完成！共更新了 {total_updated_files} 個系列的檔案。")

if __name__ == "__main__":
    main()