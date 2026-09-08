import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/deck_provider.dart';
import '../providers/collection_provider.dart';

class DeckListScreen extends StatelessWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deckProvider = Provider.of<DeckProvider>(context);
    final collectionProvider = Provider.of<CollectionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("我的牌組與收藏本",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "新增牌組 / 收藏本",
            onPressed: () => _showCreateDialog(context, deckProvider),
          ),
        ],
      ),
      body: deckProvider.decks.isEmpty
          ? const Center(
              child: Text("尚未建立內容", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: deckProvider.decks.length,
              itemBuilder: (context, index) {
                final deck = deckProvider.decks[index];
                int totalCards =
                    deck.cards.values.fold(0, (sum, count) => sum + count);
                Color itemColor = deck.isBinder
                    ? Colors.orange.shade700
                    : Colors.teal.shade700;
                final Widget? badge = _legalityBadge(
                    deck, deckProvider, collectionProvider);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Icon(deck.isBinder ? Icons.menu_book : Icons.style,
                        color: itemColor, size: 30),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(deck.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          badge,
                        ],
                      ],
                    ),
                    subtitle: Text(
                        "種類：${deck.isBinder ? '收藏本' : '牌組'}\n卡片總數：$totalCards ${!deck.isBinder ? '/ 60' : ''}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 改名按鈕
                        IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey),
                            onPressed: () =>
                                _showRenameDialog(context, deckProvider, deck)),
                        // 進入編輯 (板手)
                        IconButton(
                            icon: const Icon(Icons.build, color: Colors.teal),
                            onPressed: () {
                              deckProvider.selectDeck(deck.id);
                              Navigator.pop(context);
                            }),
                        // 導出
                        IconButton(
                            icon:
                                const Icon(Icons.copy_all, color: Colors.blue),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text: deckProvider.generateExportText(
                                      deck, collectionProvider.database)));
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("清單已複製")));
                            }),
                        // 刪除
                        IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () =>
                                _confirmDelete(context, deckProvider, deck)),
                      ],
                    ),
                    onTap: () => _showDeckPreview(
                        context, deck, collectionProvider.database),
                  ),
                );
              },
            ),
    );
  }

  // 牌組合法性 badge（收藏本回 null）
  Widget? _legalityBadge(Deck deck, DeckProvider dp, CollectionProvider cp) {
    if (deck.isBinder) return null;
    final legal = dp.checkLegality(deck, cp.database, cp.standardRegs);
    final Color c = switch (legal.status) {
      "標準" => Colors.green.shade600,
      "開放" => Colors.grey.shade500,
      _ => Colors.orange.shade700,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
          color: c, borderRadius: BorderRadius.circular(4)),
      child: Text(legal.status,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }

  // --- 改名對話框 ---
  void _showRenameDialog(
      BuildContext context, DeckProvider provider, Deck deck) {
    final controller = TextEditingController(text: deck.name);
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("重新命名"),
              content: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: "新名稱")),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("取消")),
                TextButton(
                    onPressed: () {
                      if (controller.text.isNotEmpty)
                        provider.renameDeck(deck.id, controller.text);
                      Navigator.pop(ctx);
                    },
                    child: const Text("確定")),
              ],
            ));
  }

  // --- 修改建立對話框：增加種類選擇 ---
  void _showCreateDialog(BuildContext context, DeckProvider provider) {
    final controller = TextEditingController();
    bool isBinder = false;
    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
              builder: (context, setDialogState) => AlertDialog(
                title: const Text("建立新項目"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: controller,
                        decoration: const InputDecoration(hintText: "名稱")),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text("設為收藏本"),
                      subtitle: const Text("不限張數，無同名卡限制"),
                      value: isBinder,
                      activeColor: Colors.orange,
                      onChanged: (val) => setDialogState(() => isBinder = val),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("取消")),
                  TextButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty)
                          provider.createDeck(controller.text, isBinder);
                        Navigator.pop(ctx);
                      },
                      child: const Text("確定")),
                ],
              ),
            ));
  }

  void _showDeckPreview(
      BuildContext context, Deck deck, Map<String, dynamic> database) {
    var sortedEntries = deck.cards.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final legal = deck.isBinder
        ? null
        : Provider.of<DeckProvider>(context, listen: false).checkLegality(
            deck,
            database,
            Provider.of<CollectionProvider>(context, listen: false)
                .standardRegs);
    final legalityLines = <String>[
      if (legal != null && legal.cardCount < 60)
        "尚缺 ${60 - legal.cardCount} 張",
      if (legal != null && legal.cardCount > 0 && !legal.hasBasic)
        "沒有基礎寶可夢",
      if (legal != null && legal.nonStandardNames.isNotEmpty)
        "含 ${legal.nonStandardCount} 張非標準卡："
            "${legal.nonStandardNames.take(8).join('、')}"
            "${legal.nonStandardNames.length > 8 ? '…' : ''}",
    ];
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) => Column(children: [
                Container(
                    margin: const EdgeInsets.all(12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2))),
                Text("【${deck.name}】預覽",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                if (legal != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Text(
                      [
                        "賽制：${legal.status}",
                        ...legalityLines,
                      ].join("　·　"),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                const Divider(),
                Expanded(
                    child: ListView.builder(
                        controller: scrollController,
                        itemCount: sortedEntries.length,
                        itemBuilder: (ctx, i) {
                          final id = sortedEntries[i].key;
                          final parts = id.split('-');
                          final card = database[parts[0]]?['cards']?[parts[1]];
                          return ListTile(
                              leading: CircleAvatar(
                                  backgroundColor: deck.isBinder
                                      ? Colors.orange
                                      : Colors.teal,
                                  child: Text("${sortedEntries[i].value}",
                                      style: const TextStyle(
                                          color: Colors.white))),
                              title: Text(card?['name'] ?? "未知"),
                              subtitle: Text("[$id]"),
                              dense: true);
                        })),
              ]),
            ));
  }

  void _confirmDelete(BuildContext context, DeckProvider provider, Deck deck) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text("刪除"),
                content: Text("確定刪除 ${deck.name}？"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("取消")),
                  TextButton(
                      onPressed: () {
                        provider.deleteDeck(deck.id);
                        Navigator.pop(ctx);
                      },
                      child:
                          const Text("刪除", style: TextStyle(color: Colors.red)))
                ]));
  }
}
