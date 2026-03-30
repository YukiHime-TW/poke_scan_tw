import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/deck_provider.dart';
import 'package:intl/intl.dart'; // 建議在 pubspec.yaml 加入 intl 套件處理時間格式

class DeckListScreen extends StatelessWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deckProvider = Provider.of<DeckProvider>(context);
    final themeColor = Colors.blue.shade700; // 牌組功能建議使用藍色調

    return Scaffold(
      appBar: AppBar(
        title:
            const Text("我的牌組", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: deckProvider.decks.isEmpty
          ? _buildEmptyState(context)
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
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      deck.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("卡片總數：$totalCards / 60",
                            style: TextStyle(
                                color: totalCards == 60
                                    ? Colors.green
                                    : Colors.grey.shade700)),
                        Text(
                            "最後更新：${DateFormat('yyyy/MM/dd HH:mm').format(deck.lastUpdated)}",
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () =>
                          _confirmDelete(context, deckProvider, deck),
                    ),
                    onTap: () {
                      // 選擇此牌組並返回首頁開始編輯
                      deckProvider.selectDeck(deck.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("正在編輯：${deck.name}"),
                            backgroundColor: themeColor),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showCreateDeckDialog(context, deckProvider),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.style_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("尚未建立任何牌組",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  // 新增牌組彈窗
  void _showCreateDeckDialog(BuildContext context, DeckProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("建立新牌組"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "請輸入牌組名稱（如：噴火龍 ex）"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.createDeck(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text("建立"),
          ),
        ],
      ),
    );
  }

  // 刪除確認
  void _confirmDelete(BuildContext context, DeckProvider provider, Deck deck) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("刪除牌組"),
        content: Text("確定要刪除「${deck.name}」嗎？此動作無法復原。"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(
            onPressed: () {
              provider.deleteDeck(deck.id);
              Navigator.pop(context);
            },
            child: const Text("刪除", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
