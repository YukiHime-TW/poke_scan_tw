import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../providers/collection_provider.dart';
import '../providers/deck_provider.dart';
import '../widgets/card_grid_item.dart';
import '../widgets/set_header.dart';
import 'deck_list_screen.dart';
import 'scanner_screen.dart';

// 狀態過濾
enum StatusFilter { all, owned, missing, duplicates, competitive, inDeck, used }

// 賽制過濾
enum FormatFilter { all, standard, expanded }

// 種類過濾
enum TypeFilter {
  all,
  pokemon,
  goods,
  supporter,
  stadium,
  tool,
  specialEnergy,
  basicEnergy
}

// 屬性過濾（寶可夢能量色，對應卡片資料的 elem 欄位）
enum ElementFilter {
  all,
  grass,
  fire,
  water,
  lightning,
  psychic,
  fighting,
  darkness,
  metal,
  fairy,
  dragon,
  colorless,
}

// enum -> 資料庫 elem 字串（由 scripts/add_elem.py 寫入）
const Map<ElementFilter, String> kElementLabels = {
  ElementFilter.grass: "草",
  ElementFilter.fire: "火",
  ElementFilter.water: "水",
  ElementFilter.lightning: "雷",
  ElementFilter.psychic: "超",
  ElementFilter.fighting: "格鬥",
  ElementFilter.darkness: "惡",
  ElementFilter.metal: "鋼",
  ElementFilter.fairy: "妖精",
  ElementFilter.dragon: "龍",
  ElementFilter.colorless: "無色",
};

