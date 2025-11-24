import json
from opencc import OpenCC

cc = OpenCC('s2t')  # 簡體轉繁體

with open('data.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

def convert_dict(d):
    if isinstance(d, dict):
        return {k: convert_dict(v) for k, v in d.items()}
    elif isinstance(d, list):
        return [convert_dict(i) for i in d]
    elif isinstance(d, str):
        return cc.convert(d)
    else:
        return d

data_traditional = convert_dict(data)

with open('data.json', 'w', encoding='utf-8') as f:
    json.dump(data_traditional, f, ensure_ascii=False, indent=2)

print("轉換完成，請查看 data.json")