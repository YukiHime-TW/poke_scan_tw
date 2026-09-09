"""本機機制標籤編輯器。

    python card_editor.py            # 開 http://localhost:8770/

卡片基本資料（名稱 / reg / 招式 / 特性 …）現在都由爬蟲抓官方站，這裡只做
**機制標籤**：

  - 左側選系列 → 卡片清單（編號・縮圖・名稱），可搜尋，← → / j k 切換
  - 右側顯示卡圖 + 效果 / 招式 / 特性內文（唯讀，只為判斷標籤用）
  - 機制標籤打勾 → 存成 card["tags"]；會依內文**預先建議**（紫框）
  - 「無標籤（已審）」標記 card["tagsReviewed"]，配合「下一張未標記」快速跑
  - 「管理標籤」可新增 / 刪除標籤（刪除會從所有卡片一併移除）
  - 存檔只改 tags / tagsReviewed，其他欄位原樣保留

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


def load_tags():
    if os.path.exists(TAGS_FILE):
        with open(TAGS_FILE, encoding="utf-8") as f:
            return json.load(f)
    save_tags(DEFAULT_TAGS)
    return list(DEFAULT_TAGS)


def save_tags(tags):
    with open(TAGS_FILE, "w", encoding="utf-8") as f:
        json.dump(tags, f, ensure_ascii=False, indent=2)


def set_files():
    return sorted(f for f in os.listdir(SETS_DIR) if f.endswith(".json"))


def load_set(code):
    with open(os.path.join(SETS_DIR, code + ".json"), encoding="utf-8") as f:
        return json.load(f)


def patch_card_tags(code, num, tags, reviewed):
    """只改 card 的 tags / tagsReviewed，其餘欄位原樣保留。"""
    path = os.path.join(SETS_DIR, code + ".json")
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    card = data[code]["cards"][num]
    if tags:
        card["tags"] = tags
        card.pop("tagsReviewed", None)
    else:
        card.pop("tags", None)
        if reviewed:
            card["tagsReviewed"] = True
        else:
            card.pop("tagsReviewed", None)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


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


def suggest_tags(card, known):
    blob = " ".join(filter(None, [
        card.get("effect", ""),
        " ".join(a.get("text", "") for a in card.get("attacks", []) or []),
        " ".join(a.get("text", "") for a in card.get("abilities", []) or []),
    ]))
    return [t for t, rx in TAG_RULES if t in known and re.search(rx, blob)]


PAGE = """<!doctype html><html lang="zh-Hant"><meta charset="utf-8">
<title>機制標籤編輯器</title>
<style>
*{box-sizing:border-box}body{margin:0;font:14px/1.6 system-ui,"Microsoft JhengHei";display:flex;height:100vh}
#left{width:320px;border-right:1px solid #ccc;display:flex;flex-direction:column}
#left header{padding:8px;border-bottom:1px solid #ddd}
#list{overflow:auto;flex:1}
.row{padding:5px 8px;display:flex;gap:8px;align-items:center;cursor:pointer;border-bottom:1px solid #f0f0f0}
.row:hover{background:#f5f5f5}.row.sel{background:#e5e0fb}
.row img{width:28px;height:39px;object-fit:cover;border-radius:2px;background:#eee}
.row .n{color:#888;font-variant-numeric:tabular-nums;min-width:56px}
.row.tagged .n::after{content:" ●";color:#4B3BA6}
.row.reviewed{color:#999}
.row.reviewed .n::after{content:" ○";color:#999}
#right{flex:1;overflow:auto;padding:16px;display:flex;gap:20px}
#main{flex:1;max-width:620px}
#pic img{width:240px;border-radius:8px;background:#eee}
.bar{position:sticky;top:0;background:#fff;padding-bottom:8px;display:flex;gap:8px;align-items:center;flex-wrap:wrap}
button{padding:6px 14px;font:inherit;border:1px solid #4B3BA6;background:#4B3BA6;color:#fff;border-radius:6px;cursor:pointer}
button.ghost{background:#fff;color:#4B3BA6}
small{color:#999}
h2{margin:6px 0 2px;font-size:18px}
.meta{color:#666;font-size:12px;margin-bottom:10px}
.txt{border:1px solid #eee;border-radius:6px;padding:8px 10px;margin:6px 0;white-space:pre-wrap;background:#fafafa}
.txt b{color:#4B3BA6}
.tags{display:flex;flex-wrap:wrap;gap:6px;margin-top:6px}
.tags label{display:flex;align-items:center;gap:4px;margin:0;padding:6px 12px;border:1px solid #bbb;border-radius:16px;cursor:pointer;font-size:15px}
.tags label.sug{border-color:#4B3BA6;background:#f0edfd}
.tags input{width:auto}
#tagmgr label{font-size:13px;padding:4px 8px}
.lbl{display:block;margin:14px 0 2px;color:#555;font-size:12px}
</style>
<div id="left"><header>
<select id="setSel"></select>
<input id="q" placeholder="搜尋編號 / 名稱" style="width:100%;padding:5px;margin-top:6px;border:1px solid #bbb;border-radius:4px">
</header><div id="list"></div></div>
<div id="right"><div id="main"><div class="bar">
<button class="ghost" id="noTags">無標籤（已審）→</button>
<button class="ghost" id="nextUntagged">下一張未標記 →</button>
<small id="status"></small></div>
<div id="card"></div>
<label class="lbl">機制標籤　<small>紫框 = 依內文建議；打勾即存</small></label>
<div class="tags" id="tagbox"></div>
<details style="margin-top:16px"><summary style="cursor:pointer;color:#555">管理標籤</summary>
<div class="tags" id="tagmgr" style="margin-top:6px"></div>
<div style="display:flex;gap:6px;margin-top:6px">
<input id="newtag" placeholder="新標籤名稱" style="flex:1;padding:5px;border:1px solid #bbb;border-radius:4px">
<button id="addtag">新增</button></div>
</details>
</div><div id="pic"><img id="pimg"></div></div>
<script>
let TAGS=[], SET=null, CODE=null, NUM=null;
const $=s=>document.querySelector(s);
async function j(u,o){const r=await fetch(u,o);if(!r.ok){alert("請求失敗 "+r.status);throw new Error(r.status);}return r.json()}

async function boot(){
  TAGS=await j("/api/tags");
  const sets=await j("/api/sets");
  $("#setSel").innerHTML=sets.map(s=>`<option value="${s.code}">${s.code}　${s.name}　(${s.count})</option>`).join("");
  $("#setSel").onchange=()=>openSet($("#setSel").value);
  $("#q").oninput=renderList;
  $("#addtag").onclick=addTag;
  $("#newtag").onkeydown=e=>{if(e.key==="Enter")addTag()};
  $("#nextUntagged").onclick=nextUntagged;
  $("#noTags").onclick=markNoTags;
  renderTagMgr();
  openSet(sets[0].code);
}
function esc(s){return (s||"").replace(/[&<>]/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;"}[c]))}
function renderTagMgr(){
  $("#tagmgr").innerHTML=TAGS.map(t=>
    `<label>${esc(t)} <span data-del="${esc(t)}" style="cursor:pointer;color:#a33">✕</span></label>`).join("");
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
  CODE=code; SET=await j("/api/set/"+code); NUM=null;
  renderList(); $("#card").innerHTML=""; $("#tagbox").innerHTML="";
}
function renderList(){
  const q=$("#q").value.trim().toLowerCase();
  const rows=Object.entries(SET).filter(([n,c])=>!q||n.toLowerCase().includes(q)||(c.name||"").toLowerCase().includes(q));
  $("#list").innerHTML=rows.map(([n,c])=>{
    const mark=c.tags?.length?'tagged':(c.tagsReviewed?'reviewed':'');
    return `<div class="row ${mark} ${n===NUM?'sel':''}" data-n="${n}">
      <span class="n">${esc(n.split('/')[0])}</span>
      <img src="${c.image||''}" loading="lazy">
      <span>${esc(c.name)}</span></div>`}).join("");
  $("#list").querySelectorAll(".row").forEach(r=>r.onclick=()=>pick(r.dataset.n));
}
function pick(n){
  NUM=n; const c=SET[n];
  const bits=[c.type,c.elem,c.hp?("HP "+c.hp):null,c.stage,c.rarity].filter(Boolean).join("　");
  let html=`<h2>${esc(c.name)}　<small>${esc(n)}　${esc(c.reg||"")}</small></h2><div class="meta">${esc(bits)}</div>`;
  for(const a of c.abilities||[]) html+=`<div class="txt"><b>[特性] ${esc(a.name)}</b>　${esc(a.text)}</div>`;
  for(const a of c.attacks||[]) html+=`<div class="txt"><b>${esc(a.name)}</b> ${esc((a.cost||[]).join(""))} ${esc(a.damage||"")}　${esc(a.text||"")}</div>`;
  if(c.effect) html+=`<div class="txt">${esc(c.effect)}</div>`;
  $("#card").innerHTML=html;
  const sug=new Set(c._suggest||[]), cur=new Set(c.tags||[]);
  $("#tagbox").innerHTML=TAGS.map(t=>
    `<label class="${sug.has(t)?'sug':''}"><input type="checkbox" value="${esc(t)}" ${cur.has(t)?'checked':''}>${esc(t)}</label>`).join("");
  $("#tagbox").querySelectorAll("input").forEach(i=>i.onchange=saveTags);
  $("#pimg").src=c.image||"";
  $("#status").textContent="";
  renderList();
}
async function saveTags(){
  if(!NUM)return;
  const tg=[...$("#tagbox").querySelectorAll("input:checked")].map(i=>i.value);
  await j("/api/save",{method:"POST",headers:{"Content-Type":"application/json"},
    body:JSON.stringify({set:CODE,num:NUM,tags:tg,reviewed:false})});
  const c=SET[NUM]; if(tg.length){c.tags=tg;delete c.tagsReviewed;}else delete c.tags;
  $("#status").textContent="已存 "+new Date().toLocaleTimeString();
  renderList();
}
async function markNoTags(){
  if(!NUM)return;
  await j("/api/save",{method:"POST",headers:{"Content-Type":"application/json"},
    body:JSON.stringify({set:CODE,num:NUM,tags:[],reviewed:true})});
  const c=SET[NUM]; delete c.tags; c.tagsReviewed=true;
  renderList(); nextUntagged();
}
function nextUntagged(){
  const ns=Object.keys(SET); let i=ns.indexOf(NUM);
  for(let k=1;k<=ns.length;k++){const n=ns[(i+k)%ns.length];const x=SET[n];
    if(!x.tags?.length && !x.tagsReviewed){pick(n);return}}
  alert("這個系列都審完了");
}
document.onkeydown=e=>{
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
        if self.path == "/api/save":  # 只改 tags / tagsReviewed
            patch_card_tags(body["set"], body["num"],
                            [t for t in body.get("tags", []) if t],
                            bool(body.get("reviewed")))
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
    print(f"機制標籤編輯器：http://localhost:{PORT}/  (Ctrl+C 結束)")
    ThreadingHTTPServer(("127.0.0.1", PORT), H).serve_forever()
