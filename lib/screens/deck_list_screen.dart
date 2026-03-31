import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 必須匯入以使用剪貼簿 (Clipboard)
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/deck_provider.dart';
import '../providers/collection_provider.dart';

class DeckListScreen extends StatelessWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deckProvider = Provider.of<DeckProvider>(context);
    // 取得 collectionProvider 以獲取資料庫內容供導出使用
    final collectionProvider =
        Provider.of<CollectionProvider>(context, listen: false);

    final themeColor = Colors.teal.shade800; // 與編輯模式顏色保持一致

    return Scaffold(
      appBar: AppBar(
        title:
            const Text("我的牌組", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: deckProvider.decks.isEmpty
          ? _buildEmptyState()
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
                    // --- 關鍵修改：將 trailing 改為 Row 以容納兩個按鈕 ---
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. 導出按鈕 (複製清單)
                        IconButton(
                          icon: const Icon(Icons.copy_all, color: Colors.blue),
                          tooltip: "導出牌組清單",
                          onPressed: () {
                            // 呼叫我們在 Provider 寫好的導出邏輯
                            String exportText = deckProvider.generateExportText(
                                deck, collectionProvider.database);

                            // 複製到剪貼簿
                            Clipboard.setData(ClipboardData(text: exportText));

                            // 震動回饋與提示
                            HapticFeedback.mediumImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("「${deck.name}」清單已複製到剪貼簿！"),
                                backgroundColor: Colors.blue.shade700,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                        // 2. 刪除按鈕
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () =>
                              _confirmDelete(context, deckProvider, deck),
                        ),
                      ],
                    ),
                    onTap: () {
                      // 選擇此牌組並返回首頁開始編輯
                      deckProvider.selectDeck(deck.id);
                      Navigator.pop(context);
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

  Widget _buildEmptyState() {
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

  void _showCreateDeckDialog(BuildContext context, DeckProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("建立新牌組"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "請輸入牌組名稱"),
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

  void _confirmDelete(BuildContext context, DeckProvider provider, Deck deck) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("刪除牌組"),
        content: Text("確定要刪除「${deck.name}」嗎？"),
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
