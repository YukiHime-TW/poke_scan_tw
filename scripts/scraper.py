import requests
from bs4 import BeautifulSoup
import json
from tcgdexsdk import TCGdex
import time

# 定義要抓取的系列 (可以自行擴充 URL)
TARGET_URLS = [
    {
        "code": "AC1a",
        "name": "眾星雲集組合篇 SET A",
        "url": "https://wiki.52poke.com/wiki/%E4%BC%97%E6%98%9F%E4%BA%91%E9%9B%86%E7%BB%84%E5%90%88%E7%AF%87_SET_A%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "AC1b",
        "name": "眾星雲集組合篇 SET B",
        "url": "https://wiki.52poke.com/wiki/%E4%BC%97%E6%98%9F%E4%BA%91%E9%9B%86%E7%BB%84%E5%90%88%E7%AF%87_SET_B%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "AC2a",
        "name": "美夢成真組合篇 SET A",
        "url": "https://wiki.52poke.com/wiki/%E7%BE%8E%E5%A4%A2%E6%88%90%E7%9C%9F%E7%B5%84%E5%90%88%E7%AF%87_SET_A%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "AC2b",
        "name": "美夢成真組合篇 SET B",
        "url": "https://wiki.52poke.com/wiki/%E7%BE%8E%E5%A4%A2%E6%88%90%E7%9C%9F%E7%B5%84%E5%90%88%E7%AF%87_SET_B%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "AS5a",
        "name": "雙倍爆擊 SET A",
        "url": "https://wiki.52poke.com/wiki/%E5%8F%8C%E5%80%8D%E7%88%86%E5%87%BB_SET_A%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "AS5b",
        "name": "雙倍爆擊 SET B",
        "url": "https://wiki.52poke.com/wiki/%E5%8F%8C%E5%80%8D%E7%88%86%E5%87%BB_SET_B%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "AS6a",
        "name": "傳說交鋒 SET A",
        "url": "https://wiki.52poke.com/wiki/%E4%BC%A0%E8%AF%B4%E4%BA%A4%E9%94%8B_SET_A%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "AS6b",
        "name": "傳說交鋒 SET B",
        "url": "https://wiki.52poke.com/wiki/%E4%BC%A0%E8%AF%B4%E4%BA%A4%E9%94%8B_SET_B%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S4",
        "name": "驚天伏特攻擊",
        "url": "https://wiki.52poke.com/wiki/%E6%83%8A%E5%A4%A9%E4%BC%8F%E7%89%B9%E6%94%BB%E5%87%BB%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S5I",
        "name": "一擊大師",
        "url": "https://wiki.52poke.com/wiki/%E4%B8%80%E5%87%BB%E5%A4%A7%E5%B8%88%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S5R",
        "name": "連擊大師",
        "url": "https://wiki.52poke.com/wiki/%E8%BF%9E%E5%87%BB%E5%A4%A7%E5%B8%88%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S6H",
        "name": "銀白戰槍",
        "url": "https://wiki.52poke.com/wiki/%E9%93%B6%E7%99%BD%E6%88%98%E6%9E%AA%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S6K",
        "name": "漆黑幽魂",
        "url": "https://wiki.52poke.com/wiki/%E6%BC%86%E9%BB%91%E5%B9%BD%E9%AD%82%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S7D",
        "name": "摩天巔峰",
        "url": "https://wiki.52poke.com/wiki/%E6%91%A9%E5%A4%A9%E5%B7%85%E5%B3%B0%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S7R",
        "name": "蒼空烈流",
        "url": "https://wiki.52poke.com/wiki/%E8%92%BC%E7%A9%BA%E7%83%88%E6%B5%81%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S8",
        "name": "匯流藝術",
        "url": "https://wiki.52poke.com/wiki/%E5%8C%AF%E6%B5%81%E8%97%9D%E8%A1%93%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S9",
        "name": "星星誕生",
        "url": "https://wiki.52poke.com/wiki/%E6%98%9F%E6%98%9F%E8%AA%95%E7%94%9F%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S10D",
        "name": "時間觀察者",
        "url": "https://wiki.52poke.com/wiki/%E6%97%B6%E9%97%B4%E8%A7%82%E5%AF%9F%E8%80%85%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S10P",
        "name": "空間魔術師",
        "url": "https://wiki.52poke.com/wiki/%E7%A9%BA%E9%97%B4%E9%AD%94%E6%9C%AF%E5%B8%88%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S10a",
        "name": "黑暗亡靈",
        "url": "https://wiki.52poke.com/wiki/%E9%BB%91%E6%9A%97%E4%BA%A1%E7%81%B5%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S11",
        "name": "迷途深淵",
        "url": "https://wiki.52poke.com/wiki/%E8%BF%B7%E9%80%94%E6%B7%B1%E6%B8%8A%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S12",
        "name": "思維激盪",
        "url": "https://wiki.52poke.com/wiki/%E6%80%9D%E7%BB%B4%E6%BF%80%E8%8D%A1%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S5a",
        "name": "雙璧戰士",
        "url": "https://wiki.52poke.com/wiki/%E9%9B%99%E7%92%A7%E6%88%B0%E5%A3%AB%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S6a",
        "name": "伊布英雄",
        "url": "https://wiki.52poke.com/wiki/%E4%BC%8A%E5%B8%83%E8%8B%B1%E9%9B%84%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S9a",
        "name": "對戰地區",
        "url": "https://wiki.52poke.com/wiki/%E5%AF%B9%E6%88%98%E5%9C%B0%E5%8C%BA%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S10b",
        "name": "強化擴充包 Pokémon GO",
        "url": "https://wiki.52poke.com/wiki/%E5%BC%BA%E5%8C%96%E6%89%A9%E5%85%85%E5%8C%85_Pok%C3%A9mon_GO%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S11a",
        "name": "白熱奧祕",
        "url": "https://wiki.52poke.com/wiki/%E7%99%BD%E7%83%AD%E5%A5%A5%E7%A7%98%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S4a",
        "name": "閃色明星V",
        "url": "https://wiki.52poke.com/wiki/%E9%96%83%E8%89%B2%E6%98%8E%E6%98%9FV%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S8b",
        "name": "VMAX絕群壓軸",
        "url": "https://wiki.52poke.com/wiki/VMAX%E7%B5%95%E7%BE%A4%E5%A3%93%E8%BB%B8%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S12a",
        "name": "天地萬物VSTAR",
        "url": "https://wiki.52poke.com/wiki/%E5%A4%A9%E5%9C%B0%E4%B8%87%E7%89%A9VSTAR%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S-P",
        "name": "S-P繁體中文版特典卡",
        "url": "https://wiki.52poke.com/wiki/S-P%E7%B9%81%E4%BD%93%E4%B8%AD%E6%96%87%E7%89%88%E7%89%B9%E5%85%B8%E5%8D%A1%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV1S",
        "name": "朱ex",
        "url": "https://wiki.52poke.com/wiki/%E6%9C%B1ex%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV1V",
        "name": "紫ex",
        "url": "https://wiki.52poke.com/wiki/%E7%B4%ABex%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV2P",
        "name": "冰雪險境",
        "url": "https://wiki.52poke.com/wiki/%E5%86%B0%E9%9B%AA%E9%99%A9%E5%A2%83%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV2D",
        "name": "碟旋暴擊",
        "url": "https://wiki.52poke.com/wiki/%E7%A2%9F%E6%97%8B%E6%9A%B4%E5%87%BB%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV3",
        "name": "黯焰支配者",
        "url": "https://wiki.52poke.com/wiki/%E9%BB%AF%E7%84%B0%E6%94%AF%E9%85%8D%E8%80%85%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV4K",
        "name": "古代咆哮",
        "url": "https://wiki.52poke.com/wiki/%E5%8F%A4%E4%BB%A3%E5%92%86%E5%93%AE%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV4M",
        "name": "未來閃光",
        "url": "https://wiki.52poke.com/wiki/%E6%9C%AA%E6%9D%A5%E9%97%AA%E5%85%89%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV5K",
        "name": "狂野之力",
        "url": "https://wiki.52poke.com/wiki/%E7%8B%82%E9%87%8E%E4%B9%8B%E5%8A%9B%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV5M",
        "name": "異度審判",
        "url": "https://wiki.52poke.com/wiki/%E7%95%B0%E5%BA%A6%E5%AF%A9%E5%88%A4%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV6",
        "name": "變幻假面",
        "url": "https://wiki.52poke.com/wiki/%E5%8F%98%E5%B9%BB%E5%81%87%E9%9D%A2%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV7",
        "name": "星晶奇跡",
        "url": "https://wiki.52poke.com/wiki/%E6%98%9F%E6%99%B6%E5%A5%87%E8%BF%B9%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV8",
        "name": "超電突圍",
        "url": "https://wiki.52poke.com/wiki/%E8%B6%85%E9%9B%BB%E7%AA%81%E5%9C%8D%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV9",
        "name": "對戰搭檔",
        "url": "https://wiki.52poke.com/wiki/%E5%B0%8D%E6%88%B0%E6%90%AD%E6%AA%94%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV10",
        "name": "火箭隊的榮耀",
        "url": "https://wiki.52poke.com/wiki/%E7%81%AB%E7%AE%AD%E9%9A%8A%E7%9A%84%E6%A6%AE%E8%80%80%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV11W",
        "name": "純白閃焰",
        "url": "https://wiki.52poke.com/wiki/%E7%B4%94%E7%99%BD%E9%96%83%E7%84%B0%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV11B",
        "name": "漆黑伏特",
        "url": "https://wiki.52poke.com/wiki/%E6%BC%86%E9%BB%91%E4%BC%8F%E7%89%B9%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV1a",
        "name": "三連音爆",
        "url": "https://wiki.52poke.com/wiki/%E4%B8%89%E8%BF%9E%E9%9F%B3%E7%88%86%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV2a",
        "name": "寶可夢卡牌151",
        "url": "https://wiki.52poke.com/wiki/%E5%AE%9D%E5%8F%AF%E6%A2%A6%E5%8D%A1%E7%89%8C151%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV3a",
        "name": "激狂駭浪",
        "url": "https://wiki.52poke.com/wiki/%E6%BF%80%E7%8B%82%E9%A7%AD%E6%B5%AA%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV4a",
        "name": "閃色寶藏ex",
        "url": "https://wiki.52poke.com/wiki/%E9%97%AA%E8%89%B2%E5%AE%9D%E8%97%8Fex%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV5a",
        "name": "緋紅薄霧",
        "url": "https://wiki.52poke.com/wiki/%E7%BB%AF%E7%BA%A2%E8%96%84%E9%9B%BE%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV6a",
        "name": "黑夜漫遊者",
        "url": "https://wiki.52poke.com/wiki/%E9%BB%91%E5%A4%9C%E6%BC%AB%E6%B8%B8%E8%80%85%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV7a",
        "name": "樂園騰龍",
        "url": "https://wiki.52poke.com/wiki/%E4%B9%90%E5%9B%AD%E8%85%BE%E9%BE%99%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV8a",
        "name": "太晶慶典ex",
        "url": "https://wiki.52poke.com/wiki/%E5%A4%AA%E6%99%B6%E6%85%B6%E5%85%B8ex%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV9a",
        "name": "熱風競技場",
        "url": "https://wiki.52poke.com/wiki/%E7%86%B1%E9%A2%A8%E7%AB%B6%E6%8A%80%E5%A0%B4%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SV-P",
        "name": "SV-P繁體中文版特典卡",
        "url": "https://wiki.52poke.com/wiki/SV-P%E7%B9%81%E4%BD%93%E4%B8%AD%E6%96%87%E7%89%88%E7%89%B9%E5%85%B8%E5%8D%A1%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "M1L",
        "name": "超級勇氣",
        "url": "https://wiki.52poke.com/wiki/%E8%B6%85%E7%B4%9A%E5%8B%87%E6%B0%A3%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "M1S",
        "name": "超級交響樂",
        "url": "https://wiki.52poke.com/wiki/%E8%B6%85%E7%B4%9A%E4%BA%A4%E9%9F%BF%E6%A8%82%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "M2",
        "name": "烈獄狂火X",
        "url": "https://wiki.52poke.com/wiki/%E7%83%88%E7%8D%84%E7%8B%82%E7%81%ABX%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "M-P",
        "name": "M-P繁體中文版特典卡",
        "url": "https://wiki.52poke.com/wiki/M-P%E7%B9%81%E4%BD%93%E4%B8%AD%E6%96%87%E7%89%88%E7%89%B9%E5%85%B8%E5%8D%A1%EF%BC%88TCG%EF%BC%89"
    },
]

