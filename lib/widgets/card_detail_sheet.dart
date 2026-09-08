import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/collection_provider.dart';
import '../providers/deck_provider.dart';

const Map<String, Color> _energyColors = {
  "草": Color(0xFF4CAF50),
  "火": Color(0xFFF44336),
  "水": Color(0xFF2196F3),
  "雷": Color(0xFFFBC02D),
  "超": Color(0xFF9C27B0),
  "鬥": Color(0xFFBF360C),
  "惡": Color(0xFF37474F),
  "鋼": Color(0xFF90A4AE),
  "妖精": Color(0xFFEC407A),
  "龍": Color(0xFFFFB300),
  "無色": Color(0xFFBDBDBD),
};

void showCardDetailSheet(
    BuildContext context, String setCode, String cNum, dynamic cardData) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => CardDetailSheet(
        setCode: setCode, cNum: cNum, cardData: cardData),
  );
}

class CardDetailSheet extends StatelessWidget {
  final String setCode;
  final String cNum;
  final dynamic cardData;
  const CardDetailSheet(
      {super.key,
      required this.setCode,
      required this.cNum,
      required this.cardData});

  String get _fullId => "$setCode-$cNum";

  @override
  Widget build(BuildContext context) {
    final deckProvider = Provider.of<DeckProvider>(context);
    final deck = deckProvider.currentDeck;
    final bool deckMode = deck != null;

    return Consumer<CollectionProvider>(
      builder: (context, prov, _) {
        final int owned = prov.userCollection[_fullId] ?? 0;
        final int inDeck = deck?.cards[_fullId] ?? 0;
        final int want = prov.wishOf(_fullId);

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.82),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _header(),
                  const SizedBox(height: 12),
                  ..._body(),
                  const Divider(height: 24),
                  _counterRow(
                    "收藏",
                    owned,
                    enabled: !deckMode,
                    onAdd: () => prov.addCard(setCode, cNum),
                    onRemove: () => prov.removeCard(setCode, cNum),
                  ),
                  if (deckMode)
                    _counterRow(
                      "這副",
                      inDeck,
                      color: Colors.teal.shade700,
                      onAdd: () {
                        final err = deckProvider.addCardToDeck(
                            _fullId, cardData['name'].toString(), prov.database);
                        if (err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(err),
                              duration: const Duration(seconds: 1)));
                        }
                      },
                      onRemove: () => deckProvider.removeCardFromDeck(_fullId),
                    ),
                  _counterRow(
                    "想要",
                    want,
                    color: Colors.pink.shade400,
                    onAdd: () => prov.addWish(_fullId),
                    onRemove: () => prov.removeWish(_fullId),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header() {
    final String img = (cardData['image'] ?? "").toString();
    final String rarity = (cardData['rarity'] ?? "").toString();
    final String type = (cardData['type'] ?? "").toString();
    final String stage = (cardData['stage'] ?? "").toString();
    final hp = cardData['hp'];
    final elem = (cardData['elem'] ?? "").toString();

    final subBits = <String>[
      if (stage.isNotEmpty) stage,
      if (type.isNotEmpty && type != "寶可夢") type,
      if (elem.isNotEmpty) elem,
      if (hp != null) "HP $hp",
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: img.isEmpty
              ? Container(width: 84, height: 117, color: Colors.grey.shade200)
              : CachedNetworkImage(
                  imageUrl: img,
                  width: 84,
                  height: 117,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                      width: 84, height: 117, color: Colors.grey.shade200),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cardData['name'].toString(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text("$setCode  $cNum${rarity.isNotEmpty ? '  ·  $rarity' : ''}",
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontFamily: "Monospace")),
              if (subBits.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(subBits.join("　"),
                    style: const TextStyle(fontSize: 13)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _body() {
    final out = <Widget>[];

    for (final a in (cardData['abilities'] as List? ?? [])) {
      out.add(_block(
        "[特性] ${a['name']}",
        a['text']?.toString() ?? "",
        titleColor: Colors.red.shade700,
      ));
    }

    for (final a in (cardData['attacks'] as List? ?? [])) {
      final cost = (a['cost'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final dmg = (a['damage'] ?? "").toString();
      out.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final c in cost)
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                        color: _energyColors[c] ?? Colors.grey,
                        shape: BoxShape.circle),
                  ),
                if (cost.isNotEmpty) const SizedBox(width: 4),
                Expanded(
                  child: Text(a['name'].toString(),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                if (dmg.isNotEmpty)
                  Text(dmg,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            if ((a['text'] ?? "").toString().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(a['text'].toString(),
                  style: const TextStyle(fontSize: 13, height: 1.4)),
            ],
          ],
        ),
      ));
    }

    final effect = (cardData['effect'] ?? "").toString();
    if (effect.isNotEmpty) {
      out.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(effect, style: const TextStyle(fontSize: 14, height: 1.5)),
      ));
    }

    final weak = (cardData['weakness'] ?? "").toString();
    final resist = (cardData['resistance'] ?? "").toString();
    final retreat = cardData['retreat'];
    if (weak.isNotEmpty || resist.isNotEmpty || retreat != null) {
      out.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          [
            if (weak.isNotEmpty) "弱點 $weak",
            if (resist.isNotEmpty) "抵抗力 $resist",
            if (retreat != null) "撤退 $retreat",
          ].join("　　"),
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
      ));
    }

    final tags = (cardData['tags'] as List?)?.map((e) => e.toString()).toList();
    if (tags != null && tags.isNotEmpty) {
      out.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in tags)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0EDFD),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(t,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF4B3BA6))),
              ),
          ],
        ),
      ));
    }

    final dex = (cardData['dex'] ?? "").toString();
    final cat = (cardData['category'] ?? "").toString();
    final ill = (cardData['illustrator'] ?? "").toString();
    final meta = <String>[
      if (dex.isNotEmpty) "No.$dex${cat.isNotEmpty ? ' $cat' : ''}",
      if (ill.isNotEmpty) "繪師 $ill",
    ];
    if (meta.isNotEmpty) {
      out.add(Text(meta.join("　·　"),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)));
    }

    return out;
  }

  Widget _block(String title, String text, {Color? titleColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: titleColor)),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
          ],
        ],
      ),
    );
  }

  Widget _counterRow(String label, int value,
      {bool enabled = true,
      Color? color,
      required VoidCallback onAdd,
      required VoidCallback onRemove}) {
    final c = color ?? Colors.redAccent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 44,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold))),
          const Spacer(),
          if (enabled)
            IconButton(
              onPressed: value > 0
                  ? () {
                      HapticFeedback.selectionClick();
                      onRemove();
                    }
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
              color: c,
              visualDensity: VisualDensity.compact,
            ),
          Container(
            constraints: const BoxConstraints(minWidth: 36),
            alignment: Alignment.center,
            child: Text("$value",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: value > 0 ? c : Colors.grey)),
          ),
          if (enabled)
            IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onAdd();
              },
              icon: const Icon(Icons.add_circle),
              color: c,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
