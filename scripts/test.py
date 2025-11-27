from tcgdexsdk import TCGdex

tcgdex = TCGdex("zh-tw")
card = tcgdex.card.getSync("SV8a-001")

print(card)