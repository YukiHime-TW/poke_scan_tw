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

      // 1. 篩選卡片
      if (query.isEmpty) {
        filteredCards = allCards;
      } else {
        String setNameLower = setData['name'].toString().toLowerCase();
        String setCodeLower = setCode.toLowerCase();

        // 如果系列名稱或代號符合，顯示整套
        bool setMatches =
            setNameLower.contains(query) || setCodeLower.contains(query);

        if (setMatches) {
          filteredCards = allCards;
        } else {
          // 否則篩選單卡名稱
          allCards.forEach((k, v) {
            String cardNameLower = v['name'].toString().toLowerCase();
            // 同時比對名稱或編號
            if (cardNameLower.contains(query) || k.contains(query)) {
              filteredCards[k] = v;
            }
          });
        }
      }

      if (filteredCards.isEmpty) continue;

      // 2. 計算進度 (計算該系列總進度，不受搜尋影響)
      int ownedCount = 0;
      allCards.keys.forEach((key) {
        if (provider.userCollection.containsKey("$setCode-$key")) {
          ownedCount++;
        }
      });
      double progress =
          allCards.isNotEmpty ? ownedCount / allCards.length : 0.0;

      // 搜尋模式下強制展開，否則讀取狀態
      bool isExpanded =
          query.isNotEmpty ? true : (_expandedState[setCode] ?? false);

      // 3. 建構介面
      slivers.add(
        MultiSliver(
          pushPinnedChildren: true, // 讓標題有推擠效果
          children: [
            // --- 黏性標題 (Sticky Header) ---
            SliverPinnedHeader(
              child: GestureDetector(
                onTap: () {
                  // 搜尋時不允許收合，避免邏輯混亂
                  if (query.isEmpty) {
                    setState(() {
                      _expandedState[setCode] = !isExpanded;
                    });
                  }
                },
                child: Container(
                  height: 90.0, // 高度加高以容納大字體
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
                                fontSize: 16), // 進度文字大小
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- 內容網格 (Cards Grid) ---
            if (isExpanded)
              SliverPadding(
                padding: const EdgeInsets.all(8.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8, // 8 列
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
        // --- 搜尋欄 ---
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

        // --- 右上角按鈕區 (搜尋 & 登入狀態) ---
        actions: [
          // 1. 搜尋按鈕 (不變)
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

          // 2. 登入狀態 (使用 Consumer 包裹，確保一定會收到更新)
          Consumer<CollectionProvider>(
            builder: (context, provider, child) {
              if (provider.user == null) {
                // --- 未登入 ---
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton.icon(
                    onPressed: () => provider.signInWithGoogle(),
                    icon: const Icon(Icons.login, color: Colors.white),
                    label:
                        const Text("登入", style: TextStyle(color: Colors.white)),
                  ),
                );
              } else {
                // --- 已登入 ---
                return Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("登出"),
                              content: Text(
                                  "確定要登出 ${provider.user!.displayName} 嗎？"),
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
                            ClipOval(
                              child: Image.network(
                                provider.user!.photoURL ?? "",
                                width: 32, // 對應原本 radius: 16 * 2
                                height: 32,
                                fit: BoxFit.cover,
                                // 這是關鍵：如果讀取失敗 (429/404)，顯示預設圖示，不要報錯
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.white,
                                    child: const Icon(Icons.person,
                                        color: Colors.grey),
                                  );
                                },
                                // 載入中顯示空白
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(color: Colors.white);
                                },
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
                            const Icon(Icons.logout,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
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

      // --- 掃描按鈕 (Web版隱藏) ---
      floatingActionButton: kIsWeb
          ? null
          : FloatingActionButton(
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.qr_code_scanner, color: Colors.white),
              onPressed: () {
                // 取消註解以啟用掃描頁面
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
//  (包含：長按加速、圖片顯示、無圖時的大文字顯示)
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
  int _interval = 500; // 初始連點速度

  // 開始扣除循環
  void _startDecreasing(CollectionProvider provider) {
    _interval = 500;
    _decreaseLoop(provider);
  }

  // 執行扣除並加速
  void _decreaseLoop(CollectionProvider provider) {
    provider.removeCard(widget.setCode, widget.cNum);

    // 每次間隔縮短為 80% (變快)，最快 50ms
    int nextInterval = (_interval * 0.8).toInt();
    if (nextInterval < 50) nextInterval = 50;
    _interval = nextInterval;

    _timer = Timer(Duration(milliseconds: _interval), () {
      _decreaseLoop(provider);
    });
  }

  // 停止計時
  void _stopDecreasing() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CollectionProvider>(context);

    // 檢查是否有這張卡
    String fullId = "${widget.setCode}-${widget.cNum}";
    int count = provider.userCollection[fullId] ?? 0;
    bool isOwned = count > 0;

    // 處理編號 (去除斜線後)
    String shortNum = widget.cNum.split('/')[0];
    // 圖片連結
    String? imgUrl = widget.cardData['image'];

    return GestureDetector(
      // 單擊：增加
      onTap: () => provider.addCard(widget.setCode, widget.cNum),

      // 長按：開始連發扣除
      onLongPressStart: (_) {
        if (count > 0) _startDecreasing(provider);
      },
      onLongPressEnd: (_) => _stopDecreasing(),
      onLongPressCancel: () => _stopDecreasing(),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isOwned ? Colors.white : Colors.grey[200], // 未擁有底色灰一點
          borderRadius: BorderRadius.circular(6),
          // 邊框：已擁有顯示金黃色，未擁有灰色
          border: isOwned
              ? Border.all(color: Colors.amber.shade600, width: 2)
              : Border.all(color: Colors.grey.shade400, width: 1),
          // 陰影
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
            // --- 層級 1: 內容 (圖片 或 文字) ---
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
                        // 未擁有：黑白濾鏡 + 半透明
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
              // 無圖片時的替代顯示 (保留您的大字體文字)
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
                          fontSize: 26, // 大字體編號
                          color: isOwned ? Colors.black87 : Colors.grey[500],
                        ),
                      ),
                    ),
                    // 稀有度顯示邏輯
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Builder(
                        builder: (context) {
                          String name = widget.cardData['name'];
                          String rarity = widget.cardData['rarity'];
                          if (rarity == '—' ||
                              rarity == 'C' ||
                              rarity == 'U' ||
                              rarity == 'R') {
                            return Text(name,
                                style: const TextStyle(fontSize: 24));
                          } else {
                            return Text("$name $rarity",
                                style: const TextStyle(fontSize: 24));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // --- 層級 2: 卡號標籤 (右下角) ---
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
                    "${widget.setCode}-$shortNum", // 顯示格式: AC1a-001
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: "Monospace",
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            // --- 層級 3: 數量統計 (左上角，紅色圓圈) ---
            if (isOwned)
              Positioned(
                left: 2,
                top: 2,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.redAccent, // 紅色底
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2), // 粗白邊
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
                            fontWeight: FontWeight.w900), // 特粗體
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
