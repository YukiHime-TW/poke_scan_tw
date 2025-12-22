import requests
from bs4 import BeautifulSoup
import json
import time
import os
import re
import subprocess
from tcgdexsdk import TCGdex

# ==========================================
# 1. 設定區
# ==========================================
SETS_DIR = '../assets/sets'     # 存放分開 JSON 的資料夾
INDEX_FILE = '../assets/index.json' # 索引檔案路徑

TARGET_URLS = [
    {
        "code": "SM-P",
        "name": "SM-P 太陽&月亮 特典卡",
        "url": "https://wiki.52poke.com/wiki/SM-P%E7%B9%81%E4%BD%93%E4%B8%AD%E6%96%87%E7%89%88%E7%89%B9%E5%85%B8%E5%8D%A1%EF%BC%88TCG%EF%BC%89"
    },
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
        "code": "AC1D",
        "name": "G超起始牌組 眾星雲集組合篇",
        "url": "https://wiki.52poke.com/wiki/G%E8%B6%85%E8%B5%B7%E5%A7%8B%E7%89%8C%E7%B5%84_%E7%9C%BE%E6%98%9F%E9%9B%B2%E9%9B%86%E7%B5%84%E5%90%88%E7%AF%87%EF%BC%88TCG%EF%BC%89"
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
        "code": "AC2D",
        "name": "G超起始牌組 美夢成真組合篇",
        "url": "https://wiki.52poke.com/wiki/G%E8%B6%85%E8%B5%B7%E5%A7%8B%E7%89%8C%E7%B5%84_%E7%BE%8E%E5%A4%A2%E6%88%90%E7%9C%9F%E7%B5%84%E5%90%88%E7%AF%87%EF%BC%88TCG%EF%BC%89"
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
        "code": "AS5D",
        "name": "G超起始牌組 雙倍爆擊",
        "url": "https://wiki.52poke.com/wiki/G%E8%B6%85%E8%B5%B7%E5%A7%8B%E7%89%8C%E7%B5%84_%E9%9B%99%E5%80%8D%E7%88%86%E6%93%8A%EF%BC%88TCG%EF%BC%89"
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
        "code": "AS6D",
        "name": "G超起始牌組 傳說交鋒",
        "url": "https://wiki.52poke.com/wiki/G%E8%B6%85%E8%B5%B7%E5%A7%8B%E7%89%8C%E7%B5%84_%E5%82%B3%E8%AA%AA%E4%BA%A4%E9%8B%92%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SC1a",
        "name": "劍&盾 SET A",
        "url": "https://wiki.52poke.com/wiki/%E5%89%91%26%E7%9B%BE_SET_A%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SC1b",
        "name": "劍&盾 SET B",
        "url": "https://wiki.52poke.com/wiki/%E5%89%91%26%E7%9B%BE_SET_B%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SC1D",
        "name": "V起始牌組 劍&盾",
        "url": "https://wiki.52poke.com/wiki/V%E8%B5%B7%E5%A7%8B%E7%89%8C%E7%BB%84_%E5%89%91%26%E7%9B%BE%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SC2a",
        "name": "無極力量 SET A",
        "url": "https://wiki.52poke.com/wiki/%E6%97%A0%E6%9E%81%E5%8A%9B%E9%87%8F_SET_A%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SC2b",
        "name": "無極力量 SET B",
        "url": "https://wiki.52poke.com/wiki/%E6%97%A0%E6%9E%81%E5%8A%9B%E9%87%8F_SET_B%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SC2D",
        "name": "V起始牌組 無極力量",
        "url": "https://wiki.52poke.com/wiki/V%E8%B5%B7%E5%A7%8B%E7%89%8C%E7%BB%84_%E6%97%A0%E6%9E%81%E5%8A%9B%E9%87%8F%EF%BC%88TCG%EF%BC%89"
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
        "code": "SCA",
        "name": "V起始牌組 搭檔",
        "url": "https://wiki.52poke.com/wiki/V%E8%B5%B7%E5%A7%8B%E7%89%8C%E7%BB%84_%E6%90%AD%E6%A1%A3%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SCB",
        "name": "V起始牌組 挑戰",
        "url": "https://wiki.52poke.com/wiki/V%E8%B5%B7%E5%A7%8B%E7%89%8C%E7%BB%84_%E6%8C%91%E6%88%98%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SCC",
        "name": "V起始牌組 進化",
        "url": "https://wiki.52poke.com/wiki/V%E8%B5%B7%E5%A7%8B%E7%89%8C%E7%BB%84_%E8%BF%9B%E5%8C%96%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SCD",
        "name": "V起始牌組 強大",
        "url": "https://wiki.52poke.com/wiki/V%E8%B5%B7%E5%A7%8B%E7%89%8C%E7%BB%84_%E5%BC%BA%E5%A4%A7%EF%BC%88TCG%EF%BC%89"
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
        "code": "S8a",
        "name": "25週年收藏版",
        "url": "https://wiki.52poke.com/wiki/25%E5%91%A8%E5%B9%B4%E6%94%B6%E8%97%8F%E7%89%88%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S9a",
        "name": "對戰地區",
        "url": "https://wiki.52poke.com/wiki/%E5%AF%B9%E6%88%98%E5%9C%B0%E5%8C%BA%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SLD",
        "name": "起始組合VSTAR 達克萊伊",
        "url": "https://wiki.52poke.com/wiki/%E8%B5%B7%E5%A7%8B%E7%BB%84%E5%90%88VSTAR_%E8%BE%BE%E5%85%8B%E8%8E%B1%E4%BC%8A%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SLL",
        "name": "起始組合VSTAR 路卡利歐",
        "url": "https://wiki.52poke.com/wiki/%E8%B5%B7%E5%A7%8B%E7%BB%84%E5%90%88VSTAR_%E8%B7%AF%E5%8D%A1%E5%88%A9%E6%AC%A7%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S10b",
        "name": "Pokémon GO",
        "url": "https://wiki.52poke.com/wiki/%E5%BC%BA%E5%8C%96%E6%89%A9%E5%85%85%E5%8C%85_Pok%C3%A9mon_GO%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SPZ",
        "name": "VSTAR&VMAX高級牌組 捷拉奧拉",
        "url": "https://wiki.52poke.com/wiki/VSTAR%26VMAX%E9%AB%98%E7%BA%A7%E7%89%8C%E7%BB%84_%E6%8D%B7%E6%8B%89%E5%A5%A5%E6%8B%89%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SPD",
        "name": "VSTAR&VMAX高級牌組 代歐奇希斯",
        "url": "https://wiki.52poke.com/wiki/VSTAR%26VMAX%E9%AB%98%E7%BA%A7%E7%89%8C%E7%BB%84_%E4%BB%A3%E6%AC%A7%E5%A5%87%E5%B8%8C%E6%96%AF%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S11a",
        "name": "白熱奧祕",
        "url": "https://wiki.52poke.com/wiki/%E7%99%BD%E7%83%AD%E5%A5%A5%E7%A7%98%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SDL",
        "name": "V初階牌組 噴火龍",
        "url": "https://wiki.52poke.com/wiki/V%E5%88%9D%E9%98%B6%E7%89%8C%E7%BB%84_%E5%96%B7%E7%81%AB%E9%BE%99%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SDP",
        "name": "V初階牌組 皮卡丘",
        "url": "https://wiki.52poke.com/wiki/V%E5%88%9D%E9%98%B6%E7%89%8C%E7%BB%84_%E7%9A%AE%E5%8D%A1%E4%B8%98%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SDM",
        "name": "V初階牌組 超夢",
        "url": "https://wiki.52poke.com/wiki/V%E5%88%9D%E9%98%B6%E7%89%8C%E7%BB%84_%E8%B6%85%E6%A2%A6%EF%BC%88TCG%EF%BC%89"
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
        "code": "SK",
        "name": "頂級訓練家收藏箱 VSTAR",
        "url": "https://wiki.52poke.com/wiki/%E9%A0%82%E7%B4%9A%E8%A8%93%E7%B7%B4%E5%AE%B6%E6%94%B6%E8%97%8F%E7%AE%B1_VSTAR%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "S-P",
        "name": "S-P 劍&盾 特典卡",
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
        "name": "SV-P 朱&紫 特典卡",
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
        "code": "M2a",
        "name": "超級進化夢想ex",
        "url": "https://wiki.52poke.com/wiki/%E8%B6%85%E7%B4%9A%E9%80%B2%E5%8C%96%E5%A4%A2%E6%83%B3ex%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "M-P",
        "name": "M-P 超級進化 特典卡",
        "url": "https://wiki.52poke.com/wiki/M-P%E7%B9%81%E4%BD%93%E4%B8%AD%E6%96%87%E7%89%88%E7%89%B9%E5%85%B8%E5%8D%A1%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SJ",
        "name": "特別牌組組合 蒼響・藏瑪然特VS無極汰那",
        "url": "https://wiki.52poke.com/wiki/%E7%89%B9%E5%88%A5%E7%89%8C%E7%B5%84%E7%B5%84%E5%90%88_%E8%92%BC%E9%9F%BF%E3%83%BB%E8%97%8F%E7%91%AA%E7%84%B6%E7%89%B9VS%E7%84%A1%E6%A5%B5%E6%B1%B0%E9%82%A3%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SI",
        "name": "初階牌組100",
        "url": "https://wiki.52poke.com/wiki/%E5%88%9D%E9%98%B6%E7%89%8C%E7%BB%84100%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SN",
        "name": "初階牌組100特別版",
        "url": "https://wiki.52poke.com/wiki/%E5%88%9D%E9%98%B6%E7%89%8C%E7%BB%84100%E7%89%B9%E5%88%AB%E7%89%88%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "MBG",
        "name": "挑戰牌組 超級耿鬼ex",
        "url": "https://wiki.52poke.com/wiki/%E6%8C%91%E6%88%B0%E7%89%8C%E7%B5%84_%E8%B6%85%E7%B4%9A%E8%80%BF%E9%AC%BCex%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "MBD",
        "name": "挑戰牌組 超級蒂安希ex",
        "url": "https://wiki.52poke.com/wiki/%E6%8C%91%E6%88%B0%E7%89%8C%E7%B5%84_%E8%B6%85%E7%B4%9A%E8%92%82%E5%AE%89%E5%B8%8Cex%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SVAW",
        "name": "起始組合ex 潤水鴨&謎擬Ｑex",
        "url": "https://wiki.52poke.com/wiki/%E8%B5%B7%E5%A7%8B%E7%BB%84%E5%90%88ex_%E6%B6%A6%E6%B0%B4%E9%B8%AD%26%E8%B0%9C%E6%8B%9F%EF%BC%B1ex%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SVAL",
        "name": "起始組合ex 呆火鱷&電龍ex",
        "url": "https://wiki.52poke.com/wiki/%E8%B5%B7%E5%A7%8B%E7%BB%84%E5%90%88ex_%E5%91%86%E7%81%AB%E9%B3%84%26%E7%94%B5%E9%BE%99ex%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SVAM",
        "name": "起始組合ex 新葉喵&路卡利歐ex",
        "url": "https://wiki.52poke.com/wiki/%E8%B5%B7%E5%A7%8B%E7%BB%84%E5%90%88ex_%E6%96%B0%E5%8F%B6%E5%96%B5%26%E8%B7%AF%E5%8D%A1%E5%88%A9%E6%AC%A7ex%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SVB",
        "name": "頂級訓練家收藏箱ex",
        "url": "https://wiki.52poke.com/wiki/%E9%A1%B6%E7%BA%A7%E8%AE%AD%E7%BB%83%E5%AE%B6%E6%94%B6%E8%97%8F%E7%AE%B1ex%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SVC",
        "name": "起始組合ex 皮卡丘ex&巴布土撥",
        "url": "https://wiki.52poke.com/wiki/%E8%B5%B7%E5%A7%8B%E7%BB%84%E5%90%88ex_%E7%9A%AE%E5%8D%A1%E4%B8%98ex%26%E5%B7%B4%E5%B8%83%E5%9C%9F%E6%8B%A8%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SVP1",
        "name": "ex特別組合",
        "url": "https://wiki.52poke.com/wiki/Ex%E7%89%B9%E5%88%AB%E7%BB%84%E5%90%88%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SVD",
        "name": "ex初階牌組",
        "url": "https://wiki.52poke.com/wiki/Ex%E5%88%9D%E9%98%B6%E7%89%8C%E7%BB%84%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SVF",
        "name": "牌組構築BOX 黯焰支配者",
        "url": "https://wiki.52poke.com/wiki/%E7%89%8C%E7%BB%84%E6%9E%84%E7%AD%91BOX_%E9%BB%AF%E7%84%B0%E6%94%AF%E9%85%8D%E8%80%85%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SVEM",
        "name": "起始組合 太晶 超夢ex",
        "url": "https://wiki.52poke.com/wiki/%E8%B5%B7%E5%A7%8B%E7%BB%84%E5%90%88_%E5%A4%AA%E6%99%B6_%E8%B6%85%E6%A2%A6ex%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SVEL",
        "name": "起始組合 太晶 骨紋巨聲鱷ex",
        "url": "https://wiki.52poke.com/wiki/%E8%B5%B7%E5%A7%8B%E7%BB%84%E5%90%88_%E5%A4%AA%E6%99%B6_%E9%AA%A8%E7%BA%B9%E5%B7%A8%E5%A3%B0%E9%B3%84ex%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SVHK",
        "name": "起始組合 古代故勒頓ex",
        "url": "https://wiki.52poke.com/wiki/%E8%B5%B7%E5%A7%8B%E7%BB%84%E5%90%88_%E5%8F%A4%E4%BB%A3%E6%95%85%E5%8B%92%E9%A1%BFex%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SVHM",
        "name": "起始組合 未來密勒頓ex",
        "url": "https://wiki.52poke.com/wiki/%E8%B5%B7%E5%A7%8B%E7%BB%84%E5%90%88_%E6%9C%AA%E6%9D%A5%E5%AF%86%E5%8B%92%E9%A1%BFex%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SVK",
        "name": "牌組構築BOX 樂園騰龍",
        "url": "https://wiki.52poke.com/wiki/%E7%89%8C%E7%BB%84%E6%9E%84%E7%AD%91BOX_%E4%B9%90%E5%9B%AD%E8%85%BE%E9%BE%99%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SVPN",
        "name": "ex特別組合 太晶屬性：星晶 仙子伊布ex",
        "url": "https://wiki.52poke.com/wiki/Ex%E7%89%B9%E5%88%A5%E7%B5%84%E5%90%88_%E5%A4%AA%E6%99%B6%E5%B1%AC%E6%80%A7%EF%BC%9A%E6%98%9F%E6%99%B6_%E4%BB%99%E5%AD%90%E4%BC%8A%E5%B8%83ex%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SVPS",
        "name": "ex特別組合 太晶屬性：星晶 蒼炎刃鬼ex",
        "url": "https://wiki.52poke.com/wiki/Ex%E7%89%B9%E5%88%A5%E7%B5%84%E5%90%88_%E5%A4%AA%E6%99%B6%E5%B1%AC%E6%80%A7%EF%BC%9A%E6%98%9F%E6%99%B6_%E8%92%BC%E7%82%8E%E5%88%83%E9%AC%BCex%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SVOM",
        "name": "挑戰牌組 瑪俐的莫魯貝可&長毛巨魔ex",
        "url": "https://wiki.52poke.com/wiki/%E6%8C%91%E6%88%98%E7%89%8C%E7%BB%84_%E7%8E%9B%E4%BF%90%E7%9A%84%E8%8E%AB%E9%B2%81%E8%B4%9D%E5%8F%AF%26%E9%95%BF%E6%AF%9B%E5%B7%A8%E9%AD%94ex%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SVOD",
        "name": "挑戰牌組 大吾的鐵啞鈴&巨金怪ex",
        "url": "https://wiki.52poke.com/wiki/%E6%8C%91%E6%88%98%E7%89%8C%E7%BB%84_%E5%A4%A7%E5%90%BE%E7%9A%84%E9%93%81%E5%93%91%E9%93%83%26%E5%B7%A8%E9%87%91%E6%80%AAex%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SO",
        "name": "特別牌組組合 噴火龍VSTAR vs 烈空坐VMAX",
        "url": "https://wiki.52poke.com/wiki/%E7%89%B9%E5%88%AB%E7%89%8C%E7%BB%84%E7%BB%84%E5%90%88_%E5%96%B7%E7%81%AB%E9%BE%99VSTAR_vs_%E7%83%88%E7%A9%BA%E5%9D%90VMAX%EF%BC%88TCG%EF%BC%89"
    },
    {
        "code": "SP6",
        "name": "VSTAR特別組合",
        "url": "https://wiki.52poke.com/wiki/VSTAR%E7%89%B9%E5%88%AB%E7%BB%84%E5%90%88%EF%BC%88TCG%EF%BC%89"
    },
]

