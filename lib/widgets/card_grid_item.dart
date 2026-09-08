import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/collection_provider.dart';
import '../providers/deck_provider.dart';
import 'card_detail_sheet.dart';

class CardGridItem extends StatefulWidget {
  final String setCode;
  final String cNum;
  final dynamic cardData;

  const CardGridItem(
      {super.key,
      required this.setCode,
      required this.cNum,
      required this.cardData});

  @override
  State<CardGridItem> createState() => _CardGridItemState();
}

class _CardGridItemState extends State<CardGridItem> {
  // --- 圖片優化邏輯 ---
  String _getOptimizedUrl(String? rawUrl, double screenWidth) {
    if (rawUrl == null || rawUrl.isEmpty || rawUrl == "X") return "";
    String cleanUrl = rawUrl.replaceFirst(RegExp(r'^https?://'), '');
    int width = screenWidth > 1200 ? 600 : (screenWidth > 600 ? 450 : 300);
    return "https://wsrv.nl/?url=$cleanUrl&w=$width&q=80&output=webp&il";
  }

  Widget _buildPlaceholder(String shortNum, bool isOwned) {
    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              shortNum,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 26,
                color: isOwned ? Colors.black87 : Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Builder(
              builder: (context) {
                String name = widget.cardData['name'];
                String rarity = widget.cardData['rarity'];
                String displayText = (rarity == '—' ||
                        rarity == 'C' ||
                        rarity == 'U' ||
                        rarity == 'R')
                    ? name
                    : "$name $rarity";

                return Text(displayText,
                    style: TextStyle(
                      fontSize: 24,
                      color: isOwned ? Colors.black87 : Colors.grey[500],
                    ));
              },
            ),
          ),
        ],
      ),
    );
  }

  // 顯示卡片在哪些牌組中被使用的彈窗
  void _showUsageDialog(
      BuildContext context, String cardName, Map<String, int> usages) {
    final deckProvider = Provider.of<DeckProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(cardName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: usages.entries.map((e) {
            // 從清單中找出該牌組/收藏本的屬性
            final deck = deckProvider.decks.firstWhere((d) => d.name == e.key,
                orElse: () => Deck(
                    id: '', name: '', cards: {}, lastUpdated: DateTime.now()));
            return ListTile(
              leading: Icon(deck.isBinder ? Icons.menu_book : Icons.style,
                  color: deck.isBinder ? Colors.orange : Colors.teal, size: 20),
              title: Text(e.key, style: const TextStyle(fontSize: 14)),
              trailing: Text("x${e.value}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              dense: true,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("關閉"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CollectionProvider>(context);
    final deckProvider = Provider.of<DeckProvider>(context);
    final activeDeck = deckProvider.currentDeck;

    double screenWidth = MediaQuery.of(context).size.width;
    String fullId = "${widget.setCode}-${widget.cNum}";

    int count = provider.userCollection[fullId] ?? 0;
    bool isOwned = count > 0;
    int wishCount = provider.wishOf(fullId);
    String shortNum = widget.cNum.split('/')[0];
    String optimizedImgUrl =
        _getOptimizedUrl(widget.cardData['image'], screenWidth);
    int inDeckCount = activeDeck?.cards[fullId] ?? 0;

    // 取得該卡片在所有牌組/收藏本中的使用狀況
    final Map<String, int> usages = deckProvider.getCardUsages(fullId);

    return GestureDetector(
      onTap: () {
        if (activeDeck != null) {
          final err = deckProvider.addCardToDeck(
              fullId, widget.cardData['name'], provider.database);
          if (err != null)
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(err), duration: const Duration(seconds: 1)));
        } else {
          provider.addCard(widget.setCode, widget.cNum);
        }
      },
      onLongPress: () => showCardDetailSheet(
          context, widget.setCode, widget.cNum, widget.cardData),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isOwned ? Colors.white : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: isOwned
              ? Border.all(color: Colors.amber.shade600, width: 2)
              : Border.all(color: Colors.grey.shade400, width: 1),
          boxShadow: [
            if (isOwned)
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (optimizedImgUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: optimizedImgUrl,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) =>
                      _buildPlaceholder(shortNum, isOwned),
                  errorWidget: (ctx, url, err) =>
                      _buildPlaceholder(shortNum, isOwned),
                  imageBuilder: (ctx, imageProvider) => isOwned
                      ? Image(image: imageProvider, fit: BoxFit.cover)
                      : ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                              Colors.grey, BlendMode.saturation),
                          child: Opacity(
                              opacity: 0.4,
                              child: Image(
                                  image: imageProvider, fit: BoxFit.cover)),
                        ),
                )
              else
                _buildPlaceholder(shortNum, isOwned),

              // 1. 卡號標籤 (右下)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius:
                          const BorderRadius.only(topLeft: Radius.circular(6))),
                  child: Text("${widget.setCode}-$shortNum",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Monospace")),
                ),
              ),

              // 2. 收藏數量 (左上)
              if (isOwned)
                Positioned(
                  left: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5)),
                    constraints:
                        const BoxConstraints(minWidth: 24, minHeight: 24),
                    child: Center(
                        child: Text("x$count",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900))),
                  ),
                ),

              // 2b. 願望清單星星 (左下)
              if (wishCount > 0)
                Positioned(
                  left: 2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        color: Colors.pink.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5)),
                    constraints:
                        const BoxConstraints(minWidth: 22, minHeight: 22),
                    child: Center(
                      child: wishCount > 1
                          ? Text("★$wishCount",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900))
                          : const Icon(Icons.star,
                              color: Colors.white, size: 12),
                    ),
                  ),
                ),

              // 3. 牌組/收藏本 編輯數量 (右上)
              if (activeDeck != null && inDeckCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Builder(builder: (context) {
                    bool isShortage = inDeckCount > count;

                    // --- 顏色判斷邏輯 ---
                    Color badgeColor;
                    if (activeDeck.isBinder) {
                      badgeColor = Colors.orange.shade700; // 收藏本模式：一律琥珀橘
                    } else {
                      // 牌組模式：庫存不足顯示深紅，充足顯示青綠
                      badgeColor = isShortage
                          ? Colors.red.shade900
                          : Colors.teal.shade600;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 2)
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 只有在「牌組模式」且「庫存不足」時才顯示警告圖示
                          if (!activeDeck.isBinder && isShortage)
                            const Padding(
                                padding: EdgeInsets.only(right: 2),
                                child: Icon(Icons.warning_amber_rounded,
                                    color: Colors.white, size: 12)),
                          Text("IN: $inDeckCount",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                    );
                  }),
                ),

              // 4. 使用狀況提示條 (僅非編輯模式且有使用時顯示)
              if (activeDeck == null && usages.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 20, // 避開最底部的卡號標籤
                  child: GestureDetector(
                    onTap: () => _showUsageDialog(
                        context, widget.cardData['name'], usages),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              color: Colors.white, size: 10),
                          const SizedBox(width: 4),
                          Text(
                            "用於 ${usages.length} 個收藏區",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