const Map<ElementFilter, Color> kElementColors = {
  ElementFilter.grass: Color(0xFF4CAF50),
  ElementFilter.fire: Color(0xFFF44336),
  ElementFilter.water: Color(0xFF2196F3),
  ElementFilter.lightning: Color(0xFFFBC02D),
  ElementFilter.psychic: Color(0xFF9C27B0),
  ElementFilter.fighting: Color(0xFFBF360C),
  ElementFilter.darkness: Color(0xFF37474F),
  ElementFilter.metal: Color(0xFF90A4AE),
  ElementFilter.fairy: Color(0xFFEC407A),
  ElementFilter.dragon: Color(0xFFFFB300),
  ElementFilter.colorless: Color(0xFFBDBDBD),
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, bool> _expandedState = {};
  final Map<String, GlobalKey> _headerKeys = {};
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  // 收合某個系列時，若目前已捲動到它的內容裡，
  // 收合後把該系列標題重新對齊到頂端，避免整個清單「跟著往下滑」。
  void _keepHeaderPinnedAfterCollapse(String setCode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final ctx = _headerKeys[setCode]?.currentContext;
      final renderObject = ctx?.findRenderObject();
      if (renderObject == null) return;

      final viewport = RenderAbstractViewport.of(renderObject);
      final position = _scrollController.position;
      final target = viewport
          .getOffsetToReveal(renderObject, 0.0)
          .offset
          .clamp(position.minScrollExtent, position.maxScrollExtent);

      if (_scrollController.offset > target) {
        _scrollController.jumpTo(target);
      }
    });
  }

  StatusFilter _statusFilter = StatusFilter.all;
  FormatFilter _formatFilter = FormatFilter.standard;
  TypeFilter _typeFilter = TypeFilter.all;
  ElementFilter _elementFilter = ElementFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- 賽制過濾邏輯 ---
  bool _matchesFormat(dynamic cardData) {
    if (_formatFilter == FormatFilter.all) return true;
    String regMark = (cardData['reg'] ?? "").toString().toUpperCase();
    if (_formatFilter == FormatFilter.standard) {
      return ["H", "I", "J", "NONE"].contains(regMark);
    }
    return true;
  }

  // --- 種類過濾邏輯 ---
  bool _matchesType(dynamic cardData) {
    if (_typeFilter == TypeFilter.all) return true;
    String type = (cardData['type'] ?? "").toString();

    switch (_typeFilter) {
      case TypeFilter.pokemon:
        return type == "寶可夢";
      case TypeFilter.goods:
        return type == "訓練家|物品";
      case TypeFilter.supporter:
        return type == "訓練家|支援者";
      case TypeFilter.stadium:
        return type == "訓練家|競技場";
      case TypeFilter.tool:
        return type == "訓練家|道具";
      case TypeFilter.specialEnergy:
        return type == "特殊能量";
      case TypeFilter.basicEnergy:
        return type == "基本能量" || type == "能量";
      default:
        return true;
    }
  }

  // --- 屬性過濾邏輯（只有寶可夢卡有 elem）---
  bool _matchesElement(dynamic cardData) {
    if (_elementFilter == ElementFilter.all) return true;
    return (cardData['elem'] ?? "").toString() == kElementLabels[_elementFilter];
  }

  Color _getThemeColor(bool isDeckMode) {
    if (_statusFilter == StatusFilter.inDeck) return Colors.teal.shade400;
    if (_statusFilter == StatusFilter.used) return Colors.blueGrey.shade600;
    if (isDeckMode) return Colors.teal.shade800;

    if (_statusFilter == StatusFilter.duplicates ||
        _statusFilter == StatusFilter.competitive) {
      return Colors.deepPurple.shade700;
    }
    if (_statusFilter == StatusFilter.owned) return Colors.green.shade700;
    if (_statusFilter == StatusFilter.missing) return Colors.orange.shade800;
    if (_formatFilter == FormatFilter.standard) return Colors.blue.shade700;
    if (_formatFilter == FormatFilter.expanded) return Colors.purple.shade700;
    return Colors.redAccent;
  }

  String _getAppBarTitle(bool isDeckMode) {
    if (_isSearching) return "";
    String title = "PokeScan TW";
    if (_statusFilter == StatusFilter.inDeck)
      title = "當前牌組內容";
    else if (_statusFilter == StatusFilter.used)
      title = "已使用的卡片";
    else if (isDeckMode)
      title = "正在編輯牌組";
    else {
      switch (_statusFilter) {
        case StatusFilter.owned:
          title = "我的收藏";
          break;
        case StatusFilter.missing:
          title = "缺卡清單";
          break;
        case StatusFilter.duplicates:
          title = "重複卡片 (>1)";
          break;
        case StatusFilter.competitive:
          title = "多餘物資 (>4)";
          break;
        default:
          break;
      }
    }
    return title;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CollectionProvider>(context);
    final deckProvider = Provider.of<DeckProvider>(context);

    final activeDeck = deckProvider.currentDeck;
    final bool isDeckMode = activeDeck != null;
    final themeColor = _getThemeColor(isDeckMode);

    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth < 600 ? 3 : (screenWidth < 1000 ? 5 : 8);

    if (provider.isLoading) {
      return Scaffold(
          body: Center(child: CircularProgressIndicator(color: themeColor)));
    }

    List<Widget> slivers = [];
    String query = _searchText.trim().toLowerCase();

    var sortedKeys = provider.database.keys.toList();
    sortedKeys.sort((a, b) => (provider.database[b]['releaseDate'] ?? "")
        .compareTo(provider.database[a]['releaseDate'] ?? ""));

    for (String setCode in sortedKeys) {
      var setData = provider.database[setCode];

      if (setData == null || setData['cards'] == null) continue; 

      Map allCards = setData['cards'];
      Map filteredCards = {};

      allCards.forEach((k, v) {
        String fullId = "$setCode-$k";
        int count = provider.userCollection[fullId] ?? 0;

        if (_statusFilter == StatusFilter.inDeck) {
          if (!isDeckMode || !activeDeck.cards.containsKey(fullId)) return;
        } else if (_statusFilter == StatusFilter.used) {
          final usages = deckProvider.getCardUsages(fullId);
          if (usages.isEmpty) return;
        } else {
          if (_statusFilter == StatusFilter.owned && count == 0) return;
          if (_statusFilter == StatusFilter.missing && count > 0) return;
          if (_statusFilter == StatusFilter.duplicates && count <= 1) return;
          if (_statusFilter == StatusFilter.competitive && count <= 4) return;
        }

        if (!_matchesFormat(v)) return;
        if (!_matchesType(v)) return;
        if (!_matchesElement(v)) return;

        if (query.isNotEmpty) {
          String cardName = v['name'].toString().toLowerCase();
          String rarity = (v['rarity'] ?? "").toString().toLowerCase();
          String cardNumber = k.toLowerCase();
          String setCodeLower = setCode.toLowerCase();
          String setName = setData['name'].toString().toLowerCase();

          bool matchesText = cardName.contains(query) ||
              rarity.contains(query) ||
              cardNumber.contains(query) ||
              setCodeLower.contains(query) ||
              setName.contains(query);
          if (!matchesText) return;
        }
        filteredCards[k] = v;
      });

      if (filteredCards.isEmpty) continue;

      int ownedInSet = allCards.keys
          .where((k) => provider.userCollection.containsKey("$setCode-$k"))
          .length;

      bool isExpanded = (query.isNotEmpty ||
              _statusFilter == StatusFilter.inDeck ||
              _statusFilter == StatusFilter.used ||
              _typeFilter != TypeFilter.all ||
              _elementFilter != ElementFilter.all)
          ? true
          : (_expandedState[setCode] ?? false);

      slivers.add(
        MultiSliver(
          pushPinnedChildren: true,
          children: [
            SliverPinnedHeader(
              child: SetHeader(
                key: _headerKeys.putIfAbsent(setCode, () => GlobalKey()),
                title: setData['name'],
                setCode: setCode,
                progress:
                    allCards.isNotEmpty ? ownedInSet / allCards.length : 0,
                owned: ownedInSet,
                total: allCards.length,
                isExpanded: isExpanded,
                themeColor: themeColor,
                onTap: () {
                  if (query.isEmpty &&
                      _statusFilter != StatusFilter.inDeck &&
                      _statusFilter != StatusFilter.used &&
                      _typeFilter == TypeFilter.all &&
                      _elementFilter == ElementFilter.all) {
                    final bool willCollapse = isExpanded;
                    setState(() => _expandedState[setCode] = !isExpanded);
                    if (willCollapse) {
                      _keepHeaderPinnedAfterCollapse(setCode);
                    }
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
                    (ctx, i) => CardGridItem(
                        setCode: setCode,
                        cNum: filteredCards.keys.elementAt(i),
                        cardData: filteredCards.values.elementAt(i)),
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
          tooltip: "使用說明",
          onPressed: () => _showHelpDialog(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                    hintText: "搜尋名稱 / 編號 / 稀有度 / 系列...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70)),
                onChanged: (val) => setState(() => _searchText = val),
                onSubmitted: (val) {
                  setState(() => _searchText = val);
                  FocusScope.of(context).unfocus();
                },
              )
            : Text(_getAppBarTitle(isDeckMode),
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
                  })),
          _buildFilterMenu(isDeckMode),
          IconButton(
              icon: const Icon(Icons.style),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DeckListScreen()))),
          Consumer<CollectionProvider>(
            builder: (context, prov, _) => prov.user == null
                ? IconButton(
                    icon: const Icon(Icons.login),
                    onPressed: () => prov.signInWithGoogle())
                : InkWell(
                    onTap: () => _showLogoutDialog(context, prov),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: CircleAvatar(
                          radius: 14,
                          backgroundImage: prov.user!.photoURL != null
                              ? NetworkImage(prov.user!.photoURL!)
                              : null),
                    ),
                  ),
          ),
        ],
        bottom: activeDeck == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                          activeDeck.isBinder
                              ? Icons.menu_book
                              : Icons.edit_note,
                          color: Colors.white,
                          size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              "編輯：${activeDeck.name} (${activeDeck.cards.values.fold(0, (sum, c) => sum + c)}${activeDeck.isBinder ? '' : '/60'})",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13))),
                      TextButton(
                          onPressed: () {
                            deckProvider.selectDeck(null);
                            setState(() {
                              _statusFilter = StatusFilter.all;
                              _typeFilter = TypeFilter.all;
                              _elementFilter = ElementFilter.all;
                            });
                          },
                          child: const Text("完成",
                              style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ),
      ),
      body: CustomScrollView(
          controller: _scrollController, cacheExtent: 1000, slivers: slivers),

      // --- 【重點修改：智慧掃描按鈕】 ---
      floatingActionButton: kIsWeb
          ? null
          : FloatingActionButton(
              backgroundColor: themeColor,
              child: const Icon(Icons.qr_code_scanner, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScannerScreen()),
                );
              },
            ),
    );
  }

  // 下拉選單組件
  Widget _buildFilterMenu(bool isDeckMode) {
    return PopupMenuButton<dynamic>(
      icon: const Icon(Icons.filter_list),
      onSelected: (value) => setState(() {
        if (value is StatusFilter) _statusFilter = value;
        if (value is FormatFilter) _formatFilter = value;
        if (value is TypeFilter) _typeFilter = value;
        if (value is ElementFilter) _elementFilter = value;
      }),
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
        if (isDeckMode)
          _buildPopupItem(StatusFilter.inDeck, Icons.fact_check, "這副牌的卡片",
              _statusFilter == StatusFilter.inDeck),
        _buildPopupItem(StatusFilter.used, Icons.inventory, "已使用的卡片",
            _statusFilter == StatusFilter.used),
        _buildPopupItem(StatusFilter.owned, Icons.check_circle, "只看已擁有",
            _statusFilter == StatusFilter.owned),
        _buildPopupItem(StatusFilter.missing, Icons.radio_button_unchecked,
            "只看未擁有", _statusFilter == StatusFilter.missing),
        _buildPopupItem(StatusFilter.duplicates, Icons.copy, "重複 (>1)",
            _statusFilter == StatusFilter.duplicates),
        _buildPopupItem(StatusFilter.competitive, Icons.layers, "多餘物資 (>4)",
            _statusFilter == StatusFilter.competitive),
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
        const PopupMenuDivider(),
        const PopupMenuItem(
            enabled: false,
            child: Text("種類篩選",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey))),
        _buildPopupItem(TypeFilter.all, Icons.dashboard_customize, "所有種類",
            _typeFilter == TypeFilter.all),
        _buildPopupItem(TypeFilter.pokemon, Icons.catching_pokemon, "寶可夢",
            _typeFilter == TypeFilter.pokemon),
        _buildPopupItem(TypeFilter.goods, Icons.shopping_bag, "物品",
            _typeFilter == TypeFilter.goods),
        _buildPopupItem(TypeFilter.supporter, Icons.person, "支援者",
            _typeFilter == TypeFilter.supporter),
        _buildPopupItem(TypeFilter.stadium, Icons.stadium, "競技場",
            _typeFilter == TypeFilter.stadium),
        _buildPopupItem(TypeFilter.tool, Icons.build_circle, "道具",
            _typeFilter == TypeFilter.tool),
        _buildPopupItem(TypeFilter.specialEnergy, Icons.stars, "特殊能量",
            _typeFilter == TypeFilter.specialEnergy),
        _buildPopupItem(TypeFilter.basicEnergy, Icons.flash_on, "基本能量",
            _typeFilter == TypeFilter.basicEnergy),
        const PopupMenuDivider(),
        const PopupMenuItem(
            enabled: false,
            child: Text("屬性篩選",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey))),
        _buildElementItem(ElementFilter.all, "所有屬性"),
        for (final e in ElementFilter.values)
          if (e != ElementFilter.all)
            _buildElementItem(e, kElementLabels[e]!),
      ],
    );
  }

  PopupMenuEntry<dynamic> _buildElementItem(ElementFilter value, String title) {
    final bool isSelected = _elementFilter == value;
    final Color activeColor = _getThemeColor(false);
    final Color dot = kElementColors[value] ?? Colors.grey;
    return PopupMenuItem<dynamic>(
      value: value,
      child: Row(
        children: [
          value == ElementFilter.all
              ? Icon(Icons.blur_on,
                  size: 20, color: isSelected ? activeColor : Colors.grey)
              : Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.black12, width: 1))),
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

  PopupMenuEntry<dynamic> _buildPopupItem(
      dynamic value, IconData icon, String title, bool isSelected) {
    Color activeColor = _getThemeColor(false);
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
        builder: (ctx) => AlertDialog(
                title: const Text("登出"),
                content: Text("確定要登出 ${provider.user!.displayName} 嗎？"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("取消")),
                  TextButton(
                      onPressed: () {
                        provider.signOut();
                        Navigator.pop(ctx);
                      },
                      child:
                          const Text("登出", style: TextStyle(color: Colors.red)))
                ]));
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.style, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("PokeScan TW 使用手冊"),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "歡迎使用 PokeScan TW！這是一款專為繁體中文 PTCG 玩家與收藏家設計的工具，支援雲端同步、牌組構建與詳細的收藏管理。",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const Divider(height: 30),
                _buildHelpHeader("1. 基礎收藏管理", Icons.touch_app),
                _buildHelpItem("增加數量", "直接點擊卡片，收藏數量 +1。"),
                _buildHelpItem("減少數量", "長按卡片即可減少數量 -1。\n加速功能：按越久減越快。"),
                _buildHelpItem(
                    "視覺辨識", "• 彩色：已擁有該卡片\n• 黑白半透明：尚未收藏\n• 左上角紅圈：持有總數量"),
                _buildHelpHeader("2. 強大的搜尋與過濾", Icons.search),
                _buildHelpItem(
                    "全方位搜尋", "點擊放大鏡輸入 名稱 / 編號 / 稀有度 / 系列名，按 Enter 執行。"),
                _buildHelpItem("多重過濾", "點擊漏斗切換收藏狀態、賽制環境或卡片種類。"),
                const Padding(
                  padding: EdgeInsets.only(left: 12, top: 4),
                  child: Column(
                    children: [
                      _ColorTip(Colors.redAccent, "紅色：一般瀏覽"),
                      _ColorTip(Colors.green, "綠色：只看已擁有"),
                      _ColorTip(Colors.orange, "橘色：只看缺卡"),
                      _ColorTip(Colors.deepPurple, "紫色：資產清點"),
                      _ColorTip(Colors.blue, "藍色：標準賽制環境"),
                    ],
                  ),
                ),
                _buildHelpHeader("3. 牌組與收藏本系統", Icons.style),
                _buildHelpItem("種類區分", "• 牌組：限 60 張、同名 4 張限制\n• 收藏本：無張數與同名限制"),
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("🛠️ 編輯模式",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      const Text("點擊「板手」進入。上方顯示青色條。",
                          style:
                              TextStyle(fontSize: 13, color: Colors.black54)),
                      const Text("• 點擊卡片改為「放入牌組」",
                          style:
                              TextStyle(fontSize: 13, color: Colors.black54)),
                      _LabelRow(Colors.teal.shade600, "青標籤：庫存充足"),
                      _LabelRow(Colors.red.shade900, "紅標籤 + ⚠️：實體收藏不足"),
                    ],
                  ),
                ),
                _buildHelpHeader("4. 進階實戰功能", Icons.bolt),
                _buildHelpItem("卡片用途查詢", "非編輯模式點擊卡片底部「用於 N 副牌」可查看具體位置。"),
                _buildHelpItem("一鍵導出", "牌組清單點「複製」可生成對齊的分享文字。"),
                _buildHelpItem("雲端同步", "登入 Google 帳號後，收藏與牌組將跨裝置自動同步。"),
                const Divider(height: 30),
                _buildHelpHeader("💡 小提示", Icons.lightbulb_outline),
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text(
                    "• 基本能量在牌組模式下不受 4 張限制。\n• 點擊系列標題橫條可以收合或展開內容。\n• 內建智慧縮圖，第二次開啟卡片將秒開。",
                    style: TextStyle(
                        fontSize: 13, color: Colors.blueGrey, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("我知道了",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey.shade700),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey)),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 2),
          Text(content,
              style: const TextStyle(
                  fontSize: 13, color: Colors.black54, height: 1.4)),
        ],
      ),
    );
  }
}

// 顏色提示
class _ColorTip extends StatelessWidget {
  final Color color;
  final String text;
  const _ColorTip(this.color, this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}

// 標籤範例
class _LabelRow extends StatelessWidget {
  final Color color;
  final String text;
  const _LabelRow(this.color, this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(4)),
            child: const Text("IN: 1",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }
}
