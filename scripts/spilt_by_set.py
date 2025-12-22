import json
import os
import shutil

INPUT_FILE = '../assets/data.json'
OUTPUT_DIR = '../assets/sets'
INDEX_FILE = '../assets/index.json'

def split_data():
    if not os.path.exists(INPUT_FILE):
        print(f"❌ 找不到 {INPUT_FILE}")
        return

    # 1. 準備資料夾 (如果已存在，建議先清空以免殘留舊檔)
    if os.path.exists(OUTPUT_DIR):
        shutil.rmtree(OUTPUT_DIR)
    os.makedirs(OUTPUT_DIR)

    print("📂 讀取原始資料...")
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    set_index = [] # 用來存系列清單，例如 ["SV4a", "S12a"...]

    # 2. 開始分割
    for set_code, set_data in data.items():
        # 為了方便 Flutter 讀取後直接合併，我們保持 {"SV4a": {...}} 的結構
        single_set_data = {set_code: set_data}
        
        file_name = f"{set_code}.json"
        file_path = os.path.join(OUTPUT_DIR, file_name)
        
        # 寫入單一系列檔案
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(single_set_data, f, ensure_ascii=False, indent=2)
            
        set_index.append(set_code)
        print(f"  -> 已建立: {file_name}")

    # 3. 建立索引檔 (Index)
    # 根據日期排序 (如果有的話)，或是字母順序
    # 這裡我們簡單用字母順序，反正 APP 端會再排一次
    set_index.sort() 
    
    with open(INDEX_FILE, 'w', encoding='utf-8') as f:
        json.dump(set_index, f, ensure_ascii=False, indent=2)

    print(f"\n✅ 分割完成！")
    print(f"1. 擴充包檔案已存入: {OUTPUT_DIR}/ (共 {len(set_index)} 個)")
    print(f"2. 索引檔案已建立: {INDEX_FILE}")

if __name__ == "__main__":
    split_data()