import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/deck_provider.dart';
import '../providers/collection_provider.dart';

class DeckListScreen extends StatelessWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deckProvider = Provider.of<DeckProvider>(context);
    final collectionProvider =
        Provider.of<CollectionProvider>(context, listen: false);
    final themeColor = Colors.teal.shade800;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text("我的牌組", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: deckProvider.decks.isEmpty
          ? const Center(
              child: Text("尚未建立牌組", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: deckProvider.decks.length,
              itemBuilder: (context, index) {
                final deck = deckProvider.decks[index];
                int totalCards =
                    deck.cards.values.fold(0, (sum, count) => sum + count);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(deck.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text(
                        "卡片總數：$totalCards / 60\n最後更新：${DateFormat('MM/dd HH:mm').format(deck.lastUpdated)}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. 板手：進入編輯模式
                        IconButton(
                          icon: const Icon(Icons.build, color: Colors.teal),
                          tooltip: "編輯牌組",
                          onPressed: () {
                            deckProvider.selectDeck(deck.id);
                            Navigator.pop(context);
                          },
                        ),
                        // 2. 導出
                        IconButton(
                          icon: const Icon(Icons.copy_all, color: Colors.blue),
                          onPressed: () {
                            String text = deckProvider.generateExportText(
                                deck, collectionProvider.database);
                            Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("已複製清單至剪貼簿")));
                          },
                        ),
                        // 3. 刪除
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () =>
                              _confirmDelete(context, deckProvider, deck),
                        ),
                      ],
                    ),
                    // --- 點擊 ListTile：顯示預覽清單 ---
                    onTap: () => _showDeckPreview(
                        context, deck, collectionProvider.database),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showCreateDialog(context, deckProvider),
      ),
    );
  }

  // --- 預覽彈窗 ---
  void _showDeckPreview(
      BuildContext context, Deck deck, Map<String, dynamic> database) {
    // 預先排序預覽內容 (擴充包 -> 名稱)
    var sortedEntries = deck.cards.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
                margin: const EdgeInsets.all(12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            Text("【${deck.name}】清單",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: sortedEntries.length,
                itemBuilder: (ctx, i) {
                  final id = sortedEntries[i].key;
                  final count = sortedEntries[i].value;
                  final parts = id.split('-');
                  final card = database[parts[0]]?['cards']?[parts[1]];
                  return ListTile(
                    leading: CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Text("$count",
                            style: const TextStyle(color: Colors.white))),
                    title: Text(card?['name'] ?? "未知卡片"),
                    subtitle: Text("[$id] ${card?['rarity'] ?? ''}"),
                    dense: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, DeckProvider provider) {
    final controller = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text("建立牌組"),
                content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: "名稱")),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("取消")),
                  TextButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty)
                          provider.createDeck(controller.text);
                        Navigator.pop(ctx);
                      },
                      child: const Text("確定"))
                ]));
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
