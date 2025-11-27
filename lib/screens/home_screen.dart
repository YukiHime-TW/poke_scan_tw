import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';
import '../providers/collection_provider.dart';

// 如果要編譯手機版並使用掃描功能，請取消下面這行的註解
// import 'scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 展開狀態紀錄
  final Map<String, bool> _expandedState = {};

  // 搜尋相關變數
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CollectionProvider>(context);

    // --- 1. 【新增】取得螢幕寬度與計算列數 ---
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;

    if (screenWidth < 600) {
      crossAxisCount = 3; // 手機直向：3列 (卡片大一點才看得到圖)
    } else if (screenWidth < 1000) {
      crossAxisCount = 5; // 平板或手機橫向：5列
    } else {
      crossAxisCount = 8; // 電腦/大螢幕：8列 (維持您原本的設定)
    }

    // 讀取資料中
    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // --- 搜尋過濾與列表生成邏輯 ---
    List<Widget> slivers = [];
    String query = _searchText.trim().toLowerCase();

    for (String setCode in provider.database.keys) {
      var setData = provider.database[setCode];
      Map allCards = setData['cards'];

      Map filteredCards = {};

      // 篩選卡片
      if (query.isEmpty) {
        filteredCards = allCards;
      } else {
        String setNameLower = setData['name'].toString().toLowerCase();
        String setCodeLower = setCode.toLowerCase();

        bool setMatches =
            setNameLower.contains(query) || setCodeLower.contains(query);

        if (setMatches) {
          filteredCards = allCards;
        } else {
          allCards.forEach((k, v) {
            String cardNameLower = v['name'].toString().toLowerCase();
            if (cardNameLower.contains(query) || k.contains(query)) {
              filteredCards[k] = v;
            }
          });
        }
      }

      if (filteredCards.isEmpty) continue;

      // 計算進度
      int ownedCount = 0;
      allCards.keys.forEach((key) {
        if (provider.userCollection.containsKey("$setCode-$key")) {
          ownedCount++;
        }
      });
      double progress =
          allCards.isNotEmpty ? ownedCount / allCards.length : 0.0;

      bool isExpanded =
          query.isNotEmpty ? true : (_expandedState[setCode] ?? false);

      slivers.add(
        MultiSliver(
          pushPinnedChildren: true,
          children: [
            // --- 黏性標題 ---
            SliverPinnedHeader(
              child: GestureDetector(
                onTap: () {
                  if (query.isEmpty) {
                    setState(() {
                      _expandedState[setCode] = !isExpanded;
                    });
                  }
                },
                child: Container(
                  height: 90.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${setData['name']} ($setCode)",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (query.isEmpty)
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color:
                                  isExpanded ? Colors.redAccent : Colors.grey,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey[200],
                                color: Colors.redAccent,
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "$ownedCount / ${allCards.length}",
                            style: TextStyle(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- 內容網格 ---
            if (isExpanded)
              SliverPadding(
                padding: const EdgeInsets.all(8.0),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount, // 2. 【使用動態計算的列數】
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, cIndex) {
                      String cNum = filteredCards.keys.elementAt(cIndex);
                      var cardData = filteredCards[cNum];
                      return CardGridItem(
                        setCode: setCode,
                        cNum: cNum,
                        cardData: cardData,
                      );
                    },
                    childCount: filteredCards.length,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: "搜尋...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _searchText = value),
              )
            : const Text("PokeScan TW",
                style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _isSearching = false;
                _searchText = "";
                _searchController.clear();
              }),
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
            ),
          if (provider.user == null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: () => provider.signInWithGoogle(),
                icon: const Icon(Icons.login, color: Colors.white),
                label: const Text("登入", style: TextStyle(color: Colors.white)),
              ),
            )
          else
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("登出"),
                          content:
                              Text("確定要登出 ${provider.user!.displayName} 嗎？"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("取消"),
                            ),
                            TextButton(
                              onPressed: () {
                                provider.signOut();
                                Navigator.pop(context);
                              },
                              child: const Text("登出",
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          child: ClipOval(
                            child: Image.network(
                              provider.user!.photoURL ?? "",
                              width: 28,
                              height: 28,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.white,
                                  child: const Icon(Icons.person,
                                      size: 16, color: Colors.grey),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(color: Colors.white);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: Text(
                            provider.user!.displayName ?? "玩家",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.logout, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: slivers.isNotEmpty
            ? slivers
            : [
                const SliverFillRemaining(
                  child: Center(
                      child:
                          Text("沒有找到卡片", style: TextStyle(color: Colors.grey))),
                )
              ],
      ),
      floatingActionButton: kIsWeb
          ? null
          : FloatingActionButton(
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.qr_code_scanner, color: Colors.white),
              onPressed: () {
                // Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen()));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("請先設定 ScannerScreen 匯入")));
              },
            ),
    );
  }
}

// ------------------------------------------------------
//  👇 獨立元件：單張卡片格子
// ------------------------------------------------------
class CardGridItem extends StatefulWidget {
  final String setCode;
  final String cNum;
  final dynamic cardData;

  const CardGridItem({
    super.key,
    required this.setCode,
    required this.cNum,
    required this.cardData,
  });

  @override
  State<CardGridItem> createState() => _CardGridItemState();
}

class _CardGridItemState extends State<CardGridItem> {
  Timer? _timer;
  int _interval = 500;

  void _startDecreasing(CollectionProvider provider) {
    _interval = 500;
    _decreaseLoop(provider);
  }

  void _decreaseLoop(CollectionProvider provider) {
    provider.removeCard(widget.setCode, widget.cNum);

    int nextInterval = (_interval * 0.8).toInt();
    if (nextInterval < 50) nextInterval = 50;
    _interval = nextInterval;

    _timer = Timer(Duration(milliseconds: _interval), () {
      _decreaseLoop(provider);
    });
  }

  void _stopDecreasing() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CollectionProvider>(context);

    String fullId = "${widget.setCode}-${widget.cNum}";
    int count = provider.userCollection[fullId] ?? 0;
    bool isOwned = count > 0;

    String shortNum = widget.cNum.split('/')[0];
    String? imgUrl = widget.cardData['image'];

    return GestureDetector(
      onTap: () => provider.addCard(widget.setCode, widget.cNum),
      onLongPressStart: (_) {
        if (count > 0) _startDecreasing(provider);
      },
      onLongPressEnd: (_) => _stopDecreasing(),
      onLongPressCancel: () => _stopDecreasing(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isOwned ? Colors.white : Colors.grey[200],
          borderRadius: BorderRadius.circular(6),
          border: isOwned
              ? Border.all(color: Colors.amber.shade600, width: 2)
              : Border.all(color: Colors.grey.shade400, width: 1),
          boxShadow: [
            if (isOwned)
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imgUrl != null && imgUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: isOwned
                    ? Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, loading) {
                          if (loading == null) return child;
                          return Container(color: Colors.grey[200]);
                        },
                        errorBuilder: (ctx, err, stack) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image,
                                color: Colors.grey)),
                      )
                    : ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.grey,
                          BlendMode.saturation,
                        ),
                        child: Opacity(
                          opacity: 0.4,
                          child: Image.network(imgUrl, fit: BoxFit.cover),
                        ),
                      ),
              )
            else
              Container(
                padding: const EdgeInsets.all(2),
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
                          // 稀有度顯示邏輯
                          String displayText = (rarity == '—' ||
                                  rarity == 'C' ||
                                  rarity == 'U' ||
                                  rarity == 'R')
                              ? name
                              : "$name $rarity";

                          return Text(displayText,
                              style: TextStyle(
                                fontSize: 24,
                                color:
                                    isOwned ? Colors.black87 : Colors.grey[500],
                              ));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomRight: Radius.circular(4)),
                ),
                child: FittedBox(
                  child: Text(
                    "${widget.setCode}-$shortNum",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: "Monospace",
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            if (isOwned)
              Positioned(
                left: 2,
                top: 2,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black38,
                          blurRadius: 3,
                          offset: Offset(1, 1))
                    ],
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "x$count",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
