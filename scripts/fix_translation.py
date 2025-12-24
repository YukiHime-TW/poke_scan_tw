import json
import os

# 設定目錄
SETS_DIR = '../assets/sets'

# 修正字典
REPLACEMENTS = {
    # --- 常見錯別字/轉換錯誤 ---
    "樹纔怪": "樹才怪",       # "纔" 是 "才" 的錯誤繁體轉換
    "僞螳草": "偽螳草",       # "僞" 是 "偽" 的異體字
    "僞": "偽",               # 通用修正
    "峯": "峰",               # "摩天巔峯" -> "摩天巔峰"
    "竈": "灶",               # "厄鬼椪 火竈面具" -> "火灶面具"
    "振翼發": "振翼髮",       # "髮" (頭髮) 被錯誤轉為 "發" (發財)
    "后": "后",               # 確保 "尼多后"、"甜冷美后" 不會被轉成 "後" (此行僅作邏輯確認)
    "准": "準",               # 準神
    "鈎": "鉤",               # 爪鉤
    "綫": "線",
    "滙": "匯",
    "羣": "群",               # 有些字體會顯示 "羣"，統一為 "群"
    "巖": "岩",
    "託": "托",
    "着": "著",
    "脣": "唇",

    # --- 寶可夢名稱/系列名修正 (針對舊翻譯或異體) ---
    "3D龍": "多邊獸",
    "鐵斑葉": "鐵斑葉",
    "吼叫尾": "吼叫尾",
    "猛惡菇": "猛惡菇",
    "振翼髮": "振翼髮",
    "爬地翅": "爬地翅",
    "沙鐵皮": "沙鐵皮",
    "鐵轍跡": "鐵轍跡",
    "鐵包袱": "鐵包袱",
    "鐵臂膀": "鐵臂膀",
    "鐵脖頸": "鐵脖頸",
    "鐵毒蛾": "鐵毒蛾",
    "鐵荊棘": "鐵荊棘",
    "鐵武者": "鐵武者",
    "轟鳴月": "轟鳴月",
    "故勒頓": "故勒頓",
    "密勒頓": "密勒頓",
    "焰後蜥": "焰后蜥",
    "夜間搶架": "夜間擔架",
    "迭失棺": "死神棺",
    "尼多後": "尼多后",
    "烏慄": "烏栗",
    "愛喫豚": "愛吃豚",
    "山谷迴音喇叭": "山谷回音喇叭",
    
    # --- 特殊案例修正 ---
    "阿羅拉 臭臭泥": "阿羅拉 臭臭泥", # 確保空格正確
    "阿羅拉 椰蛋樹": "阿羅拉 椰蛋樹",
}

# 針對特定欄位進行文字替換
def fix_text(text):
    if not isinstance(text, str):
        return text
    new_text = text
    for wrong, correct in REPLACEMENTS.items():
        if wrong in new_text:
            new_text = new_text.replace(wrong, correct)
    return new_text

def fix_translation_files():
    if not os.path.exists(SETS_DIR):
        print(f"❌ 找不到目錄: {SETS_DIR}")
        return

    print("🔧 開始修正異體字與翻譯...")
    
    files = [f for f in os.listdir(SETS_DIR) if f.endswith('.json')]
    total_fixed_count = 0

    for filename in files:
        file_path = os.path.join(SETS_DIR, filename)
        is_modified = False
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)

            # 遍歷該檔案中的系列 (通常只有一個 key，但也支援多個)
            for set_code, set_data in data.items():
                
                # 1. 修正系列名稱
                if 'name' in set_data:
                    new_name = fix_text(set_data['name'])
                    if new_name != set_data['name']:
                        set_data['name'] = new_name
                        is_modified = True

                # 2. 修正卡片資料
                if 'cards' in set_data:
                    for card_id, card_info in set_data['cards'].items():
                        # 修正卡名
                        if 'name' in card_info:
                            new_card_name = fix_text(card_info['name'])
                            if new_card_name != card_info['name']:
                                card_info['name'] = new_card_name
                                is_modified = True
                        
                        # 修正稀有度
                        if 'rarity' in card_info:
                            new_rarity = fix_text(card_info['rarity'])
                            if new_rarity != card_info['rarity']:
                                card_info['rarity'] = new_rarity
                                is_modified = True

            # 如果有修改才寫回檔案
            if is_modified:
                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)
                total_fixed_count += 1

        except Exception as e:
            print(f"   ❌ {filename} 處理失敗: {e}")

    print(f"✅ 修正完成！共更新了 {total_fixed_count} 個檔案。")

if __name__ == "__main__":
    fix_translation_files()