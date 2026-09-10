import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../providers/collection_provider.dart';
import '../providers/deck_provider.dart';
import '../widgets/card_grid_item.dart';
import '../widgets/set_header.dart';
import 'deck_list_screen.dart';
import 'scanner_screen.dart';
import 'settings_screen.dart';

// 狀態過濾
enum StatusFilter {
  all,
  owned,
  missing,
  duplicates,
  competitive,
  inDeck,
  used,
  wishlist
}

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
  ElementFilter.fighting: "鬥",
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

const Map<TypeFilter, String> kTypeFilterLabels = {
  TypeFilter.all: "所有種類",
  TypeFilter.pokemon: "寶可夢",
  TypeFilter.goods: "物品",
  TypeFilter.supporter: "支援者",
  TypeFilter.stadium: "競技場",
  TypeFilter.tool: "道具",
  TypeFilter.specialEnergy: "特殊能量",
  TypeFilter.basicEnergy: "基本能量",
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
  bool _firstRunHintDismissed = false;
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
  String? _rarityFilter; // null = 全部；"" = 無標記
  String? _tagFilter; // null = 全部

  bool _formatTouched = false;

  @override
  void initState() {
    super.initState();
    // 只記住上次的「賽制」篩選（其他篩選每次開 App 還原預設）
    SharedPreferences.getInstance().then((prefs) {
      final f = prefs.getString('last_format');
      // 若使用者在讀取完成前已自己選過賽制，就不要覆蓋
      if (f != null && mounted && !_formatTouched) {
        setState(() {
          _formatFilter = FormatFilter.values.firstWhere((e) => e.name == f,
              orElse: () => FormatFilter.standard);
        });
      }
    });
  }

  void _setFormat(FormatFilter f) {
    _formatTouched = true;
    _formatFilter = f;
    SharedPreferences.getInstance()
        .then((p) => p.setString('last_format', f.name));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- 賽制過濾邏輯（標準 reg 清單 / 過往可用卡清單來自 formats.json，見 collection_provider）---
  bool _matchesFormat(
      dynamic cardData, Set<String> standardRegs, Set<String> standardNames) {
    if (_formatFilter == FormatFilter.all) return true;
    if (_formatFilter == FormatFilter.standard) {
      final regs = standardRegs.isEmpty
          ? const {"H", "I", "J", "NONE"}
          : standardRegs;
      if (regs.contains((cardData['reg'] ?? "").toString().toUpperCase())) {
        return true;
      }
      return standardNames.contains((cardData['name'] ?? "").toString());
    }
    return true; // 開放：台灣無殿堂 / extra 限制，全部合法
  }

  // --- 稀有度過濾（動態，值來自資料裡實際出現的 rarity）---
  bool _matchesRarity(dynamic cardData) {
    if (_rarityFilter == null) return true;
    return (cardData['rarity'] ?? "").toString() == _rarityFilter;
  }

  // --- 機制標籤過濾（單選）---
  bool _matchesTag(dynamic cardData) {
    if (_tagFilter == null) return true;
    final tags = cardData['tags'];
    return tags is List && tags.contains(_tagFilter);
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
    if (_statusFilter == StatusFilter.wishlist) return Colors.pink.shade400;
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
    String title = "繁中PTCG集換所";
    if (_statusFilter == StatusFilter.wishlist)
      title = "願望清單";
    else if (_statusFilter == StatusFilter.inDeck)
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

    if (provider.loadFailed) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text("卡片資料載入失敗",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("請確認網路連線後再試一次。",
                    style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.read<CollectionProvider>().retry(),
                  icon: const Icon(Icons.refresh),
                  label: const Text("重試"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    List<Widget> slivers = [];
    String query = _searchText.trim().toLowerCase();

    // 首次使用引導：全新使用者（收藏是空的）、且在預設檢視時，
    // 上方顯示一次性提示，加入第一張卡或關掉後就不再出現。
    final bool showFirstRunHint = !_firstRunHintDismissed &&
        !isDeckMode &&
        query.isEmpty &&
        _statusFilter == StatusFilter.all &&
        provider.userCollection.isEmpty &&
        provider.wishlist.isEmpty;
    if (showFirstRunHint) {
      slivers.add(SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.waving_hand, color: themeColor, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                      child: Text("開始使用",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15))),
                  InkWell(
                    onTap: () =>
                        setState(() => _firstRunHintDismissed = true),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 18, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "• 點卡片：收藏數 +1\n"
                "• 長按卡片：看詳情、調整「收藏 / 這副 / 想要」張數\n"
                "• 右下角相機：對準卡片左下角編號自動登錄\n"
                "• 右上角圖示：搜尋 / 篩選 / 牌組　·　頭像：設定與完整說明",
                style: TextStyle(
                    fontSize: 13, color: Colors.black54, height: 1.7),
              ),
            ],
          ),
        ),
      ));
    }

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
        } else if (_statusFilter == StatusFilter.wishlist) {
          if (!provider.wishlist.containsKey(fullId)) return;
        } else {
          if (_statusFilter == StatusFilter.owned && count == 0) return;
          if (_statusFilter == StatusFilter.missing && count > 0) return;
          if (_statusFilter == StatusFilter.duplicates && count <= 1) return;
          if (_statusFilter == StatusFilter.competitive && count <= 4) return;
        }

        if (!_matchesFormat(v, provider.standardRegs, provider.standardNames))
          return;
        if (!_matchesType(v)) return;
        if (!_matchesElement(v)) return;
        if (!_matchesRarity(v)) return;
        if (!_matchesTag(v)) return;

        if (query.isNotEmpty) {
          String cardName = v['name'].toString().toLowerCase();
          String cardNumber = k.toLowerCase();
          String setCodeLower = setCode.toLowerCase();
          String setName = setData['name'].toString().toLowerCase();

          bool matchesText = cardName.contains(query) ||
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
              _statusFilter == StatusFilter.wishlist ||
              _typeFilter != TypeFilter.all ||
              _elementFilter != ElementFilter.all ||
              _rarityFilter != null ||
              _tagFilter != null)
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
                      _statusFilter != StatusFilter.wishlist &&
                      _typeFilter == TypeFilter.all &&
                      _elementFilter == ElementFilter.all &&
                      _rarityFilter == null &&
                      _tagFilter == null) {
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
          if (_statusFilter == StatusFilter.wishlist)
            IconButton(
              icon: const Icon(Icons.copy_all),
              tooltip: "複製願望清單",
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await Clipboard.setData(ClipboardData(
                      text: provider.generateWishlistText()));
                  messenger.showSnackBar(const SnackBar(
                      content: Text("願望清單已複製"),
                      duration: Duration(seconds: 1)));
                } catch (_) {
                  messenger.showSnackBar(const SnackBar(
                      content: Text("複製失敗"),
                      duration: Duration(seconds: 1)));
                }
              },
            ),
          IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () => setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchText = "";
                      _searchController.clear();
                    }
                  })),
          _buildFilterButton(isDeckMode),
          IconButton(
              icon: const Icon(Icons.style),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DeckListScreen()))),
          Consumer<CollectionProvider>(
            builder: (context, prov, _) => InkWell(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white24,
                  backgroundImage: prov.user?.photoURL != null
                      ? NetworkImage(prov.user!.photoURL!)
                      : null,
                  child: prov.user?.photoURL == null
                      ? const Icon(Icons.person, size: 18, color: Colors.white)
                      : null,
                ),
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
                              "編輯：${activeDeck.name} (${deckProvider.deckSize(activeDeck, provider.database, provider.deckRules)}${activeDeck.isBinder ? '' : '/60'})",
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
                              _rarityFilter = null;
                              _tagFilter = null;
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

  // ---- 篩選面板（底部彈出 + chip 分組）----

  // 目前生效（非預設）的篩選數量。賽制預設是「標準」。
  int _activeFilterCount() {
    int n = 0;
    if (_statusFilter != StatusFilter.all) n++;
    if (_formatFilter != FormatFilter.standard) n++;
    if (_typeFilter != TypeFilter.all) n++;
    if (_elementFilter != ElementFilter.all) n++;
    if (_rarityFilter != null) n++;
    if (_tagFilter != null) n++;
    return n;
  }

  void _resetFilters() {
    _statusFilter = StatusFilter.all;
    _setFormat(FormatFilter.standard);
    _typeFilter = TypeFilter.all;
    _elementFilter = ElementFilter.all;
    _rarityFilter = null;
    _tagFilter = null;
  }

  Widget _buildFilterButton(bool isDeckMode) {
    final int count = _activeFilterCount();
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          tooltip: "篩選",
          onPressed: () => _openFilterSheet(isDeckMode),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              constraints:
                  const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: const BoxDecoration(
                  color: Colors.redAccent, shape: BoxShape.circle),
              child: Text("$count",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  void _openFilterSheet(bool isDeckMode) {
    final Color active = _getThemeColor(isDeckMode);
    final provider = Provider.of<CollectionProvider>(context, listen: false);
    final rarities = provider.availableRarities;
    final tags = provider.availableTags;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            void pick(VoidCallback apply) {
              setState(apply);
              setSheet(() {});
            }

            Widget chip(String label, bool selected, VoidCallback onTap,
                {Widget? avatar}) {
              return ChoiceChip(
                label: Text(label),
                avatar: avatar,
                selected: selected,
                showCheckmark: false,
                onSelected: (_) => onTap(),
                visualDensity: VisualDensity.compact,
                labelStyle: TextStyle(
                    fontSize: 13,
                    color: selected ? active : Colors.black87,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal),
                selectedColor: active.withOpacity(0.15),
                backgroundColor: const Color(0xFFF0F0F0),
                side: selected
                    ? BorderSide(color: active, width: 1.2)
                    : BorderSide(color: Colors.grey.shade300),
              );
            }

            Widget section(String title, List<Widget> chips) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: chips),
                    ],
                  ),
                );

            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.78),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text("篩選",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const Spacer(),
                          TextButton(
                            onPressed: _activeFilterCount() == 0
                                ? null
                                : () => pick(_resetFilters),
                            child: const Text("清除全部"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      section("收藏狀態", [
                        chip("全部", _statusFilter == StatusFilter.all,
                            () => pick(() => _statusFilter = StatusFilter.all)),
                        if (isDeckMode)
                          chip(
                              "這副牌的卡片",
                              _statusFilter == StatusFilter.inDeck,
                              () => pick(() =>
                                  _statusFilter = StatusFilter.inDeck)),
                        chip("已使用的卡片", _statusFilter == StatusFilter.used,
                            () => pick(
                                () => _statusFilter = StatusFilter.used)),
                        chip("願望清單", _statusFilter == StatusFilter.wishlist,
                            () => pick(
                                () => _statusFilter = StatusFilter.wishlist)),
                        chip("只看已擁有", _statusFilter == StatusFilter.owned,
                            () => pick(
                                () => _statusFilter = StatusFilter.owned)),
                        chip("只看未擁有", _statusFilter == StatusFilter.missing,
                            () => pick(
                                () => _statusFilter = StatusFilter.missing)),
                        chip("重複 (>1)",
                            _statusFilter == StatusFilter.duplicates,
                            () => pick(() =>
                                _statusFilter = StatusFilter.duplicates)),
                        chip("多餘物資 (>4)",
                            _statusFilter == StatusFilter.competitive,
                            () => pick(() =>
                                _statusFilter = StatusFilter.competitive)),
                      ]),
                      section("賽制", [
                        chip("不限", _formatFilter == FormatFilter.all,
                            () => pick(() => _setFormat(FormatFilter.all))),
                        chip("標準", _formatFilter == FormatFilter.standard,
                            () =>
                                pick(() => _setFormat(FormatFilter.standard))),
                        chip("開放", _formatFilter == FormatFilter.expanded,
                            () =>
                                pick(() => _setFormat(FormatFilter.expanded))),
                      ]),
                      section("種類", [
                        for (final e in kTypeFilterLabels.entries)
                          chip(e.value, _typeFilter == e.key,
                              () => pick(() => _typeFilter = e.key)),
                      ]),
                      section("屬性", [
                        chip("全部", _elementFilter == ElementFilter.all,
                            () => pick(() =>
                                _elementFilter = ElementFilter.all)),
                        for (final e in ElementFilter.values)
                          if (e != ElementFilter.all)
                            chip(
                              kElementLabels[e]!,
                              _elementFilter == e,
                              () => pick(() => _elementFilter = e),
                              avatar: CircleAvatar(
                                  radius: 7,
                                  backgroundColor: kElementColors[e]),
                            ),
                      ]),
                      if (rarities.isNotEmpty)
                        section("稀有度", [
                          chip("全部", _rarityFilter == null,
                              () => pick(() => _rarityFilter = null)),
                          for (final r in rarities)
                            chip(r.isEmpty ? "無標記" : r, _rarityFilter == r,
                                () => pick(() => _rarityFilter = r)),
                        ]),
                      if (tags.isNotEmpty)
                        section("機制", [
                          chip("全部", _tagFilter == null,
                              () => pick(() => _tagFilter = null)),
                          for (final t in tags)
                            chip(t, _tagFilter == t,
                                () => pick(() => _tagFilter = t)),
                        ]),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

}
