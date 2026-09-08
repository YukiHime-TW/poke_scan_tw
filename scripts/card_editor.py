"""本機卡片資料編輯器。

    python card_editor.py            # 開 http://localhost:8770/

功能：
  - 左側選系列 → 卡片清單（編號・縮圖・名稱），可搜尋，← → 或 j k 切換
  - 右側編輯所有欄位；abilities / attacks 用 JSON 區塊修正
  - 機制標籤（抽卡 / 過牌 / 換位 / 檢索 / 回收 / 治療 / 加速能量 / 妨礙）打勾
    → 存成 card["tags"]；會依 effect / 招式 / 特性文字**預先建議**打勾
  - 「下一張未標記」快速跑標籤
  - 存檔直接寫回 assets/sets/<code>.json（保留鍵順序、indent=2）

只在本機跑，沒有驗證 / 沒有並發保護；一次一個人用。
"""

import json
import os
import re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(__file__)
SETS_DIR = os.path.join(HERE, "..", "assets", "sets")
TAGS_FILE = os.path.join(HERE, "mechanic_tags.json")
PORT = 8770

DEFAULT_TAGS = ["抽卡", "過牌", "換位", "檢索", "回收", "治療", "加速能量", "妨礙"]


def load_tags():
    if os.path.exists(TAGS_FILE):
        with open(TAGS_FILE, encoding="utf-8") as f:
            return json.load(f)
    save_tags(DEFAULT_TAGS)
    return list(DEFAULT_TAGS)


def save_tags(tags):
    with open(TAGS_FILE, "w", encoding="utf-8") as f:
        json.dump(tags, f, ensure_ascii=False, indent=2)


