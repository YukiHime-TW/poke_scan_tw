import json
import os

# 設定 JSON 檔案所在的目錄
SETS_DIR = '../assets/sets'

def add_type_to_cards():
    if not os.path.exists(SETS_DIR):
        print(f"❌ 找不到目錄: {SETS_DIR}")
        return

    print("🧬 開始遍歷卡片並補齊賽制標記 ...")
    
    # 取得目錄下所有 .json 檔案
    files = [f for f in os.listdir(SETS_DIR) if f.endswith('.json')]
    updated_files_count = 0

    for filename in files:
        file_path = os.path.join(SETS_DIR, filename)
        is_modified = False
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)

            # 遍歷 JSON 內部的每個擴充包 (Set)
            for set_code, set_data in data.items():
                
                # 檢查是否有 cards 欄位
                if 'cards' in set_data and isinstance(set_data['cards'], dict):
                    for card_id, card_info in set_data['cards'].items():

                        if 'reg' not in card_info:
                            card_info['reg'] = "J"
                            is_modified = True

            # 如果檔案內容有變動，才執行寫回動作
            if is_modified:
                with open(file_path, 'w', encoding='utf-8') as f:
                    # ensure_ascii=False 確保中文字不會被轉成 Unicode 碼
                    json.dump(data, f, ensure_ascii=False, indent=2)
                updated_files_count += 1
                print(f"   ✅ 已處理: {filename}")

        except Exception as e:
            print(f"   ❌ {filename} 處理失敗: {e}")

    print(f"\n✨ 任務完成！共更新了 {updated_files_count} 個 JSON 檔案。")

if __name__ == "__main__":
    add_type_to_cards()