PROMO_CODES = [
    "S-P",
    "SV-P",
    "M-P"
]

database = {}

def clean_text(text):
    return text.strip().replace('\n', '')

def run_scraper():
    print("🚀 開始爬取繁體中文卡表...")
    start_time = time.time()

    headers = {'User-Agent': 'Mozilla/5.0'}

    tcgdex = TCGdex("zh-tw")

    for target in TARGET_URLS:
        print(f"正在處理: {target['name']} ({target['code']})...")
        
        try:
            resp = requests.get(target['url'], headers=headers)
            soup = BeautifulSoup(resp.text, 'html.parser')
            
            # 初始化該系列的資料結構
            database[target['code']] = {
                "name": target['name'],
                "cards": {}
            }
            
            # 52Poke 的卡表通常在 table.roundy 裡面
            # 我們尋找包含卡片列表的表格
            tables = soup.find_all('table', class_='roundy')
            
            card_count = 0
            
            for table in tables:
                rows = table.find_all('tr')
                for row in rows:
                    cols = row.find_all('td')
                    if len(cols) < 3: continue
                    
                    # 嘗試解析欄位 (編號、名稱、稀有度)
                    # 結構通常是: [編號] [圖片] [名稱] [稀有度]
                    try:
                        # 提取編號 (第1欄)
                        num_text = clean_text(cols[0].text)
                        
                        # 如果編號不是數字開頭，跳過 (例如標題列)
                        if not num_text or not num_text[0].isdigit():
                            continue

                        # 處理編號格式
                        # 編號格式不改動
                        card_num = num_text

                        # 提取名稱 (第2欄)
                        # 有時候結構會變，這裡做一個簡單的容錯
                        name_text = "未知"
                        if len(cols) >= 3:
                            name_text = clean_text(cols[1].text)

                        # 提取稀有度 (第3欄)
                        rarity_text = ""
                        if len(cols) >= 4:
                            rarity_text = clean_text(cols[2].text)

                        # 如果編號格式為 "001/S-P"、"001/SV-P"、"001/M-P"，則將稀有度設置為PROMO
                        if any(code in num_text for code in PROMO_CODES):
                            rarity_text = "PROMO"

                        # 組合完整卡號，編號移除/後的部分
                        card_num_for_search = card_num.split('/')[0]
                        full_card_num = f"{target['code']}-{card_num_for_search}"
                        # 取得卡片圖片URL
                        print(f"    處理卡片: {full_card_num} - {name_text}")
                        image_url = ""
                        try:
                            card = tcgdex.card.getSync(full_card_num)
                            image_url = f"{card.image}/high.png"
                        except Exception as e:
                            print(f"      ❌ 在 TCGdex SDK 中找不到卡片 {full_card_num}")
                            # image_url 保持空字串

                        # 存入資料庫
                        database[target['code']]['cards'][card_num] = {
                            "name": name_text,
                            "rarity": rarity_text,
                            "image": image_url
                        }
                        card_count += 1
                    except Exception as e:
                        continue

            print(f"  ✅ 成功抓取 {card_count} 張卡片")

        except Exception as e:
            print(f"  ❌ 錯誤: {e}")

    # 輸出 JSON
    with open('data.json', 'w', encoding='utf-8') as f:
        json.dump(database, f, ensure_ascii=False, indent=2)
    print("\n🎉 資料庫建立完成！請將 data.json 複製到 Flutter 專案的 assets 資料夾。")
    elapsed_time = time.time() - start_time
    print(f"⏱️ 爬取完成，總共花費 {elapsed_time:.2f} 秒。")

if __name__ == "__main__":
    run_scraper()

    # 執行 convert.py
    import subprocess
    print("\n🚦 開始簡體轉繁體...")
    subprocess.run(["python", "convert.py"], check=True)

    print("\n🚦 開始轉換台灣翻譯...")
    subprocess.run(["python", "fix_translation.py"], check=True)
    print("\n✅ 全部完成！")