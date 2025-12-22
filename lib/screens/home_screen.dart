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

  // 【新增 1】用來定位每一個標題的 Key Map
  final Map<String, GlobalKey> _headerKeys = {};

  // 搜尋相關變數
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 【新增 2】捲動到指定 Key 的函式
  void _scrollToHeader(String setCode) {
    // 稍微延遲一下，等待介面收合渲染完畢後再捲動
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _headerKeys[setCode];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 300), // 動畫時間
          curve: Curves.easeInOut, // 動畫曲線
          alignment: 0.0, // 0.0 代表對齊螢幕「最上方」 (1.0 是最下方)
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CollectionProvider>(context);

    // 1. 取得螢幕寬度與計算列數 (響應式設計)
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;

    if (screenWidth < 600) {
      crossAxisCount = 3; // 手機直向：3列
    } else if (screenWidth < 1000) {
      crossAxisCount = 5; // 平板或手機橫向：5列
    } else {
      crossAxisCount = 8; // 電腦/大螢幕：8列
    }

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // --- 搜尋過濾與列表生成邏輯 ---
    List<Widget> slivers = [];
    String query = _searchText.trim().toLowerCase();

    // 1. 排序 Key (依照日期降冪)
    var sortedKeys = provider.database.keys.toList();
    sortedKeys.sort((keyA, keyB) {
      var dataA = provider.database[keyA];
      var dataB = provider.database[keyB];
      // 如果沒有日期，預設排在最後
      String dateA = dataA['releaseDate'] ?? "2000-01-01";
      String dateB = dataB['releaseDate'] ?? "2000-01-01";
      return dateB.compareTo(dateA); // 新的在上面
    });

    for (String setCode in sortedKeys) {
      var setData = provider.database[setCode];
      Map allCards = setData['cards'];
      Map filteredCards = {};

      // 篩選卡片
      if (query.isEmpty) {
        filteredCards = allCards;
      } else {
        String setNameLower = setData['name'].toString().toLowerCase();
        String setCodeLower = setCode.toLowerCase();

        // 如果系列名稱或代號符合，顯示整套
        bool setMatches = setNameLower.contains(query) || setCodeLower.contains(query);

        if (setMatches) {
          filteredCards = allCards;
        } else {
          // 否則篩選單卡 (名稱、編號、稀有度)
          allCards.forEach((k, v) {
            String cardNameLower = v['name'].toString().toLowerCase();
            String rarityLower = (v['rarity'] ?? "").toString().toLowerCase();
            if (cardNameLower.contains(query) ||
                k.contains(query) ||
                rarityLower.contains(query)) {
              filteredCards[k] = v;
            }
          });
        }
      }

      if (filteredCards.isEmpty) continue;

      // 計算進度 (計算該系列總進度，不受搜尋影響)
      int ownedCount = 0;
      allCards.keys.forEach((key) {
        if (provider.userCollection.containsKey("$setCode-$key")) {
          ownedCount++;
        }
      });
      double progress =
          allCards.isNotEmpty ? ownedCount / allCards.length : 0.0;

      // 搜尋模式下強制展開，否則讀取狀態
      bool isExpanded = query.isNotEmpty ? true : (_expandedState[setCode] ?? false);

      // 【新增 3】確保這個系列有一個對應的 GlobalKey
      if (!_headerKeys.containsKey(setCode)) {
        _headerKeys[setCode] = GlobalKey();
      }

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
                    bool currentlyExpanded = _expandedState[setCode] ?? false;

                    setState(() {
                      // 切換狀態
                      _expandedState[setCode] = !currentlyExpanded;
                    });

                    // 【新增 4】如果是執行「收合」動作，觸發捲動
                    if (currentlyExpanded) {
                      _scrollToHeader(setCode);
                    }
                  }
                },
                child: Container(
                  // 【新增 5】綁定 Key，這樣系統才知道要捲動到哪裡
                  key: _headerKeys[setCode],

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
                                fontSize: 16), // 進度文字大小
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
                    crossAxisCount: crossAxisCount,
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

        // --- 左上角說明按鈕 ---
        leading: IconButton(
          icon: const Icon(Icons.help_outline),
          tooltip: "使用說明",
          onPressed: () => _showHelpDialog(context),
        ),

        // --- 搜尋欄 ---
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: "搜尋 名稱 / 編號 / 稀有度 ...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _searchText = value),
              )
            : const Text("PokeScan TW",
                style: TextStyle(fontWeight: FontWeight.bold)),

        // --- 右上角按鈕區 (搜尋 & 登入狀態) ---
        actions: [
          // 1. 搜尋按鈕
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

          // 2. 登入狀態判斷
          Consumer<CollectionProvider>(
            builder: (context, provider, child) {
              if (provider.user == null) {
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

  // --- 顯示操作說明的彈窗 ---
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.redAccent),
            SizedBox(width: 8),
            Text("使用說明"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(
                  Icons.touch_app, "收藏卡片", "• 點擊卡片：數量 +1\n• 長按卡片：數量 -1 (連按加速)"),
              const Divider(),
              _buildHelpItem(Icons.search, "搜尋功能",
                  "支援多種關鍵字：\n• 卡片名稱 (如：皮卡丘)\n• 卡片編號 (如：001)\n• 稀有度 (如：SR, SAR, UR)"),
              const Divider(),
              _buildHelpItem(Icons.cloud_sync, "雲端同步",
                  "• 點擊右上角登入 Google 帳號。\n• 資料會自動在手機與網頁版間同步。\n• 登出時會自動清除本地暫存。"),
              const Divider(),
              if (!kIsWeb) ...[
                _buildHelpItem(Icons.qr_code_scanner, "掃描功能",
                    "• 點擊右下角相機按鈕。\n• 對準卡片左下角編號 (如 SV1a 001/078)。"),
                const Divider(),
              ],
              const Text(
                "小提示：點擊系列標題可以收合/展開該系列喔！",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text("我知道了", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(desc,
                    style: TextStyle(color: Colors.grey[800], height: 1.4)),
              ],
            ),
          ),
        ],
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

    // 每次間隔縮短為 80% (變快)，最快 50ms
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

    // 檢查是否有這張卡
    String fullId = "${widget.setCode}-${widget.cNum}";
    int count = provider.userCollection[fullId] ?? 0;
    bool isOwned = count > 0;

    // 處理編號 (去除斜線後)
    String shortNum = widget.cNum.split('/')[0];
    String? imgUrl = widget.cardData['image'];

    if (kIsWeb && imgUrl != null && imgUrl.isNotEmpty) {
      if (imgUrl.contains("asia.pokemon-card.com")) {
        String cleanUrl = imgUrl.replaceFirst(RegExp(r'^https?://'), '');
        imgUrl = "https://wsrv.nl/?url=$cleanUrl&output=webp";
      }
    }

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
          color: isOwned ? Colors.white : Colors.grey[200], // 未擁有，底色灰一點
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
              // 無圖片時的替代顯示 (大字體文字)
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
