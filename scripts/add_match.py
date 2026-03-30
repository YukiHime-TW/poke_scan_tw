import json
import os
import time

SETS_DIR = '../assets/sets'

SET_MATCH = {
    "SI": "EF",
    "SDL": "EF",
    "SDP": "EF",
    "SDM": "EF",
    "S12a": "EF",
    "SO": "EF",
    "SVB": "EFG",
    "SVF": "EFG",
    "SVEM": "EFG",
    "SVEL": "EG",
    "SVHK": "FGH",
    "SVHM": "FGH",
    "SVK": "GH",
    "SV8a": "GH",
    "SVOM": "GHI",
    "SVOD": "GHI",
    "M2a": "HI",
    "MC": "HIJ",
}

def update_cards_regulation():
    if not os.path.exists(SETS_DIR):
        print(f"❌ 找不到目錄: {SETS_DIR}")
        return

    print("📅 開始為每張卡片補齊賽制標記 (match_reg)...")
    
    files = [f for f in os.listdir(SETS_DIR) if f.endswith('.json')]
    updated_files_count = 0

    for filename in files:
        file_path = os.path.join(SETS_DIR, filename)
        is_modified = False
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)

            # 遍歷 Set (例如 "SV4a")
            for set_code, set_data in data.items():
                
                # 決定這個系列的賽制標記
                reg_mark = SET_MATCH.get(set_code, "I") # 若找不到，預設為最新賽制 I
                
                # 同時更新系列的元數據 (Metadata)
                if set_data.get('match_reg') != reg_mark:
                    set_data['match_reg'] = reg_mark
                    is_modified = True

                # --- 核心：遍歷該系列下的所有卡片 ---
                if 'cards' in set_data:
                    for card_id, card_info in set_data['cards'].items():
                        # 如果這張卡沒有 match_reg，或者標記不正確
                        if card_info.get('reg') != reg_mark:
                            # 在每一張卡片屬性中加入 reg (與你之前的 HomeScreen 邏輯對應)
                            card_info['reg'] = reg_mark
                            is_modified = True

            if is_modified:
                with open(file_path, 'w', encoding='utf-8') as f:
                    # 使用 ensure_ascii=False 確保中文字不會變成 Unicode 碼
                    json.dump(data, f, ensure_ascii=False, indent=2)
                updated_files_count += 1
                print(f"   ✅ 已更新: {filename} (標記: {reg_mark})")

        except Exception as e:
            print(f"   ❌ {filename} 處理失敗: {e}")

    print(f"\n✨ 完成！共更新了 {updated_files_count} 個擴充包檔案。")

if __name__ == "__main__":
    update_cards_regulation()