PROMO_CODES = [
    "SM-P",
    "S-P",
    "SV-P",
    "M-P"
]

# 初始化 TCGdex
tcgdex = TCGdex("zh-tw")

def clean_text(text):
    if not text: return ""
    return text.strip().replace('\n', '')

def run_scraper():
    print("🚀 開始執行智慧爬蟲...")
    start_time = time.time()

    headers = {'User-Agent': 'Mozilla/5.0'}

    # 1. 確保資料夾存在
    if not os.path.exists(SETS_DIR):
        os.makedirs(SETS_DIR)

    # 2. 開始迴圈
    for target in TARGET_URLS:
        set_code = target['code']
        set_name = target['name']

        # 定義該系列的檔案路徑
        set_file_path = os.path.join(SETS_DIR, f"{set_code}.json")
        
        # ------------------------------------------------------
        # 👇 步驟 A: 讀取單一系列的舊資料
        # ------------------------------------------------------
        current_set_data = {}
        if os.path.exists(set_file_path):
            try:
                with open(set_file_path, 'r', encoding='utf-8') as f:
                    full_data = json.load(f)
                    if set_code in full_data:
                        current_set_data = full_data[set_code]
            except:
                pass 

        # 初始化資料結構 (如果是新檔案)
        if not current_set_data:
            current_set_data = {
                "name": set_name,
                "releaseDate": "2000-01-01", # 預設日期，之後可用 add_date.py 更新
                "cards": {}
            }

        # ------------------------------------------------------
        # 👇 步驟 B: 爬取網頁 (這裡不跳過，必須爬才能比對新卡)
        # ------------------------------------------------------
        print(f"🕷️ 掃描系列: {set_name} ({set_code})...")
        try:
            resp = requests.get(target['url'], headers=headers, timeout=15)
            soup = BeautifulSoup(resp.text, 'html.parser')
            tables = soup.find_all('table', class_='roundy')
            processed_count = 0 # 新增或補圖的數量
            skipped_count = 0   # 已存在的數量
            
            for table in tables:
                rows = table.find_all('tr')
                for row in rows:
                    cols = row.find_all('td')
                    if len(cols) < 3: continue

                    try:
                        # 提取編號
                        num_text = clean_text(cols[0].text)
                        if not num_text or not num_text[0].isdigit():
                            continue

                        card_num = num_text # e.g. 001/158

                        # ==================================================
                        # 👇 【核心修改】: 判斷是否為新卡或缺圖卡
                        # ==================================================
                        
                        existing_card = current_set_data['cards'].get(card_num)
                        
                        # 情況 1: 卡片已存在 且 有圖片 -> 完美，跳過
                        if existing_card and existing_card.get('image') and len(existing_card['image']) > 0:
                            skipped_count += 1
                            continue
                        
                        # 情況 2: 卡片不存在 (新卡!) 或 存在但沒圖 -> 往下執行
                        if not existing_card:
                            print(f"   ✨ 發現新卡片: {card_num}")
                        elif not existing_card.get('image'):
                            print(f"   🔄 補圖中: {card_num}")
                            pass

                        # ==================================================
                        # 👇 資料解析與補圖邏輯
                        # ==================================================

                        # 提取名稱 (順便更新文字，以防是新卡)
                        name_text = "未知"
                        if len(cols) >= 3:
                            name_text = clean_text(cols[1].text)

                        # 特例處理: name_text 為 "25周年收藏版" 的資料是錯誤的，跳過不存
                        if name_text == "25周年收藏版":
                            continue

                        # 提取稀有度
                        rarity_text = ""
                        if len(cols) >= 4:
                            rarity_text = clean_text(cols[2].text)

                        # 如果編號格式為 "001/S-P"、"001/SV-P"、"001/M-P"，則將稀有度設置為PROMO
                        if any(code in num_text for code in PROMO_CODES):
                            rarity_text = "PROMO"

                        # --------------------------------------------------
                        # 圖片獲取 (呼叫 TCGdex SDK)
                        # --------------------------------------------------
                        image_url = ""

                        # 1. 嘗試保留舊圖片
                        if existing_card and existing_card.get('image'):
                            image_url = existing_card.get('image')

                        # 2. 嘗試 TCGdex SDK
                        if not image_url:
                            try:
                                card_num_for_search = card_num.split('/')[0] # 取斜線前部分 (例如 005)
                                full_card_num = f"{set_code}-{card_num_for_search}"

                                # TCGdex 查詢
                                card = tcgdex.card.getSync(full_card_num)
                                if card and card.image:
                                    image_url = f"{card.image}/high.webp"
                            except:
                                print(f"   ⚠️ TCGdex 查詢失敗: {full_card_num}")
                                pass

                        # 3. 嘗試從官網推算 (Fallback)
                        if not image_url:
                            try:
                                # 檢查是否為高版本卡 (SR/SAR 等)，如果是通常不適用順序推算，跳過
                                is_high_rarity = False
                                if '/' in card_num:
                                    parts = card_num.split('/')
                                    if len(parts) == 2 and parts[0].isdigit() and parts[1].isdigit():
                                        if int(parts[0]) > int(parts[1]):
                                            is_high_rarity = True

                                if not is_high_rarity:
                                    # 尋找該系列的 001 號卡片 (需要模糊搜尋，因為 Key 可能是 "001/165")
                                    base_card = None
                                    cards_in_set = current_set_data[set_code]['cards']
                                    
                                    # 遍歷尋找 001 開頭的卡
                                    for k, v in cards_in_set.items():
                                        if k.startswith("001/") or k == "001":
                                            base_card = v
                                            break

                                    # 如果找到了 001 且它有官網圖片連結
                                    if base_card and base_card.get('image') and "asia.pokemon-card.com" in base_card['image']:
                                        base_image_url = base_card['image']
                                        
                                        # 解析檔名數字 (例如 tw00004637.png -> 00004637)
                                        match = re.search(r'tw(\d+)\.png', base_image_url)
                                        if match:
                                            base_number_str = match.group(1) # "00004637"
                                            base_number_int = int(base_number_str)

                                            # 計算目標卡片的檔名數字
                                            # 公式: 001的檔名數字 + (當前卡號 - 1)
                                            target_offset = int(card_num_for_search) - 1
                                            new_number_int = base_number_int + target_offset

                                            # 轉回字串並補零 (保持跟原本一樣的位數，通常是8位)
                                            new_number_str = str(new_number_int).zfill(len(base_number_str))

                                            # 替換網址
                                            image_url = base_image_url.replace(f"tw{base_number_str}.png", f"tw{new_number_str}.png")
                                            print(f"   📸 官網補圖成功: {full_card_num}")
                                    else:
                                        print(f"   ⚠️ 官網補圖失敗: 找不到系列 {set_code} 的 001 號卡片作為基準，無法推算 {full_card_num} 的圖片")
                                else:
                                    print(f"   ⚠️ 官網補圖跳過: {full_card_num} 為高版本卡，跳過官網補圖邏輯")
                            except Exception as logic_error:
                                print(f"   ⚠️ 官網補圖邏輯錯誤: {logic_error}")
                                pass
                        # --------------------------------------------------

                        # 4. 更新/寫入資料
                        # 這裡使用 update 確保如果原本有其他欄位(如 note)不會被洗掉
                        if card_num not in current_set_data['cards']:
                            current_set_data['cards'][card_num] = {}

                        current_set_data['cards'][card_num]['name'] = name_text
                        current_set_data['cards'][card_num]['rarity'] = rarity_text
                        
                        # 只有當真的抓到新圖時才更新 image，避免把原本手動填的蓋成空字串
                        if image_url:
                            current_set_data['cards'][card_num]['image'] = image_url
                        elif 'image' not in current_set_data['cards'][card_num]:
                            current_set_data['cards'][card_num]['image'] = ""

                        processed_count += 1
                    except Exception:
                        continue
            
            print(f"   💾 {set_code} 處理完畢。跳過(已有圖): {skipped_count} 張, 處理(補圖/新增): {processed_count} 張")
            
            # --- 步驟 C: 儲存單一檔案 ---
            output_data = {set_code: current_set_data}
            with open(set_file_path, 'w', encoding='utf-8') as f:
                json.dump(output_data, f, ensure_ascii=False, indent=2)
            
            # 只有在真的有發送大量請求時才睡覺
            if processed_count > 5:
                time.sleep(1)
            else:
                time.sleep(0.1)

        except Exception as e:
            print(f"   ❌ {set_code} 失敗: {e}")

    # 3. 建立索引檔 (Index)
    print("📑 正在更新索引檔 index.json ...")
    actual_files = [f.replace('.json', '') for f in os.listdir(SETS_DIR) if f.endswith('.json')]
    actual_files.sort()

    with open(INDEX_FILE, 'w', encoding='utf-8') as f:
        json.dump(actual_files, f, ensure_ascii=False, indent=2)

    elapsed_time = time.time() - start_time
    print(f"\n🎉 全部完成！")
    print(f"⏱️ 總共花費 {elapsed_time:.2f} 秒。")

if __name__ == "__main__":
    run_scraper()

    print("\n🚦 開始簡體轉繁體...")
    subprocess.run(["python", "convert.py"], check=True)

    print("\n🚦 開始轉換台灣翻譯...")
    subprocess.run(["python", "fix_translation.py"], check=True)

    print("\n🚦 加入擴充包發售日期...")
    subprocess.run(["python", "add_date.py"], check=True)

    print("\n✅ 全部完成！")