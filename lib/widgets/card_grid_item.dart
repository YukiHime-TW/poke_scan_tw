import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/collection_provider.dart';
import '../providers/deck_provider.dart';

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
  Timer? _timer;
  int _interval = 500;

  @override
  void dispose() {
    _stopDecreasing();
    super.dispose();
  }

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
              child: Text(shortNum,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      color: isOwned ? Colors.black87 : Colors.grey[500]))),
          const SizedBox(height: 2),
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(widget.cardData['name'] ?? "",
                  style: TextStyle(
                      fontSize: 24,
                      color: isOwned ? Colors.black87 : Colors.grey[500]))),
        ],
      ),
    );
  }

  // --- 【核心修改】通用連續扣除邏輯 ---
  // action: 要執行的扣除函數
  // getCount: 取得目前數量的函數
  void _startDecreasing(VoidCallback action, int Function() getCount) {
    _stopDecreasing(); // 確保安全
    _interval = 500;
    _executeLoop(action, getCount);
  }

  void _executeLoop(VoidCallback action, int Function() getCount) {
    if (!mounted || getCount() <= 0) {
      _stopDecreasing();
      return;
    }

    action(); // 執行扣除動作 (可能是減收藏，也可能是減牌組)

    // 加速邏輯
    _interval = (_interval * 0.8).toInt();
    if (_interval < 50) _interval = 50;

    _timer = Timer(Duration(milliseconds: _interval),
        () => _executeLoop(action, getCount));
  }

  void _stopDecreasing() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
      _timer = null;
    }
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
    String shortNum = widget.cNum.split('/')[0];
    String optimizedImgUrl =
        _getOptimizedUrl(widget.cardData['image'], screenWidth);
    int inDeckCount = activeDeck?.cards[fullId] ?? 0;

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
      // --- 【修改點】長按邏輯判斷 ---
      onLongPressStart: (_) {
        if (activeDeck != null) {
          // 編輯模式：連續扣除牌組內數量
          if (inDeckCount > 0) {
            _startDecreasing(() => deckProvider.removeCardFromDeck(fullId),
                () => activeDeck.cards[fullId] ?? 0);
          }
        } else {
          // 收藏模式：連續扣除我的收藏
          if (count > 0) {
            _startDecreasing(
                () => provider.removeCard(widget.setCode, widget.cNum),
                () => provider.userCollection[fullId] ?? 0);
          }
        }
      },
      onLongPressEnd: (_) => _stopDecreasing(),
      onLongPressCancel: () => _stopDecreasing(),
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
                  imageBuilder: (ctx, imgProv) => isOwned
                      ? Image(image: imgProv, fit: BoxFit.cover)
                      : ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                              Colors.grey, BlendMode.saturation),
                          child: Opacity(
                              opacity: 0.4,
                              child: Image(image: imgProv, fit: BoxFit.cover)),
                        ),
                )
              else
                _buildPlaceholder(shortNum, isOwned),
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
              if (activeDeck != null && inDeckCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Builder(builder: (context) {
                    bool isShortage = inDeckCount > count;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isShortage
                            ? Colors.red.shade900
                            : Colors.teal.shade600,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 2)
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isShortage)
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
            ],
          ),
        ),
      ),
    );
  }
}
