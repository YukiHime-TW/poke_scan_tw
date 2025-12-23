import json
import os
import re

SETS_DIR = '../assets/sets'

def get_sort_key(card_key):
    """
    自定義排序邏輯：
    1. 優先取斜線前的部分 (例如 "001/158" -> "001")
    2. 分離英文字母與數字 (例如 "TG05" -> "TG", 5)
    3. 數字部分轉為整數比對，文字部分轉小寫比對
    """
    # 取斜線前部分，去除空白
    prefix = card_key.split('/')[0].strip()
    
    # 使用 Regex 分離 "非數字前綴" 與 "數字"
    # 例如: "001" -> "", "001"
    # 例如: "TG01" -> "TG", "01"
    match = re.match(r'([a-zA-Z]*)(\d+)', prefix)
    
    if match:
        text_part = match.group(1).lower() # 文字部分 (如 tg)
        number_part = int(match.group(2))  # 數字部分 (如 1)
        
        # 排序權重:
        # 1. 有文字前綴的 (如 TG, AR, SAR) 通常排在純數字後面 -> 用 len(text_part) > 0 判斷
        # 2. 文字部分字母順序
        # 3. 數字大小
        is_special = len(text_part) > 0
        return (is_special, text_part, number_part)
    else:
        # 如果完全無法解析 (例如 "PROMO")，就排最後面
        return (True, prefix, 99999)

def main():
    if not os.path.exists(SETS_DIR):
        print(f"❌ 找不到目錄: {SETS_DIR}")
        return

    print("Fn 正在對 JSON 檔案進行排序...")
    
    files = [f for f in os.listdir(SETS_DIR) if f.endswith('.json')]
    files.sort() # 檔名也排一下
    
    sorted_count = 0

    for filename in files:
        file_path = os.path.join(SETS_DIR, filename)
        
        try:
            # 1. 讀取
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # 取得系列 Key (例如 "SV4a")
            set_code = list(data.keys())[0]
            set_data = data[set_code]
            
            if 'cards' in set_data:
                cards = set_data['cards']
                
                # 2. 排序
                # cards.items() 轉成 list 後進行排序
                sorted_items = sorted(cards.items(), key=lambda item: get_sort_key(item[0]))
                
                # 3. 轉回 Dict (Python 3.7+ 的 Dict 會記住插入順序)
                sorted_cards = {k: v for k, v in sorted_items}
                
                # 檢查順序是否真的有變 (避免不必要的寫入)
                if list(cards.keys()) != list(sorted_cards.keys()):
                    set_data['cards'] = sorted_cards
                    
                    # 4. 寫入
                    with open(file_path, 'w', encoding='utf-8') as f:
                        json.dump(data, f, ensure_ascii=False, indent=2)
                    
                    print(f"   ✅ 已排序: {filename}")
                    sorted_count += 1
                # else:
                #     print(f"   (略過) {filename} 順序已正確")

        except Exception as e:
            print(f"   ❌ 處理 {filename} 時發生錯誤: {e}")

    print(f"\n🎉 排序完成！共重新排列了 {sorted_count} 個檔案。")

if __name__ == "__main__":
    main()