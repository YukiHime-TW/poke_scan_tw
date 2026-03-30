import json
import os
import time

SETS_DIR = '../assets/sets'

# 台灣繁體中文版 發售日期對照表
# 資料來源：台灣寶可夢官網/Wiki
SET_MATCH = {
    # --- 通用 ---
    "ENERGY": "None",  # 基本能量
    # --- 太陽&月亮 (Sun & Moon) ---
    # 眾星雲集組合篇
    "AC1a": "A", "AC1b": "A",
    "AC1D": "A",
    # 美夢成真組合篇
    "AC2a": "B", "AC2b": "B",
    "AC2D": "B",
    # 雙倍爆擊
    "AS5a": "C", "AS5b": "C",
    "AS5D": "C",
    # 傳說交鋒
    "AS6a": "C", "AS6b": "C",
    "AS6D": "C",

    # --- 劍&盾 (Sword & Shield) ---
    # 劍&盾
    "SC1a": "D", "SC1b": "D",
    "SC1D": "D",
    # 無極力量
    "SC2a": "D", "SC2b": "D",
    "SC2D": "D",
    # 驚天伏特攻擊
    "S4": "D",
    # 閃色明星V
    "S4a": "D",
    "SCA": "D",
    # 連擊大師、一擊大師
    "S5I": "E",  "S5R": "E",
    "SCB": "E",
    # 雙璧戰士
    "S5a": "E",
    # 銀白戰槍、漆黑幽魂
    "S6H": "E",  "S6K": "E",
    # 伊布英雄
    "S6a": "E",
    "SCC": "E",
    # 摩天巔峰、蒼空烈流
    "S7D": "E",  "S7R": "E",
    # 匯流藝術
    "S8": "E",
    "SCD": "E",
    # 25 週年收藏版
    "S8a": "E", 
    # VMAX絕群壓軸
    "S8b": "DEF",
    # 星星誕生
    "S9": "F",
    "SJ": "D",
    "SK": "DEF",
    "SI": "EF",
    # 對戰地區
    "S9a": "F",
    "SLL": "DEF",  "SLD": "DEF",
    # 時間觀察者、空間魔術師
    "S10D": "F", "S10P": "F",
    # 黑暗亡靈
    "S10a": "F",
    # Pokémon GO
    "S10b": "F",
    # 迷途深淵
    "S11": "F",  
    "SPZ": "EF",  "SPD": "EF",
    "SP6": "F",
    # 白熱奧祕
    "S11a": "F",
    "SN": "EF",
    # 思維激盪
    "S12": "F",
    "SDL": "EF", "SDP": "EF", "SDM": "EF",
    # 天地萬物VSTAR
    "S12a": "EF",
    "SO": "EF",

    # --- 朱&紫 (Scarlet & Violet) ---
    # 朱ex、紫ex
    "SV1S": "G", "SV1V": "G",
    "SVAW": "G", "SVAM": "G", "SVAL": "G",
    "SVB": "EFG",
    # 三連音爆
    "SV1a": "G",
    "SVC": "G",
    # 冰雪險境、碟旋暴擊
    "SV2P": "G", "SV2D": "G",
    "SVP1": "G",
    # 寶可夢卡牌151
    "SV2a": "G",
    "SVD": "G",
    # 黯焰支配者
    "SV3": "G", 
    "SVF": "EFG",
    # 激狂駭浪
    "SV3a": "G",
    "SVEM": "EFG",
    "SVEL": "EG",
    # 古代咆哮、未來閃光
    "SV4K": "G", "SV4M": "G",
    # 閃色寶藏ex
    "SV4a": "G",
    # 狂野之力、異度審判
    "SV5K": "H", "SV5M": "H",
    "SVHK": "FGH", "SVHM": "FGH",
    # 緋紅薄霧
    "SV5a": "H",
    # 變幻假面
    "SV6": "H",
    # 黑夜漫遊者
    "SV6a": "H",
    # 星晶奇跡
    "SV7": "H",
    # 樂園騰龍
    "SV7a": "H",
    "SVK": "GH",
    "SVPN": "H",
    "SVPS": "H",
    # 超電突圍
    "SV8": "H",
    # 太晶慶典ex
    "SV8a": "GH",
    # 對戰搭檔
    "SV9": "I",
    "SVOM": "GHI",
    "SVOD": "GHI",
    # 熱風競技場
    "SV9a": "I",
    # 火箭隊的榮耀
    "SV10": "I",
    # 純白閃焰、漆黑伏特
    "SV11W": "I", "SV11B": "I",

    # --- 超級進化 (Mega) ---
    # 超級勇氣、超級交響樂
    "M1L": "I", "M1S": "I",
    "MBG": "I","MBD": "I",
    # 烈獄狂火X
    "M2": "I",
    # 超級進化夢想
    "M2a": "HI",
    # 初階牌組100對戰收藏
    "MC": "HIJ",
    # 虛無歸零
    "M3": "J",
    # 忍者飛旋
    "M4": "J",
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