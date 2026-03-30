import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';

// 匯入自定義組件與 Provider (請確保路徑正確)
import '../providers/collection_provider.dart';
import '../widgets/card_grid_item.dart';
import '../widgets/set_header.dart';

// 如果要編譯手機版並使用掃描功能，請取消下面這行的註解
// import 'scanner_screen.dart';

// 狀態過濾：全部、已擁有、未擁有
enum StatusFilter { all, owned, missing }

// 賽制過濾：不限、標準賽制、開放賽制
enum FormatFilter { all, standard, expanded }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 記錄每個系列的展開/收合狀態
  final Map<String, bool> _expandedState = {};

  // 搜尋控制
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  // 過濾條件初始化
  StatusFilter _statusFilter = StatusFilter.all;
  FormatFilter _formatFilter = FormatFilter.standard;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- 核心邏輯：判斷卡片是否符合賽制 ---
  bool _matchesFormat(dynamic cardData) {
    if (_formatFilter == FormatFilter.all) return true;

    // 取得卡片上的賽制標記 (例如 F, G, H)
    String regMark = (cardData['reg'] ?? "").toString().toUpperCase();

    if (_formatFilter == FormatFilter.standard) {
      // 目前標準賽制包含 H、I、J 標記， None為通用
      return ["H", "I", "J", "NONE"].contains(regMark);
    }

    // 開放賽制通常包含所有卡片
    return true;
  }

  // --- 輔助：根據過濾狀態切換主題顏色 ---
  Color _getThemeColor() {
    if (_statusFilter == StatusFilter.owned) return Colors.green.shade700;
    if (_statusFilter == StatusFilter.missing) return Colors.orange.shade800;
    if (_formatFilter == FormatFilter.standard) return Colors.blue.shade700;
    if (_formatFilter == FormatFilter.expanded) return Colors.purple.shade700;
    return Colors.redAccent;
  }

  // --- 輔助：動態 AppBar 標題 ---
  String _getAppBarTitle() {
    if (_isSearching) return "";
    String title = "PokeScan TW";
    if (_statusFilter == StatusFilter.owned) title = "我的收藏";
    if (_statusFilter == StatusFilter.missing) title = "缺卡清單";
    if (_formatFilter == FormatFilter.standard) title += " (標準)";
    if (_formatFilter == FormatFilter.expanded) title += " (開放)";
    return title;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CollectionProvider>(context);
    final themeColor = _getThemeColor();
    double screenWidth = MediaQuery.of(context).size.width;

    // 響應式列數計算
    int crossAxisCount = screenWidth < 600 ? 3 : (screenWidth < 1000 ? 5 : 8);

    if (provider.isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: themeColor)),
      );
    }

    List<Widget> slivers = [];
    String query = _searchText.trim().toLowerCase();

    // 1. 排序系列 (依照日期降冪)
    var sortedKeys = provider.database.keys.toList();
    sortedKeys.sort((a, b) => (provider.database[b]['releaseDate'] ?? "")
        .compareTo(provider.database[a]['releaseDate'] ?? ""));

    for (String setCode in sortedKeys) {
      var setData = provider.database[setCode];
      Map allCards = setData['cards'];
      Map filteredCards = {};

      // 2. 應用雙重過濾與搜尋
      allCards.forEach((k, v) {
        String fullId = "$setCode-$k";
        bool isOwned = provider.userCollection.containsKey(fullId);

        // A. 收藏狀態過濾
        if (_statusFilter == StatusFilter.owned && !isOwned) return;
        if (_statusFilter == StatusFilter.missing && isOwned) return;

        // B. 賽制過濾
        if (!_matchesFormat(v)) return;

        // C. 關鍵字搜尋
        if (query.isNotEmpty) {
          String cardName = v['name'].toString().toLowerCase();
          String rarity = (v['rarity'] ?? "").toString().toLowerCase();
          String setName = setData['name'].toString().toLowerCase();
          bool matchesText = cardName.contains(query) ||
              k.contains(query) ||
              rarity.contains(query) ||
              setName.contains(query);
          if (!matchesText) return;
        }

        filteredCards[k] = v;
      });

      if (filteredCards.isEmpty) continue;

      // 3. 計算系列原始進度
      int ownedInSet = allCards.keys
          .where((k) => provider.userCollection.containsKey("$setCode-$k"))
          .length;

      // 4. 智慧展開邏輯 (搜尋文字時強制展開)
      bool isExpanded =
          (query.isNotEmpty) ? true : (_expandedState[setCode] ?? false);

      slivers.add(
        MultiSliver(
          pushPinnedChildren: true,
          children: [
            SliverPinnedHeader(
              child: SetHeader(
                title: setData['name'],
                setCode: setCode,
                progress:
                    allCards.isNotEmpty ? ownedInSet / allCards.length : 0,
                owned: ownedInSet,
                total: allCards.length,
                isExpanded: isExpanded,
                themeColor: themeColor,
                onTap: () {
                  if (query.isEmpty) {
                    setState(() => _expandedState[setCode] = !isExpanded);
                  }
                },
              ),
            ),
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
                    (ctx, i) {
                      String cNum = filteredCards.keys.elementAt(i);
                      return CardGridItem(
                        setCode: setCode,
                        cNum: cNum,
                        cardData: filteredCards[cNum],
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
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: () => _showHelpDialog(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    hintText: "搜尋名稱/編號/系列...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70)),
                onChanged: (val) => setState(() => _searchText = val),
              )
            : Text(_getAppBarTitle(),
                style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchText = "";
                _searchController.clear();
              }
            }),
          ),
          _buildFilterMenu(),
          Consumer<CollectionProvider>(
            builder: (context, prov, _) {
              if (prov.user == null) {
                return TextButton.icon(
                  onPressed: () => prov.signInWithGoogle(),
                  icon: const Icon(Icons.login, color: Colors.white),
                  label:
                      const Text("登入", style: TextStyle(color: Colors.white)),
                );
              } else {
                return InkWell(
                  onTap: () => _showLogoutDialog(context, prov),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: prov.user!.photoURL != null
                              ? NetworkImage(prov.user!.photoURL!)
                              : null,
                          child: prov.user!.photoURL == null
                              ? const Icon(Icons.person, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.logout, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: CustomScrollView(
        cacheExtent: 1000,
        slivers: slivers.isNotEmpty
            ? slivers
            : [
                const SliverFillRemaining(
                    child: Center(
                        child: Text("沒有符合條件的卡片",
                            style: TextStyle(color: Colors.grey)))),
              ],
      ),
      floatingActionButton: kIsWeb
          ? null
          : FloatingActionButton(
              backgroundColor: themeColor,
              child: const Icon(Icons.qr_code_scanner, color: Colors.white),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("請在手機端部署 ScannerScreen"))),
            ),
    );
  }

  // --- 構建下拉式過濾選單 (修正類型錯誤) ---
  Widget _buildFilterMenu() {
    return PopupMenuButton<dynamic>(
      icon: const Icon(Icons.filter_list),
      tooltip: "進階過濾",
      onSelected: (value) {
        setState(() {
          if (value is StatusFilter) _statusFilter = value;
          if (value is FormatFilter) _formatFilter = value;
        });
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<dynamic>>[
        const PopupMenuItem(
            enabled: false,
            child: Text("收藏狀態",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey))),
        _buildPopupItem(StatusFilter.all, Icons.apps, "顯示全部",
            _statusFilter == StatusFilter.all),
        _buildPopupItem(StatusFilter.owned, Icons.check_circle, "只看已擁有",
            _statusFilter == StatusFilter.owned),
        _buildPopupItem(StatusFilter.missing, Icons.radio_button_unchecked,
            "只看未擁有", _statusFilter == StatusFilter.missing),
        const PopupMenuDivider(),
        const PopupMenuItem(
            enabled: false,
            child: Text("賽制篩選",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey))),
        _buildPopupItem(FormatFilter.all, Icons.not_interested, "不限賽制",
            _formatFilter == FormatFilter.all),
        _buildPopupItem(FormatFilter.standard, Icons.verified_user, "標準賽制",
            _formatFilter == FormatFilter.standard),
        _buildPopupItem(FormatFilter.expanded, Icons.public, "開放賽制",
            _formatFilter == FormatFilter.expanded),
      ],
    );
  }

  // 返回 PopupMenuEntry 以避免類型不匹配
  PopupMenuEntry<dynamic> _buildPopupItem(
      dynamic value, IconData icon, String title, bool isSelected) {
    Color activeColor = _getThemeColor();
    return PopupMenuItem<dynamic>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: isSelected ? activeColor : Colors.grey, size: 20),
          const SizedBox(width: 12),
          Text(title,
              style: TextStyle(
                  color: isSelected ? activeColor : Colors.black87,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal)),
          const Spacer(),
          if (isSelected) Icon(Icons.check, color: activeColor, size: 16),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, CollectionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("登出"),
        content: Text("確定要登出 ${provider.user!.displayName} 嗎？"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(
              onPressed: () {
                provider.signOut();
                Navigator.pop(context);
              },
              child: const Text("登出", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("使用說明"),
        content: const Text("• 點擊卡片：數量 +1\n"
            "• 長按卡片：數量 -1 (長按可加速)\n"
            "• 智慧搜尋：搜尋文字時會自動展開系列\n"
            "• 進階過濾：右上角漏斗可切換「狀態」與「賽制」"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("我知道了"))
        ],
      ),
    );
  }
}
