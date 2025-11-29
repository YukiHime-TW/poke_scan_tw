import json
import re

JSON_FILE_PATH = '../assets/data.json'

# 定義修正字典 (左邊是錯誤/異體字，右邊是台灣官方標準字)
# 這些是針對您提供的檔案中觀察到的問題，以及常見的轉換錯誤
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

    # --- 寶可夢名稱/系列名修正 (針對舊翻譯或異體) ---
    "3D龍": "多邊獸",         # 雖然您的檔案多是多邊獸，以防萬一
    "鐵斑葉": "鐵斑葉",       # 確認用字
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

def process_data():
    print("📂 讀取 data.json 中...")
    try:
        with open(JSON_FILE_PATH, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"❌ 找不到 {JSON_FILE_PATH}，請確認檔案位置。")
        return

    print("🔧 開始修正翻譯與異體字...")
    
    count = 0
    
    # 遍歷資料結構
    for set_code, set_data in data.items():
        # 1. 修正系列名稱
        original_set_name = set_data.get('name', '')
        fixed_set_name = fix_text(original_set_name)
        if original_set_name != fixed_set_name:
            set_data['name'] = fixed_set_name
            print(f"  [系列] {original_set_name} -> {fixed_set_name}")
            count += 1

        # 2. 修正卡片資料
        if 'cards' in set_data:
            for card_id, card_info in set_data['cards'].items():
                # 修正卡名
                original_name = card_info.get('name', '')
                fixed_name = fix_text(original_name)
                
                if original_name != fixed_name:
                    card_info['name'] = fixed_name
                    count += 1
                
                # (選用) 修正稀有度，如果有中文字的話
                if 'rarity' in card_info:
                    card_info['rarity'] = fix_text(card_info['rarity'])
                    if card_info['rarity'] == '全':
                        card_info['rarity'] = 'SR'

    print(f"✅ 修正完成！共修正了 {count} 處。")
    
    # 輸出檔案至assets資料夾
    print(f"💾 儲存至 {JSON_FILE_PATH} ...")
    with open(JSON_FILE_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print("🎉 完成！ data.json 已放入您的 Flutter 專案。")

if __name__ == "__main__":
    process_data()