def remove_tag_everywhere(tag):
    """把某個標籤從所有卡片移除，回傳受影響張數。"""
    n = 0
    for fn in set_files():
        code = fn[:-5]
        path = os.path.join(SETS_DIR, code + ".json")
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        mod = False
        for c in data.get(code, {}).get("cards", {}).values():
            if tag in (c.get("tags") or []):
                c["tags"] = [t for t in c["tags"] if t != tag]
                if not c["tags"]:
                    del c["tags"]
                mod = True
                n += 1
        if mod:
            with open(path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
    return n

# (tag, 觸發用的正規式) — 只用來「預先建議」，人工確認。
# 使用者自行新增的標籤沒有規則，純手動打勾。
TAG_RULES = [
    ("抽卡", r"抽(出)?.{0,4}\d+.{0,2}張卡|抽\d+張|抽出.{0,6}卡"),
    ("過牌", r"棄掉.{0,20}(再抽|抽\d)|洗回牌庫.{0,10}抽"),
    ("換位", r"交換.{0,6}(戰鬥)?寶可夢|回到手牌|放回(手牌|備戰)|退場|拉(出|到).{0,6}備戰"),
    ("檢索", r"檢查自己的牌庫|從自己的牌庫.{0,20}加入手牌|從自己的牌庫.{0,10}選擇.{0,10}加入手牌"),
    ("回收", r"從自己的棄牌堆.{0,20}(加入手牌|放回|回到)"),
    ("治療", r"恢復.{0,4}(「?\d+」?)?.{0,2}HP|回復.{0,4}HP|移除.{0,10}傷害指示物"),
    ("加速能量", r"從自己的(手牌|牌庫|棄牌堆).{0,20}能量卡.{0,10}附於|附加.{0,10}能量卡.{0,10}於"),
    ("妨礙", r"讓對手.{0,10}棄|對手.{0,6}無法|將對手.{0,10}手牌.{0,10}放回|對手.{0,10}回合.{0,10}不能"),
]


def set_files():
    return sorted(f for f in os.listdir(SETS_DIR) if f.endswith(".json"))


def load_set(code):
    with open(os.path.join(SETS_DIR, code + ".json"), encoding="utf-8") as f:
        return json.load(f)


def save_card(code, num, card):
    path = os.path.join(SETS_DIR, code + ".json")
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    data[code]["cards"][num] = card
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def suggest_tags(card, known):
    blob = " ".join(filter(None, [
        card.get("effect", ""),
        " ".join(a.get("text", "") for a in card.get("attacks", []) or []),
        " ".join(a.get("text", "") for a in card.get("abilities", []) or []),
    ]))
    return [t for t, rx in TAG_RULES if t in known and re.search(rx, blob)]


PAGE = """<!doctype html><html lang="zh-Hant"><meta charset="utf-8">
<title>卡片資料編輯器</title>
<style>
*{box-sizing:border-box}body{margin:0;font:14px/1.5 system-ui,"Microsoft JhengHei";display:flex;height:100vh}
#left{width:320px;border-right:1px solid #ccc;display:flex;flex-direction:column}
#left header{padding:8px;border-bottom:1px solid #ddd}
#list{overflow:auto;flex:1}
.row{padding:5px 8px;display:flex;gap:8px;align-items:center;cursor:pointer;border-bottom:1px solid #f0f0f0}
.row:hover{background:#f5f5f5}.row.sel{background:#e5e0fb}
.row img{width:28px;height:39px;object-fit:cover;border-radius:2px}
.row .n{color:#888;font-variant-numeric:tabular-nums;min-width:56px}
.row.tagged .n::after{content:" ●";color:#4B3BA6}
#right{flex:1;overflow:auto;padding:16px;display:flex;gap:20px}
#form{flex:1;max-width:560px}#pic img{width:240px;border-radius:8px}
label{display:block;margin:8px 0 2px;color:#555;font-size:12px}
input,textarea,select{width:100%;padding:5px;font:inherit;border:1px solid #bbb;border-radius:4px}
textarea{min-height:60px}
.tags{display:flex;flex-wrap:wrap;gap:6px;margin-top:6px}
.tags label{display:flex;align-items:center;gap:4px;margin:0;padding:4px 8px;border:1px solid #bbb;border-radius:14px;cursor:pointer}
.tags input{width:auto}
.tags label.sug{border-color:#4B3BA6;background:#f0edfd}
.bar{position:sticky;top:0;background:#fff;padding-bottom:8px;display:flex;gap:8px;align-items:center}
button{padding:6px 14px;font:inherit;border:1px solid #4B3BA6;background:#4B3BA6;color:#fff;border-radius:6px;cursor:pointer}
button.ghost{background:#fff;color:#4B3BA6}
small{color:#999}
</style>
<div id="left"><header>
<select id="setSel"></select>
<input id="q" placeholder="搜尋編號 / 名稱" style="margin-top:6px">
</header><div id="list"></div></div>
<div id="right"><div id="form"><div class="bar">
<button id="save">存檔 (Ctrl+S)</button>
<button class="ghost" id="nextUntagged">下一張未標記 →</button>
<small id="status"></small></div><div id="fields"></div>
<label>機制標籤　<small>紫框 = 依效果文字建議</small></label>
<div class="tags" id="tagbox"></div>
<details style="margin-top:10px"><summary style="cursor:pointer;color:#555">管理標籤</summary>
<div class="tags" id="tagmgr" style="margin-top:6px"></div>
<div style="display:flex;gap:6px;margin-top:6px">
<input id="newtag" placeholder="新標籤名稱" style="flex:1">
<button id="addtag">新增</button></div>
</details>
</div><div id="pic"><img id="pimg"></div></div>
<script>
let TAGS=[];
let SET=null, CODE=null, NUM=null, dirty=false;
const $=s=>document.querySelector(s);
const FIELDS=["name","rarity","type","reg","elem","hp","stage","evolvesFrom","dex","category","weakness","resistance","retreat","illustrator","image"];
async function j(u,o){const r=await fetch(u,o);return r.json()}

async function boot(){
  TAGS=await j("/api/tags");
  const sets=await j("/api/sets");
  $("#setSel").innerHTML=sets.map(s=>`<option value="${s.code}">${s.code}　${s.name}　(${s.count})</option>`).join("");
  $("#setSel").onchange=()=>openSet($("#setSel").value);
  $("#q").oninput=renderList;
  $("#addtag").onclick=addTag;
  $("#newtag").onkeydown=e=>{if(e.key==="Enter")addTag()};
  renderTagMgr();
  openSet(sets[0].code);
}
function renderTagMgr(){
  $("#tagmgr").innerHTML=TAGS.map(t=>
    `<label>${t} <span data-del="${t}" style="cursor:pointer;color:#a33">✕</span></label>`).join("");
  $("#tagmgr").querySelectorAll("[data-del]").forEach(x=>x.onclick=()=>delTag(x.dataset.del));
}
async function addTag(){
  const v=$("#newtag").value.trim(); if(!v||TAGS.includes(v))return;
  TAGS.push(v); $("#newtag").value="";
  await j("/api/tags",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({tags:TAGS})});
  renderTagMgr(); if(NUM)pick(NUM);
}
async function delTag(t){
  if(!confirm(`刪除標籤「${t}」？會從所有卡片一併移除。`))return;
  const r=await j("/api/tags/delete",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({tag:t})});
  TAGS=TAGS.filter(x=>x!==t);
  alert(`已刪除，影響 ${r.removed} 張卡。`);
  renderTagMgr(); openSet(CODE);
}
async function openSet(code){
  CODE=code; SET=await j("/api/set/"+code); NUM=null; renderList(); $("#fields").innerHTML="";
}
function renderList(){
  const q=$("#q").value.trim().toLowerCase();
  const rows=Object.entries(SET).filter(([n,c])=>!q||n.toLowerCase().includes(q)||(c.name||"").toLowerCase().includes(q));
  $("#list").innerHTML=rows.map(([n,c])=>
    `<div class="row ${c.tags?.length?'tagged':''} ${n===NUM?'sel':''}" data-n="${n}">
      <span class="n">${n.split('/')[0]}</span>
      <img src="${c.image||''}" loading="lazy">
      <span>${c.name||''}</span></div>`).join("");
  $("#list").querySelectorAll(".row").forEach(r=>r.onclick=()=>pick(r.dataset.n));
}
function pick(n){
  if(dirty && !confirm("尚未存檔，要放棄變更嗎？"))return;
  NUM=n; dirty=false; const c=SET[n];
  $("#fields").innerHTML=FIELDS.map(f=>{
    const v=c[f]??"";
    if(f==="stage")return field(f,`<select id="fx_${f}">${["","基礎","1階進化","2階進化"].map(o=>`<option ${o===v?'selected':''}>${o}</option>`).join("")}</select>`);
    return field(f,`<input id="fx_${f}" value="${String(v).replace(/"/g,'&quot;')}">`);
  }).join("")
   + field("effect",`<textarea id="fx_effect">${c.effect||""}</textarea>`)
   + field("abilities (JSON)",`<textarea id="fx_abilities">${JSON.stringify(c.abilities||[],null,1)}</textarea>`)
   + field("attacks (JSON)",`<textarea id="fx_attacks">${JSON.stringify(c.attacks||[],null,1)}</textarea>`);
  const sug=new Set(c._suggest||[]);
  const cur=new Set(c.tags||[]);
  $("#tagbox").innerHTML=TAGS.map(t=>
    `<label class="${sug.has(t)?'sug':''}"><input type="checkbox" value="${t}" ${cur.has(t)?'checked':''}>${t}</label>`).join("");
  $("#tagbox").querySelectorAll("input").forEach(i=>i.onchange=()=>dirty=true);
  $("#fields").querySelectorAll("input,textarea,select").forEach(e=>e.oninput=()=>dirty=true);
  $("#pimg").src=c.image||"";
  $("#status").textContent="";
  renderList();
}
function field(f,inner){return `<label>${f}</label>${inner}`}
async function save(){
  if(!NUM)return;
  const c={...SET[NUM]}; delete c._suggest;
  FIELDS.forEach(f=>{
    let v=$("#fx_"+f).value.trim();
    if(v==="")delete c[f];
    else if(["hp","retreat"].includes(f))c[f]=parseInt(v)||undefined;
    else c[f]=v;
  });
  const eff=$("#fx_effect").value.trim(); eff?c.effect=eff:delete c.effect;
  try{const a=JSON.parse($("#fx_abilities").value); a.length?c.abilities=a:delete c.abilities;
      const k=JSON.parse($("#fx_attacks").value); k.length?c.attacks=k:delete c.attacks;}
  catch(e){alert("abilities / attacks JSON 格式錯誤："+e.message);return;}
  const tg=[...$("#tagbox").querySelectorAll("input:checked")].map(i=>i.value);
  tg.length?c.tags=tg:delete c.tags;
  Object.keys(c).forEach(k=>c[k]===undefined&&delete c[k]);
  await j("/api/save",{method:"POST",headers:{"Content-Type":"application/json"},
    body:JSON.stringify({set:CODE,num:NUM,card:c})});
  SET[NUM]=c; dirty=false; $("#status").textContent="已存 "+new Date().toLocaleTimeString();
  renderList();
}
function nextUntagged(){
  const ns=Object.keys(SET); let i=ns.indexOf(NUM);
  for(let k=1;k<=ns.length;k++){const n=ns[(i+k)%ns.length];if(!SET[n].tags?.length){pick(n);return}}
  alert("這個系列都標完了");
}
$("#save").onclick=save; $("#nextUntagged").onclick=nextUntagged;
document.onkeydown=e=>{
  if((e.ctrlKey||e.metaKey)&&e.key==="s"){e.preventDefault();save();return}
  if(["INPUT","TEXTAREA","SELECT"].includes(e.target.tagName))return;
  const ns=Object.keys(SET); let i=ns.indexOf(NUM);
  if(e.key==="ArrowRight"||e.key==="j")pick(ns[Math.min(i+1,ns.length-1)]);
  if(e.key==="ArrowLeft"||e.key==="k")pick(ns[Math.max(i-1,0)]);
};
boot();
</script></html>"""


class H(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype="application/json"):
        b = body if isinstance(body, bytes) else body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype + "; charset=utf-8")
        self.send_header("Content-Length", str(len(b)))
        self.end_headers()
        self.wfile.write(b)

    def log_message(self, *a):
        pass

    def do_GET(self):
        if self.path == "/":
            return self._send(200, PAGE, "text/html")
        if self.path == "/api/tags":
            return self._send(200, json.dumps(load_tags(), ensure_ascii=False))
        if self.path == "/api/sets":
            out = []
            for fn in set_files():
                code = fn[:-5]
                d = load_set(code).get(code, {})
                out.append({"code": code, "name": d.get("name", ""),
                            "count": len(d.get("cards", {}))})
            return self._send(200, json.dumps(out))
        if self.path.startswith("/api/set/"):
            code = self.path.split("/api/set/", 1)[1]
            known = set(load_tags())
            cards = load_set(code).get(code, {}).get("cards", {})
            for c in cards.values():
                c["_suggest"] = suggest_tags(c, known)
            return self._send(200, json.dumps(cards, ensure_ascii=False))
        return self._send(404, "{}")

    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(n)) if n else {}
        if self.path == "/api/save":
            save_card(body["set"], body["num"], body["card"])
            return self._send(200, json.dumps({"ok": True}))
        if self.path == "/api/tags":  # 儲存整個標籤清單（新增 / 排序）
            save_tags([t.strip() for t in body["tags"] if t.strip()])
            return self._send(200, json.dumps({"ok": True}))
        if self.path == "/api/tags/delete":  # 刪一個標籤，並從所有卡片移除
            tag = body["tag"]
            hit = remove_tag_everywhere(tag)
            save_tags([t for t in load_tags() if t != tag])
            return self._send(200, json.dumps({"ok": True, "removed": hit}))
        return self._send(404, "{}")


if __name__ == "__main__":
    print(f"卡片資料編輯器：http://localhost:{PORT}/  (Ctrl+C 結束)")
    ThreadingHTTPServer(("127.0.0.1", PORT), H).serve_forever()
