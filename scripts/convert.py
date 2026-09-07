import json
import os
try:
    import opencc
except ImportError:
    print("❌ 錯誤：找不到 opencc 套件。請執行 pip install opencc-python-reimplemented")
    exit()

# 設定目錄
SETS_DIR = '../assets/sets'

def convert_json_files():
    if not os.path.exists(SETS_DIR):
        print(f"❌ 找不到目錄: {SETS_DIR}")
        return

    # 初始化轉換器 (簡體 -> 繁體)
    # 註：試過 s2tw（台灣字形標準），但它的 MOE 用字（巖/託/後/僕/迴）
    # 跟寶可夢卡牌繁中官方譯名（岩/托/后/仆）相反，會把 290 個卡名改壞，
    # 也會 undo fix_translation.py 的規則，所以維持 s2t。
    converter = opencc.OpenCC('s2t')
    
    print("🚀 開始執行簡繁轉換...")
    
    files = [f for f in os.listdir(SETS_DIR) if f.endswith('.json')]
    count = 0

    for filename in files:
        file_path = os.path.join(SETS_DIR, filename)
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 直接對整個字串做轉換
            converted_content = converter.convert(content)
            
            # 檢查是否有變更，有變更才寫入
            if content != converted_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(converted_content)
                count += 1
                
        except Exception as e:
            print(f"   ❌ {filename} 轉換失敗: {e}")

    print(f"✅ 簡繁轉換完成！共掃描 {len(files)} 個檔案，更新了 {count} 個檔案。")

if __name__ == "__main__":
    convert_json_files()